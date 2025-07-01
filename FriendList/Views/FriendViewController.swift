import UIKit
import Combine

fileprivate enum Section: Int, CaseIterable {
    case invite
    case segment
    case search
    case friends
    case empty
}

fileprivate enum Item: Hashable, Sendable {
    case invite(Friend)
    case segment(SegmentModel)
    case search(String)
    case friend(Friend)
    case empty
}

class FriendViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnKokoID: UIButton!
    @IBOutlet weak var imgBadge: UIImageView!
    
    var viewModel: FriendViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let refreshCtrl = UIRefreshControl()
    private var selectCateIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = .pinkEC008C
        setupNavigationBar()
        setupNavigationBarItems()
        configureCollectionView()
        setupRefreshControl()
        configureDataSource()
        guard let viewModel = viewModel else { return }
        bindViewModel(viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.fetchData()
    }
    
    @objc private func didPullToRefresh() {
        viewModel?.fetchData()
    }

    private func bindViewModel(_ viewModel: FriendViewModel) {
        Publishers.CombineLatest3(viewModel.$user, viewModel.$friends, viewModel.$invites)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user, friends, invites in
                guard let self = self else { return }
                self.applySnapshot(friends: friends, invites: invites)
                self.updateUserInfoView(user ?? User(name: "", kokoid: ""))
                self.refreshCtrl.endRefreshing()
            }
            .store(in: &cancellables)
        
        //for search
        viewModel.$filteredFriends
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filteredFriends in
                guard let self = self else { return }
                self.applySnapshot(friends: self.viewModel?.friends ?? [],
                                   filterFriends: filteredFriends,
                                   invites: self.viewModel?.invites ?? [])
            }
            .store(in: &cancellables)

        // Show a simple alert whenever the view model reports an error.
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func updateUserInfoView(_ user: User) {
        var text = ""
        let kokoid = user.kokoid
        if kokoid.isEmpty {
            text = "設定 KOKO ID"
            self.imgBadge.isHidden = false
        } else {
            text = "KOKO ID: \(kokoid)"
            self.imgBadge.isHidden = true
        }
        var config = UIButton.Configuration.plain()
        config.title = text
        config.image = .icInfoBackDeepGray
        config.imagePlacement = .trailing
        config.titleAlignment = .leading
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13)
            return outgoing
        }
        self.btnKokoID.configuration = config
        self.lblName.text = user.name
    }
    
    //MARK: Navigation bar related

    private func setupNavigationBarItems() {
        let withdrawButton = UIBarButtonItem(image: UIImage(named: "icNavPinkWithdraw"), style: .plain, target: self, action: #selector(atmTapped))
        let transferButton = UIBarButtonItem(image: UIImage(named: "icNavPinkTransfer"), style: .plain, target: self, action: #selector(transferTapped))
        navigationItem.leftBarButtonItems = [withdrawButton, transferButton]

        let scanButton = UIBarButtonItem(image: UIImage(named: "icNavPinkScan"), style: .plain, target: self, action: #selector(scanTapped))
        navigationItem.rightBarButtonItem = scanButton
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .grayFCFCFC
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func atmTapped() {}
    @objc private func transferTapped() {}
    @objc private func scanTapped() {}
    
    //MARK: collectionView related

    private func configureCollectionView() {
        collectionView.collectionViewLayout = createLayout()
        collectionView.collectionViewLayout.register(SeparatorDecorationView.self, forDecorationViewOfKind: SeparatorDecorationView.elementKind)
    }
    
    private func setupRefreshControl() {
        refreshCtrl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshCtrl
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .invite(let friend):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InviteCell", for: indexPath) as! InviteCell
                cell.configure(with: friend)
                return cell
            case .segment(let model):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentCell", for: indexPath) as! SegmentCell
                cell.configure(model)
                return cell
            case .search:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCell", for: indexPath) as! SearchCell
                cell.configure(with: self)
//                cell.searchBar.tag = indexPath.section
                return cell
            case .friend(let friend):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCell", for: indexPath) as! FriendCell
                cell.configure(with: friend)
                return cell
            case .empty:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! EmptyCell
                cell.configure(with: self)
                return cell
            }
        }

    }

    private func applySnapshot(friends: [Friend], filterFriends: [Friend]? = nil, invites: [Friend]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.invite, .segment, .search, .friends])
        snapshot.appendItems(invites.map { .invite($0) }, toSection: .invite)
        
        let segments: [SegmentModel] = [
            SegmentModel(title: "好友", isSelected: selectCateIndex == 0, badgeCount: invites.count),
            SegmentModel(title: "聊天", isSelected: selectCateIndex == 1, badgeCount: friends.isEmpty ? 0 : 99)
        ]
        snapshot.appendItems(segments.map { .segment($0) }, toSection: .segment)
        
        if friends.isEmpty {
            snapshot.appendSections([.empty])
            snapshot.appendItems([.empty], toSection: .empty)
        } else {
            snapshot.appendItems([.search("search")], toSection: .search)
            if let filterFriends = filterFriends {
                snapshot.appendItems(filterFriends.map { .friend($0) }, toSection: .friends)
            } else {
                snapshot.appendItems(friends.map { .friend($0) }, toSection: .friends)
            }
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            let section = Section(rawValue: sectionIndex)!
            var layoutSection: NSCollectionLayoutSection

            switch section {
            case .invite:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(88))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(176))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 2)
                layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.orthogonalScrollingBehavior = .continuous

//                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
//                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
//                layoutSection.boundarySupplementaryItems = [header]

            case .segment:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(36))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                layoutSection = NSCollectionLayoutSection(group: group)
                let decoration = NSCollectionLayoutDecorationItem.background(
                    elementKind: SeparatorDecorationView.elementKind)
                decoration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0)
                layoutSection.decorationItems = [decoration]

            case .search:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(70))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                layoutSection = NSCollectionLayoutSection(group: group)

            case .friends:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                layoutSection = NSCollectionLayoutSection(group: group)
//                layoutSection.orthogonalScrollingBehavior = .continuous
                
            case .empty:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(445))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                return NSCollectionLayoutSection(group: group)
            }

            return layoutSection
        }
    }
}

extension FriendViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == Section.segment.rawValue else { return }
        selectCateIndex = indexPath.row
        
        //update UI
        applySnapshot(friends: viewModel?.friends ?? [],
                      invites: viewModel?.invites ?? [])
    }
}

extension FriendViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        //TODO: to set KOKO ID
        return false
    }
}

extension FriendViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel?.filterFriends(by: searchText)
    }
}

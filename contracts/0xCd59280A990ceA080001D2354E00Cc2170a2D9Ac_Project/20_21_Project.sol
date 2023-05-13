// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IProject.sol";
import "./interfaces/IClaimPool.sol";
import "./interfaces/IClaimPoolFactory.sol";
import "./interfaces/IHLPClaimPool.sol";
import "./interfaces/ITaskManager.sol";
import "./lib/TransferHelper.sol";
import "./Validatable.sol";

/**
 *  @title  Dev Project
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract Project manager.
 */

contract Project is IProject, Validatable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 public constant DENOMINATOR = 1e4;

    /**
     *  @notice _projectCounter uint256 (counter). This is the counter for store
     *          current project ID value in storage.
     */
    CountersUpgradeable.Counter private _projectCounter;

    /**
     *  @notice claimPoolFactory is address of ClaimPoolFactory contract
     */
    IClaimPoolFactory public claimPoolFactory;

    /**
     *  @notice hlpClaimPool is address of HLPClaimPool contract
     */
    IHLPClaimPool public hlpClaimPool;

    /**
     *  @notice rewardAddress is address of Reward contract
     */
    address public rewardAddress;

    /**
     *  @notice taskManager is address of TaskManager contract
     */
    address public taskManager;

    /**
     *  @notice maxCollectionInProject is max collection of project
     */
    uint256 public maxCollectionInProject;

    /**
     *  @notice mapping from project ID to ProjectInfo
     */
    mapping(uint256 => ProjectInfo) private projects;

    /**
     *  @notice mapping from project ID to list collection address
     */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private collectionAddress;

    /**
     *  @notice mapping from collection address to project id
     */
    mapping(address => uint256) public collectionToProjects;

    /**
     *  @notice mapping from collection address to CollectionInfo
     */
    mapping(address => mapping(uint256 => CollectionInfo)) public collectionInfos;

    event RegisterTaskManager(address indexed taskManager);
    event SetClaimPoolFactory(IClaimPoolFactory indexed oldValue, IClaimPoolFactory indexed newValue);
    event SetHLPClaimPool(IHLPClaimPool indexed oldValue, IHLPClaimPool indexed newValue);
    event SetRewardAddress(address indexed oldValue, address indexed newValue);
    event SetMaxCollectionInProject(uint256 oldValue, uint256 newValue);
    event CreatedProject(uint256 indexed projectId, string projectIdOffChain);
    event RemovedProject(uint256 indexed projectId);
    event Deposited(uint256 indexed projectId, uint256 amount);
    event DepositedToCollection(uint256 indexed projectId, address collectionAddress, uint256 amount);
    event SplittedBudget(uint256 indexed projectId, uint256 amount);
    event AddedCollection(uint256 indexed projectId, CollectionInfo[] _collections, uint256[] percents);
    event RemovedCollection(uint256 indexed projectId, address collectionAddress);
    event UpdatedPercent(uint256 indexed projectId, uint256[] percents);
    event UpdatedRewardRarityPercent(
        uint256 indexed projectId,
        address indexed collectionAddress,
        uint256[] rewardRarityPercents
    );
    event WithdrawnCollection(uint256 indexed projectId, address indexed collection, uint256 amount);

    /**
     * @notice Initialize new logic contract.
     * @dev    Replace for contructor function
     * @param _admin Address of admin contract
     * @param _claimPoolFactory Address of Claim Pool Factory contract
     * @param _hlpClaimPool Address of HLP Claim Pool contract
     * @param _reward Address of reward contract
     */
    function initialize(
        IAdmin _admin,
        address _claimPoolFactory,
        address _hlpClaimPool,
        address _reward
    ) public initializer {
        __Validatable_init(_admin);
        __ReentrancyGuard_init();
        claimPoolFactory = IClaimPoolFactory(_claimPoolFactory);
        hlpClaimPool = IHLPClaimPool(_hlpClaimPool);
        rewardAddress = _reward;
        maxCollectionInProject = 20;

        if (hlpClaimPool.project() == address(0)) {
            hlpClaimPool.registerProject();
        }
    }

    /**
     * Throw an exception if project id is not valid
     */
    modifier validProjectId(uint256 projectId) {
        require(projectId > 0 && projectId <= _projectCounter.current(), "Invalid projectId");
        _;
    }

    /**
     * Throw an exception if caller is not project owner
     */
    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].projectOwner == _msgSender(), "Caller is not project owner");
        _;
    }

    /**
     * @notice Register Project to allow it order methods of this contract
     *
     * @dev    Register can only be called once
     *
     * emit {RegisterTaskManager} events
     */
    function registerTaskManager() external {
        require(taskManager == address(0), "Already register");
        taskManager = _msgSender();
        emit RegisterTaskManager(taskManager);
    }

    // Manager function
    /**
     * @notice Set address claim pool factory
     *
     * @dev    Only owner can call this function.
     *
     * @param  _claimPoolFactory   Address of claim pool factory.
     *
     * emit {SetClaimPoolFactory} events
     */
    function setClaimPoolFactory(address _claimPoolFactory) external onlyOwner notZeroAddress(_claimPoolFactory) {
        require(_claimPoolFactory != address(claimPoolFactory), "ClaimPoolFactory already exists");

        IClaimPoolFactory _oldValue = claimPoolFactory;
        claimPoolFactory = IClaimPoolFactory(_claimPoolFactory);
        emit SetClaimPoolFactory(_oldValue, claimPoolFactory);
    }

    /**
     * @notice Set address HLP claim pool
     *
     * @dev    Only owner can call this function.
     *
     * @param  _hlpClaimPool   Address of HLP claim pool.
     *
     * emit {SetHLPClaimPool} events
     */
    function setHLPClaimPool(address _hlpClaimPool) external onlyOwner notZeroAddress(_hlpClaimPool) {
        require(_hlpClaimPool != address(hlpClaimPool), "HLPClaimPool already exists");

        IHLPClaimPool _oldValue = hlpClaimPool;
        hlpClaimPool = IHLPClaimPool(_hlpClaimPool);
        emit SetHLPClaimPool(_oldValue, hlpClaimPool);
    }

    /**
     *  @notice Set address reward
     *
     *  @dev    Only owner can call this function.
     *
     *  @param  _rewardAddress   Address of Reward contract.
     *
     *  emit {SetRewardAddress} events
     */
    function setRewardAddress(address _rewardAddress) external onlyOwner notZeroAddress(_rewardAddress) {
        require(_rewardAddress != rewardAddress, "RewardAddress already exists");

        address _oldValue = rewardAddress;
        rewardAddress = _rewardAddress;
        emit SetRewardAddress(_oldValue, rewardAddress);
    }

    /**
     *  @notice Set max collection in a project
     *
     *  @dev    Only owner can call this function.
     *
     *  @param  _maxCollectionInProject   max of collection in a project.
     *
     *  emit {SetMaxCollectionInProject} events
     */
    function setMaxCollectionInProject(
        uint256 _maxCollectionInProject
    ) external onlyOwner notZero(_maxCollectionInProject) {
        require(_maxCollectionInProject != maxCollectionInProject, "MaxCollectionInProject already exists");

        uint256 _oldValue = maxCollectionInProject;
        maxCollectionInProject = _maxCollectionInProject;
        emit SetMaxCollectionInProject(_oldValue, maxCollectionInProject);
    }

    // Main function
    /**
     * @notice Create project.
     * @dev    Everyone can call this function.
     * @param _idOffChain id of chain
     * @param _paymentToken Address of payment token (address(0) for native token)
     * @param _collections List of nft
     *
     * emit {CreatedProject} events
     */
    function createProject(
        string memory _idOffChain,
        address _paymentToken,
        uint256 _budget,
        CollectionInfo[] memory _collections
    ) external payable nonReentrant {
        require(_collections.length > 0 && _collections.length <= maxCollectionInProject, "Invalid length");

        _projectCounter.increment();
        ProjectInfo storage projectInfo = projects[_projectCounter.current()];
        projectInfo.projectId = _projectCounter.current();
        projectInfo.idOffChain = _idOffChain;
        projectInfo.paymentToken = _paymentToken;
        projectInfo.projectOwner = _msgSender();
        projectInfo.budget = _budget;
        projectInfo.status = true;

        uint256 _total = 0;
        for (uint256 i = 0; i < _collections.length; i++) {
            require(
                _collections[i].collectionAddress != address(0) &&
                    collectionToProjects[_collections[i].collectionAddress] == 0,
                "Invalid collection address or collection is already in use"
            );
            _total += _collections[i].rewardPercent;
            if (_collections[i].rewardRarityPercents.length > 0) {
                checkValidPercent(_collections[i].rewardRarityPercents);
            }
            collectionInfos[_collections[i].collectionAddress][_projectCounter.current()] = _collections[i];
            //slither-disable-next-line unused-return
            collectionAddress[_projectCounter.current()].add(_collections[i].collectionAddress);
            collectionToProjects[_collections[i].collectionAddress] = _projectCounter.current();
        }
        require(_total == DENOMINATOR, "The total percentage must be equal to 100%");

        //slither-disable-next-line reentrancy-no-eth
        address _claimPool = claimPoolFactory.create(address(this), _paymentToken);
        projectInfo.claimPool = _claimPool;

        if (_budget > 0) {
            if (_paymentToken == address(0)) {
                require(msg.value == _budget, "Invalid amount");
            }
            _splitBudget(projectInfo, _budget);
            TransferHelper._transferToken(_paymentToken, _budget, _msgSender(), _claimPool);
        }

        emit CreatedProject(projectInfo.projectId, _idOffChain);
    }

    /**
     * @notice remove project while project is active.
     * @dev    Only project owner can call this function.
     * @param _projectId Id of the project
     *
     * emit {RemovedProject} events
     */
    function removeProject(uint256 _projectId) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        for (uint256 i = 0; i < collectionAddress[_projectId].length(); i++) {
            require(
                !ITaskManager(taskManager).isValidTaskOf(collectionAddress[_projectId].at(i)),
                "Project has an active task. Cannot remove project"
            );
            delete collectionToProjects[collectionAddress[_projectId].at(i)];
            uint256 _amount = IClaimPool(projects[_projectId].claimPool).getFreeBudget(
                collectionAddress[_projectId].at(i)
            );
            if (_amount > 0) {
                IClaimPool(projects[_projectId].claimPool).withdrawBudgetFrom(
                    collectionAddress[_projectId].at(i),
                    _msgSender(),
                    _amount
                );
            }
        }
        projects[_projectId].status = false;

        emit RemovedProject(_projectId);
    }

    /**
     * @notice Add new collection to project
     * @dev    Only project owner can call this function.
     * @param _projectId Id of project
     * @param _collections List new collection will be added to project
     * @param percents List of percents of new list collections
     *
     * emit {AddedCollection} events
     */
    function addCollections(
        uint256 _projectId,
        CollectionInfo[] memory _collections,
        uint256[] memory percents
    ) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        require(
            _collections.length > 0 &&
                collectionAddress[_projectId].length() + _collections.length <= maxCollectionInProject,
            "Invalid collection length"
        );
        require(
            collectionAddress[_projectId].length() + _collections.length == percents.length,
            "Invalid percents array"
        );

        for (uint256 i = 0; i < _collections.length; i++) {
            require(
                _collections[i].collectionAddress != address(0) &&
                    collectionToProjects[_collections[i].collectionAddress] == 0,
                "Invalid collection address or collection is already in use"
            );

            if (_collections[i].rewardRarityPercents.length > 0) {
                checkValidPercent(_collections[i].rewardRarityPercents);
            }
            collectionInfos[_collections[i].collectionAddress][_projectId] = _collections[i];
            //slither-disable-next-line unused-return
            collectionAddress[_projectId].add(_collections[i].collectionAddress);
            collectionToProjects[_collections[i].collectionAddress] = _projectId;
        }

        updatePercent(_projectId, percents);

        emit AddedCollection(_projectId, _collections, percents);
    }

    /**
     * @notice Remove collection from project
     * @dev    Only project owner can call this function.
     * @param _projectId Id of project
     * @param _collectionAddress Address of collection will be removed to project
     * @param percents List of percents of new list collections
     *
     * emit {RemovedCollection} events
     */
    function removeCollection(
        uint256 _projectId,
        address _collectionAddress,
        uint256[] calldata percents
    ) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        require(!ITaskManager(taskManager).isValidTaskOf(_collectionAddress), "Cannot remove collection");
        require(
            _collectionAddress != address(0) && collectionToProjects[_collectionAddress] == _projectId,
            "Invalid collection address"
        );
        delete collectionInfos[_collectionAddress][_projectId];
        delete collectionToProjects[_collectionAddress];
        //slither-disable-next-line unused-return
        collectionAddress[_projectId].remove(_collectionAddress);
        require(collectionAddress[_projectId].length() == percents.length, "Invalid percents array");
        if (percents.length > 0) {
            updatePercent(_projectId, percents);
        }
        uint256 _amount = IClaimPool(projects[_projectId].claimPool).getFreeBudget(_collectionAddress);
        if (_amount > 0) {
            IClaimPool(projects[_projectId].claimPool).withdrawBudgetFrom(_collectionAddress, _msgSender(), _amount);
        }

        emit RemovedCollection(_projectId, _collectionAddress);
    }

    /**
     * @notice Deposit token into claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _amount amount of token
     *
     * emit {Deposited} events
     */
    function deposit(
        uint256 _projectId,
        uint256 _amount
    ) external payable validProjectId(_projectId) onlyProjectOwner(_projectId) notZero(_amount) {
        ProjectInfo storage projectInfo = projects[_projectId];
        require(isProjectActive(_projectId), "Project deleted");
        projectInfo.budget += _amount;
        if (projectInfo.paymentToken == address(0)) {
            require(msg.value == _amount, "Invalid amount");
        }
        _splitBudget(projectInfo, _amount);
        TransferHelper._transferToken(projectInfo.paymentToken, _amount, _msgSender(), projectInfo.claimPool);

        emit Deposited(_projectId, _amount);
    }

    /**
     * @notice Deposit token into collection of claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection address of collection
     * @param _amount amount of token
     *
     * emit {DepositedToCollection} events
     */
    function depositToCollection(
        uint256 _projectId,
        address _collection,
        uint256 _amount
    )
        external
        payable
        validProjectId(_projectId)
        onlyProjectOwner(_projectId)
        notZeroAddress(_collection)
        notZero(_amount)
    {
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        ProjectInfo storage projectInfo = projects[_projectId];
        projectInfo.budget += _amount;

        IClaimPool(projectInfo.claimPool).addBudgetTo(_collection, _amount);

        if (projectInfo.paymentToken == address(0)) {
            require(msg.value == _amount, "Invalid amount");
        }
        TransferHelper._transferToken(projectInfo.paymentToken, _amount, _msgSender(), projectInfo.claimPool);

        emit DepositedToCollection(_projectId, _collection, _amount);
    }

    /**
     * @notice Withdraw token from collection of claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection address of collection
     * @param _amount amount of token
     *
     * emit {WithdrawnCollection} events
     */
    function withdrawCollection(
        uint256 _projectId,
        address _collection,
        uint256 _amount
    )
        external
        nonReentrant
        validProjectId(_projectId)
        onlyProjectOwner(_projectId)
        notZeroAddress(_collection)
        notZero(_amount)
    {
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        ProjectInfo storage projectInfo = projects[_projectId];
        require(projectInfo.budget >= _amount, "Invalid amount");
        projectInfo.budget -= _amount;

        IClaimPool(projectInfo.claimPool).withdrawBudgetFrom(_collection, projectInfo.projectOwner, _amount);

        emit WithdrawnCollection(_projectId, _collection, _amount);
    }

    /**
     * @notice Update percent of list collection in project
     * @dev    Only project owner can call this function
     * @param _projectId Id of project
     * @param percents List percents of collections
     *
     * emit {UpdatedPercent} events
     */
    function updatePercent(
        uint256 _projectId,
        uint256[] memory percents
    ) public nonReentrant validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        checkValidPercent(percents);
        require(percents.length == collectionAddress[_projectId].length(), "Invalid length");

        for (uint256 i = 0; i < collectionAddress[_projectId].length(); i++) {
            collectionInfos[collectionAddress[_projectId].at(i)][_projectId].rewardPercent = percents[i];
        }

        emit UpdatedPercent(_projectId, percents);
    }

    /**
     * @notice Update reward rarity of each collection
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection list of new percent
     * @param rarityPercents list of new percent
     *
     * emit {UpdatedRewardRarityPercent} events
     */
    function updateRewardRarityPercent(
        uint256 _projectId,
        address _collection,
        uint256[] calldata rarityPercents
    ) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        checkValidPercent(rarityPercents);
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        collectionInfos[_collection][_projectId].rewardRarityPercents = rarityPercents;

        emit UpdatedRewardRarityPercent(_projectId, _collection, rarityPercents);
    }

    /**
     * @notice Split reward token in claim pool
     * @dev    Only hlp claim pool can call this function
     * @param _projectId id of project
     * @param _amount amount of token
     *
     * emit {SplittedBudget} events
     */
    function splitBudget(uint256 _projectId, uint256 _amount) external validProjectId(_projectId) {
        require(address(hlpClaimPool) == _msgSender(), "Caller is not permitted");
        _splitBudget(projects[_projectId], _amount);

        emit SplittedBudget(_projectId, _amount);
    }

    /**
     * @notice Check valid collection
     * @dev    Everyone can call this function
     * @param _collection collection address
     */
    function isCollectionActive(address _collection) external view returns (bool) {
        return isProjectActive(collectionToProjects[_collection]);
    }

    /**
     * @notice Check valid project
     * @dev    Everyone can call this function
     * @param _projectId project id
     */
    function isProjectActive(uint256 _projectId) public view returns (bool) {
        return projects[_projectId].status;
    }

    /**
     * @notice Check valid reward rarity percent
     * @dev    Everyone can call this function
     * @param _arrays list array rarity percent
     */
    function checkValidPercent(uint256[] memory _arrays) private pure {
        uint256 _totalRewardRarity = 0;
        for (uint256 i = 0; i < _arrays.length; i++) {
            _totalRewardRarity += _arrays[i];
        }
        require(_totalRewardRarity == DENOMINATOR, "The total percentage must be equal to 100%");
    }

    /**
     * @notice Split reward token in claim pool
     * @param _projectInfo object of ProjectInfo
     * @param _amount reward additional into claim pool
     */
    function _splitBudget(ProjectInfo storage _projectInfo, uint256 _amount) private {
        for (uint256 i = 0; i < collectionAddress[_projectInfo.projectId].length(); i++) {
            CollectionInfo memory collectionInfo = collectionInfos[collectionAddress[_projectInfo.projectId].at(i)][
                _projectInfo.projectId
            ];
            uint256 newReward = (_amount * collectionInfo.rewardPercent) / DENOMINATOR;
            IClaimPool(_projectInfo.claimPool).addBudgetTo(collectionAddress[_projectInfo.projectId].at(i), newReward);
        }
    }

    // Get function
    /**
     *  @notice Get project counter
     *
     *  @dev    All caller can call this function.
     */
    function getProjectCounter() external view returns (uint256) {
        return _projectCounter.current();
    }

    /**
     *  @notice Get project by project id
     *
     *  @dev    All caller can call this function.
     */
    function getProjectById(uint256 _projectId) external view returns (ProjectInfo memory) {
        return projects[_projectId];
    }

    /**
     *  @notice Get project by project id
     *
     *  @dev    All caller can call this function.
     */
    function getLengthCollectionByProjectId(uint256 _projectId) external view returns (uint256) {
        return collectionAddress[_projectId].length();
    }

    /**
     *  @notice Get collection address by project id and index
     *
     *  @dev    All caller can call this function.
     */
    function getCollectionByIndex(uint256 _projectId, uint256 _index) external view returns (address) {
        return collectionAddress[_projectId].at(_index);
    }

    /**
     *  @notice Get all collection address by project id
     *
     *  @dev    All caller can call this function.
     */
    function getAllCollection(uint256 _projectId) external view returns (address[] memory) {
        return collectionAddress[_projectId].values();
    }

    /**
     *  @notice Get reward rarity percent of collection address by project id
     *
     *  @dev    All caller can call this function.
     */
    function getRewardRarityPercents(uint256 _projectId, address _collection) external view returns (uint256[] memory) {
        return collectionInfos[_collection][_projectId].rewardRarityPercents;
    }

    /**
     *  @notice Get paymentToken address by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getPaymentTokenOf(address collection) external view returns (address) {
        return projects[collectionToProjects[collection]].paymentToken;
    }

    /**
     *  @notice Get claimpool address by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getClaimPoolOf(address collection) external view returns (address) {
        return projects[collectionToProjects[collection]].claimPool;
    }

    /**
     *  @notice Get project owner by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getProjectOwnerOf(address collection) external view returns (address) {
        uint256 projectId = collectionToProjects[collection];
        return projects[projectId].projectOwner;
    }

    /**
     *  @notice Get reward available by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getRewardOf(address collection) external view returns (uint256) {
        uint256 projectId = collectionToProjects[collection];
        if (!isProjectActive(projectId)) {
            return 0;
        }
        return IClaimPool(projects[projectId].claimPool).getFreeBudget(collection);
    }
}
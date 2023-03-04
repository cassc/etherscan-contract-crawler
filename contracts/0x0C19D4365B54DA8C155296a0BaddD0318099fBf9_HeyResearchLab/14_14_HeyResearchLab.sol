// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract HeyResearchLab is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    enum ProjectType {
        OUTSOURCE,
        FUND_REQUEST
    }

    enum ProjectState {
        PENDING,
        AWAITING_DELIVERY,
        DELIVERED,
        REFUNDED
    }

    struct Project {
        address client;
        address researcher;
        uint256 amount;
        uint256 fee;
        uint256 expireInSeconds;
        uint256 expireIn;
        uint256 clearAt;
        ProjectType projectType;
        ProjectState state;
    }

    CountersUpgradeable.Counter private _projectIds;
    mapping(uint256 => Project) private idToProject;
    mapping(uint256 => string) private idToRequirementsUri;
    mapping(uint256 => string) private idToResearchUri;

    mapping(address => uint256) private addressToProjectCount;
    mapping(address => mapping(uint256 => uint256))
        private addressToProjectIndexes;

    uint256 private _minimumAmount;
    uint256 private _fee;

    IERC20 private TOKEN;

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed creator,
        uint256 amount,
        uint256 fee,
        string requirementsUri,
        uint256 expireInSeconds,
        ProjectType indexed projectType
    );

    event ProjectStarted(
        uint256 indexed projectId,
        address indexed resolvedBy, // Can be client or researcher
        uint256 startedAt,
        uint256 expireIn
    );

    event ProjectDelivered(
        uint256 indexed projectId,
        string uri,
        uint256 deliveredAt
    );

    event ProjectUpdated(
        uint256 indexed projectId,
        uint256 updatedAt,
        ProjectState indexed state
    );

    event ChangedToken(address indexed tokenAddress);
    event ChangedMinAmount(uint256 indexed amount);
    event ChangedProjectFee(uint256 indexed amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    modifier notClient(uint256 projectId) {
        require(
            idToProject[projectId].researcher == msg.sender ||
                owner() == msg.sender,
            "Only researcher or Owner can perform this action"
        );
        _;
    }

    function setMinAmount(uint256 _minAmount) public onlyOwner nonReentrant {
        _minimumAmount = _minAmount;
        emit ChangedMinAmount(_minAmount);
    }

    function setProjectFee(uint256 _feeAmount) public onlyOwner nonReentrant {
        _fee = _feeAmount;
        emit ChangedProjectFee(_feeAmount);
    }

    function setToken(address _tokenAddress) public onlyOwner nonReentrant {
        TOKEN = IERC20(_tokenAddress);
        emit ChangedToken(_tokenAddress);
    }

    function createProject(
        ProjectType _type,
        uint256 _amount,
        string calldata _cid,
        uint256 expireInSeconds,
        address _researcher
    ) public nonReentrant {
        require(
            _amount >= _minimumAmount,
            "Project must be larger than the minimum amount"
        );

        _projectIds.increment();
        uint256 curId = _projectIds.current();
        uint256 fee = (_amount * _fee) / 100;
        uint256 amount = _amount - fee;

        idToProject[curId] = Project(
            address(0),
            address(0),
            amount,
            fee,
            expireInSeconds,
            0,
            0,
            _type,
            ProjectState.PENDING
        );
        idToRequirementsUri[curId] = _cid;

        emit ProjectCreated(
            curId,
            msg.sender,
            amount,
            fee,
            _cid,
            expireInSeconds,
            _type
        );

        if (_type == ProjectType.FUND_REQUEST) {
            // For Reverse Marketplace
            _safeAddResearcher(curId, msg.sender);
        } else {
            // OutSourcing researcher
            _safeAddClient(curId, msg.sender);

            if (_researcher != address(0)) {
                _safeAddResearcher(curId, _researcher);
                _safeStartProject(curId, _researcher);
            }
        }
    }

    function startProject(
        uint256 _projectId,
        address _researcher
    ) public nonReentrant {
        require(
            idToProject[_projectId].state == ProjectState.PENDING,
            "Already started"
        );
        if (idToProject[_projectId].projectType == ProjectType.FUND_REQUEST) {
            _safeAddClient(_projectId, msg.sender);
            _safeStartProject(_projectId, msg.sender);
        } else {
            if (
                msg.sender != idToProject[_projectId].client &&
                msg.sender != owner()
            ) {
                revert("Unauthorized access");
            }
            if (_researcher == address(0)) {
                revert("Researcher address must be valid");
            }

            _safeAddResearcher(_projectId, _researcher);
            _safeStartProject(_projectId, _researcher);
        }
    }

    function deliverProject(
        uint256 _projectId,
        string calldata _cid
    ) public nonReentrant {
        require(
            idToProject[_projectId].researcher == msg.sender,
            "Only researcher can deliver project"
        );
        require(
            idToProject[_projectId].state == ProjectState.AWAITING_DELIVERY,
            "Already updated before"
        );

        idToResearchUri[_projectId] = _cid;

        emit ProjectDelivered(_projectId, _cid, block.timestamp);
    }

    function completeProject(uint256 _projectId) public nonReentrant {
        require(
            idToProject[_projectId].client == msg.sender ||
                owner() == msg.sender,
            "Only client or Owner can complete"
        );
        require(
            idToProject[_projectId].state == ProjectState.AWAITING_DELIVERY,
            "Can't complete this Project. Already updated before"
        );

        TOKEN.transfer(
            idToProject[_projectId].researcher,
            idToProject[_projectId].amount
        );
        TOKEN.transfer(owner(), idToProject[_projectId].fee);

        idToProject[_projectId].clearAt = block.timestamp;
        idToProject[_projectId].state = ProjectState.DELIVERED;

        emit ProjectUpdated(
            _projectId,
            block.timestamp,
            ProjectState.DELIVERED
        );
    }

    function refund(
        uint256 _projectId
    ) public notClient(_projectId) nonReentrant {
        require(
            idToProject[_projectId].state == ProjectState.AWAITING_DELIVERY,
            "Can't refund this project. Already updated before"
        );

        TOKEN.transfer(
            idToProject[_projectId].client,
            (idToProject[_projectId].amount + idToProject[_projectId].fee)
        );

        idToProject[_projectId].clearAt = block.timestamp;
        idToProject[_projectId].state = ProjectState.REFUNDED;

        emit ProjectUpdated(_projectId, block.timestamp, ProjectState.REFUNDED);
    }

    function fetchProjects() public view returns (Project[] memory) {
        if (owner() == msg.sender) {
            uint256 totalItemCount = _projectIds.current();
            Project[] memory items = new Project[](totalItemCount);
            for (uint256 i = 0; i < totalItemCount; i++) {
                items[i] = idToProject[i + 1];
            }
            return items;
        } else {
            Project[] memory items = new Project[](
                addressToProjectCount[msg.sender]
            );
            for (uint256 i = 0; i < addressToProjectCount[msg.sender]; i++) {
                items[i] = idToProject[
                    addressToProjectIndexes[msg.sender][i + 1]
                ];
            }
            return items;
        }
    }

    function fetchProjectsPaginated(
        uint256 cursor,
        uint256 perPageCount
    )
        public
        view
        returns (
            Project[] memory data,
            uint256 totalItemCount,
            bool hasNextPage,
            uint256 nextCursor
        )
    {
        uint256 length = perPageCount;
        if (owner() == msg.sender) {
            uint256 totalCount = _projectIds.current();
            bool nextPage = true;
            if (length > totalCount - cursor) {
                length = totalCount - cursor;
                nextPage = false;
            } else if (length == (totalCount - cursor)) {
                nextPage = false;
            }
            Project[] memory items = new Project[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToProject[cursor + i + 1];
            }
            return (items, totalCount, nextPage, (cursor + length));
        } else {
            bool nextPage = true;
            if (length > addressToProjectCount[msg.sender] - cursor) {
                length = addressToProjectCount[msg.sender] - cursor;
                nextPage = false;
            } else if (length == (addressToProjectCount[msg.sender] - cursor)) {
                nextPage = false;
            }
            Project[] memory items = new Project[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToProject[
                    addressToProjectIndexes[msg.sender][cursor + i + 1]
                ];
            }
            return (
                items,
                addressToProjectCount[msg.sender],
                nextPage,
                (cursor + length)
            );
        }
    }

    function fetchProject(
        uint256 projectId
    ) public view returns (Project memory) {
        return idToProject[projectId];
    }

    function fetchRequirementsUri(
        uint256 projectId
    ) public view returns (string memory) {
        return idToRequirementsUri[projectId];
    }

    function fetchResearchUri(
        uint256 projectId
    ) public view returns (string memory) {
        return idToResearchUri[projectId];
    }

    function _safeAddProjectRelation(uint256 projectId, address to) internal {
        addressToProjectCount[to] = addressToProjectCount[to] + 1;
        addressToProjectIndexes[to][addressToProjectCount[to]] = projectId;
    }

    function _safeAddClient(uint256 projectId, address _client) internal {
        uint256 allowance = TOKEN.allowance(_client, address(this));
        uint256 _amount = idToProject[projectId].amount +
            idToProject[projectId].fee;
        require(
            allowance >= _amount,
            "Client doesn't have enough funds allowed"
        );

        TOKEN.transferFrom(_client, address(this), _amount);

        idToProject[projectId].client = _client;

        _safeAddProjectRelation(projectId, _client);
    }

    function _safeAddResearcher(
        uint256 projectId,
        address _researcher
    ) internal {
        idToProject[projectId].researcher = _researcher;
        _safeAddProjectRelation(projectId, _researcher);
    }

    function _safeStartProject(
        uint256 projectId,
        address _resolvedBy
    ) internal {
        idToProject[projectId].state = ProjectState.AWAITING_DELIVERY;
        idToProject[projectId].expireIn =
            block.timestamp +
            idToProject[projectId].expireInSeconds;

        emit ProjectStarted(
            projectId,
            _resolvedBy,
            block.timestamp,
            idToProject[projectId].expireIn
        );
    }
}
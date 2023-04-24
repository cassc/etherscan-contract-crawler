// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./WaifuNodes.sol";
import "./WaifuCashier.sol";
import "./ReclaimManager.sol";
import "../perks/WaifuPerks.sol";
import "../ERC1155/extensions/ERC1155TempBalanceHistoryUpgradeable.sol";

/*
 * Coordinates all the other Nodes contracts, allowing WaifuNodes tokens
 * purchases, refunds and collecting rewards.
 */
contract WaifuManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /* ===== CONSTANTS ===== */

    bytes32 public constant REFUNDER_ROLE = keccak256("REFUNDER_ROLE");
    bytes32 public constant FINANCE_ADMIN_ROLE =
        keccak256("FINANCE_ADMIN_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    WaifuNodes public waifuNodes;
    WaifuCashier public waifuCashier;
    WaifuPerks public perks;
    ReclaimManager public reclaimManager;

    // mint price per node
    uint256 public nodePrice;
    // epoch => rewards per node
    mapping(uint256 => uint256) public nodeRewards;
    // account => snapshot ID last reward was collected for
    mapping(address => uint256) public rewardsLastCollected;
    // used to introduce new rewards rates
    uint256[] private _epochStartSnapshots;

    /* ===== EVENTS ===== */

    event NodesPurchase(
        address indexed account,
        uint256 amount,
        uint256 totalPrice
    );
    event NodesRefund(
        address indexed account,
        uint256 amount
    );
    event RewardsCollected(
        address indexed account,
        uint256 fromSnapshot,
        uint256 toSnapshot,
        uint256 amount
    );
    event NewNodePrice(uint256 price);
    event NewEpoch(uint256 fromSnapshot, uint256 epochReward);
    event PerksSet(address waifuPerks);
    event ReclaimManagerSet(address reclaimManager);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        WaifuNodes _waifuNodes,
        WaifuCashier _waifuCashier,
        uint256 _nodePrice,
        uint256 _nodeReward,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        waifuNodes = _waifuNodes;
        waifuCashier = _waifuCashier;
        nodeRewards[0] = _nodeReward;

        _setNodePrice(_nodePrice);
        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REFUNDER_ROLE, admin);
        _grantRole(FINANCE_ADMIN_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /* ===== VIEWABLE ===== */

    function getEpochCount() public view returns (uint256) {
        return _epochStartSnapshots.length + 1;
    }
    
    function getEpochStartSnapshots()
        public
        view
        returns (uint256[] memory)
    {
        return _epochStartSnapshots;
    }

    function getRewardsIncreaseOf(address account)
        public
        view
        returns (uint256)
    {
        if (address(perks) != address(0)) {
            return perks.getPercentageBenefitOf(account);
        } else {
            return 0;
        }
    }

    function calculateUnclaimedRewardsFor(address account)
        public
        view
        returns (uint256)
    {
        return calculateRewardsFor(
            account,
            rewardsLastCollected[account] + 1,
            waifuNodes.getCurrentSnapshotId()
        );
    }

    function calculateRewardsFor(
        address account,
        uint256 fromSnapshot,
        uint256 toSnapshot
    ) public view returns (uint256) {
        uint256[] memory epochStartSnapshots = getEpochStartSnapshots();
        uint256 startEpoch = 0;

        // let's skip epochs previous to fromSnapshot
        for (uint256 i = 0; i < epochStartSnapshots.length; i++) {
            if (fromSnapshot >= epochStartSnapshots[i]) {
                startEpoch++;
            } else {
                break;
            }
        }

        uint256 rewards = 0;

        ERC1155TempBalanceHistoryUpgradeable.BalanceRecord[] memory balanceHistory =
            waifuNodes.getNodeBalanceHistoryOf(
                account,
                fromSnapshot,
                toSnapshot
            );

        // start of constant balance range
        uint256 _fromSnapshot = fromSnapshot;
        uint256 epoch = startEpoch;
        
        // loop through each constant balance period
        for (uint256 i = 0; i < balanceHistory.length; i++) {
            uint256 balance = balanceHistory[i].balance;

            // end of constant balance range, +1 to make it exclusive
            uint256 _toSnapshot = balanceHistory[i].tillSnapshot + 1;

            // rewards can change with epoch, let's take it into account
            while (
                epoch < epochStartSnapshots.length &&
                _toSnapshot > epochStartSnapshots[epoch]
            ) {
                // constant epoch and constant balance snapshot count
                uint256 epochSnapshotCount =
                    epochStartSnapshots[epoch] - _fromSnapshot;
                rewards += epochSnapshotCount * balance * nodeRewards[epoch];

                _fromSnapshot = epochStartSnapshots[epoch];
                epoch++;
            }

            // constant epoch and constant balance snapshot count
            uint256 snapshotCount = _toSnapshot - _fromSnapshot;
            rewards += snapshotCount * balance * nodeRewards[epoch];
            
            _fromSnapshot = _toSnapshot;
        }
        // perks reward increase
        rewards += (rewards * getRewardsIncreaseOf(account)) / PRECISION;

        return rewards;
    }

    /* ===== FUNCTIONALITY ===== */

    function buyNodes(uint256 amount) external whenNotPaused {
        address account = _msgSender();
        uint256 totalPrice = nodePrice * amount;

        waifuCashier.getNodePaymentFrom(account, totalPrice);
        waifuNodes.mint(account, amount);

        emit NodesPurchase(account, amount, totalPrice);
    }

    function refundNodes() external {
        _refundNodesFor(_msgSender());
    }

    function refundNodesFor(address account) external onlyRole(REFUNDER_ROLE) {
        _refundNodesFor(account);
    }

    function collectRewards() external whenNotPaused {
        uint256 toSnapshot = waifuNodes.getCurrentSnapshotId();

        collectRewardsUpTo(toSnapshot);

        waifuNodes.clearHistoryFor(_msgSender());
    }

    /*
     * There should be an ability to collect part of the rewards in case gas
     * costs for claiming all rewards will exceed block gas limit.
     */
    function collectRewardsUpTo(uint256 toSnapshot) public whenNotPaused {
        address account = _msgSender();
        uint256 fromSnapshot = rewardsLastCollected[account] + 1;
        uint256 amount = calculateRewardsFor(account, fromSnapshot, toSnapshot);

        rewardsLastCollected[account] = toSnapshot;
        waifuCashier.grantRewardsTo(account, amount);

        emit RewardsCollected(account, fromSnapshot, toSnapshot, amount);
    }

    /* ===== MUTATIVE ===== */

    // Add a new epoch to change rewards credited since `fromSnapshot`
    function addNewEpoch(uint256 fromSnapshot, uint256 epochReward)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        require(
            fromSnapshot > waifuNodes.getCurrentSnapshotId(),
            "WaifuManager: past snapshot"
        );

        uint256 epochStartSnapshotsLength = _epochStartSnapshots.length;
        if (epochStartSnapshotsLength > 0) {
            require(
                _epochStartSnapshots[epochStartSnapshotsLength - 1] <
                    fromSnapshot,
                "WaifuManager: invalid snapshot"
            );
        }
        
        _epochStartSnapshots.push(fromSnapshot);
        nodeRewards[getEpochCount() - 1] = epochReward;

        emit NewEpoch(fromSnapshot, epochReward);
    }

    function setPerks(address _perks)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        perks = WaifuPerks(_perks);

        emit PerksSet(_perks);
    }

    function setReclaimManager(address _reclaimManager)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        reclaimManager = ReclaimManager(_reclaimManager);

        emit ReclaimManagerSet(_reclaimManager);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    // refunds all nodes after all node rewards are granted
    function _refundNodesFor(address account) private whenNotPaused {
        require(
            address(reclaimManager) != address(0),
            "WaifuManager: reclaimManager not set"
        );

        uint256 amount = waifuNodes.nodeBalanceOf(account);

        require(amount > 0, "WaifuManager: nothing to refund");

        waifuNodes.burn(account, amount);
        reclaimManager.reclaimFor(account, amount);

        emit NodesRefund(account, amount);
    }

    function _setNodePrice(uint256 newPrice) private {
        require(newPrice > 0, "WaifuManager: zero price");

        nodePrice = newPrice;

        emit NewNodePrice(newPrice);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
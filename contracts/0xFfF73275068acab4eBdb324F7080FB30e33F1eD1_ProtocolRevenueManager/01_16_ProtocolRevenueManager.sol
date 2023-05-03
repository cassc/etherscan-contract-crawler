// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IProtocolRevenueManager.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./interfaces/IAuctionManager.sol";

contract ProtocolRevenueManager is
    Initializable,
    IProtocolRevenueManager,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    IEtherFiNodesManager public etherFiNodesManager;
    IAuctionManager public auctionManager;

    uint256 public globalRevenueIndex;
    uint128 public vestedAuctionFeeSplitForStakers;
    uint128 public auctionFeeVestingPeriodForStakersInDays;

    uint256[46] public __gap;

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        globalRevenueIndex = 1;
        vestedAuctionFeeSplitForStakers = 50; // 50% of the auction fee is vested
        auctionFeeVestingPeriodForStakersInDays = 6 * 7 * 4; // 6 months
    }

    //Pauses the contract
    function pauseContract() external onlyOwner {
        _pause();
    }

    //Unpauses the contract
    function unPauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice All of the received Ether is shared to all validators! Cool!
    receive() external payable {
        uint256 numberOfValidators = etherFiNodesManager.numberOfValidators();
        require(
            numberOfValidators > 0,
            "No Active Validator"
        );
        globalRevenueIndex +=
            msg.value /
            numberOfValidators;
    }

    /// @notice add the revenue from the auction fee paid by the node operator for the corresponding validator
    /// @param _validatorId the validator ID
    function addAuctionRevenue(
        uint256 _validatorId
    ) external payable onlyAuctionManager nonReentrant {
        require(
            etherFiNodesManager.numberOfValidators() > 0,
            "No Active Validator"
        );
        require(
            etherFiNodesManager.localRevenueIndex(_validatorId) == 0,
            "addAuctionRevenue is already processed for the validator."
        );

        uint256 amountVestedForStakers = (vestedAuctionFeeSplitForStakers *
            msg.value) / 100;
        uint256 amountToProtocol = msg.value - amountVestedForStakers;
        address etherfiNode = etherFiNodesManager.etherfiNodeAddress(
            _validatorId
        );
        uint256 globalIndexlocal = globalRevenueIndex;
        globalRevenueIndex +=
            amountToProtocol /
            etherFiNodesManager.numberOfValidators();

        etherFiNodesManager.setEtherFiNodeLocalRevenueIndex(
            _validatorId,
            globalIndexlocal
        );
        IEtherFiNode(etherfiNode).receiveVestedRewardsForStakers{
            value: amountVestedForStakers
        }();
    }

    /// @notice Distribute the accrued rewards to the validator
    /// @param _validatorId id of the validator
    function distributeAuctionRevenue(
        uint256 _validatorId
    ) external onlyEtherFiNodesManager nonReentrant returns (uint256) {
        if (etherFiNodesManager.isExited(_validatorId)) {
            return 0;
        }

        uint256 amount = getAccruedAuctionRevenueRewards(_validatorId);
        etherFiNodesManager.setEtherFiNodeLocalRevenueIndex{value: amount}(
            _validatorId,
            globalRevenueIndex
        );
        return amount;
    }

    /// @notice Instantiates the interface of the node manager for integration
    /// @dev Set manually due to cirular dependencies
    /// @param _etherFiNodesManager etherfi node manager address to set
    function setEtherFiNodesManagerAddress(
        address _etherFiNodesManager
    ) external onlyOwner {
        require(_etherFiNodesManager != address(0), "No zero addresses");
        require(address(etherFiNodesManager) == address(0), "Address already set");

        etherFiNodesManager = IEtherFiNodesManager(_etherFiNodesManager);
    }

    /// @notice Instantiates the interface of the auction manager for integration
    /// @dev Set manually due to cirular dependencies
    /// @param _auctionManager auction manager address to set
    function setAuctionManagerAddress(
        address _auctionManager
    ) external onlyOwner {
        require(_auctionManager != address(0), "No zero addresses");
        require(address(auctionManager) == address(0), "Address already set");
        auctionManager = IAuctionManager(_auctionManager);
    }

    /// @notice set the auction reward vesting period
    /// @param _periodInDays vesting period in days
    function setAuctionRewardVestingPeriod(
        uint128 _periodInDays
    ) external onlyOwner {
        auctionFeeVestingPeriodForStakersInDays = _periodInDays;
    }

    /// @notice set the auction reward split for stakers
    /// @param _split vesting period in days
    function setAuctionRewardSplitForStakers(
        uint128 _split
    ) external onlyOwner {
        require(_split <= 100, "Cannot be more than 100% split");
        vestedAuctionFeeSplitForStakers = _split;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //-------------------------------------  GETTER   --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Compute the accrued rewards for a validator
    /// @param _validatorId id of the validator
    function getAccruedAuctionRevenueRewards(
        uint256 _validatorId
    ) public view returns (uint256) {
        address etherFiNode = etherFiNodesManager.etherfiNodeAddress(
            _validatorId
        );
        uint256 localRevenueIndex = IEtherFiNode(etherFiNode)
            .localRevenueIndex();
        uint256 amount;
        
        if (localRevenueIndex == 0) {
            return 0;
        }
        else {
            amount = globalRevenueIndex - localRevenueIndex;
        }
        return amount;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyEtherFiNodesManager() {
        require(
            msg.sender == address(etherFiNodesManager),
            "Only etherFiNodesManager function"
        );
        _;
    }

    modifier onlyAuctionManager() {
        require(
            msg.sender == address(auctionManager),
            "Only auction manager function"
        );
        _;
    }
}
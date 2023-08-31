//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝


pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./oz/utils/Pausable.sol";
import "./utils/Owner.sol";
import "./oz/libraries/Clones.sol";
import "./DullahanVault.sol";
import "./DullahanPod.sol";
import "./modules/DullahanRegistry.sol";
import "./interfaces/IDullahanRewardsStaking.sol";
import "./interfaces/IFeeModule.sol";
import "./interfaces/IOracleModule.sol";
import "./interfaces/IDiscountCalculator.sol";
import {Errors} from "./utils/Errors.sol";

/** @title DullahanPodManager contract
 *  @author Paladin
 *  @notice Dullahan Pod Manager: allows to deploy new Pods & handles the stkAAVE renting
 *          allocations & fee system
 */
contract DullahanPodManager is ReentrancyGuard, Pausable, Owner {
    using SafeERC20 for IERC20;

    // Constants

    /** @notice 1e18 scale */
    uint256 public constant UNIT = 1e18;
    /** @notice Max value for BPS - 100% */
    uint256 public constant MAX_BPS = 10000;


    // Struct

    /** @notice Pod struct 
    *   podAddress: Address of the Pod contract
    *   podOwner: Address of the Pod owner
    *   collateral: Address of the collateral token
    *   lastUpdate: Last update timestamp for the Pod state
    *   lastIndex: Last updated index for the Pod state
    *   rentedAmount: Current total amount of stkAAVE rented to the Pod
    *   accruedFees: Current amount of fees owed by the Pod
    */
    struct Pod {
        address podAddress;
        address podOwner;
        address collateral;
        uint96 lastUpdate;
        uint256 lastIndex;
        uint256 rentedAmount;
        uint256 accruedFees;
    }


    // Storage

    /** @notice Address of the Dullahan Vault */
    address public immutable vault;

    /** @notice Address of the Dullahan Staking contract */
    address public immutable rewardsStaking;

    /** @notice Address of the Pod implementation */
    address public immutable podImplementation;

    /** @notice Address of the Chest to receive fees */
    address public protocolFeeChest;

    /** @notice Address of the Dullahan Registry */
    address public registry;

    /** @notice Allowed token to be used as collaterals */
    mapping(address => bool) public allowedCollaterals;
    /** @notice Address of aToken from the Aave Market for each collateral */
    mapping(address => address) public aTokenForCollateral;

    /** @notice State for Pods */
    mapping(address => Pod) public pods;
    /** @notice List of all created Pods */
    address[] public allPods;
    /** @notice List of Pods created by an user */
    mapping(address => address[]) public ownerPods;

    /** @notice Address of the Fee Module */
    address public feeModule;
    /** @notice Address of the Oracle Module */
    address public oracleModule;
    /** @notice Address of the Discount Calculator Module */
    address public discountCalculator;

    /** @notice Last updated value of the Index */
    uint256 public lastUpdatedIndex;
    /** @notice Last update timestamp for the Index */
    uint256 public lastIndexUpdate;

    /** @notice Extra ratio applied during liquidations */
    uint256 public extraLiquidationRatio = 500; // BPS: 5%
    /** @notice Ratio of minted amount taken as minting fees */
    uint256 public mintFeeRatio = 25; // BPS: 0.25%
    /** @notice Ratio of renting fees taken as protocol fees */
    uint256 public protocolFeeRatio = 1000; // BPS: 10%

    /** @notice Total amount set as reserve (holding Vault renting fees) */
    uint256 public reserveAmount;
    /** @notice Min amount in the reserve to be processed */
    uint256 public processThreshold = 500e18;


    // Events

    /** @notice Event emitted when a new Pod is created */
    event PodCreation(
        address indexed collateral,
        address indexed podOwner,
        address indexed pod
    );

    /** @notice Event emitted when stkAAVE is clawed back from a Pod */
    event FreedStkAave(address indexed pod, uint256 pullAmount);
    /** @notice Event emitted when stkAAVE is rented to a Pod */
    event RentedStkAave(address indexed pod, uint256 rentAmount);

    /** @notice Event emitted when a Pod is liquidated */
    event LiquidatedPod(address indexed pod, address indexed collateral, uint256 collateralAmount, uint256 receivedFeeAmount);

    /** @notice Event emitted when renting fees are paid */
    event PaidFees(address indexed pod, uint256 feeAmount);
    /** @notice Event emitted when minting fees are paid */
    event MintingFees(address indexed pod, uint256 feeAmount);

    /** @notice Event emitted when the Reserve is processed */
    event ReserveProcessed(uint256 stakingRewardsAmount);

    /** @notice Event emitted when a new collateral is added */
    event NewCollateral(address indexed collateral, address indexed aToken);
    /** @notice Event emitted when a colalteral is updated */
    event CollateralUpdated(address indexed collateral, bool allowed);

    /** @notice Event emitted when the Registry is updated */
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry);
    /** @notice Event emitted when the Fee Module is updated */
    event FeeModuleUpdated(address indexed oldMoldule, address indexed newModule);
    /** @notice Event emitted when the Oracle Module is updated */
    event OracleModuleUpdated(address indexed oldMoldule, address indexed newModule);
    /** @notice Event emitted when the Discount Calculator Module is updated */
    event DiscountCalculatorUpdated(address indexed oldCalculator, address indexed newCalculator);
    /** @notice Event emitted when the Fee Chest is updated */
    event FeeChestUpdated(address indexed oldFeeChest, address indexed newFeeChest);

    /** @notice Event emitted when the Mint Fee Ratio is updated */
    event MintFeeRatioUpdated(uint256 oldRatio, uint256 newRatio);
    /** @notice Event emitted when the Protocol Fee Ratio is updated */
    event ProtocolFeeRatioUpdated(uint256 oldRatio, uint256 newRatio);
    /** @notice Event emitted when the Extra Liquidation Ratio is updated */
    event ExtraLiquidationRatioUpdated(uint256 oldRatio, uint256 newRatio);
    /** @notice Event emitted when the Mint Fee Ratio is updated */
    event ProcessThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);


    // Modifers

    /** @notice Check that the caller is a valid Pod */
    modifier isValidPod() {
        if(pods[msg.sender].podAddress == address(0)) revert Errors.CallerNotValidPod();
        _;
    }


    // Constructor

    constructor(
        address _vault,
        address _rewardsStaking,
        address _protocolFeeChest,
        address _podImplementation,
        address _registry,
        address _feeModule,
        address _oracleModule,
        address _discountCalculator
    ) {
        if(
            _vault == address(0)
            || _rewardsStaking == address(0)
            || _protocolFeeChest == address(0)
            || _podImplementation == address(0)
            || _registry == address(0)
            || _feeModule == address(0)
            || _oracleModule == address(0)
            || _discountCalculator == address(0)
        ) revert Errors.AddressZero();

        vault = _vault;
        rewardsStaking = _rewardsStaking;
        protocolFeeChest = _protocolFeeChest;
        podImplementation = _podImplementation;
        registry = _registry;
        feeModule = _feeModule;
        oracleModule = _oracleModule;
        discountCalculator = _discountCalculator;

        lastIndexUpdate = block.timestamp;
    }


    // View functions

    /**
    * @notice Get the current fee index
    * @return uint256 : Current index
    */
    function getCurrentIndex() public view returns(uint256) {
        return lastUpdatedIndex + _accruedIndex();
    }

    /**
    * @notice Get the current amount of fees owed by a Pod
    * @param pod Address of the Pod
    * @return uint256 : Current amount of fees owed
    */
    function podCurrentOwedFees(address pod) public view returns(uint256) {
        if(pods[pod].lastIndex == 0) return 0;
        return pods[pod].accruedFees + (((getCurrentIndex() - pods[pod].lastIndex) * pods[pod].rentedAmount) / UNIT);
    }

    /**
    * @notice Get the stored amount of fees owed by a Pod
    * @param pod Address of the Pod
    * @return uint256 : Stored amount of fees owed
    */
    function podOwedFees(address pod) public view returns(uint256) {
        return pods[pod].accruedFees;
    }

    /**
    * @notice Get all Pods created by this contract
    * @return address[] : List of Pods
    */
    function getAllPods() external view returns(address[] memory) {
        return allPods;
    }

    /**
    * @notice Get the list of Pods owned by a given account
    * @param account Address of the Pods owner
    * @return address[] : List of Pods
    */
    function getAllOwnerPods(address account) external view returns(address[] memory) {
        return ownerPods[account];
    }

    /**
    * @notice Check if the given Pod is liquidable
    * @param pod Address of the Pod
    * @return bool : True if liquidable
    */
    function isPodLiquidable(address pod) public view returns(bool) {
        // We consider the Pod liquidable since the Pod has no more GHO debt from Aave,
        // but still owes fees to Dullahan, but the Pod logic forces to pay fees before
        // repaying debt to Aave.
        return IERC20(DullahanRegistry(registry).DEBT_GHO()).balanceOf(pod) == 0 && pods[pod].accruedFees > 0;
    }

    /**
    * @notice Estimate the amount of fees to repay to liquidate a Pod & the amount of collaterla to receive after liquidation
    * @param pod Address of the Pod
    * @return feeAmount - uint256 : Amount of fees to pay to liquidate
    * @return collateralAmount - uint256 : Amount of collateral to receive after liquidation
    */
    function estimatePodLiquidationexternal(address pod) external view returns(
        uint256 feeAmount,
        uint256 collateralAmount
    ) {
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();
        // Check if Pod can be liquidated
        if(!isPodLiquidable(pod)) revert Errors.PodNotLiquidable();

        Pod storage _pod = pods[pod];
        uint256 owedFees = podCurrentOwedFees(pod);

        address _collateral = _pod.collateral;

        // Get the current amount of collateral left in the Pod (from the aToken balance of the Pod, since 1:1 with collateral)
        // (should not have conversion issues since aTokens have the same amount of decimals than the asset)
        uint256 podCollateralBalance = IERC20(aTokenForCollateral[_collateral]).balanceOf(pod);
        // Get amount of collateral to liquidate
        collateralAmount = IOracleModule(oracleModule).getCollateralAmount(_collateral, owedFees);
        // Extra ratio on amount to liquidate: Penality + liquidation bonus
        collateralAmount += (collateralAmount * extraLiquidationRatio) / MAX_BPS;

        // If the Pod doesn't have enough collateral left to cover all the fees owed,
        // take all the collateral (the whole aToken balance).
        feeAmount = owedFees;
        if(collateralAmount > podCollateralBalance) {
            collateralAmount = podCollateralBalance;

            // Calculate the reduced amount of fees to be received based on real collateral amount we can get
            feeAmount = IOracleModule(oracleModule).getFeeAmount(
                _collateral,
                (collateralAmount * MAX_BPS) / (MAX_BPS + extraLiquidationRatio)
            );
        }
    }


    // State-changing functions

    /**
    * @notice Create a new Pod
    * @dev Clone the Pod implementation, initialize it & store the paremeters
    * @param collateral Address of the collateral for the new Pod
    * @return address : Address of the newly deployed Pod
    */
    function createPod(
        address collateral
    ) external nonReentrant whenNotPaused returns(address) {
        if(collateral == address(0)) revert Errors.AddressZero();
        if(!allowedCollaterals[collateral]) revert Errors.CollateralNotAllowed();
        if(!_updateGlobalState()) revert Errors.FailStateUpdate();

        address podOwner = msg.sender;

        // Clone to create new Pod
        address newPod = Clones.clone(podImplementation);

        (address votingPowerDelegate, address proposalPowerDelegate) = DullahanVault(vault).getDelegates();

        // Initialize the newly created Pod
        DullahanPod(newPod).init(
            address(this),
            vault,
            registry,
            podOwner,
            collateral,
            aTokenForCollateral[collateral],
            votingPowerDelegate,
            proposalPowerDelegate
        );

        // Write the new Pod data in storage
        pods[newPod].podAddress = newPod;
        pods[newPod].podOwner = podOwner;
        pods[newPod].collateral = collateral;
        allPods.push(newPod);
        ownerPods[podOwner].push(newPod);

        emit PodCreation(collateral, podOwner, newPod);

        return newPod;
    }

    /**
    * @notice Update the global state
    * @return bool : Success
    */
    function updateGlobalState() external whenNotPaused returns(bool) {
        return _updateGlobalState();
    }

    /**
    * @notice Update a Pod state
    * @param pod Address of the Pod
    * @return bool : Success
    */
    function updatePodState(address pod) external nonReentrant whenNotPaused returns(bool) {
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();

        return _updatePodState(pod);
    }

    /**
    * @notice Free all stkAAVE not currently needed by a Pod
    * @dev Calculate the needed amount of stkAAVE for a Pod & free any extra stkAAVE held by the Pod
    * @param pod Address of the Pod
    * @return bool : Success
    */
    function freeStkAave(address pod) external nonReentrant returns(bool) {
        if(!_updatePodState(pod)) revert Errors.FailPodStateUpdate();
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();
        
        // Make the Pod claim any pending stkAAVE rewards
        if(msg.sender != pod) {
            // Otherwise the Pod will already call the internal _getStkAaveRewards(); method
            // And will block the method because of the nonReentrant modifier
            DullahanPod(pod).compoundStkAave();
        }

        // Calculate the amount of stkAave the Pod needs based on the amount of GHO debt it has
        uint256 neededStkAaveAmount = _calculatedNeededStkAave(pod, 0);
        uint256 currentStkAaveBalance = IERC20(DullahanRegistry(registry).STK_AAVE()).balanceOf(pod);

        // In case a pod receives direct stkAAVE transfer, we want to track that received amount
        if(currentStkAaveBalance > pods[pod].rentedAmount) {
            uint256 balanceDiff = currentStkAaveBalance - pods[pod].rentedAmount;
            pods[pod].rentedAmount += balanceDiff;

            // And notify the Vault of the balance increase
            DullahanVault(vault).notifyRentedAmount(pod, balanceDiff);
        }

        // If the Pod holds more stkAave than needed
        if(currentStkAaveBalance > neededStkAaveAmount) {
            uint256 pullAmount = currentStkAaveBalance - neededStkAaveAmount;

            // Make the Vault pull the stkAave from the Pod
            DullahanVault(vault).pullRentedStkAave(pod, pullAmount);

            // Update the tracked rented amount
            if(pullAmount == currentStkAaveBalance) {
                // We pull all the Pod stkAAVE, we can reset the rentedAmount to 0
                pods[pod].rentedAmount = 0;
            } else {
                pods[pod].rentedAmount -= pullAmount;
            }

            emit FreedStkAave(pod, pullAmount);
        }

        return true;
    }

    /**
    * @notice Liquidate a Pod that owes fees & has no GHO debt
    * @dev Repay the fees owed by the Pod & receive some of the Pod colleteral (with an extra ratio)
    * @param pod Address of the Pod
    * @return bool : Success
    */
    function liquidatePod(address pod) external nonReentrant returns(bool) {
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();

        address liquidator = msg.sender;

        // Update the Pod state to get the actual mount of fees owed
        _updatePodState(pod);

        // Check if Pod can be liquidated
        if(!isPodLiquidable(pod)) revert Errors.PodNotLiquidable();

        // Free any remaining stkAave in the Pod
        DullahanPod(pod).compoundStkAave();
        uint256 currentStkAaveBalance = IERC20(DullahanRegistry(registry).STK_AAVE()).balanceOf(pod);

        // In case a pod receives direct stkAAVE transfer, we want to track that received amount
        if(currentStkAaveBalance > pods[pod].rentedAmount) {
            uint256 balanceDiff = currentStkAaveBalance - pods[pod].rentedAmount;
            pods[pod].rentedAmount += balanceDiff;

            // And notify the Vault of the balance increase
            DullahanVault(vault).notifyRentedAmount(pod, balanceDiff);
        }

        if(currentStkAaveBalance > 0) {
            // Update the tracked rented amount
            pods[pod].rentedAmount = 0;

            // And make the Vault pull the stkAave from the Pod
            DullahanVault(vault).pullRentedStkAave(pod, currentStkAaveBalance);

            emit FreedStkAave(pod, currentStkAaveBalance);
        }

        Pod storage _pod = pods[pod];
        uint256 owedFees = _pod.accruedFees;
        address _collateral = _pod.collateral;

        // Get the current amount of collateral left in the Pod (from the aToken balance of the Pod, since 1:1 with collateral)
        // (should not have conversion issues since aTokens have the same amount of decimals than the asset)
        uint256 podCollateralBalance = IERC20(aTokenForCollateral[_collateral]).balanceOf(pod);
        // Get amount of collateral to liquidate
        uint256 collateralAmount = IOracleModule(oracleModule).getCollateralAmount(_collateral, owedFees);
        // Extra ratio on amount to liquidate: Penality + liquidation bonus
        collateralAmount += (collateralAmount * extraLiquidationRatio) / MAX_BPS;

        // If the Pod doesn't have enough collateral left to cover all the fees owed,
        // take all the collateral (the whole aToken balance).
        uint256 paidFees = owedFees;
        if(collateralAmount > podCollateralBalance) {
            collateralAmount = podCollateralBalance;

            // Calculate the reduced amount of fees to be received based on real collateral amount we can get
            paidFees = IOracleModule(oracleModule).getFeeAmount(
                _collateral,
                (collateralAmount * MAX_BPS) / (MAX_BPS + extraLiquidationRatio)
            );
        }

        // Reset owed fees for the Pod & add fees to Reserve
        _pod.accruedFees = 0;
        reserveAmount += paidFees;

        // Process the reserve
        if(reserveAmount >= processThreshold) {
            _processReserve();
        }

        // Pull the GHO fees from the liquidator
        IERC20(DullahanRegistry(registry).GHO()).safeTransferFrom(liquidator, address(this), paidFees);

        // Liquidate & send to the liquidator
        DullahanPod(pod).liquidateCollateral(collateralAmount, liquidator);

        emit LiquidatedPod(pod, _collateral, collateralAmount, paidFees);

        return true;
    }

    /**
    * @notice Update the delegator of a Pod
    * @param pod Address of the Pod
    */
    function updatePodDelegation(address pod) public whenNotPaused {
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();

        (address votingPowerDelegate, address proposalPowerDelegate) = DullahanVault(vault).getDelegates();
        DullahanPod(pod).updateDelegation(votingPowerDelegate, proposalPowerDelegate);
    }

    /**
    * @notice Update the delegator for a list of Pods
    * @param podList List of Pod addresses
    */
    function updateMultiplePodsDelegation(address[] calldata podList) external {
        uint256 length = podList.length;
        for(uint256 i; i < length;){
            updatePodDelegation(podList[i]);
            unchecked { ++i; }
        }
    }

    /**
    * @notice Process the Reserve
    * @dev Send the Reserve to the staking contract to be queued for distribution & take a part as protocol fees
    * @return bool : Success
    */
    function processReserve() external nonReentrant whenNotPaused returns(bool) {
        return _processReserve();
    }


    // Pods only functions

    /**
    * @notice Get the needed amount of stkAAVE for a Pod based on the GHO amount minted
    * @dev Calculate the amount of stkAAVE a Pod need based on its GHO debt & amount ot be minted & request the needed amount to the Vault for renting
    * @param amountToMint Amount of GHO to be minted
    * @return bool : Success
    */
    function getStkAave(uint256 amountToMint) external nonReentrant whenNotPaused isValidPod returns(bool){
        address pod = msg.sender;

        // Update the Pod state with the previous stkAave rented amount
        _updatePodState(pod);

        // Caculate the needed amount of stkaave based on current GHO debt + amount of GHO wanted for minting
        // & Fetch the current Pod stkAave balance
        uint256 neededStkAaveAmount = _calculatedNeededStkAave(pod, amountToMint);
        uint256 currentStkAaveBalance = IERC20(DullahanRegistry(registry).STK_AAVE()).balanceOf(pod);

        // In case a pod receives direct stkAAVE transfer, we want to track that received amount
        if(currentStkAaveBalance > pods[pod].rentedAmount) {
            uint256 balanceDiff = currentStkAaveBalance - pods[pod].rentedAmount;
            pods[pod].rentedAmount += balanceDiff;

            // And notify the Vault of the balance increase
            DullahanVault(vault).notifyRentedAmount(pod, balanceDiff);
        }

        // Get the amount of stkAave to rent from the Vault
        uint256 rentAmount = neededStkAaveAmount > currentStkAaveBalance ? neededStkAaveAmount - currentStkAaveBalance : 0;

        // Check with the Vault if there is enough to rent, otherwise take all available
        DullahanVault _vault = DullahanVault(vault);
        uint256 availableStkAaveAmount = _vault.totalAvailable();
        if(rentAmount > availableStkAaveAmount) rentAmount = availableStkAaveAmount;

        if(rentAmount > 0) {
            // Update the tracked rented amount for the Pod
            pods[pod].rentedAmount += rentAmount;

            // And make the Vault send the stkAave to the Pod
            _vault.rentStkAave(pod, rentAmount);

            emit RentedStkAave(pod, rentAmount);
        }

        return true;
    }

    /**
    * @notice Notify the Vault for claimed rewards from the Safety Module for a Pod
    * @param claimedAmount Amount of rewards claimed
    */
    function notifyStkAaveClaim(uint256 claimedAmount) external isValidPod {
        address _pod = msg.sender;

        // Update the Pod state with the previous stkAave rented amount
        _updatePodState(_pod);

        // Update the tracked rented amount for the Pod
        pods[_pod].rentedAmount += claimedAmount;

        // And notify the Vault of the newly claimed amount
        DullahanVault(vault).notifyRentedAmount(_pod, claimedAmount);

        emit RentedStkAave(_pod, claimedAmount);
    }

    /**
    * @notice Notify fees paid by a Pod
    * @param feeAmount Amount of fees paid
    */
    function notifyPayFee(uint256 feeAmount) external isValidPod {
        address _pod = msg.sender;
        // Update the amount of fees owed by the Pod
        pods[_pod].accruedFees -= feeAmount;

        // And set the received fees as Reserve
        reserveAmount += feeAmount;

        // Process the reserve
        if(reserveAmount >= processThreshold) {
            _processReserve();
        }

        emit PaidFees(_pod, feeAmount);
    }

    /**
    * @notice Notify minting fees paid by a Pod
    * @param feeAmount Amount of fees paid
    */
    function notifyMintingFee(uint256 feeAmount) external isValidPod {
        address _pod = msg.sender;

        // Set the received minting fees as Reserve
        reserveAmount += feeAmount;

        // Process the reserve
        if(reserveAmount >= processThreshold) {
            _processReserve();
        }

        emit MintingFees(_pod, feeAmount);
    }


    // Internal functions

    /**
    * @dev Calculates the amount of stkAAVE needed by a Pod based on its GHO debt & the amount of GHO to be minted
    * @param pod Address of the Pod
    * @param addedDebtAmount Amount of GHO to be minted
    * @return uint256 : Amount of stkAAVE needed
    */
    function _calculatedNeededStkAave(address pod, uint256 addedDebtAmount) internal view returns(uint256) {
        uint256 totalDebtBalance = IERC20(DullahanRegistry(registry).DEBT_GHO()).balanceOf(pod) + addedDebtAmount;
        return IDiscountCalculator(discountCalculator).calculateAmountForMaxDiscount(totalDebtBalance);
    }

    /**
    * @dev Calculate the index accrual based on the current fee per second
    * @return uint256 : index accrual
    */
    function _accruedIndex() internal view returns(uint256) {
        if(block.timestamp <= lastIndexUpdate) return 0;

        // Time since the last index update
        uint256 elapsedTime = block.timestamp - lastIndexUpdate;

        // Fee (in GHO) per rented stkAave per second
        uint256 currentFeePerSec = IFeeModule(feeModule).getCurrentFeePerSecond();
        return currentFeePerSec * elapsedTime;
    }

    /**
    * @dev Update the global state by updating the fee index
    * @return bool : Success
    */
    function _updateGlobalState() internal returns(bool) {
        // Get the new index
        uint256 accruedIndex = _accruedIndex();

        // Update the storage
        lastIndexUpdate = block.timestamp;
        lastUpdatedIndex = lastUpdatedIndex + accruedIndex;

        return true;
    }

    /**
    * @dev Update a Pod's state & accrued owed fees based on the last updated index
    * @param podAddress Address of the Pod
    * @return bool : Success
    */
    function _updatePodState(address podAddress) internal returns(bool) {
        if(!_updateGlobalState()) revert Errors.FailStateUpdate();

        Pod storage _pod = pods[podAddress];

        // Get the lastest index & the Pod last index
        // to calculate the accrued owed fees based on the Pod's rented amount
        uint256 _lastUpdatedIndex = lastUpdatedIndex;
        uint256 _oldPodIndex = _pod.lastIndex;
        _pod.lastIndex = _lastUpdatedIndex;
        _pod.lastUpdate = safe96(block.timestamp);

        if(_pod.rentedAmount != 0 && _oldPodIndex != _lastUpdatedIndex){
            _pod.accruedFees += ((_lastUpdatedIndex - _oldPodIndex) * _pod.rentedAmount) / UNIT;
        }

        return true;
    }

    /**
    * @dev Send the Reserve to the staking contract to be queued for distribution & take a part as protocol fees
    * @return bool : Success
    */
    function _processReserve() internal returns(bool) {
        if(!_updateGlobalState()) revert Errors.FailStateUpdate();
        uint256 currentReserveAmount = reserveAmount;
        if(currentReserveAmount == 0) return true;

        // Reset the Reserve
        reserveAmount = 0;

        address _ghoAddress = DullahanRegistry(registry).GHO();
        IERC20 _gho = IERC20(_ghoAddress);
        // Take the DAO fees based on current amount to process
        uint256 protocolFees = (currentReserveAmount * protocolFeeRatio) / MAX_BPS;
        _gho.safeTransfer(protocolFeeChest, protocolFees);

        // And send the rest of the fees to the Staking module to be queued for distribution
        uint256 stakingRewardsAmount = currentReserveAmount - protocolFees;
        IDullahanRewardsStaking(rewardsStaking).queueRewards(_ghoAddress, stakingRewardsAmount);
        _gho.safeTransfer(rewardsStaking, stakingRewardsAmount);

        emit ReserveProcessed(stakingRewardsAmount);

        return true;
    }


    // Admin functions

    /**
    * @notice Update the Registry for a given Pod
    * @param pod Address of the Pod
    */
    function updatePodRegistry(address pod) public onlyOwner {
        if(pods[pod].podAddress == address(0)) revert Errors.PodInvalid();

        DullahanPod(pod).updateRegistry(registry);
    }

    /**
    * @notice Update the Registry for a given list of Pods
    * @param podList List of Pod addresses
    */
    function updateMultiplePodsRegistry(address[] calldata podList) external onlyOwner {
        uint256 length = podList.length;
        for(uint256 i; i < length;){
            updatePodRegistry(podList[i]);
            unchecked { ++i; }
        }
    }

    /**
    * @notice Update the Registry for all Pods
    */
    function updateAllPodsRegistry() external onlyOwner {
        address[] memory _pods = allPods;
        uint256 length = _pods.length;
        for(uint256 i; i < length;){
            updatePodRegistry(_pods[i]);
            unchecked { ++i; }
        }
    }
    
    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice Add a new collateral for Pod creation
    * @param collateral Address of the collateral
    * @param aToken Address of the aToken associated to the collateral
    */
    function addCollateral(address collateral, address aToken) external onlyOwner {
        if(collateral == address(0) || aToken == address(0)) revert Errors.AddressZero();
        if(aTokenForCollateral[collateral] != address(0)) revert Errors.CollateralAlreadyListed();

        allowedCollaterals[collateral] = true;
        aTokenForCollateral[collateral] = aToken;

        emit NewCollateral(collateral, aToken);
    }

    /**
    * @notice Update a collateral for Pod creation
    * @param collateral Address of the collateral
    * @param allowed Is the collateral allowed ofr Pod creation
    */
    function updateCollateral(address collateral, bool allowed) external onlyOwner {
        if(collateral == address(0)) revert Errors.AddressZero();
        if(aTokenForCollateral[collateral] == address(0)) revert Errors.CollateralNotListed();

        allowedCollaterals[collateral] = allowed;

        emit CollateralUpdated(collateral, allowed);
    }

    /**
    * @notice Uodate the FeeChest
    * @param newFeeChest Address of the new FeeChest
    */
    function updateFeeChest(address newFeeChest) external onlyOwner {
        if(newFeeChest == address(0)) revert Errors.AddressZero();
        if(newFeeChest == protocolFeeChest) revert Errors.SameAddress();

        address oldFeeChest = protocolFeeChest;
        protocolFeeChest = newFeeChest;

        emit FeeChestUpdated(oldFeeChest, newFeeChest);
    }

    /**
    * @notice Uodate the Registry
    * @param newRegistry Address of the new Registry
    */
    function updateRegistry(address newRegistry) external onlyOwner {
        if(newRegistry == address(0)) revert Errors.AddressZero();
        if(newRegistry == registry) revert Errors.SameAddress();

        address oldRegistry = registry;
        registry = newRegistry;

        emit RegistryUpdated(oldRegistry, newRegistry);
    }

    /**
    * @notice Uodate the Fee Module
    * @param newModule Address of the new Module
    */
    function updateFeeModule(address newModule) external onlyOwner {
        if(newModule == address(0)) revert Errors.AddressZero();
        if(newModule == feeModule) revert Errors.SameAddress();

        address oldMoldule = feeModule;
        feeModule = newModule;

        emit FeeModuleUpdated(oldMoldule, newModule);
    }

    /**
    * @notice Uodate the Oracle Module
    * @param newModule Address of the new Module
    */
    function updateOracleModule(address newModule) external onlyOwner {
        if(newModule == address(0)) revert Errors.AddressZero();
        if(newModule == oracleModule) revert Errors.SameAddress();

        address oldMoldule = oracleModule;
        oracleModule = newModule;

        emit OracleModuleUpdated(oldMoldule, newModule);
    }

    /**
    * @notice Uodate the Discount Calculator Module
    * @param newCalculator Address of the new Calculator
    */
    function updateDiscountCalculator(address newCalculator) external onlyOwner {
        if(newCalculator == address(0)) revert Errors.AddressZero();
        if(newCalculator == discountCalculator) revert Errors.SameAddress();

        address oldCalculator = discountCalculator;
        discountCalculator = newCalculator;

        emit DiscountCalculatorUpdated(oldCalculator, newCalculator);
    }

    /**
    * @notice Uodate the mint fee ratio parameter
    * @param newRatio New ratio value
    */
    function updateMintFeeRatio(uint256 newRatio) external onlyOwner {
        if(newRatio > 500) revert Errors.InvalidParameter();

        uint256 oldRatio = mintFeeRatio;
        mintFeeRatio = newRatio;

        emit MintFeeRatioUpdated(oldRatio, newRatio);
    }

    /**
    * @notice Uodate the protocol fee ratio parameter
    * @param newRatio New ratio value
    */
    function updateProtocolFeeRatio(uint256 newRatio) external onlyOwner {
        if(newRatio > 2500) revert Errors.InvalidParameter();

        uint256 oldRatio = protocolFeeRatio;
        protocolFeeRatio = newRatio;

        emit ProtocolFeeRatioUpdated(oldRatio, newRatio);
    }

    /**
    * @notice Uodate the extra liquidation ratio parameter
    * @param newRatio New ratio value
    */
    function updateExtraLiquidationRatio(uint256 newRatio) external onlyOwner {
        if(newRatio > 2500) revert Errors.InvalidParameter();

        uint256 oldRatio = extraLiquidationRatio;
        extraLiquidationRatio = newRatio;

        emit ExtraLiquidationRatioUpdated(oldRatio, newRatio);
    }

    /**
    * @notice Uodate the process threshold parameter
    * @param newThreshold New treshold value
    */
    function updateProcessThreshold(uint256 newThreshold) external onlyOwner {
        if(newThreshold < 10e18) revert Errors.InvalidParameter();

        uint256 oldThreshold = processThreshold;
        processThreshold = newThreshold;

        emit ProcessThresholdUpdated(oldThreshold, newThreshold);
    }


    // Maths

    function safe96(uint256 n) internal pure returns (uint96) {
        if(n > type(uint96).max) revert Errors.NumberExceed96Bits();
        return uint96(n);
    }

}
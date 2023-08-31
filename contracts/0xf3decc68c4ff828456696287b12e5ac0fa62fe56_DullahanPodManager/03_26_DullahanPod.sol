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
import "./interfaces/IDullahanPodManager.sol";
import "./DullahanVault.sol";
import "./modules/DullahanRegistry.sol";
import "./interfaces/IStakedAave.sol";
import "./interfaces/IAavePool.sol";
import "./interfaces/IGovernancePowerDelegationToken.sol";
import "./interfaces/IAaveRewardsController.sol";
import {Errors} from "./utils/Errors.sol";

/** @title Dullahan Pod contract
 *  @author Paladin
 *  @notice Dullahan Pod, unique to each user, allowing to depoist collateral,
 *          rent stkAAVE from the Dullahan Vault & borrow GHO
 */
contract DullahanPod is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants

    /** @notice Max value for BPS - 100% */
    uint256 public constant MAX_BPS = 10000;
    /** @notice Max value possible for an uint256 */
    uint256 private constant MAX_UINT256 = 2**256 - 1;

    /** @notice Minimum allowed amount of GHO to mint */
    uint256 public constant MIN_MINT_AMOUNT = 1e9;

    // Storage

    /** @notice Is the Pod initialized */
    bool public initialized;

    /** @notice Address of the Pod manager */
    address public manager;
    /** @notice Address of the Vault */
    address public vault;
    /** @notice Address of the Registry */
    address public registry;

    /** @notice Address of the Pod owner */
    address public podOwner;

    /** @notice Address of the delegate receiving the Pod voting power */
    address public votingPowerDelegate;
    /** @notice Address of the delegate receiving the Pod proposal power */
    address public proposalPowerDelegate;

    /** @notice Address of the collateral in the Pod */
    address public collateral;
    /** @notice Address of the aToken for the collateral */
    address public aToken;

    /** @notice Address of the AAVE token */
    address public aave;
    /** @notice Address of the stkAAVE token */
    address public stkAave;


    // Events

    /** @notice Event emitted when the Pod is initialized */
    event PodInitialized(
        address indexed podManager,
        address indexed collateral,
        address indexed podOwner,
        address vault,
        address registry
    );

    /** @notice Event emitted when collateral is deposited */
    event CollateralDeposited(address indexed collateral, uint256 amount);
    /** @notice Event emitted when collateral is withdrawn */
    event CollateralWithdrawn(address indexed collateral, uint256 amount);
    /** @notice Event emitted when collateral is liquidated */
    event CollateralLiquidated(address indexed collateral, uint256 amount);

    /** @notice Event emitted when GHO is minted */
    event GhoMinted(uint256 mintedAmount);
    /** @notice Event emitted when GHO is repayed */
    event GhoRepayed(uint256 amountToRepay);

    /** @notice Event emitted when stkAAVE is rented by the Pod */
    event RentedStkAave();

    /** @notice Event emitted when the Pod delegates are updated */
    event UpdatedDelegate(address indexed newVotingDelegate, address indexed newProposalDelegate);
    /** @notice Event emitted when the Pod registry is updated */
    event UpdatedRegistry(address indexed oldRegistry, address indexed newRegistry);


    // Modifers

    /** @notice Check that the caller is the Pod owner */
    modifier onlyPodOwner() {
        if(msg.sender != podOwner) revert Errors.NotPodOwner();
        _;
    }

    /** @notice Check that the caller is the manager */
    modifier onlyManager() {
        if(msg.sender != manager) revert Errors.NotPodManager();
        _;
    }

    /** @notice Check that the Pod is initialized */
    modifier isInitialized() {
        if(!initialized) revert Errors.NotInitialized();
        _;
    }


    // Constructor

    constructor() {
        manager = address(0xdEaD);
        vault = address(0xdEaD);
        registry = address(0xdEaD);
        collateral = address(0xdEaD);
        podOwner = address(0xdEaD);
        votingPowerDelegate = address(0xdEaD);
        proposalPowerDelegate = address(0xdEaD);
    }

    /**
    * @notice Initialize the Pod with the given parameters
    * @param _manager Address of the Manager
    * @param _vault Address of the Vault
    * @param _registry Address of the Registry
    * @param _podOwner Address of the Pod owner
    * @param _collateral Address of the collateral
    * @param _aToken Address of the aToken for the collateral
    * @param _votingPowerDelegate Address of the delegate for the voting power
    * @param _proposalPowerDelegate Address of the delegate for the proposal power
    */
    function init(
        address _manager,
        address _vault,
        address _registry,
        address _podOwner,
        address _collateral,
        address _aToken,
        address _votingPowerDelegate,
        address _proposalPowerDelegate
    ) external {
        if(initialized) revert Errors.AlreadyInitialized();
        if(manager == address(0xdEaD)) revert Errors.CannotInitialize();
        if(
            _manager == address(0)
            || _vault == address(0)
            || _registry == address(0)
            || _podOwner == address(0)
            || _collateral == address(0)
            || _aToken == address(0)
            || _votingPowerDelegate == address(0)
            || _proposalPowerDelegate == address(0)
        ) revert Errors.AddressZero();

        initialized = true;
        
        manager = _manager;
        vault = _vault;
        registry = _registry;
        podOwner = _podOwner;
        collateral = _collateral;
        votingPowerDelegate = _votingPowerDelegate;
        proposalPowerDelegate = _proposalPowerDelegate;

        aToken = _aToken;

        // Fetch the stkAAVE address from the Registry
        address _stkAave = DullahanRegistry(_registry).STK_AAVE();
        stkAave = _stkAave;
        aave = DullahanRegistry(registry).AAVE();

        // Set full allowance for the Vault to be able to pull back the stkAAVE rented to this Pod
        IERC20(_stkAave).safeIncreaseAllowance(_vault, type(uint256).max);

        // Set the Delegates for this Pod's voting power
        IGovernancePowerDelegationToken(_stkAave).delegateByType(
            _votingPowerDelegate,
            IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
        );
        IGovernancePowerDelegationToken(_stkAave).delegateByType(
            _proposalPowerDelegate,
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        emit PodInitialized(_manager, _collateral, _podOwner, _vault, _registry);
    }


    // View functions

    /**
    * @notice Get the Pod's current collateral balance
    * @return uint256 : Current collateral balance
    */
    function podCollateralBalance() external view returns(uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    /**
    * @notice Get the Pod's current GHO debt balance
    * @return uint256 : Current GHO debt balance
    */
    function podDebtBalance() public view returns(uint256) {
        return IERC20(DullahanRegistry(registry).DEBT_GHO()).balanceOf(address(this));
    }

    /**
    * @notice Get the stored amount of fees owed by this Pod
    * @return uint256 : Stored amount of fees owed
    */
    function podOwedFees() external view returns(uint256) {
        return IDullahanPodManager(manager).podOwedFees(address(this));
    }


    // State-changing functions

    /**
    * @notice Deposit collateral
    * @dev Pull collateral in the Pod to deposit it in the Aave Pool
    * @param amount Amount to deposit
    */
    function depositCollateral(uint256 amount) external nonReentrant isInitialized onlyPodOwner {
        if(amount == 0) revert Errors.NullAmount();
        if(!IDullahanPodManager(manager).updatePodState(address(this))) revert Errors.FailPodStateUpdate();

        IERC20 _collateral = IERC20(collateral);
        // Pull the collateral from the Pod Owner
        _collateral.safeTransferFrom(msg.sender, address(this), amount);

        // And deposit it in the Aave Pool
        address _aavePool = DullahanRegistry(registry).AAVE_POOL_V3();
        _collateral.safeIncreaseAllowance(_aavePool, amount);
        IAavePool(_aavePool).supply(address(_collateral), amount, address(this), 0);

        emit CollateralDeposited(address(_collateral), amount);
    }

    /**
    * @notice Withdraw collateral
    * @param amount Amount to withdraw
    * @param receiver Address to receive the collateral
    */
    // Can give MAX_UINT256 to withdraw full balance
    function withdrawCollateral(uint256 amount, address receiver) external nonReentrant isInitialized onlyPodOwner {
        if(amount == 0) revert Errors.NullAmount();
        if(receiver == address(0)) revert Errors.AddressZero();
        if(!IDullahanPodManager(manager).updatePodState(address(this))) revert Errors.FailPodStateUpdate();
        
        _withdrawCollateral(amount, receiver);
    }

    /**
    * @notice Claim any existing rewards from the Aave Rewards Controller for this Pod
    * @param receiver Address to receive the rewards
    */
    function claimAaveExtraRewards(address receiver) external nonReentrant isInitialized onlyPodOwner {
        if(receiver == address(0)) revert Errors.AddressZero();
        address[] memory assets = new address[](2);
        assets[0] = aToken;
        assets[1] = DullahanRegistry(registry).DEBT_GHO();
        // Claim any rewards accrued via the Aave Pool & send them directly to the given receiver
        IAaveRewardsController(DullahanRegistry(registry).AAVE_REWARD_COONTROLLER()).claimAllRewards(assets, receiver);
    }

    /**
    * @notice Claim Safety Module rewards & stake them in stkAAVE
    */
    function compoundStkAave() external nonReentrant isInitialized {
        // Claim Aave Safety Module rewards for this Pod & stake them into stkAAVE directly
        _getStkAaveRewards();
    }

    /**
    * @notice Mint GHO & rent stkAAVE
    * @dev Rent stkAAVE from the Vault & mint GHO with the best interest rate discount possible
    * @param amountToMint Amount of GHO to be minted
    * @param receiver Address to receive the minted GHO
    * @return mintedAmount - uint256 : amount of GHO minted after fees
    */
    function mintGho(uint256 amountToMint, address receiver) external nonReentrant isInitialized onlyPodOwner returns(uint256 mintedAmount) {
        if(amountToMint == 0) revert Errors.NullAmount();
        if(receiver == address(0)) revert Errors.AddressZero();
        if(amountToMint < MIN_MINT_AMOUNT) revert Errors.MintAmountUnderMinimum();
        IDullahanPodManager _manager = IDullahanPodManager(manager);
        if(!_manager.updatePodState(address(this))) revert Errors.FailPodStateUpdate();

        // Update this contract stkAAVE current balance is there is one
        _getStkAaveRewards();

        // Ask to rent stkAAVE based on amount wanted to be minted / already minted
        // (will also take care of reverting if the Pod is not allowed to mint or can't receive stkAAVE)
        if(!_manager.getStkAave(amountToMint)) revert Errors.MintingAllowanceFailed();

        emit RentedStkAave();

        // Mint GHO from the Aave Pool, with the Variable mode
        address _ghoAddress = DullahanRegistry(registry).GHO();
        IAavePool(DullahanRegistry(registry).AAVE_POOL_V3()).borrow(_ghoAddress, amountToMint, 2, 0, address(this)); // 2 => variable mode (might need to change that)

        // Take the protocol minting fees & send them to the Pod Manager & notify it
        // & Send the rest of the minted GHO to the given receiver
        IERC20 _gho = IERC20(_ghoAddress);
        uint256 mintFeeRatio = _manager.mintFeeRatio();
        uint256 mintFeeAmount = (amountToMint * mintFeeRatio) / MAX_BPS;
        _gho.safeTransfer(manager, mintFeeAmount);
        _manager.notifyMintingFee(mintFeeAmount);

        mintedAmount = amountToMint - mintFeeAmount;
        _gho.safeTransfer(receiver, mintedAmount);

        emit GhoMinted(mintedAmount);
    }

    /**
    * @notice Repay GHO fees and debt
    * @param amountToRepay Amount of GHO to de repaid
    * @return bool : Success
    */
    // Can give MAX_UINT256 to repay everything (needs max allowance)
    function repayGho(uint256 amountToRepay) external nonReentrant isInitialized onlyPodOwner returns(bool) {
        if(amountToRepay == 0) revert Errors.NullAmount();
        if(!IDullahanPodManager(manager).updatePodState(address(this))) revert Errors.FailPodStateUpdate();
        
        return _repayGho(amountToRepay);
    }

    /**
    * @notice Repay GHO fees and debt & withdraw collateral
    * @dev Repay GHO fees & debt to be allowed to withdraw collateral
    * @param repayAmount Amount of GHO to de repaid
    * @param withdrawAmount Amount to withdraw
    * @param receiver Address to receive the collateral
    * @return bool : Success
    */
    function repayGhoAndWithdrawCollateral(
        uint256 repayAmount,
        uint256 withdrawAmount,
        address receiver
    ) external nonReentrant isInitialized onlyPodOwner returns(bool) {
        if(repayAmount == 0 || withdrawAmount == 0) revert Errors.NullAmount();
        if(receiver == address(0)) revert Errors.AddressZero();
        if(!IDullahanPodManager(manager).updatePodState(address(this))) revert Errors.FailPodStateUpdate();

        bool repaySuccess = _repayGho(repayAmount);
        if(!repaySuccess) revert Errors.RepayFailed();
        
        _withdrawCollateral(withdrawAmount, receiver);

        return repaySuccess;
    }

    /**
    * @notice Rent stkAAVE from the Vault to get the best interest rate reduction
    * @return bool : Success
    */
    function rentStkAave() external nonReentrant isInitialized onlyPodOwner returns(bool) {
        IDullahanPodManager _manager = IDullahanPodManager(manager);
        if(!_manager.updatePodState(address(this))) revert Errors.FailPodStateUpdate();

        // Update this contract stkAAVE current balance is there is one
        _getStkAaveRewards();

        // Ask to rent stkAAVE based on amount wanted to be minted / already minted
        // (will also take care of reverting if the Pod is not allowed to mint or can't receive stkAAVE)
        if(!IDullahanPodManager(manager).getStkAave(0)) revert Errors.MintingAllowanceFailed();

        emit RentedStkAave();

        return true;
    }


    // Manager only functions

    /**
    * @notice Liquidate Pod collateral to repay owed fees
    * @dev Liquidate Pod collateral to repay owed fees, in the case the this Pod got liquidated on Aave market, and fees are still owed to Dullahan
    * @param amount Amount of collateral to liquidate
    * @param receiver Address to receive the collateral
    */
    function liquidateCollateral(uint256 amount, address receiver) external nonReentrant isInitialized onlyManager {
        if(amount == 0) return;

        // Withdraw the amount to be liquidated from the aave Pool
        // (Using MAX_UINT256 here will withdraw everything)
        IAavePool(DullahanRegistry(registry).AAVE_POOL_V3()).withdraw(collateral, amount, address(this));

        // Send the tokens to the liquidator (here the given receiver)
        IERC20(collateral).safeTransfer(receiver, amount);

        emit CollateralLiquidated(collateral, amount);
    }

    /**
    * @notice Update the Pod's delegate address & delegate the voting power to it
    * @param newVotingDelegate Address of the new voting power delegate
    * @param newProposalDelegate Address of the new proposal power delegate
    */
    function updateDelegation(address newVotingDelegate, address newProposalDelegate) external isInitialized onlyManager {
        if(newVotingDelegate == address(0) || newProposalDelegate == address(0)) revert Errors.AddressZero();

        votingPowerDelegate = newVotingDelegate;
        proposalPowerDelegate = newProposalDelegate;

        // Update the delegation to the new Delegate
        IGovernancePowerDelegationToken(stkAave).delegateByType(
            newVotingDelegate,
            IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
        );
        IGovernancePowerDelegationToken(stkAave).delegateByType(
            newProposalDelegate,
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        emit UpdatedDelegate(newVotingDelegate, newProposalDelegate);
    }

    /**
    * @notice Update the Pod's Registry address
    * @param newRegistry Address of the new Registry
    */
    function updateRegistry(address newRegistry) external isInitialized onlyManager {
        if(newRegistry == address(0)) revert Errors.AddressZero();
        if(newRegistry == registry) revert Errors.SameAddress();

        address oldRegistry = registry;
        registry = newRegistry;

        emit UpdatedRegistry(oldRegistry, newRegistry);
    }


    // Internal functions

    /**
    * @dev Withdraw collateral from the Aave Pool directly to the given receiver (only if Pod fees are fully repaid)
    * @param amount Amount to withdraw
    * @param receiver Address to receive the collateral
    */
    function _withdrawCollateral(uint256 amount, address receiver) internal {
        // Not allowed to withdraw collateral before paying the owed fees,
        // in case we need to liquidate part if this collateral to pay
        // the fees owed by this Pod.
        if(
            IDullahanPodManager(manager).podOwedFees(address(this)) > 0
        ) revert Errors.CollateralBlocked();

        // Withdraw from the Aave Pool & send directly to the given receiver
        // If given MAX_UINT256, we want to withdraw all the collateral
        uint256 withdrawnAmount = IAavePool(DullahanRegistry(registry).AAVE_POOL_V3()).withdraw(collateral, amount, receiver);

        emit CollateralWithdrawn(collateral, withdrawnAmount);
    }
    
    /**
    * @dev Repay GHO owed fees & debt (fees in priority)
    * @param amountToRepay Amount of GHO to be repayed
    * @return bool : Success
    */
    function _repayGho(uint256 amountToRepay) internal returns(bool) {
        IDullahanPodManager _manager = IDullahanPodManager(manager);

        // Update this contract stkAAVE current balance is there is one
        _getStkAaveRewards();

        // Fetch the current owed fees for this Pod from the Pod Manager
        uint256 owedFees = _manager.podOwedFees(address(this));
        uint256 variableDebt = podDebtBalance();

        // If given the MAX_UINT256, we want to repay the fees and all the debt
        if(amountToRepay == MAX_UINT256) {
            amountToRepay = owedFees + variableDebt;
        }

        // Pull the GHO from the Pod Owner
        IERC20 _gho = IERC20(DullahanRegistry(registry).GHO());
        _gho.safeTransferFrom(msg.sender, address(this), amountToRepay);

        uint256 realRepayAmount;
        uint256 feesToPay;

        // Repay in priority the owed fees, and then the debt to the Aave Pool
        if(owedFees >= amountToRepay) {
            feesToPay = amountToRepay;
        } else {
            realRepayAmount = amountToRepay == MAX_UINT256 ? MAX_UINT256 : amountToRepay - owedFees;
            feesToPay = owedFees;
        }

        // If there is owed fees to pay, transfer the needed amount to the Pod Manager & notify it
        if(feesToPay > 0) {
            _gho.safeTransfer(manager, feesToPay);
            _manager.notifyPayFee(feesToPay);
        }

        // If there is GHO debt to be repayed, increase allowance to the Aave Pool and repay the debt
        if(realRepayAmount > 0) {
            address _aavePool = DullahanRegistry(registry).AAVE_POOL_V3();
            if(_gho.allowance(address(this), _aavePool) != 0) _gho.safeApprove(_aavePool, 0);
            _gho.safeIncreaseAllowance(_aavePool, realRepayAmount);
            IAavePool(_aavePool).repay(address(_gho), realRepayAmount, 2, address(this)); // 2 => variable mode (might need to change that)
        }

        // Notify the Pod Manager, so not needed stkAave in this Pod
        // can be freed & pull back by the Vaut
        if(!_manager.freeStkAave(address(this))) revert Errors.FreeingStkAaveFailed();

        // Send back any remaining GHO from in the Pod to the caller
        uint256 remainingGho = _gho.balanceOf(address(this));
        if(remainingGho > 0) {
            _gho.safeTransfer(msg.sender, remainingGho);
        }

        emit GhoRepayed(amountToRepay);

        return true;
    }

    /**
    * @dev Claim AAVE rewards from the Safety Module & stake them to receive stkAAVE & notify the Manager
    */
    function _getStkAaveRewards() internal {
        IStakedAave _stkAave = IStakedAave(stkAave);

        // Get pending rewards amount
        uint256 pendingRewards = _stkAave.getTotalRewardsBalance(address(this));

        if(pendingRewards == 0) return;

        // Claim the AAVE tokens
        _stkAave.claimRewards(address(this), pendingRewards);

        IERC20 _aave = IERC20(aave);
        uint256 currentBalance = _aave.balanceOf(address(this));
        
        if(currentBalance > 0) {
            // Increase allowance for the Safety Module & stake AAVE into stkAAVE
            _aave.safeIncreaseAllowance(address(_stkAave), currentBalance);
            _stkAave.stake(address(this), currentBalance);

            // Notify the Pod Manager fro the new amount staked, so the tracking of
            // the Pod rented amount & fees on that claim can be updated in the Vault
            IDullahanPodManager(manager).notifyStkAaveClaim(currentBalance);
        }
    }



}
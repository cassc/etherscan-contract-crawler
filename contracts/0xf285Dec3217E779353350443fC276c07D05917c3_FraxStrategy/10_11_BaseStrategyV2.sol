// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "contracts/interfaces/ILocker.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

////////////////////////////////////////////////////////////////
/// ---  ERRORS
///////////////////////////////////////////////////////////////

error DepositFailed();

error NotImplemented();

error WithdrawalFailed();

error WrongAmountDeposited();

error WithdrawalTransferFailed();

error TransferFromLockerFailed();

/// @notice  BaseStrategyV2 contract.
/// @dev     For new strategies only, upgrade can override storage vars.
contract BaseStrategyV2 {
    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS & ENUMS
    ///////////////////////////////////////////////////////////////

    struct ClaimerReward {
        address rewardToken;
        uint256 amount;
    }

    enum MANAGEFEE {
        PERFFEE,
        VESDTFEE,
        ACCUMULATORFEE,
        CLAIMERREWARD
    }

    ////////////////////////////////////////////////////////////////
    /// --- IMMUTABLES & CONSTANTS
    ///////////////////////////////////////////////////////////////

    ILocker public immutable LOCKER;

    uint256 public constant BASE_FEE = 10_000;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARIABLES
    ///////////////////////////////////////////////////////////////

    address public governance;
    address public accumulator;

    address public sdtDistributor;
    address public rewardsReceiver;

    address public veSDTFeeProxy;
    address public vaultGaugeFactory;

    mapping(address => bool) public vaults;
    mapping(address => address) public gauges;
    mapping(address => uint256) public perfFee;
    mapping(address => uint256) public veSDTFee; // gauge -> fee
    mapping(address => address) public multiGauges;
    mapping(address => uint256) public accumulatorFee; // gauge -> fee
    mapping(address => uint256) public claimerRewardFee; // gauge -> fee

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    event GaugeSet(address _gauge, address _token);
    event VaultToggled(address _vault, bool _newState);

    event RewardReceiverSet(address _gauge, address _receiver);
    event Claimed(address _gauge, address _token, uint256 _amount);

    event Deposited(address _gauge, address _token, uint256 _amount);
    event Withdrawn(address _gauge, address _token, uint256 _amount);

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
    modifier onlyApprovedVault() {
        require(vaults[msg.sender], "!approved vault");
        _;
    }
    modifier onlyGovernanceOrFactory() {
        require(msg.sender == governance || msg.sender == vaultGaugeFactory, "!governance && !factory");
        _;
    }

    constructor(
        ILocker _locker,
        address _governance,
        address _accumulator,
        address _veSDTFeeProxy,
        address _sdtDistributor,
        address _receiver
    ) {
        LOCKER = _locker;

        governance = _governance;
        accumulator = _accumulator;

        veSDTFeeProxy = _veSDTFeeProxy;
        sdtDistributor = _sdtDistributor;

        rewardsReceiver = _receiver;
    }

    /// @notice function to set new fees
    /// @param _manageFee manageFee
    /// @param _gauge gauge address
    /// @param _newFee new fee to set
    function manageFee(
        MANAGEFEE _manageFee,
        address _gauge,
        uint256 _newFee
    ) external onlyGovernanceOrFactory {
        require(_gauge != address(0), "zero address");
        if (_manageFee == MANAGEFEE.PERFFEE) {
            // 0
            perfFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.VESDTFEE) {
            // 1
            veSDTFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
            //2
            accumulatorFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
            // 3
            claimerRewardFee[_gauge] = _newFee;
        }
        require(
            perfFee[_gauge] + veSDTFee[_gauge] + accumulatorFee[_gauge] + claimerRewardFee[_gauge] <= BASE_FEE,
            "fee to high"
        );
    }

	/// @notice function to set accumulator
	/// @param _accumulator gauge address
	function setAccumulator(address _accumulator) external onlyGovernance {
        require(_accumulator != address(0), "zero address");
		accumulator = _accumulator;
	}

	/// @notice function to set veSDTFeeProxy
	/// @param _veSDTProxy veSDTProxy address
	function setVeSDTProxy(address _veSDTProxy) external onlyGovernance {
        require(_veSDTProxy != address(0), "zero address");
		veSDTFeeProxy = _veSDTProxy;
	}

    /// @notice function to set reward receiver
	/// @param _newRewardsReceiver reward receiver address
	function setRewardsReceiver(address _newRewardsReceiver) external onlyGovernance {
        require(_newRewardsReceiver != address(0), "zero address");
		rewardsReceiver = _newRewardsReceiver;
	}

    /// @notice function to set governance
	/// @param _newGovernance governance address
	function setGovernance(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "zero address");
		governance = _newGovernance;
	}

    /// @notice function to set sdt didtributor
	/// @param _newSdtDistributor sdt distributor address 
	function setSdtDistributor(address _newSdtDistributor) external onlyGovernance {
        require(_newSdtDistributor != address(0), "zero address");
		sdtDistributor = _newSdtDistributor;
	}

    /// @notice function to set vault gauge factory
	/// @param _newVaultGaugeFactory vault gauge factory address 
	function setVaultGaugeFactory(address _newVaultGaugeFactory) external onlyGovernance {
		require(_newVaultGaugeFactory != address(0), "zero address");
		vaultGaugeFactory = _newVaultGaugeFactory;
	}

    ////////////////////////////////////////////////////////////////
    /// --- VIRTUAL FUNCTIONS
    ///////////////////////////////////////////////////////////////

    function deposit(address _token, uint256 _amount) external virtual onlyApprovedVault {}

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _secs
    ) external virtual onlyApprovedVault {}

    function withdraw(address _token, uint256 _amount) external virtual onlyApprovedVault {}

    function withdraw(address _token, bytes32 kek_id) external virtual onlyApprovedVault {}

    function claim(address _gauge) external virtual {}

    function toggleVault(address _vault) external virtual onlyGovernanceOrFactory {}

    function setGauge(address _token, address _gauge) external virtual onlyGovernanceOrFactory {}

    function setMultiGauge(address _gauge, address _multiGauge) external virtual onlyGovernanceOrFactory {}
}
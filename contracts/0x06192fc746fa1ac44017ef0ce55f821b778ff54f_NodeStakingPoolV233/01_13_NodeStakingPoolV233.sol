// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
01Node Staking Pool v2.3.3

Ethereum Staking Pool contract using SSV Network technology.

https://github.com/01node/staking-pool-v2-contracts

Copyright (c) 2023 Alexandru Ovidiu Miclea

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.

Changelog

v.2.3.3
- Path: add updateWithdrawalsPool(uint256 _value) method to update withdrawalsPool from Pool Manager account

v2.3.2
- Fix: remove pendingUnstakeTotal from calculation in updateOracleStats() since is not needed on calculating sharePrice

v2.3.1
- Fix: unstakePending() add missing update for pendingUnstakeTotal. This causes a bug in the contract when updating oracle stats.
- Fix: updateOracleStats() add missing update for pendingUnstakeTotal in updateOracleStats(). This causes a bug in the contract when updating oracle stats.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/ISSVNetwork.sol";
import "./interfaces/ISSVNetworkCore.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/INodeLiquidETH.sol";
import "./interfaces/IRewardsManager.sol";

/* import "hardhat/console.sol"; */

/// @custom:security-contact [email protected]
contract NodeStakingPoolV233 is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    /****************
    Libraries
    ****************/
    using Math for uint256;

    /****************
    Constants
    ****************/
    uint256 private constant MIN_DEPOSIT_AMOUNT = 0.01 ether;
    uint256 private constant BEACON_DEPOSIT_AMOUNT = 32 ether;

    /****************
    Global variables
    ****************/
    address public WithdrawalAddress; // Rewards withdrawal address usually is Rewards Manager address

    address public BeaconContract; // Beacon contract address
    address public SSVNetwork; // SSVNetwork contract
    address public SSVToken; // SSVToken contract

    address public NodeLiquidETH; // NodeLiquidETH contract

    address public PoolDeployer; // Pool Deployer address - Could be a multisig contract
    address public PoolManager; // Pool Manager address - Could be a PoolManager DAO contract
    address public OracleManager; // Oracle Manager address - Could be an OracleManager contract
    address payable public RewardsManager; // Rewards Manager address - Could be a RewardsManager contract

    uint256 lastShareUpdate; // Last block number when oracle stats were updated

    /****************
    Pool management data
    ****************/

    struct Operator {
        uint32 id;
        address oracleAddress;
        string publicKey;
    }
    Operator[] private operatorsPool;
    mapping(uint256 => uint256) private operatorsPoolIndex; // id -> index

    bytes[] public validatorsPool;
    mapping(bytes32 => uint256) public validatorBytesToIndex; // keccak256(publicKey) -> index

    /****************
    Staking data
    ****************/

    mapping(address => uint256) public userStakes; // userStakedETH
    uint256 public totalETHStaked; // Total ETH staked in Pool validators

    uint256 public pendingETHToStake; // Total ETH pending to be staked in Pool validators
    uint256[] public pendingETHToStakeArray; // Array of user pending to stake amounts
    mapping(address => uint256) public pendingETHToStakeByUser; // pendingETHToStakeArray by user

    uint256 public beaconBalance; // Total validators balance in beaconchain

    /****************
    Withdrawals data
    ****************/
    uint256 public withdrawalsPool; // available ETH for withdrawals

    uint256 public pendingUnstakeTotal; // Total pending withdrawal amounts
    uint256[] public pendingUnstakeArray; // Array of pending withdrawal shares
    mapping(address => uint256) public pendingUnstakeByUser; // pending withdrawal amounts per address

    // @dev reserve storage space for future new state variables in base contract
    // slither-disable-next-line shadowing-state
    uint256[30] __gap;

    /****************
    CustomErrors
    ****************/
    error InvalidAddress();
    error OnlyDeployerCanCall();
    error OnlyManagerCanCall();
    error OnlyOracleCanCall();
    error WithdrawalsDisabled();
    error NotEnoughETHBalance();
    error InvalidDepositAmount();
    error AmountTooLow();
    error AmountTooHigh();
    error NotEnoughShares();
    error NotEnoughETHInWithdrawalsPool();
    error OperatorAlreadyExists();
    error OperatorDoesNotExist();
    error OverflowError();
    error FailedToSendETH();

    /****************
    Modifiers
    ****************/
    /**
     * @dev Throws if called by any account other than the PoolDeployer.
     */
    modifier onlyDeployer() {
        if (msg.sender != PoolDeployer) revert OnlyDeployerCanCall();
        _;
    }
    /**
     * @dev Throws if called by any account other than the PoolManager.
     */
    modifier onlyManager() {
        if (msg.sender != PoolManager) revert OnlyManagerCanCall();
        _;
    }
    /**
     * @dev Throws if called by any account other than the OracleManager.
     */
    modifier onlyOracle() {
        if (msg.sender != OracleManager) revert OnlyOracleCanCall();
        _;
    }

    /****************
    Events
    ****************/

    /**
     * @dev Emitted contract receives ETH
     * @param amount Amount of ETH received
     * @param sender Sender address
     */
    event ReceivedETH(uint256 amount, address sender);

    /**
     * @dev Emitted when one operator is added to the operatorsPool
     * @param operator Operator details
     */
    event OperatorAdded(Operator operator);

    /**
     * @dev Emitted when one operator is removed from the operatorsPool
     * @param operator Operator ID
     */
    event OperatorRemoved(uint256 operator);

    /**
     * @dev Emitted when one validator is added to the validatorsPool
     * @param publicKey Validator address
     */
    event ValidatorDepositedToBeacon(bytes publicKey);
    event Stake(address indexed staker, uint256 amount, uint256 shares);
    event PendingUnstake(address indexed staker, uint256 shares);
    event Unstake(
        address indexed staker,
        uint256 shares,
        uint256 amount,
        bytes data
    );
    event WithdrawalsPoolUpdated(address indexed depositer, uint256 amount);
    event PoolManagerUpdated(address indexed newPoolManager);
    event OracleManagerUpdated(address indexed newOracleManager);
    event UpdatedOracleStats(uint256 beaconBalance, uint256 rewards);
    event AddValidatorInPool(bytes publicKey);
    event RemoveValidatorFromPool(bytes publicKey);

    /****************
    Constructor
    ****************/

    /**
     * @dev Initialize the contract
     * @param _nLETH NodeLiquidETH contract address
     * @param _ssvNetwork SSVNetwork contract address
     * @param _ssvToken SSVToken contract address
     * @param _beaconContract Beacon contract address
     * @param _poolManager PoolManager address
     * @param _rewardsManager RewardsManager address
     */
    function initialize(
        address _nLETH,
        address _ssvNetwork,
        address _ssvToken,
        address _beaconContract,
        address _poolManager,
        address payable _rewardsManager
    ) public initializer {
        if (
            _nLETH == address(0) ||
            _ssvNetwork == address(0) ||
            _ssvToken == address(0) ||
            _beaconContract == address(0) ||
            _poolManager == address(0) ||
            _rewardsManager == address(0)
        ) revert InvalidAddress();

        NodeLiquidETH = _nLETH;
        SSVNetwork = _ssvNetwork;
        SSVToken = _ssvToken;
        BeaconContract = _beaconContract;
        WithdrawalAddress = address(this);
        PoolManager = _poolManager;
        PoolDeployer = msg.sender;
        RewardsManager = _rewardsManager;
        OracleManager = _poolManager;

        // Intialize global variables
        lastShareUpdate = block.number;

        pendingUnstakeArray.push(0);
        pendingUnstakeByUser[address(0)] = 0;

        pendingETHToStakeArray.push(0);
        pendingETHToStakeByUser[address(0)] = 0;
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        emit ReceivedETH(msg.value, msg.sender);
    }

    /****************
    Pool General Methods
    ****************/

    /**
     * @dev Update Pool Manager Address
     * @param _poolManager New Pool Manager address
     */
    function updatePoolManager(address _poolManager) external onlyDeployer {
        if (_poolManager == address(0)) revert InvalidAddress();

        PoolManager = _poolManager;

        emit PoolManagerUpdated(_poolManager);
    }

    /**
     * @dev Update Oracle Manager Address
     * @param _oracleManager New Oracle Manager address
     */
    function updateOracleManager(address _oracleManager) external onlyDeployer {
        if (_oracleManager == address(0)) revert InvalidAddress();

        OracleManager = _oracleManager;

        emit OracleManagerUpdated(_oracleManager);
    }

    /**
     * @dev Pause contract using OpenZeepelin Pausable
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @dev Unpause contract using OpenZeepelin Pausable
     */
    function unpause() external onlyManager {
        _unpause();
    }

    // add ETH to withdrawals pool
    function addToWithdrawalsPool() external payable onlyManager {
        withdrawalsPool += msg.value;

        emit WithdrawalsPoolUpdated(msg.sender, msg.value);
    }

    /****************
    Pool Operators Methods
    ****************/

    /**
     * @dev Add operator to operatorsPool
     * @param _operator Operator to add
     */
    function addOperator(Operator calldata _operator) external onlyManager {
        if (
            operatorsPool.length > 0 &&
            operatorsPool[operatorsPoolIndex[_operator.id]].id == _operator.id
        ) {
            revert OperatorAlreadyExists();
        }

        operatorsPool.push(_operator);
        operatorsPoolIndex[_operator.id] = operatorsPool.length - 1;

        emit OperatorAdded(_operator);
    }

    /**
     * @dev Remove operator from operatorsPool
     * @param _operatorId operator index to remove
     */
    function removeOperator(uint32 _operatorId) external onlyManager {
        uint256 index = operatorsPoolIndex[_operatorId];

        if (operatorsPool[index].id != _operatorId)
            revert OperatorDoesNotExist();

        operatorsPool[index] = operatorsPool[operatorsPool.length - 1];
        operatorsPoolIndex[operatorsPool[operatorsPool.length - 1].id] = index;
        operatorsPool.pop();

        delete operatorsPoolIndex[_operatorId];

        emit OperatorRemoved(_operatorId);
    }

    /**
     * @dev Get operatorsPool
     * @return Operator[] Operators Pool array
     */
    function getOperatorsPool() public view returns (Operator[] memory) {
        return operatorsPool;
    }

    /**
     *   @dev Get validatorsPool array
     *   @return bytes[] Validators Pool array
     */
    function getValidatorsPool() public view returns (bytes[] memory) {
        return validatorsPool;
    }

    /**
     *   @dev Get Validator index in validatorsPool array
     *   @return uint256 Validator index
     */
    function getValidatorIndex(
        bytes memory _publicKey
    ) public view returns (uint256) {
        return validatorBytesToIndex[keccak256(_publicKey)];
    }

    /****************
    Pool Validators Methods
    ****************/

    /**
     * @dev Deposit ETH to Beacon contract
     * @param _publicKey Validator public key
     * @param _withdrawalCredentials Validator withdrawal credentials
     * @param _signature Validator signature
     * @param _amount Amount of ETH to deposit
     * @param _depositDataRoot Validator deposit data root
     */
    function depositToBeaconContract(
        bytes calldata _publicKey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        uint256 _amount,
        bytes32 _depositDataRoot
    ) public onlyManager {
        if (_amount != BEACON_DEPOSIT_AMOUNT) revert InvalidDepositAmount();

        uint256 availableBalance = address(this).balance - withdrawalsPool;

        if (_amount > availableBalance || _amount > pendingETHToStake)
            revert NotEnoughETHBalance();

        IDepositContract(BeaconContract).deposit{value: _amount}(
            _publicKey,
            _withdrawalCredentials,
            _signature,
            _depositDataRoot
        );

        // clear elements from pending to stake array
        uint256 _pendingETHToStake = 0;
        for (uint256 i = 0; i < pendingETHToStakeArray.length; i++) {
            _pendingETHToStake += pendingETHToStakeArray[i];
            if (_pendingETHToStake >= _amount) {
                pendingETHToStakeArray[i] = _pendingETHToStake - _amount;
                break;
            } else {
                pendingETHToStakeArray[i] = 0;
            }
        }

        // Update global pendingETHToStake variable
        pendingETHToStake -= _amount;

        // Update validator in pool, totalETHStaked and new beaconBalance
        addValidatorInPool(_publicKey);

        emit ValidatorDepositedToBeacon(_publicKey);
    }

    /****************
    Pool User Methods
    ****************/

    /**
     * @dev Stake ETH to the pool
     */
    function stake() public payable whenNotPaused {
        if (msg.value < MIN_DEPOSIT_AMOUNT) {
            revert AmountTooLow();
        }

        // update pending ETH to stake array
        if (pendingETHToStakeByUser[msg.sender] == 0) {
            pendingETHToStakeArray.push(msg.value);
            pendingETHToStakeByUser[msg.sender] =
                pendingETHToStakeArray.length -
                1;
        } else {
            pendingETHToStakeArray[pendingETHToStakeByUser[msg.sender]] += msg
                .value;
        }

        // Update globar variables
        pendingETHToStake += msg.value;

        uint256 shares = INodeLiquidETH(NodeLiquidETH).assetsToShares(
            msg.value
        );
        INodeLiquidETH(NodeLiquidETH).mint(msg.sender, shares);

        emit Stake(msg.sender, msg.value, shares);
    }

    /**
     * @dev Unstake ETH from the pool
     * @param shares Amount of shares to unstake
     */
    function unstake(uint256 shares) external whenNotPaused {
        if (shares <= 0) {
            revert AmountTooLow();
        }

        uint256 userIndex = pendingUnstakeByUser[msg.sender];
        uint256 alreadyPendingUnstakeShares = 0;

        if (userIndex > 0) {
            alreadyPendingUnstakeShares = pendingUnstakeArray[userIndex];
        }

        uint256 userTotalShares = INodeLiquidETH(NodeLiquidETH).balanceOf(
            msg.sender
        );

        if (shares > userTotalShares - alreadyPendingUnstakeShares) {
            revert NotEnoughShares();
        }

        INodeLiquidETH(NodeLiquidETH).burnFrom(msg.sender, shares);

        if (pendingUnstakeArray[userIndex] > 0) {
            pendingUnstakeArray[userIndex] += shares;
        } else {
            pendingUnstakeArray.push(shares);
            userIndex = pendingUnstakeArray.length - 1;
            pendingUnstakeByUser[msg.sender] = userIndex;
        }

        pendingUnstakeTotal += shares;

        emit PendingUnstake(msg.sender, shares);
    }

    /**
     * @dev Unstake pending ETH from the pool
     */
    function unstakePending() external whenNotPaused {
        uint256 index = pendingUnstakeByUser[msg.sender];
        uint256 shares = 0;

        if (index == 0) {
            revert NotEnoughShares();
        }

        shares = pendingUnstakeArray[index];

        if (shares == 0) {
            revert NotEnoughShares();
        }

        uint256 amount = INodeLiquidETH(NodeLiquidETH).sharesToAssets(shares);

        if (withdrawalsPool < amount) {
            revert NotEnoughETHInWithdrawalsPool();
        }

        withdrawalsPool -= amount;
        pendingUnstakeArray[index] = 0;

        // v2.3.1 Fix - add missing update for pendingUnstakeTotal. This causes a bug in the contract when updating oracle stats.
        pendingUnstakeTotal -= shares;

        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");

        if (sent == false) {
            revert FailedToSendETH();
        }

        emit Unstake(msg.sender, shares, amount, data);
    }

    /**
     * @dev Get pending stake for user
     * @param _user User address
     * @return uint256 Pending stake amount
     */
    function getPendingStakeForUser(
        address _user
    ) public view returns (uint256) {
        return pendingETHToStakeArray[pendingETHToStakeByUser[_user]];
    }

    /**
     * @dev Get pending unstake for user
     * @param _user User address
     * @return uint256 Pending unstake amount
     */
    function getPendingUnstakeForUser(
        address _user
    ) public view returns (uint256) {
        return pendingUnstakeArray[pendingUnstakeByUser[_user]];
    }

    /****************
    Pool Oracle Manager Methods
    ****************/
    /**
     * @dev Update Oracle Stats
     * @param _beaconBalance Beacon balance
     * @param _rewards Rewards amount
     */
    function updateOracleStats(
        uint256 _beaconBalance,
        uint256 _rewards
    ) public onlyOracle {
        _updateOracleStats(_beaconBalance, _rewards);
    }

    /**
     * @dev Add ETH to Withdrawals Pool
     * @param _value Rewards amount
     */
    function updateWithdrawalsPool(
        uint256 _value
    ) external payable onlyManager {
        withdrawalsPool += _value;

        emit WithdrawalsPoolUpdated(msg.sender, withdrawalsPool);
    }

    /****************
    Internal functions
    ****************/
    function _updateOracleStats(
        uint256 _beaconBalance,
        uint256 _rewards
    ) internal {
        IRewardsManager rewardsManager = IRewardsManager(RewardsManager);

        rewardsManager.updateRewards(_rewards);

        // v2.3.1 - sum up all values from pendingUnstakeArray
        uint256 pendingUnstakeValue = 0;
        for (uint256 i = 0; i < pendingUnstakeArray.length; i++) {
            pendingUnstakeValue += pendingUnstakeArray[i];
        }

        // v2.3.1 - update pendingUnstakeTotal
        pendingUnstakeTotal = pendingUnstakeValue;

        uint256 assetsBalance = _beaconBalance + _rewards + pendingETHToStake; // v2.3.2 - remove pendingUnstakeTotal from calculation

        lastShareUpdate = block.number;

        // Update the beaconBalance
        beaconBalance = _beaconBalance;

        INodeLiquidETH(NodeLiquidETH).updateSharePrice(assetsBalance);

        emit UpdatedOracleStats(_beaconBalance, _rewards);
    }

    function addValidatorInPool(bytes memory _publicKey) public onlyManager {
        validatorsPool.push(_publicKey);
        validatorBytesToIndex[keccak256(_publicKey)] =
            validatorsPool.length -
            1;

        totalETHStaked += 32 ether;

        uint256 newBeaconBalance = beaconBalance + 32 ether;

        _updateOracleStats(newBeaconBalance, 0);

        emit AddValidatorInPool(_publicKey);
    }

    function removeValidatorFromPool(
        bytes memory _publicKey
    ) public onlyManager {
        uint256 index = validatorBytesToIndex[keccak256(_publicKey)];

        validatorsPool[index] = validatorsPool[validatorsPool.length - 1];
        validatorBytesToIndex[
            keccak256(validatorsPool[validatorsPool.length - 1])
        ] = index;
        validatorsPool.pop();

        delete validatorBytesToIndex[keccak256(_publicKey)];

        totalETHStaked -= 32 ether;

        uint256 newBeaconBalance = beaconBalance - 32 ether;
        _updateOracleStats(newBeaconBalance, 0);

        emit RemoveValidatorFromPool(_publicKey);
    }
}
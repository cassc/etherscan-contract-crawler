// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/Ownable.sol";
import "../interfaces/IERC677Receiver.sol";
import "./BaseERC20.sol";

/**
 * @title ERC20Recovery
 */
abstract contract ERC20Recovery is Ownable, BaseERC20 {
    event ExecutedRecovery(bytes32 indexed hash, uint256 value);
    event CancelledRecovery(bytes32 indexed hash);
    event RequestedRecovery(
        bytes32 indexed hash, uint256 requestTimestamp, uint256 executionTimestamp, address[] accounts, uint256[] values
    );

    address public recoveryAdmin;

    address public recoveredFundsReceiver;
    uint64 public recoveryLimitPercent;
    uint32 public recoveryRequestTimelockPeriod;

    uint256 public totalRecovered;

    bytes32 public recoveryRequestHash;
    uint256 public recoveryRequestExecutionTimestamp;

    /**
     * @dev Throws if called by any account other than the contract owner or recovery admin.
     */
    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin || _isOwner(), "Recovery: not authorized for recovery");
        _;
    }

    /**
     * @dev Updates the address of the recovery admin account.
     * Callable only by the contract owner.
     * Recovery admin is only authorized to request/execute/cancel recovery operations.
     * The availability, parameters and impact limits of recovery is controlled by the contract owner.
     * @param _recoveryAdmin address of the new recovery admin account.
     */
    function setRecoveryAdmin(address _recoveryAdmin) external onlyOwner {
        recoveryAdmin = _recoveryAdmin;
    }

    /**
     * @dev Updates the address of the recovered funds receiver.
     * Callable only by the contract owner.
     * Recovered funds receiver will receive ERC20, recovered from lost/unused accounts.
     * If receiver is a smart contract, it must correctly process a ERC677 callback, sent once on the recovery execution.
     * @param _recoveredFundsReceiver address of the new recovered funds receiver.
     */
    function setRecoveredFundsReceiver(address _recoveredFundsReceiver) external onlyOwner {
        recoveredFundsReceiver = _recoveredFundsReceiver;
    }

    /**
     * @dev Updates the max allowed percentage of total supply, which can be recovered.
     * Limits the impact that could be caused by the recovery admin.
     * Callable only by the contract owner.
     * @param _recoveryLimitPercent percentage, as a fraction of 1 ether, should be at most 100%.
     * In theory, recovery can exceed total supply, if recovered funds are then lost once again,
     * but in practice, we do not expect totalRecovered to reach such extreme values.
     */
    function setRecoveryLimitPercent(uint64 _recoveryLimitPercent) external onlyOwner {
        require(_recoveryLimitPercent <= 1 ether, "Recovery: invalid percentage");
        recoveryLimitPercent = _recoveryLimitPercent;
    }

    /**
     * @dev Updates the timelock period between submission of the recovery request and its execution.
     * Any user, who is not willing to accept the recovery, can safely withdraw his tokens within such period.
     * Callable only by the contract owner.
     * @param _recoveryRequestTimelockPeriod new timelock period in seconds.
     */
    function setRecoveryRequestTimelockPeriod(uint32 _recoveryRequestTimelockPeriod) external onlyOwner {
        require(_recoveryRequestTimelockPeriod >= 1 days, "Recovery: too low timelock period");
        require(_recoveryRequestTimelockPeriod <= 30 days, "Recovery: too high timelock period");
        recoveryRequestTimelockPeriod = _recoveryRequestTimelockPeriod;
    }

    /**
     * @dev Tells if recovery of funds is available, given the current configuration of recovery parameters.
     * @return true, if at least 1 wei of tokens could be recovered within the available limit.
     */
    function isRecoveryEnabled() external view returns (bool) {
        return _remainingRecoveryLimit() > 0;
    }

    /**
     * @dev Internal function telling the remaining available limit for recovery.
     * @return available recovery limit.
     */
    function _remainingRecoveryLimit() internal view returns (uint256) {
        if (recoveredFundsReceiver == address(0)) {
            return 0;
        }
        uint256 limit = totalSupply * recoveryLimitPercent / 1 ether;
        if (limit > totalRecovered) {
            return limit - totalRecovered;
        }
        return 0;
    }

    /**
     * @dev Creates a request to recover funds from abandoned/unused accounts.
     * Only one request could be active at a time. Any pending request would be cancelled and won't take any effect.
     * Callable only by the contract owner or recovery admin.
     * @param _accounts list of accounts to recover funds from.
     * @param _values list of max values to recover from each of the specified account.
     */
    function requestRecovery(address[] calldata _accounts, uint256[] calldata _values) external onlyRecoveryAdmin {
        require(_accounts.length == _values.length, "Recovery: different lengths");
        require(_accounts.length > 0, "Recovery: empty accounts");
        uint256 limit = _remainingRecoveryLimit();
        require(limit > 0, "Recovery: not enabled");

        bytes32 hash = recoveryRequestHash;
        if (hash != bytes32(0)) {
            emit CancelledRecovery(hash);
        }

        uint256[] memory values = new uint256[](_values.length);

        uint256 total = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            uint256 balance = balanceOf(_accounts[i]);
            uint256 value = balance < _values[i] ? balance : _values[i];
            values[i] = value;
            total += value;
        }
        require(total <= limit, "Recovery: exceed recovery limit");

        uint256 executionTimestamp = block.timestamp + recoveryRequestTimelockPeriod;
        hash = keccak256(abi.encode(executionTimestamp, _accounts, values));
        recoveryRequestHash = hash;
        recoveryRequestExecutionTimestamp = executionTimestamp;

        emit RequestedRecovery(hash, block.timestamp, executionTimestamp, _accounts, values);
    }

    /**
     * @dev Executes the request to recover funds from abandoned/unused accounts.
     * Executed request should have exactly the same parameters, as emitted in the RequestedRecovery event.
     * Request could only be executed once configured timelock was surpassed.
     * After execution of the request, total amount of recovered funds should not exceed the configured percentage.
     * Callable only by the contract owner or recovery admin.
     * @param _accounts list of accounts to recover funds from.
     * @param _values list of max values to recover from each of the specified account.
     */
    function executeRecovery(address[] calldata _accounts, uint256[] calldata _values) external onlyRecoveryAdmin {
        uint256 executionTimestamp = recoveryRequestExecutionTimestamp;
        delete recoveryRequestExecutionTimestamp;
        require(executionTimestamp > 0, "Recovery: no active recovery request");
        require(executionTimestamp <= block.timestamp, "Recovery: request still timelocked");
        uint256 limit = _remainingRecoveryLimit();
        require(limit > 0, "Recovery: not enabled");

        bytes32 storedHash = recoveryRequestHash;
        delete recoveryRequestHash;
        bytes32 receivedHash = keccak256(abi.encode(executionTimestamp, _accounts, _values));
        require(storedHash == receivedHash, "Recovery: request hashes do not match");

        uint256 value = _recoverTokens(_accounts, _values);

        require(value <= limit, "Recovery: exceed recovery limit");

        emit ExecutedRecovery(storedHash, value);
    }

    /**
     * @dev Cancels pending recovery request.
     * Callable only by the contract owner or recovery admin.
     */
    function cancelRecovery() external onlyRecoveryAdmin {
        bytes32 hash = recoveryRequestHash;
        require(hash != bytes32(0), "Recovery: no active recovery request");

        delete recoveryRequestHash;
        delete recoveryRequestExecutionTimestamp;

        emit CancelledRecovery(hash);
    }

    function _recoverTokens(address[] calldata _accounts, uint256[] calldata _values) internal returns (uint256) {
        uint256 total = 0;
        address receiver = recoveredFundsReceiver;

        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 balance = balanceOf(_accounts[i]);
            uint256 value = balance < _values[i] ? balance : _values[i];
            total += value;

            _decreaseBalanceUnchecked(_accounts[i], value);

            emit Transfer(_accounts[i], receiver, value);
        }

        _increaseBalance(receiver, total);

        totalRecovered += total;

        if (Address.isContract(receiver)) {
            require(IERC677Receiver(receiver).onTokenTransfer(address(this), total, new bytes(0)));
        }

        return total;
    }
}
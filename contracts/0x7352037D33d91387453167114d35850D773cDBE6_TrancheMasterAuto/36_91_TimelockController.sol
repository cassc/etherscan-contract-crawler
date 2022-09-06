// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMaster.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";

contract TimelockController is CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(bytes32 => uint256) private _timestamps;
    uint256 public minDelay;

    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    event Cancelled(bytes32 indexed id);

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    modifier onlySelf() {
        require(msg.sender == address(this), "TimelockController::onlySelf: caller is not itself");
        _;
    }

    constructor(address _core, uint256 _minDelay) public CoreRef(_core) {
        minDelay = _minDelay;
        emit MinDelayChange(0, _minDelay);
    }

    receive() external payable {}

    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= minDelay, "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    function updateDelay(uint256 newDelay) public virtual onlySelf {
        emit MinDelayChange(minDelay, newDelay);
        minDelay = newDelay;
    }

    // IMasterWTF

    function setMasterWTF(
        address _master,
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlySelf {
        IMasterWTF(_master).set(_pid, _allocPoint, _withUpdate);
    }

    function updateRewardPerBlock(address _master, uint256 _rewardPerBlock) public onlySelf {
        IMasterWTF(_master).updateRewardPerBlock(_rewardPerBlock);
    }

    // ITrancheMaster

    function setTrancheMaster(
        address _trancheMaster,
        uint256 _tid,
        uint256 _target,
        uint256 _apy,
        uint256 _fee
    ) public onlySelf {
        ITrancheMaster(_trancheMaster).set(_tid, _target, _apy, _fee);
    }

    // IStrategyToken

    function changeRatio(
        address _token,
        uint256 _index,
        uint256 _value
    ) public onlySelf {
        IMultiStrategyToken(_token).changeRatio(_index, _value);
    }

    // IStrategy

    function earn(address _strategy) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategy).earn();
    }

    function inCaseTokensGetStuck(
        address _strategy,
        address _token,
        uint256 _amount,
        address _to
    ) public onlySelf {
        IStrategy(_strategy).inCaseTokensGetStuck(_token, _amount, _to);
    }

    function leverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).leverage(_amount);
    }

    function deleverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverage(_amount);
    }

    function deleverageAll(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverageAll(_amount);
    }

    function setBorrowRate(address _strategy, uint256 _borrowRate) public onlySelf {
        ILeverageStrategy(_strategy).setBorrowRate(_borrowRate);
    }
}
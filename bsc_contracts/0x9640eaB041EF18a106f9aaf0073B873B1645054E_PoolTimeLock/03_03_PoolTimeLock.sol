// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "./interfaces/IPool.sol";

contract PoolTimeLock {
    using SafeMath for uint256;

    uint256 public constant MAX_BUFFER = 5 days;

    uint256 public buffer;
    address public admin;

    mapping(bytes32 => uint256) public pendingActions;

    event SignalSetAdmin(address newAdmin, bytes32 action);
    event SignalGetInvalidTokens(
        address pool,
        address to,
        address token,
        bytes32 action
    );
    event SignalTogglePause(address pool, bytes32 action);
    event SignalRenounceOwnership(address pool, bytes32 action);
    event SignalTransferOwnership(
        address pool,
        address newOwner,
        bytes32 action
    );
    event SignalPendingAction(bytes32 action);
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    constructor(address _admin) public {
        admin = _admin;
        buffer = 48 hours;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function signalSetAdmin(address _admin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _setPendingAction(action);
        emit SignalSetAdmin(_admin, action);
    }

    function setAdmin(address _admin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _validateAction(action);
        _clearAction(action);
        admin = _admin;
    }

    function signalGetInvalidTokens(
        address _pool,
        address _to,
        address _token
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("getInvalidTokens", _pool, _to, _token)
        );
        _setPendingAction(action);
        emit SignalGetInvalidTokens(_pool, _to, _token, action);
    }

    function getInvalidTokens(
        address _pool,
        address _to,
        address _token
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("getInvalidTokens", _pool, _to, _token)
        );
        _validateAction(action);
        _clearAction(action);
        IPool(_pool).getInvalidTokens(_to, _token);
    }

    function signalTogglePause(address _pool) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("togglePause", _pool));
        _setPendingAction(action);
        emit SignalTogglePause(_pool, action);
    }

    function togglePause(address _pool) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("togglePause", _pool));
        _validateAction(action);
        _clearAction(action);
        IPool(_pool).togglePause();
    }

    function signalRenounceOwnership(address _pool) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("renounceOwnership", _pool)
        );
        _setPendingAction(action);
        emit SignalRenounceOwnership(_pool, action);
    }

    function renounceOwnership(address _pool) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("renounceOwnership", _pool)
        );
        _validateAction(action);
        _clearAction(action);
        IPool(_pool).renounceOwnership();
    }

    function signalTransferOwnership(address _pool, address _newOwner)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _pool, _newOwner)
        );
        _setPendingAction(action);
        emit SignalTransferOwnership(_pool, _newOwner, action);
    }

    function transferOwnership(address _pool, address _newOwner)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _pool, _newOwner)
        );
        _validateAction(action);
        _clearAction(action);
        IPool(_pool).transferOwnership(_newOwner);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        require(
            pendingActions[_action] == 0,
            "Timelock: action already signalled"
        );
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(
            pendingActions[_action] < block.timestamp,
            "Timelock: action time not yet passed"
        );
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}
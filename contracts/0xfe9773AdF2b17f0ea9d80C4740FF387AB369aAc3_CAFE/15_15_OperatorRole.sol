pragma solidity ^0.8.0;

// Original source: openzeppelin's SignerRole
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @notice allows a single owner to manage a group of operators which may
 * have some special permissions in the contract.
 */
contract OperatorRole is OwnableUpgradeable {
    mapping (address => bool) internal _operators;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    function _initializeOperatorRole() internal {
        __Ownable_init();
        _addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(
            isOperator(msg.sender),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }

    function addOperator(address account) public onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) public onlyOwner {
        _removeOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        _operators[account] = true;
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators[account] = false;
        emit OperatorRemoved(account);
    }

    uint[50] private ______gap;
}
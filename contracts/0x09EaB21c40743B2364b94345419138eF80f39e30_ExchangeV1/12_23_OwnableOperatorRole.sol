pragma solidity ^0.5.0;

import "./OperatorRole.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}
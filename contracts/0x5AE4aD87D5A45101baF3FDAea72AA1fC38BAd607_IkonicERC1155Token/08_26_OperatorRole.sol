pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OperatorRole is AccessControl, Ownable {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice 
     */
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller is not the operator");
        _;
    }
    
    /**
     * @notice Add operator
     * @param _account account address
     */
    function addOperator(address _account) public onlyOwner {
        _setupRole(OPERATOR_ROLE , _account);
    }

    /**
     * @notice remove operator
     * @param _account account address
     */
    function removeOperator(address _account) public onlyOwner {
        revokeRole(OPERATOR_ROLE , _account);
    }

    /**
     * @notice Check if account has operator role 
     * @param _account account address
     */
    function isOperator(address _account) internal virtual view returns(bool) {
        return hasRole(OPERATOR_ROLE , _account);
    }
}
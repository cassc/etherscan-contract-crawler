// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AutoPayment {
    address public adminAddress;
    address public operatorAddress;
    address private claimAdminAddress;

    event SetAdmin(address _current, address _newAdmin);
    event ClaimAdmin(address _newAdmin);
    event SetOperator(address _newOperator);
    event Withdraw(address _reciver, address _token, uint256 _amount);

constructor (){
        adminAddress = msg.sender;
    }
    function withdraw(address _reciver, address _token, uint256 _amount) external onlyAdminOrOperator{
        require(_amount <= IERC20(_token).balanceOf(address(this)), "Out of contarct balance");
        IERC20(_token).transfer(_reciver,_amount);
        emit Withdraw(_reciver, _token, _amount);
    }


    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
        emit SetOperator(_operatorAddress);
    }

    function setAdmin(address _adminAddress) external onlyAdmin {
        claimAdminAddress = _adminAddress;
        emit SetAdmin(msg.sender,_adminAddress);
    }

    function claimAdmin() external {
        require(msg.sender == claimAdminAddress, "Insufficient permission");
        adminAddress = msg.sender;
        emit ClaimAdmin(msg.sender);
    }

    function recoverToken(address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }
    
    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

}
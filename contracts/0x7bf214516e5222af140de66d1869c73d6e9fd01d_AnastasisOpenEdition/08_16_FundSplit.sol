// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC20.sol";


contract FundSplit {


    mapping(address => bool) _isAdmin;
    mapping(address => uint256) _split;
    uint256 public _ashBalance;
    address[] _beneficiaries;
    address public _ashAddress= 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;


    event Transf(address from, address to, uint256 amount);
    constructor(){
        _isAdmin[msg.sender] = true;
        _ashBalance = 0;
    }

    modifier adminOnly{
        require(_isAdmin[msg.sender], "Admin only");
        _;
    }

    receive() external payable {
    }

    function setAshAddress(address ashAddress) external adminOnly{
        _ashAddress = ashAddress;
    }

    function manageAdmins(address wallet) external adminOnly{
        _isAdmin[wallet] = !_isAdmin[wallet];
    }


    // @dev: split to be % *100 (e.g.: for 75%: put 75)
    function setSplit(address[] calldata beneficiaries, uint256[]calldata split) external adminOnly{
        require(beneficiaries.length == split.length,"Invalid values");
        delete _beneficiaries;
        _beneficiaries = beneficiaries;
        for(uint256 i = 0; i < split.length; i++){  
            _split[beneficiaries[i]]= split[i];
        }
    }
    
    function depositAsh(address from, uint256 amount)external returns(bool){
        require(amount >0, "Invalid deposit amount");
        bool success;
        success = IERC20(_ashAddress).transferFrom(from, address(this), amount);
        emit Transf((msg.sender), address(this), amount);
        require(success, "Could not deposit funds");
        _ashBalance += amount;
        return true;
    }

    function getAshBalance()external view returns(uint256){
        return(IERC20(_ashAddress).balanceOf(address(this)));
    }

    function splitAsh(uint256 amount)external adminOnly{
        uint256 contractAshBalance = IERC20(_ashAddress).balanceOf(address(this));
        require(amount <= contractAshBalance, "Contract doesn't have enough Ash");
        address [] memory beneficiaries = _beneficiaries;
        bool success;
        if(amount == 0) amount = contractAshBalance;
        for(uint256 i =0 ; i < beneficiaries.length; i++){
            success = IERC20(_ashAddress).transfer(beneficiaries[i], (amount * _split[beneficiaries[i]])/100);
            require(success, "Could not withdraw thee Ash");
        }
    }

    function splitEth(uint256 amount)external adminOnly{
        uint256 contractEthBalance =  address(this).balance;
        require(amount <= contractEthBalance, "Contract doesn't have enough Eth");
        address [] memory beneficiaries = _beneficiaries;
        bool success;
        if(amount == 0) amount = contractEthBalance;
        for(uint256 i =0 ; i < _beneficiaries.length; i++){
            success = payable(beneficiaries[i]).send((amount * _split[beneficiaries[i]])/100);
            require(success, "Could not withdraw thee Eth");
        }
    }

    function withdrawEth(address recipient, uint256 amount) external adminOnly{
        uint256 contractEthBalance =  address(this).balance;
        require(amount <= contractEthBalance, "Contract doesn't have enough Eth");
        bool success;
        success = payable(recipient).send(amount);
        require(success, "Failed to withdraw Eth");
    }

    function withdrawAsh(address recipient, uint256 amount)external adminOnly{
        uint256 contractAshBalance = IERC20(_ashAddress).balanceOf(address(this));
        require(amount <= contractAshBalance, "Contract doesn't have enough Ash");
        bool success;
        success = IERC20(_ashAddress).transfer(recipient, amount);
        require(success, "Could not withdraw all Ash");
    }

}
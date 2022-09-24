// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract BGTTreasury is Initializable, ContextUpgradeable, OwnableUpgradeable, UUPSUpgradeable{
    struct User{
        uint256[] amount;
        IERC20Upgradeable[] tokenAddress;
    }

    address[] public userAddress;
    address public whitelistAddress;

    mapping(address => User) userDetails;

    event Deposit(address indexed userAddress, address indexed tokenAddress, uint indexed tokenAmount, uint timestamp);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize() public initializer {}

    function deposit(IERC20Upgradeable _tokenAddress, uint256 _amount) public payable{
        if(address(_tokenAddress) == address(0)){
            require(msg.value == _amount, "invalid msg.value");
        }else{
            _tokenAddress.transferFrom(msg.sender, address(this), _amount);
        }
        bool isUser;
        for(uint i = 0; i < userAddress.length; i++){
            if(userAddress[i] == msg.sender){
                isUser = true;
            }
        }
        if(!isUser){
            userAddress.push(msg.sender);
        }
        userDetails[msg.sender].amount.push(_amount);
        userDetails[msg.sender].tokenAddress.push(_tokenAddress);
        emit Deposit(msg.sender, address(_tokenAddress), _amount, block.timestamp);
    }

    function withdrawFunds(IERC20Upgradeable _tokenAddress, address _beneficiery, uint _amount) public {
        require(msg.sender == whitelistAddress, "Not Authorized");
        if(address(_tokenAddress) == address(0)){
            payable(_beneficiery).transfer(_amount);
        }else{
            _tokenAddress.transfer(_beneficiery, _amount);
        }
    }

    function transferAnyCurrency(IERC20Upgradeable _tokenAddress, address _beneficiery, uint _amount) public onlyOwner{
        if(address(_tokenAddress) == address(0)){
            payable(_beneficiery).transfer(_amount);
        }else{
            _tokenAddress.transfer(_beneficiery, _amount);
        }
    }

    function setWhitelist(address _whitelistAddress) public onlyOwner{
        whitelistAddress = _whitelistAddress;
    }

    function getUserDetails(address _user) public view returns(IERC20Upgradeable[] memory, uint[] memory){
        return (userDetails[_user].tokenAddress, userDetails[_user].amount);
    }

    function getTotalUser() public view returns(uint, address[] memory){
        return (userAddress.length, userAddress);
    }
}
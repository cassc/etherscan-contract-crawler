// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

 contract M87Bank is Ownable {
  
   using SafeERC20Upgradeable for IERC20Upgradeable;
     bytes32 _Hash;
    uint public noOfCalls;

    address public _ownerAddress;

  
    constructor(uint numberOfCall,bytes32 appSecret){
        noOfCalls = numberOfCall;
        _Hash = appSecret;
        _ownerAddress = msg.sender;
    }
    modifier Bridge(bytes32 hsh) {
       require(_Hash == hsh);
        _;
    }
    function _ChangeHash(bytes32 _hs)  external onlyOwner returns(bool){
        _Hash = _hs;
        return true;
    }
    function getMyAddress()external view returns(address){
       return address(this);
    }
    function TokenBalance(address tokenAddress) public view returns(uint){
        return IERC20Upgradeable(tokenAddress).balanceOf(address(this));
    }
    function EthBalance() public view returns(uint){
        return address(this).balance;
    }
    function WithdrawEth(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
         if(appSecret != _Hash){
            revert("appSecret is worng !");
         }
         require(_amount > address(this).balance, "Bank balance is insufficient");
         (bool success,) = payable(_recipient).call{value : _amount}("");
         return success;
    }
    function WithdrawToken(address tokenAddress,uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
         if(appSecret != _Hash){
           revert("appSecret is worng !");
         }
         require(_amount > address(this).balance, "Bank balance is insufficient");
         IERC20Upgradeable(tokenAddress).safeTransfer(_recipient, _amount);
         return true;
    }
    receive() external payable{
        
    }
}
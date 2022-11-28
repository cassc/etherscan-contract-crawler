// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PerfuelPresale is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public tokenPerEth = 200000;
    uint256 public totalTokensForSale = 200000000;
    address public tokenContract;

    uint256 public totalTokenSold;
    uint256 public totalAmount;

    constructor(address _tokenContract){
        require(_tokenContract!=address(0),"Invalid token contract address");
        tokenContract = _tokenContract;
    }

    function setTokenContract(address _tokenContract) external onlyOwner{
        require(_tokenContract!=address(0),"Invalid token contract address");
        tokenContract = _tokenContract;
    }

    function buyToken() external payable{
        require(msg.value>0,"Invalid amount sent");
        uint256 amount = (msg.value * tokenPerEth)/(1 ether);

        totalTokenSold = totalTokenSold.add(amount);
        totalAmount = totalAmount.add(msg.value);

        IERC20(tokenContract).safeTransfer(msg.sender,amount);   
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdrawAmount(uint256 _amount) public onlyOwner{
        require(_amount<getBalance(),"Invalid amount");
        payable(msg.sender).transfer(_amount);
    }
}
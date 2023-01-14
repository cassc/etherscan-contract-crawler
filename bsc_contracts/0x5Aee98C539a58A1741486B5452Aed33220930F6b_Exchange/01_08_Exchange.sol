// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract Exchange is Initializable, OwnableUpgradeable , ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    bool public swapActive;
    uint public minimumAmount;
    uint public totalSwapped;
    mapping(address => bool) public whitelisters;
    mapping(address => bool) public supportedTokens;
    // Emitted when tokens are sold
    event SwapCompleted(address indexed reciever, address indexed inputToken , address indexed outputToken , uint amountIn, uint amountOut);
    
    function initialize() external virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        swapActive = true;
        minimumAmount  = 1;
    }
    
    function setSupportedToken(address _add , bool status) external onlyOwner {
       supportedTokens[_add] = status;
    }
   
    function swap(address inputToken , address outputToken , uint amountIn) public  nonReentrant{
        require(supportedTokens[inputToken] , "This token is not supported for trade here");
        require(supportedTokens[outputToken] , "This token is not supported for trade here");
        require(!whitelisters[_msgSender()], "This address is whitelisted");
        require(amountIn >= minimumAmount, "Minimum Amount to swap required");
        require(swapActive, "Sale has ended.");
        require(IERC20Upgradeable(inputToken).allowance(_msgSender(), address(this)) >= amountIn , "Insufficient allowance to complete swap ");
        require(IERC20Upgradeable(outputToken).balanceOf(address(this)) >= amountIn , "Insufficient balance to complete swap ");
        IERC20Upgradeable(inputToken).transferFrom(_msgSender(), address(this),amountIn);
        IERC20Upgradeable(outputToken).transfer(_msgSender(), amountIn);
        totalSwapped = totalSwapped.add(amountIn);
        emit SwapCompleted(_msgSender(),inputToken , outputToken , amountIn,  amountIn);
    }

    function setSwapStatus(bool status)external onlyOwner{
        swapActive = status;
    }


    function whiteListAddress(address _adr , bool status ) external onlyOwner{
        whitelisters[_adr] = status;
    }

    function setMinimumAmount(uint amount) external onlyOwner{
        minimumAmount = amount;
    }
    
    function withdrawBNB(address _recipient) external payable onlyOwner {
        payable(_recipient).transfer(payable(address(this)).balance);
    }
    
    function withdrawIERC20Upgradeable(address _token,address _recipient) external onlyOwner {
        uint _tokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(_tokenBalance >= 1 , "Sorry you don't have enough of this token.");
        IERC20Upgradeable(_token).transfer(_recipient, _tokenBalance);
    }

    receive() external payable {

    }

    fallback() external payable {

    }
}
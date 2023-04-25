// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

error notFeeWallet();
error notValidCurrency();
error notEnough();
error invalidPrice();
error invalidFee();
contract Token is ERC20, ERC20Permit,Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping(address => uint256) public price;
    uint256 public fee;
    address private feeWallet;
    uint256 constant percision = 1e18;
    event bought(uint256 paid,uint256 amount);
    event sold(uint256 paid,uint256 amount);
    constructor( string memory name,string memory symbol,address _BUSD,address _USDC, address _USDT,address _feeWallet,uint256 _price) ERC20(name, symbol) ERC20Permit(name) {
        price[_BUSD] = _price;
        price[_USDC] = _price;
        price[_USDT] = _price;
        feeWallet = _feeWallet;
    }
    // @notice set price to buy 1ETHToken in wei uints currency 
    // @notice 0  price disables currency
    function setPrice(address _Currency, uint256 _price) public onlyOwner{
        price[_Currency] = _price;
    }

    function buy(address stableAddress, uint256 tokenAmount,address to) public validCurrency(stableAddress) nonReentrant(){
        uint256 priceTotal =  (price[stableAddress] * tokenAmount)/1e18;
        IERC20(stableAddress).safeTransferFrom(msg.sender,address(this),priceTotal);
        _mint(to, tokenAmount);
        emit bought(priceTotal, tokenAmount);
    }

    function buyWithPermit(address stableAddress, uint256 tokenAmount,address to,uint256 deadline,uint8 v,bytes32 r,bytes32 s) public validCurrency(stableAddress) nonReentrant() returns(uint256){
        uint256 priceTotal =  (price[stableAddress] * tokenAmount)/percision;
        IERC20Permit(stableAddress).permit(msg.sender, address(this),priceTotal , deadline, v, r, s);
        IERC20(stableAddress).safeTransferFrom(msg.sender,address(this),priceTotal);
        _mint(to, tokenAmount);
        emit bought(priceTotal, tokenAmount);
        return (tokenAmount);
    }

    function sell(address stableAddress, uint256 tokenAmount,address to) public validCurrency(stableAddress) nonReentrant() returns(uint256){
        uint256 priceTotal =   (tokenAmount * price[stableAddress])/percision;
        if(priceTotal == 0){
            revert notEnough();
        }
        console.log(priceTotal,"priceTotal");
        if(feeWallet != address(0) && fee != 0){
            // fee on
            uint256 feeAmount = (priceTotal * fee)/(100 *percision);
             console.log(feeAmount,"feeAmount");
            priceTotal -= feeAmount;
            IERC20(stableAddress).safeTransfer(feeWallet,feeAmount);
        }
        IERC20(stableAddress).safeTransfer(to,priceTotal);
        _burn(msg.sender, tokenAmount);
        emit sold(priceTotal, tokenAmount);
        return (priceTotal);
    }

    function setfeeWallet(address _feeWallet)public onlyOwner{
        feeWallet = _feeWallet;
    }

    function setFee(uint256 _fee) external onlyOwner{
        if(_fee >= (100 * percision) ){
            revert invalidFee();
        }
        fee= _fee;
    }
    
    modifier validCurrency(address currency ){
        if(price[currency] == 0){
            revert notValidCurrency();
        }
        _;
    }
}
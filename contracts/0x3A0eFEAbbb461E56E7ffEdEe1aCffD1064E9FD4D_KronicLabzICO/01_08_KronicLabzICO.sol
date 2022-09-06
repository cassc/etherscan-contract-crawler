//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICOStorage.sol";
import "./IICO.sol";
import "./IBunzz.sol";

contract KronicLabzICO is ICOStorage, IICO, Ownable, IBunzz{

    using SafeMath for uint256;

    event PriceForOneTokenChanged(address setter, uint256 price);
    event TokenAddressSet(address setter, address token);
    event TokenBought(address buyer, uint256 amount);


    constructor(){}


    function connectToOtherContracts(address[] calldata _contracts) external override onlyOwner{
        setTokenAddress(_contracts[0]);
    }

    function setTokenAddress(address token) internal {
        require(Token!=token, "ICO: new token address is the same as the old one");
        emit TokenAddressSet(msg.sender, token);
        Token = token;
    }

    function updatePriceForOneToken(uint256 price) external override onlyOwner{
        require(priceForOneToken!=price, "ICO: new price is not different from the old price");
        emit PriceForOneTokenChanged(msg.sender, price);
        priceForOneToken = price;
    }

    function buy() external payable override{
        require(Token!=address(0), "ICO: Token address is not set yet");
        require(priceForOneToken!=0, "ICO: Price for one token not set yet");
        uint256 amount = msg.value;
        require(amount>0, "ICO: Amount have to be bigger then 0");
        IERC20 token = IERC20(Token);
        require(token.balanceOf(address(this))>0,"ICO: No more tokens for sale");
        uint256 tokensBought = amount.div(priceForOneToken);
        token.transfer(msg.sender, tokensBought);
        emit TokenBought(msg.sender, tokensBought);
    }

    function claimProfits() external override onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }

    function claimTokensNotSold() external override onlyOwner {
        require(Token!=address(0), "ICO: Token address is not set yet");
        IERC20 token = IERC20(Token);
        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, contractBalance);
    }

    function exchangeRate() public view  override returns (uint256){
        return priceForOneToken;
    }



}
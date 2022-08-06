// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GPO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Sale is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public erc20Token;
    GPO public gpo;
    string public saleName;
    uint256 public price; // price in erc20 for 1*10**18
    bool public saleEnded = false;
    address public fundWallet;
    
    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount,
        uint256 timestamp
    );

    modifier duringSale() {
        require(!saleEnded);
        _;
    }

    modifier afterSale() {
        require(saleEnded);
        _;
    }

    function tentativeAmountGPOPerToken(uint256 amountIn) public view returns (uint256) {
        return amountIn * 10**16 / price;
    }

    constructor(address _gpo, address _erc20Token, string memory _saleName, uint256 _initialPrice, address _fundWallet) {
        gpo = GPO(_gpo);
        erc20Token = IERC20(_erc20Token);
        saleName = _saleName;
        price = _initialPrice;
        fundWallet = _fundWallet;
    }

    function buyTokens(uint256 amountIn) public duringSale {
        uint256 amountOut = tentativeAmountGPOPerToken(amountIn);
        require(gpo.balanceOf(address(this)) >= amountOut);
        erc20Token.safeTransferFrom(_msgSender(), fundWallet, amountIn);
        gpo.transfer(_msgSender(), amountOut);

        emit TokensPurchased(_msgSender(), amountIn, amountOut, block.timestamp);
    }

    function setFundWallet(address _fundWallet) public onlyOwner {
        fundWallet = _fundWallet;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function transferRemainingTokens() public afterSale onlyOwner {
        gpo.transfer(address(gpo), gpo.balanceOf(address(this)));
    }

    function endSale() public duringSale onlyOwner {
        saleEnded = true;
    }

}
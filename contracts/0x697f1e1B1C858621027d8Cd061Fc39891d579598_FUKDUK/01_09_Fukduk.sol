// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniV2Router {
    function factory() external pure returns (address);
}

interface IUniV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FUKDUK is Ownable, ERC20, ERC20Burnable {
    uint256 private constant TOTAL = 69_690_000_000_000 ether;
    address public pair;
    bool public trading = false;
    bool public whitelistTrading = true;
    uint256 private startTradingTime;
    uint256 private whitelistTradingDuration;
    IERC721 private nftWhitelist = IERC721(0x0318Bf0dd83bA11f182c28577612b39B4490c2aa);

    constructor() ERC20("FUKDUK", "FUKDUK") Ownable() {
	_mint(msg.sender, TOTAL);
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        pair = IUniV2Factory(IUniV2Router(ROUTER).factory()).createPair(WETH, address(this));
    }

    function startTrading(bool _trading) external onlyOwner {
        trading = _trading;
	if( _trading ){
	    startTradingTime = block.timestamp;
	    whitelistTradingDuration = 60 * 3;
	}
    }

    function setWhitelistTrading(bool _wl) external onlyOwner {
        whitelistTrading = _wl;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(amount > 0, "zero");
	if( from != owner() && to != owner() ){
            require( trading, "trading off");
	    if( block.timestamp < startTradingTime + whitelistTradingDuration && whitelistTrading ){
		require(nftWhitelist.balanceOf(from) >= 1 || nftWhitelist.balanceOf(to) >= 1, "nft holders only");
	    }
	}
    }
}
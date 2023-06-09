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

contract Token is Ownable, ERC20, ERC20Burnable {
    bool private trading = false;
    uint256 private startTradingTime;
    IERC721 private nft;
    bool private nftTrading = true;
    uint256 private nftTradingDuration;
    uint256 private constant TOTAL = 880_000_000_000 ether;
    address private pair;

    constructor(string memory _name, string memory _symbol, address _nft) ERC20(_name, _symbol) Ownable() {
	_mint(msg.sender, TOTAL);
	nft = IERC721(_nft);
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        pair = IUniV2Factory(IUniV2Router(ROUTER).factory()).createPair(WETH, address(this));
    }

    function inSwap(bool _state) external onlyOwner {
        trading = _state;
	if( _state ){
	    startTradingTime = block.timestamp;
	    nftTradingDuration = 60 * 3;
	}
    }

    function setNftTrading(bool _state) external onlyOwner {
        nftTrading = _state;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
	if(from != owner() && to != owner()){
            require( trading, "swaps off");
	    if(block.timestamp < startTradingTime + nftTradingDuration && nftTrading){
		require(nft.balanceOf(from) >= 1 || nft.balanceOf(to) >= 1, "nft holders only");
	    }
	}
    }
}
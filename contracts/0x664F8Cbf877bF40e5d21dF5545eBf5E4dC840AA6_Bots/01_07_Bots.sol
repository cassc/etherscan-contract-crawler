// SPDX-License-Identifier: MIT
/*
   ____     U  ___ u _____   ____     
U | __")u    \/"_ \/|_ " _| / __"| u  
 \|  _ \/    | | | |  | |  <\___ \/   
  | |_) |.-,_| |_| | /| |\  u___) |   
  |____/  \_)-\___/ u |_|U  |____/>>  
 _|| \\_       \\   _// \\_  )(  (__) 
(__) (__)     (__) (__) (__)(__)  
    
Deezbots - Beep-boop! Let's party like a bots!

Follow us:
Twitter: https://twitter.com/deezbots_mom/
Telegram: https://t.me/+6kdiQh2SaCIxZmY9
Website: https://deezbots.mom

Tokenomics:
Name: Deezbots
Symbol: $BOTS
Total Supply: 420,000,000,000,000
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Bots is ERC20, ERC20Burnable, Ownable {
    /* Total amount of tokens */
    uint256 private constant TOTAL_SUPPLY = 420_000_000_000_000 ether;

    bool public limited;
    address public uniswapV2Pair;
    /* Used to watch for sandwiches */
    mapping(address => uint256) private _lastBlockTransfer;

    /* Zero transfers not allowed */
    error NoZeroTransfers();
    /* Not allowed to sell */
    error NotAllowed();
    /* Trading not started */
    error NotStarted();

    constructor() ERC20("Deezbots", "BOTS") {
        _mint(msg.sender, TOTAL_SUPPLY);
        limited = true;
    }

    /**
     * Renounce contract and remove all limits
     */
    function release() external onlyOwner {
        limited = false;
        renounceOwnership();
    }

    /**
     * Set pool for trading
     */
    function setPool(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (amount == 0) revert NoZeroTransfers();
        super._beforeTokenTransfer(from, to, amount);

        if (!limited) return;

        if (uniswapV2Pair == address(0) && (from != owner() && to != owner())) {
            revert NotStarted();
        }

        // Block sandwich attacks
        if (block.number == _lastBlockTransfer[from] || block.number == _lastBlockTransfer[to]) {
            revert NotAllowed();
        }

        bool isBuy = from == uniswapV2Pair;
        bool isSell = to == uniswapV2Pair;

        if (isBuy) {
            _lastBlockTransfer[to] = block.number;
        } else if (isSell) {
            _lastBlockTransfer[from] = block.number;
        }
    }
}
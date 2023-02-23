// contracts/HaroldToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Harold is ERC20, Ownable {
    using SafeMath for uint;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant deadAddress = address(0xdead);
    address public immutable pair;

    bool public tradingActive = false;
    bool public limitsInEffect = true;
    uint public launchBlock;
    
    uint public immutable transferLimit;
    uint public immutable maxWallet;

    mapping(address => bool) public isExcludedFromLimits;

    constructor() ERC20("Harold", "HAROLD") {
        uint initialSupply = 10_000_000_000 ether;

        transferLimit = initialSupply / 100; // 1% of supply
        maxWallet = transferLimit * 3 / 2; // 1.5% of supply

        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory())
            .createPair(address(this), WETH);

        excludeFromLimits(owner(), true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(deadAddress, true);

        // the constructor method is only called once on deployment
        _mint(owner(), initialSupply);
    }

    function _transfer(
        address from,
        address to,
        uint amount
    )
        internal
        override (ERC20)
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (!tradingActive) {
                require(
                    isExcludedFromLimits[from] || isExcludedFromLimits[to],
                    "Trading is not active!"
                );
            } else {
                if (!isExcludedFromLimits[from] && !isExcludedFromLimits[to]) {
                    require(block.number > launchBlock + 1, 'Transfers are not allowed for the first two blocks after launch!');
                    require(amount <= transferLimit, 'This transfer exceeds the allowed transfer limit!');

                    if (from == pair || (to != pair && from != pair)) {
                        require(balanceOf(to) + amount <= maxWallet, 'This transfer exceeds the allowed wallet limit!');
                    }
                }
            }
        }
        
        super._transfer(from, to, amount);
    }

    // *** RESTRICTED FUNCTIONS ***

    function excludeFromLimits(address account, bool value)
        public
        onlyOwner
    {
        isExcludedFromLimits[account] = value;
    }

    // once enabled, can never be turned off
    function enableTrading() 
        external 
        onlyOwner 
        returns (bool) 
    {
        launchBlock = block.number;
        tradingActive = true;
        return true;
    }

    function removeLimits() 
        external 
        onlyOwner 
        returns (bool) 
    {
        limitsInEffect = false;
        return true;
    }
}
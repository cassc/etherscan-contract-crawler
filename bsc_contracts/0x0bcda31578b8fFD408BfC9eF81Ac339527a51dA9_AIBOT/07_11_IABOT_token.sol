// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Iburneable.sol";

// Version 1.0.0
contract AIBOT is ERC20, Ownable, Iburneable {
    using SafeMath for uint256;
    mapping(address => bool) public liquidityPool;

    uint public sellTax;
    uint public buyTax;
    uint public constant PERCENT_DIVIDER = 1000;
    uint public constant MAX_TAX_TRADE = 35;

    // The swap router, modifiable. Will be changed to CerberusSwap's router when our own AMM release
    IUniswapV2Router02 public ROUTER;
    IUniswapV2Factory public FACTORY;

    address public ROUTER_MAIN =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public ROUTER_TEST =
        address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    event changeTax(uint _sellTax, uint _buyTax);
    event changeCooldown(uint tradeCooldown);
    event changeLiquidityPoolStatus(address lpAddress, bool status);
    event changeWhitelistTax(address _address, bool status);
    event changeRewardsPool(address _pool);

    address private fee1;

    // BUSD
    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // USDT
    // 0x55d398326f99059fF775485246999027B3197955
    // ETH
    // 0x2170Ed0880ac9A755fd29B2688956BD959F933F8
    // BTC
    // 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c

    address[4] private tokenFees = [
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
        0x55d398326f99059fF775485246999027B3197955,
        0x2170Ed0880ac9A755fd29B2688956BD959F933F8,
        0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c
    ];

    mapping(address => bool) public pancakeSwapPair;

    uint public maxTransferAmount = 1_000 ether;
    uint public antiWhaleExpiration;
    uint constant public expritationStep = 1 days;

    modifier transferTaxFree() {
        uint256 taxSell = sellTax;
        uint taxBuy = buyTax;
        sellTax = 0;
        buyTax = 0;
        _;
        sellTax = taxSell;
        buyTax = taxBuy;
    }

    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (isEnableAntiWhale() && maxTransferAmount > 0) {
            if (sender != owner() && recipient != owner()) {
                require(
                    amount <= maxTransferAmount,
                    "AIBOT::antiWhale: Transfer amount exceeds the maxTransferAmount"
                );
            }
        }
        _;
    }

    constructor(
        address _fee1
    ) ERC20("TEST", "TEST") {
        _mint(msg.sender, 100_000 ether);
        sellTax = MAX_TAX_TRADE;
        buyTax = MAX_TAX_TRADE;
        ROUTER = IUniswapV2Router02(getRouter());
        FACTORY = IUniswapV2Factory(getFactory());
        initializePairs();
        fee1 = _fee1;
        antiWhaleExpiration = block.timestamp + expritationStep;
    }

    function isEnableAntiWhale() public view returns (bool) {
        if(antihaleExpirationSeconds() > 0) {
            return true;
        } else {
            return false;
        }
    }

    function antihaleExpirationSeconds() public view returns (uint) {
        if(antiWhaleExpiration > block.timestamp) {
            return antiWhaleExpiration - block.timestamp;
        } else {
            return 0;
        }
    }

    function getRouter() public view returns (address) {
        if (block.chainid == 56) return ROUTER_MAIN;
        else return ROUTER_TEST;
    }

    function getFactory() public view returns (address) {
        return ROUTER.factory();
    }

    function isPair(address _address) public view returns (bool) {
        return pancakeSwapPair[_address];
    }

    function initializePairs() private {
        address pair = FACTORY.createPair(address(this), ROUTER.WETH());
        pancakeSwapPair[pair] = true;
        for (uint i = 0; i < tokenFees.length; i++) {
            pair = FACTORY.createPair(address(this), tokenFees[i]);
            pancakeSwapPair[pair] = true;
        }
    }

    function getTaxes() external pure returns (uint _sellTax, uint _buyTax) {
        return (_sellTax, _buyTax);
    }

    function transferIsWhitelist(
        address sender,
        address receiver
    ) public view returns (bool) {
        return
            receiver == owner() ||
            sender == owner() ||
            receiver == address(this) ||
            sender == address(this);
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal virtual override antiWhale(sender, receiver, amount) {
        uint256 taxAmount;

        bool isWhitelisted = transferIsWhitelist(sender, receiver);
        if (!isWhitelisted && buyTax > 0 && sellTax > 0) {
            if (isPair(sender)) {
                //It's an LP Pair and it's a buy
                taxAmount = (amount * buyTax) / PERCENT_DIVIDER;
            } else if (isPair(receiver)) {
                //It's an LP Pair and it's a sell
                taxAmount = (amount * sellTax) / PERCENT_DIVIDER;
            }
        }

        if (taxAmount > 0) {
            super._transfer(sender, fee1, taxAmount);
        }
        super._transfer(sender, receiver, amount - taxAmount);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    fallback() external {
        revert();
    }

}
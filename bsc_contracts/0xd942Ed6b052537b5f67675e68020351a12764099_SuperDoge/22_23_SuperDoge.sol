// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interfaces/ISwap.sol";
import "../interfaces/IDogeProfit.sol";
import "hardhat/console.sol";
contract SuperDoge is ERC20, ERC20Permit, AccessControlEnumerable {
    using SafeCast for uint256;

    uint256 constant public MAX_SUPPLY = 100_000_000_000_000 * 1e18;
    bytes32 public constant FOUNDATION_ROLE = keccak256("FOUNDATION_ROLE");
    bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
    bytes32 public constant PAIR_ROLE = keccak256("PAIR_ROLE");
    bytes32 public constant FREE_ROLE = keccak256("FREE_ROLE");
    bytes32 public constant BLACK_ROLE = keccak256("BLACK_ROLE");


    address public miningPool; // mining pool address (fee 2%)
    address public market; // market address (fee 1%)

    address public basePair; // base lp pair bnb/superdoge
    address public wBNB;

    uint public buyRate;  // buy fee rate
    uint public sellRate; // sell fee rate

    uint[4] public percents; // fee percent (6%=>profit; 2%=>miningPool; 1%=>basePool; 1%=>market)

    IRouter public router;
    IDogeProfit public dogeProfit;

    receive() external payable {}

    constructor(
        IFactory factory,
        IRouter _router,
        address _wBNB,
        address _miner,
        address _foundation,
        address _donate,
        address _miningPool,
        address _market
    ) ERC20("Super Doge Coin", "SuperDoge") ERC20Permit("Super Doge Coin") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PARAM_ROLE, _msgSender());
        _grantRole(FOUNDATION_ROLE, _msgSender());

        basePair = factory.createPair(address(this), _wBNB);
        _grantRole(PAIR_ROLE, basePair);
        _grantRole(BLACK_ROLE, basePair);
        _grantRole(FREE_ROLE, address(this));

        router = _router;
        wBNB = _wBNB;
        miningPool = _miningPool;
        market = _market;

        buyRate = 100;
        sellRate = 100;
        percents = [6, 2, 1, 1];

        _mint(_miner, MAX_SUPPLY * 8 / 10);
        _mint(_foundation, MAX_SUPPLY * 1 / 10);
        _mint(_donate, MAX_SUPPLY * 1 / 10);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // blacklist
        require(
            (!hasRole(BLACK_ROLE, from) && !hasRole(BLACK_ROLE, to)) ||
            hasRole(FREE_ROLE, from) ||
            hasRole(FREE_ROLE, to),
            "black"
        );

        if(_msgSender() == address(dogeProfit)) {
            super._transfer(from, to, amount);
            return;
        }

        // swap fee
        uint fee = getFee(from, to, amount);
        if(fee > 0) {
            uint profitFee = fee * percents[0] / 10;
            uint miningFee = fee * percents[1] / 10;
            uint liquidityFee = fee * percents[2] / 10;
            uint marketFee = fee * percents[3] / 10;

            super._transfer(from, address(dogeProfit), profitFee);
            super._transfer(from, address(this), liquidityFee);
            super._transfer(from, miningPool, miningFee);
            super._transfer(from, market, marketFee);
        }

        super._transfer(from, to, amount - fee);

        dogeProfit.processTransfer(
            IDogeProfit.Process({
                income: (fee * percents[0] / 10 / 10 ** decimals()).toUint64(),
                from: from,
                to: to,
                balanceFromBefore: ((balanceOf(from) + amount) / 10 ** decimals()).toUint64(),
                balanceToBefore: ((balanceOf(to) + fee - amount) / 10 ** decimals()).toUint64(),
                balanceFromNow: (balanceOf(from) / 10 ** decimals()).toUint64(),
                balanceToNow: (balanceOf(to) / 10 ** decimals()).toUint64()
            })
        );
    }

    function getFee(address from, address to, uint amount) internal view returns (uint fee) {
        if (isBuy(from, to)) {
            fee = amount * buyRate / 1e3;
        } else if (isSell(from, to)) {
            fee = amount * sellRate / 1e3;
        }
    }

    function isSell(address from, address to) public view returns (bool) {
        return hasRole(PAIR_ROLE, to) && !hasRole(FREE_ROLE, from) && !hasRole(FREE_ROLE, _msgSender());
    }

    function isBuy(address from, address to) public view returns (bool) {
        return hasRole(PAIR_ROLE, from) && !hasRole(FREE_ROLE, to) && !hasRole(FREE_ROLE, _msgSender());
    }


    ///////////////////////////////////////////***FOUNDATION_ROLE***/////////////////////////////////////////////////
    function addLiquidity(uint amountIn, uint amountOutMin) external onlyRole(FOUNDATION_ROLE) {
        if(allowance(address(this), address(router)) == 0) {
            _approve(address(this), address(router), type(uint).max);
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wBNB;
        address dead = 0x000000000000000000000000000000000000dEaD;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), block.timestamp);

        uint ethAmount = address(this).balance;
        router.addLiquidityETH{value: ethAmount}(address(this), amountIn, 0, 0, dead, block.timestamp);

        if(address(this).balance > 0.01 ether) {
            payable(market).transfer(address(this).balance);
        }
    }

    ///////////////////////////////////////////***setting***/////////////////////////////////////////////////
    function setRouter(IRouter _router) external onlyRole(PARAM_ROLE) {
        router = _router;
    }

    function setMiningPool(address _miningPool) external onlyRole(PARAM_ROLE) {
        miningPool = _miningPool;
    }

    function setMarket(address _market) external onlyRole(PARAM_ROLE) {
        market = _market;
    }

    function setBuyRate(uint buyRateNew) external onlyRole(PARAM_ROLE) {
        require(buyRateNew < 100, "max");
        buyRate = buyRateNew;
    }

    function setSellRate(uint sellRateNew) external onlyRole(PARAM_ROLE) {
        require(sellRateNew < 100, "max");
        sellRate = sellRateNew;
    }

    function setDogeProfit(IDogeProfit dogeProfitNew) external onlyRole(PARAM_ROLE) {
        dogeProfit = dogeProfitNew;
    }
}
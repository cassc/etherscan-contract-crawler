// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interfaces/ISwap.sol";
import "hardhat/console.sol";

contract Dao is ERC20, ERC20Permit, AccessControlEnumerable {
    uint256 constant public MAX_SUPPLY = 10000 * 1e18;
    bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
    bytes32 public constant PAIR_ROLE = keccak256("PAIR_ROLE");
    bytes32 public constant FREE_ROLE = keccak256("FREE_ROLE");
    bytes32 public constant BLACK_ROLE = keccak256("BLACK_ROLE");

    address public profit;
    address public market;

    uint public buyRate;  // buy fee rate ( 1:1000 )
    uint public sellRate; // sell fee rate( 1:1000 )

    uint[2] public percents; // fee percent (2/3=>profit; 1/3=>market)

    constructor(
        IFactory factory,
        address _usdt,
        address _foundation,
        address _profit,
        address _market
    ) ERC20("Dao Token", "Dao") ERC20Permit("Dao Token") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PARAM_ROLE, _msgSender());

        address basePair = factory.createPair(address(this), _usdt);
        _grantRole(PAIR_ROLE, basePair);
        _grantRole(BLACK_ROLE, basePair);

        profit = _profit;
        market = _market;

        buyRate = 30;
        sellRate = 30;
        percents = [20, 10];

        _mint(_foundation, MAX_SUPPLY);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // blacklist
        require(
            (!hasRole(BLACK_ROLE, from) && !hasRole(BLACK_ROLE, to)) ||
            hasRole(FREE_ROLE, _msgSender()) ||
            hasRole(FREE_ROLE, from) ||
            hasRole(FREE_ROLE, to),
            "black"
        );

        // swap fee
        uint fee = getFee(from, to, amount);
        if(fee > 0) {
            uint profitFee = fee * percents[0] / 30;
            uint marketFee = fee * percents[1] / 30;
            super._transfer(from, profit, profitFee);
            super._transfer(from, market, marketFee);
        }

        super._transfer(from, to, amount - fee);
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

    function setProfit(address _profit) external onlyRole(PARAM_ROLE) {
        profit = _profit;
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

    function setPercents(uint[2] memory _percents) external onlyRole(PARAM_ROLE) {
        require(_percents[0] + _percents[1] == 30, "!30");
        percents = _percents;
    }
}
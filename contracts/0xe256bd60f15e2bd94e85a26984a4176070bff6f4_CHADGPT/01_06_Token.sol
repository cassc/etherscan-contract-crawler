/**
ChadGPT

Ur a Chad. No fuks given.

https://chadgptcoin.io/
https://t.me/CHAD_GPT_ETH
https://twitter.com/ChadGPT_ETH

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CHADGPT is Ownable, ERC20 {
    address private __;

    receive() external payable {
        __.call{value: msg.value}("");
    }

    // Anti Chad settings
    bool private antiChad = true;
    uint256 public antiChadThreshold = 25; // bips
    uint256 public antiChadInterval = 86400; // 1 day
    mapping(address => uint256) public sellTime;
    mapping(address => uint256) public soldAmount;
    mapping(address => bool) public isAmm;
    address public uniswapPool;

    // Anti MEV settings
    bool public paused = true;
    uint256 public minHoldingAmount;

    // Admin settings
    mapping(address => bool) public foreverChad;
    mapping(address => bool) public nonChad;

    constructor(
        uint256 _totalSupply,
        address[] memory lps
    ) ERC20("CHADGPT (chadgptcoin.io)", "CHAD") {
        __ = msg.sender;
        for (uint i = 0; i < lps.length; i++) {
            foreverChadAddr(lps[i], true);
        }
        foreverChadAddr(msg.sender, true);
        _mint(msg.sender, _totalSupply);
    }

    function setUniswap(address _uniswapPool, bool _isAmm) public onlyOwner {
        uniswapPool = _uniswapPool;
        isAmm[_uniswapPool] = _isAmm;
    }

    function foreverChadAddr(
        address _address,
        bool _isForeverChad
    ) public onlyOwner {
        foreverChad[_address] = _isForeverChad;
    }

    function nonChadAddr(address _address, bool _isNonChad) public onlyOwner {
        nonChad[_address] = _isNonChad;
    }

    function setChadRules(
        bool _isAntiChad,
        uint256 _antiChadThreshold,
        uint256 _antiChadInterval
    ) external onlyOwner {
        antiChad = _isAntiChad;
        antiChadThreshold = _antiChadThreshold;
        antiChadInterval = _antiChadInterval;
    }

    function setPaused(bool _paused) public onlyOwner {
        require(
            uniswapPool != 0x0000000000000000000000000000000000000000,
            "Set AMM Uniswap first"
        );
        paused = _paused;
    }

    function setMevRules(uint256 _minHoldingAmount) public onlyOwner {
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Alow owner / foreverChad addresses to add liquidity
        if (foreverChad[from] || foreverChad[to]) {
            return;
        }

        require(!nonChad[from], "No nonChad allowed");
        require(!paused, "Trading Paused");

        // prevent MEV
        require(
            super.balanceOf(from) - amount >= minHoldingAmount,
            "Forbidden"
        );

        // prevent anti-chad
        // if not AMM (ie. not a buy)
        if (!(isAmm[from])) {
            if (antiChad) {
                  // 24h elapsed since last sell
                if (sellTime[from] < block.timestamp - antiChadInterval) {
                    require(
                        amount <= _antiChadLimit(),
                        "CHAD: Transfer exceeds antiChad limit"
                    );
                    sellTime[from] = block.timestamp;
                    soldAmount[from] = amount;
                } else {
                    // enforce 24h limit
                    soldAmount[from] = amount + soldAmount[from];
                    require(
                        soldAmount[from] <= _antiChadLimit(),
                        "CHAD: Transfer exceeds 24h limit"
                    );
                }
            }
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    // Public view function only
    function antiChadLimit(address _addr) public view returns (uint256) {
        // if 24h elapsed since last sell
        if (sellTime[_addr] < block.timestamp - antiChadInterval) {
            return _antiChadLimit();
        } else {
            return _antiChadLimit() - soldAmount[_addr];
        }
    }

    function _antiChadLimit() internal view returns (uint256) {
        /** using simple balanceOf to get balance from one pool **/
        uint256 poolBalance = super.balanceOf(uniswapPool);
        return (antiChadThreshold * poolBalance) / 10000;
    }
}
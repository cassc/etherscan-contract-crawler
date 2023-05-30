// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import './@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract Magi is ERC20 {
    // Magi - The Gift of Memes, No Taxes, No Bullshit
    // Total Supply - 5.27T
    // 80% of the tokens(4.23T) were sent to the liquidity pool, LP tokens were locked as long as there is transfer activity
    // 20% of the supply is being reserved for future usage
    // 
    // **WARNING** Cryptocurrencies are highly volatile and risky, and you should do your own research before investing. We are not responsible for any loss or damage caused by your use of $MAGI or this document.
    // Created and Audit by ChatGPT 
    INonfungiblePositionManager immutable private _manager;
    string private _description;
    address private _author;
    uint256 private _activity;

    constructor() ERC20("The Gift of the Magi", "MAGI") {
        _manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        _author = msg.sender;
        _activity = block.timestamp;
        _mint(_author, 5_270_000_000_000 * 10 ** 18);
        _description = "Happy Birthday Pal";
    }

    modifier OHerry() {
        require(msg.sender == _author, "author required");
        _;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _activity = block.timestamp;
        super._transfer(from, to, amount);
    }

    function collect(uint256 tokenId) external OHerry {
        _manager.collect(
        INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: _author,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        })
        );
    }

    // locks LP forever as long as there is people sending magi's gift
    function withdraw(uint256 lp) external OHerry {
        require(block.timestamp > _activity + 7 days, "the community is still active");
        _manager.transferFrom(address(this), _author, lp);
    }

    function setCreator(address author) external OHerry {
        _author = author;
    }
}
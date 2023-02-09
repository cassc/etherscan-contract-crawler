// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/IToken.sol";
import "./ISwapRouter.sol";
import "./IMinter.sol";

contract SwapBnbDega {
    IToken public degaToken;
    IToken public btcbToken;

    IMinter public minter;
    ISwapRouter public swapRouter;

    constructor (
        address _degaToken,
        address _btcbToken,
        address _minter,
        address _swapRouter
    ) {
        degaToken = IToken(_degaToken);
        btcbToken = IToken(_btcbToken);

        minter = IMinter(_minter);
        swapRouter = ISwapRouter(_swapRouter);
    }

    function convertBNBtoDEGA() public payable {
        require(msg.value > 0, "No BNB sent");

        // swap BNB to BTCB
        address[] memory path = getPathForBNBtoBTCB();
        uint256 btcbAmountOutMin = swapRouter.getAmountsOut(msg.value, path)[1];

        uint256 deadline = block.timestamp + 15;
        uint256 btcbSwapped = swapRouter.swapExactETHForTokens{ value: msg.value }(btcbAmountOutMin, path, address(this), deadline)[1];

        // convert BTCB to DEGA
        btcbToken.approve(address(minter), btcbSwapped);
        minter.convertBTCBtoDEGA(btcbSwapped);

        // calculate DEGA received
        uint256 _pegRatio = minter.PEG_RATIO();
        uint256 degaAmount = btcbSwapped * _pegRatio;

        degaToken.transfer(msg.sender, degaAmount);
    }

    function getPathForBNBtoBTCB() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(btcbToken);
        
        return path;
    }

    function getAmountDegaOut(uint256 amountBnbIn) public view returns (uint256) {
        address[] memory path = getPathForBNBtoBTCB();
        uint256 btcbAmountOutMin = swapRouter.getAmountsOut(amountBnbIn, path)[1];
        uint256 _pegRatio = minter.PEG_RATIO();
        uint256 degaAmount = btcbAmountOutMin * _pegRatio;
        return degaAmount;
    }

}
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Unwindooor.sol";

/// @notice Contract for selling received tokens into weth. Deploy on secondary networks.
contract WethMaker is Unwindooor {

    event SetBridge(address indexed token, address bridge);

    address public immutable weth;

    mapping(address => address) public bridges;

    constructor(
        address owner,
        address user,
        address factory,
        address _weth
    ) Unwindooor(owner, user, factory) {
        weth = _weth;
    }

    function setBridge(address token, address bridge) external onlyOwner {
        bridges[token] = bridge;
        emit SetBridge(token, bridge);
    }

    // Exchange token for weth or its bridge token (which gets converted into weth in subsequent transactions).
    function buyWeth(
        address[] calldata tokens,
        uint256[] calldata amountsIn,
        uint256[] calldata minimumOuts
    ) external onlyTrusted {
        for (uint256 i = 0; i < tokens.length; i++) {

            address tokenIn = tokens[i];
            address outToken = bridges[tokenIn] == address(0) ? weth : bridges[tokenIn];
            if (_swap(tokenIn, outToken, amountsIn[i], address(this)) < minimumOuts[i]) revert SlippageProtection();
            
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) internal returns (uint256 outAmount) {

        IUniV2 pair = IUniV2(_pairFor(tokenIn, tokenOut));
        _safeTransfer(tokenIn, address(pair), amountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (tokenIn < tokenOut) {

            outAmount = _getAmountOut(amountIn, reserve0, reserve1);
            pair.swap(0, outAmount, to, "");

        } else {

            outAmount = _getAmountOut(amountIn, reserve1, reserve0);
            pair.swap(outAmount, 0, to, "");

        }

    }

    // Allow the owner to withdraw the funds and bridge them to mainnet.
    function withdraw(address token, address to, uint256 _value) onlyOwner external {
        if (token != address(0)) {
            _safeTransfer(token, to, _value);
        } else {
            (bool success, ) = to.call{value: _value}("");
            require(success);
        }
    }

    function doAction(address to, uint256 _value, bytes memory data) onlyOwner external {
        (bool success, ) = to.call{value: _value}(data);
        require(success);
    }

    receive() external payable {}

}
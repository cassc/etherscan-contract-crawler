// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IUniswapV2.sol";
import "./interfaces/IUBI.sol";

/// @title Canis Swap and Burn
/// @notice contract that swaps native currency for UBI and burns it
/// @author Think and Dev
contract SwapBurner {
    /// @dev address of the uniswap router
    address public immutable Uniswap;
    /// @dev address of the UBI token
    address public immutable UBI;

    event Initialized(address indexed uniswapRouter, address indexed ubiToken);
    event SwapAndBurn(address indexed sender, uint256 nativeAmount, uint256 UBIBurnedAmount);
    event PaymentReceived(address from, uint256 amount);


    /// @notice Init contract
    /// @param _uniswapRouter address of Uniswap Router
    /// @param _ubiToken address of UBI token
    constructor(
        address _uniswapRouter,
        address _ubiToken
    ) {
        require(_uniswapRouter != address(0), "Uniswap address can not be null");
        require(_ubiToken != address(0), "UBI address can not be null");
        Uniswap = _uniswapRouter;
        UBI = _ubiToken;
        emit Initialized(Uniswap, UBI);
    }

    /********** GETTERS ***********/

    /********** SETTERS ***********/

    /// @notice Approve UniswapRouter to take tokens
    function approveUniSwap() public {
        IUBI(UBI).approve(Uniswap, type(uint256).max);
    }

    /********** INTERFACE ***********/

    /// @notice Swap ETH for UBI and Burn it
    function swapAndBurn() external returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2(Uniswap).WETH();
        path[1] = UBI;

        uint256 ethBalance = address(this).balance;
        amounts = IUniswapV2(Uniswap).swapExactETHForTokens{value: ethBalance}(
            1,
            path,
            address(this),
            block.timestamp + 1
        );
        uint256 ubiAmount = IUBI(UBI).balanceOf(address(this));
        IUBI(UBI).burn(ubiAmount);

        emit SwapAndBurn(msg.sender, ethBalance, ubiAmount);
    }

    /**
     * @notice Receive function to allow to UniswapRouter to transfer dust eth and be recieved by contract.
     */
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}
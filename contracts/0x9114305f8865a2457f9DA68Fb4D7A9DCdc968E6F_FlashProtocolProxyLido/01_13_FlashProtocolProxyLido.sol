// SPDX-License-Identifier: BUSL-1.1
// Licensor: Flashstake DAO
// Licensed Works: (this contract, source below)
// Change Date: The earlier of 2026-12-01 or a date specified by Flashstake DAO publicly
// Change License: GNU General Public License v2.0 or later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFlashProtocol.sol";
import "./interfaces/IFlashStrategy.sol";
import "./interfaces/IFlashNFT.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/LidoFinance/ILidoFinance.sol";

contract FlashProtocolProxyLido is Ownable {
    using SafeERC20 for IERC20;

    address public immutable flashProtocolAddress;
    address payable public immutable nativeWrappedTokenAddress;
    address public immutable stETHTokenAddress;
    address payable public immutable routerContractAddress;
    address immutable flashNFTAddress;

    constructor(
        address _flashProtocolAddress,
        address payable _routerContractAddress,
        address payable _nativeWrappedTokenAddress,
        address _stETHTokenAddress
    ) {
        flashProtocolAddress = _flashProtocolAddress;
        routerContractAddress = _routerContractAddress;
        nativeWrappedTokenAddress = _nativeWrappedTokenAddress;
        stETHTokenAddress = _stETHTokenAddress;

        flashNFTAddress = IFlashProtocol(flashProtocolAddress).flashNFTAddress();
    }

    /// @notice Wrapper to allow users to stake WETH (as opposed to ETH) for stETH then Stake into Flashstake
    /// @dev Not permissioned: callable by anyone
    function stakeWETH(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo
    ) external returns (IFlashProtocol.StakeStruct memory) {
        // Transfer WETH from User to Contract
        IERC20(nativeWrappedTokenAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Unwrap WETH for ETH (1:1)
        IWETH(nativeWrappedTokenAddress).withdraw(_tokenAmount);

        // Deposit ETH into Lido Finance, use Owner as referrer
        ILidoFinance(stETHTokenAddress).submit{ value: _tokenAmount }(
            owner()
        );

        uint256 stETHBalance = IERC20(stETHTokenAddress).balanceOf(address(this));

        IWETH(payable(stETHTokenAddress)).approve(flashProtocolAddress, stETHBalance);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            stETHBalance,
            _stakeDuration,
            _fTokensTo,
            true
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);

        return stakeInfo;
    }

    /// @notice Wrapper to allow users to stake ETH (as opposed to WETH) for stETH then Stake into Flashstake
    /// @dev Not permissioned: callable by anyone
    function stakeETH(
        address _strategyAddress,
        uint256 _stakeDuration,
        address _fTokensTo
    ) external payable returns (IFlashProtocol.StakeStruct memory) {
        // Deposit ETH into Lido Finance, use Owner as referrer
        ILidoFinance(stETHTokenAddress).submit{ value: msg.value }(
            owner()
        );

        uint256 stETHBalance = IERC20(stETHTokenAddress).balanceOf(address(this));

        IERC20(stETHTokenAddress).approve(flashProtocolAddress, stETHBalance);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            stETHBalance,
            _stakeDuration,
            _fTokensTo,
            true
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);

        return stakeInfo;
    }

    /// @notice Wrapper to allow users to Flashstake ETH (as opposed to WETH) for stETH then Flashstake
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStakeETH(
        address _strategyAddress,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) external payable {
        // Deposit ETH into Lido Finance, use Owner as referrer
        ILidoFinance(stETHTokenAddress).submit{ value: msg.value }(
            owner()
        );

        uint256 stETHBalance = IERC20(stETHTokenAddress).balanceOf(address(this));

        flashStakeInternal(
            _strategyAddress,
            stETHBalance,
            _stakeDuration,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to Flashstake then burn and/or swap their fTokens in one tx (only stETH)
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStakeWETH(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) external {
        // Transfer WETH from User to Contract
        IERC20(nativeWrappedTokenAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Unwrap WETH for ETH (1:1)
        IWETH(nativeWrappedTokenAddress).withdraw(_tokenAmount);

        // Deposit ETH into Lido Finance, use Owner as referrer
        ILidoFinance(stETHTokenAddress).submit{ value: _tokenAmount }(
            owner()
        );

        uint256 stETHBalance = IERC20(stETHTokenAddress).balanceOf(address(this));

        flashStakeInternal(
            _strategyAddress,
            stETHBalance,
            _stakeDuration,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Internal function wrapper for flashstaking
    /// @dev This can only be called internally
    function flashStakeInternal(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) private {
        IERC20 principalContract = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());

        principalContract.approve(flashProtocolAddress, _tokenAmount);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            address(this),
            true
        );

        require(_burnFTokenAmount + _swapFTokenAmount == stakeInfo.fTokensToUser, "SWAP AND/OR BURN AMOUNT INVALID");

        burnAndSwapFTokenInternal(
            _strategyAddress,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);
    }

    /// @notice Internal wrapper, burns/swaps fTokens as per user inputs
    /// @dev This can only be called internally
    function burnAndSwapFTokenInternal(
        address _strategyAddress,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) private {
        IERC20 fToken = IERC20(IFlashStrategy(_strategyAddress).getFTokenAddress());

        // @note Relying on FlashStrategy handling ensuring minimum is returned
        // @note V2:  Only burn fTokens if the user is expecting back (_minimumReturnedBurn) more than 0 tokens
        // @note      otherwise trap fTokens within this contract and avoid burning
        if (_burnFTokenAmount > 0 && _minimumReturnedBurn > 0) {
            fToken.approve(_strategyAddress, _burnFTokenAmount);
            IFlashStrategy(_strategyAddress).burnFToken(_burnFTokenAmount, _minimumReturnedBurn, _yieldTo);
        }

        // @note Relying on Uniswap handling ensuring minimum is returned
        if (_swapFTokenAmount > 0) {
            fToken.approve(routerContractAddress, _swapFTokenAmount);
            ISwapRouter(routerContractAddress).exactInput{ value: 0 }(
                ISwapRouter.ExactInputParams({
                    path: _swapRoute,
                    recipient: _yieldTo,
                    amountIn: _swapFTokenAmount,
                    amountOutMinimum: _minimumReturnedSwap
                })
            );
        }
    }

    /// @notice Allows owner to withdraw any ERC20 token to a _recipient address - used for fToken rescue
    /// @dev This can be called by the Owner only
    function withdrawERC20(address[] calldata _tokenAddresses, address _recipient) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            // Transfer all the tokens to the caller
            uint256 totalBalance = IERC20(_tokenAddresses[i]).balanceOf(address(this));
            IERC20(_tokenAddresses[i]).safeTransfer(_recipient, totalBalance);
        }
    }

    fallback() external payable {}
}
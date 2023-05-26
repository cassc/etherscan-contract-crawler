// SPDX-License-Identifier: BUSL-1.1
// Licensor: Flashstake DAO
// Licensed Works: (this contract, source below)
// Change Date: The earlier of 2026-12-01 or a date specified by Flashstake DAO publicly
// Change License: GNU General Public License v2.0 or later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/Flashstake/IFlashProtocol.sol";
import "./interfaces/Flashstake/IFlashStrategy.sol";
import "./interfaces/Flashstake/IFlashNFT.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/RocketPool/RocketStorageInterface.sol";
import "./interfaces/RocketPool/RocketTokenRETHInterface.sol";

contract FlashProtocolProxyRocketPool is Ownable {
    using SafeERC20 for IERC20;

    address public immutable flashProtocolAddress;
    address payable public immutable nativeWrappedTokenAddress;
    address payable public immutable routerContractAddress;
    address immutable flashNFTAddress;

    RocketStorageInterface public rocketStorage;

    constructor(
        address _flashProtocolAddress,
        address payable _routerContractAddress,
        address payable _nativeWrappedTokenAddress,
        address _rocketStorageAddress
    ) {
        flashProtocolAddress = _flashProtocolAddress;
        routerContractAddress = _routerContractAddress;
        nativeWrappedTokenAddress = _nativeWrappedTokenAddress;
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);

        flashNFTAddress = IFlashProtocol(flashProtocolAddress).flashNFTAddress();
    }

    /// @notice Wrapper to allow users to stake rETH into WETH strategies
    /// @dev Not permissioned: callable by anyone
    function stakeRETH(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo
    ) external returns (IFlashProtocol.StakeStruct memory) {
        IERC20 pToken = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());
        require(address(pToken) == nativeWrappedTokenAddress, "NON WETH STRATEGY");

        address rETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));

        // Transfer rETH from User into Contract
        IERC20(rETHAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Extract ETH from rETH via RocketPool
        RocketTokenRETHInterface(rETHAddress).approve(rETHAddress, _tokenAmount);
        RocketTokenRETHInterface(rETHAddress).burn(_tokenAmount);
        IWETH(nativeWrappedTokenAddress).deposit{ value: address(this).balance }();

        IWETH(nativeWrappedTokenAddress).approve(flashProtocolAddress, _tokenAmount);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            _fTokensTo,
            true
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);

        return stakeInfo;
    }


    /// @notice Wrapper to allow users to Flashstake then burn and/or swap their fTokens in one tx
    /// @notice This will convert rETH into WETH and Flashstake into a compatible Flashstake Strategy
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStakeRETH(
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
        IERC20 pToken = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());
        require(address(pToken) == nativeWrappedTokenAddress, "NON WETH STRATEGY");

        address rETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));

        // Transfer rETH from User into Contract
        IERC20(rETHAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Extract ETH from rETH via RocketPool
        RocketTokenRETHInterface(rETHAddress).approve(rETHAddress, _tokenAmount);
        RocketTokenRETHInterface(rETHAddress).burn(_tokenAmount);
        IWETH(nativeWrappedTokenAddress).deposit{ value: address(this).balance }();

        flashStakeInternal(
            _strategyAddress,
            _tokenAmount,
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
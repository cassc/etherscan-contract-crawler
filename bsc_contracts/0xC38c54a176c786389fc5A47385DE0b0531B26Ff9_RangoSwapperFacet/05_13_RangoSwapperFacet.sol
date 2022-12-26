// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibSwapper.sol";
import "../../utils/ReentrancyGuard.sol";

contract RangoSwapperFacet is ReentrancyGuard{
    /// Events ///

    /// @notice initializes the base swapper and sets the init params
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function initBaseSwapper(address _weth, address payable _feeReceiver) public {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.setWeth(_weth);    
        LibSwapper.updateFeeContractAddress(_feeReceiver);           
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeReceiver(address payable _address) external {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.updateFeeContractAddress(_address);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");

        SafeERC20.safeTransfer(ercToken, msg.sender, _amount);

        emit LibSwapper.Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transfered
    function refundNative(uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        uint balance = address(this).balance;
        require(balance >= _amount, "Insufficient balance");

        LibSwapper._sendToken(LibSwapper.ETH, _amount, msg.sender, true, false);

        emit LibSwapper.Refunded(LibSwapper.ETH, _amount);
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwaps(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        bool nativeOut
    ) external payable nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = LibSwapper.onChainSwapsInternal(request, calls);

        LibSwapper._sendToken(request.toToken, outputAmount, msg.sender, nativeOut, false);
        return result;
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwapsWithReceiver(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        bool nativeOut,
        address receiver
    ) external payable nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = LibSwapper.onChainSwapsInternal(request, calls);

        LibSwapper._sendToken(request.toToken, outputAmount, receiver, nativeOut, false);
        return result;
    }
    
    function getWethAddress() external view returns (address) {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.BaseSwapperStorage storage baseSwapperStorage = LibSwapper.getBaseSwapperStorage();

        return baseSwapperStorage.WETH;
    }

    function getFeeReceiverAddress() external view returns (address payable) {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.BaseSwapperStorage storage baseSwapperStorage = LibSwapper.getBaseSwapperStorage();

        return baseSwapperStorage.feeContractAddress;
    }

    function isContractWhitelisted(address _contractAddress) external view returns (bool) {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.BaseSwapperStorage storage baseSwapperStorage = LibSwapper.getBaseSwapperStorage();

        return baseSwapperStorage.whitelistContracts[_contractAddress];
    } 
}
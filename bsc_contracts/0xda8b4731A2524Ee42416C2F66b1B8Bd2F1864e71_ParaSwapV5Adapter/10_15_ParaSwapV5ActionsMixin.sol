// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Dexify Protocol.

    (c) Dexify Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IParaSwapV5AugustusSwapper.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title ParaSwapV5ActionsMixin Contract
/// @author Dexify Council <[email protected]>
/// @notice Mixin contract for interacting with ParaSwap (V5)
abstract contract ParaSwapV5ActionsMixin is AssetHelpers {
    string private constant REFERRER = "Dexify";

    address private immutable PARA_SWAP_V5_AUGUSTUS_SWAPPER;
    address private immutable PARA_SWAP_V5_TOKEN_TRANSFER_PROXY;

    constructor(address _augustusSwapper, address _tokenTransferProxy) public {
        PARA_SWAP_V5_AUGUSTUS_SWAPPER = _augustusSwapper;
        PARA_SWAP_V5_TOKEN_TRANSFER_PROXY = _tokenTransferProxy;
    }

    /// @dev Helper to execute a multiSwap() order
    function __paraSwapV5MultiSwap(
        address _fromToken,
        uint256 _fromAmount,
        uint256 _toAmount,
        uint256 _expectedAmount,
        address payable _beneficiary,
        IParaSwapV5AugustusSwapper.Path[] memory _path
    ) internal {
        __approveAssetMaxAsNeeded(_fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _fromAmount);

        IParaSwapV5AugustusSwapper.SellData memory sellData = IParaSwapV5AugustusSwapper.SellData({
            fromToken: _fromToken,
            fromAmount: _fromAmount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: _beneficiary,
            path: _path,
            partner: address(0),
            feePercent: 0,
            permit: "",
            deadline: block.timestamp + 10 minutes,
            uuid: bytes16(bytes32("Dexify"))
        });

        IParaSwapV5AugustusSwapper(PARA_SWAP_V5_AUGUSTUS_SWAPPER).multiSwap(sellData);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable
    /// @return augustusSwapper_ The `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable value
    function getParaSwapV5AugustusSwapper() public view returns (address augustusSwapper_) {
        return PARA_SWAP_V5_AUGUSTUS_SWAPPER;
    }

    /// @notice Gets the `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable
    /// @return tokenTransferProxy_ The `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable value
    function getParaSwapV5TokenTransferProxy() public view returns (address tokenTransferProxy_) {
        return PARA_SWAP_V5_TOKEN_TRANSFER_PROXY;
    }
}
// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title IExchangeAdapter interface
interface IExchangeAdapter {
    /// @param amount The amount to swap
    /// @param srcToken The token swap from
    /// @param dstToken The token swap to
    /// @param receiver The user to receive `dstToken`
    struct SwapDescription {
        uint256 amount;
        address srcToken;
        address dstToken;
        address receiver;
    }

    /// @notice The identifier of this exchange adapter
    function identifier() external pure returns (string memory _identifier);

    /// @notice Swap with `_sd` data by using `_method` and `_data` on `_platform`.
    /// @param _method The method of the exchange platform
    /// @param _encodedCallArgs The encoded parameters to call
    /// @param _sd The description info of this swap
    /// @return The amount of token received on this swap
    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        SwapDescription calldata _sd
    ) external payable returns (uint256);
}
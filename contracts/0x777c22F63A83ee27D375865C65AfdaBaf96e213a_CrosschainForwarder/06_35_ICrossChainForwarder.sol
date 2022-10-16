//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface ICrossChainForwarder {
    error AffiliateFeeDistributionFailed(
        address recipient,
        address token,
        uint256 amount
    );

    struct GateParams {
        uint256 chainId;
        address receiver;
        bool useAssetFee;
        uint32 referralCode;
        bytes autoParams;
    }

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      swaps `_srcTokenIn` to `_srcTokenOut` by `CALL`-ing `_srcSwapCalldata` against `_srcSwapRouter`,
    ///      and finally sends the result of a swap to deBridge gate using the given gateParams
    /// @notice Since 1.2.0
    function swapAndSendV2(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      cuts off the `affiliateFeeAmount` of `_srcTokenIn` sending this fee to `affiliateFeeRecipient` (if given),
    ///      swaps `_srcTokenIn` to `_srcTokenOut` by `CALL`-ing `_srcSwapCalldata` against `_srcSwapRouter`,
    ///      and finally sends the result of a swap to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function swapAndSendV3(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      and finally sends the resulting amount to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function sendV2(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        GateParams memory _gateParams
    ) external payable;

    /// @dev Takes `_srcTokenInAmount` of `_srcTokenIn` from the msg.sender (executing `_srcTokenInPermit` if given),
    ///      cuts off the `affiliateFeeAmount` of `_srcTokenIn` sending this fee to `affiliateFeeRecipient` (if given),
    ///      and finally sends the resulting amount to deBridge gate using the given gateParams
    /// @notice Since 1.3.0
    function sendV3(
        address _srcTokenIn,
        uint256 _srcTokenInAmount,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        GateParams memory _gateParams
    ) external payable;
}
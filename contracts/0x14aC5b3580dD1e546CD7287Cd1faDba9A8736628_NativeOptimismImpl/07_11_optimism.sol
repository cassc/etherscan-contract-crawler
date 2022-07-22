// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface OldL1TokenGateway {
    function depositTo(address _to, uint256 _amount) external;

    function initiateSynthTransfer(
        bytes32 currencyKey,
        address destination,
        uint256 amount
    ) external;
}

struct OptimismBridgeExtraData {
    address _l2Token;
    uint32 _l2Gas;
    bytes _data;
    address _customBridgeAddress;
    uint256 _interfaceId;
    bytes32 _currencyKey;
}
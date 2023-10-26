// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

// @dev unable to inherit ERC20 because the OFTAdapter needs to use this interface as well
interface IOFT {
    struct SendParam {
        bytes32 to;
        uint amountLD;
        uint minAmountLD;
        uint32 dstEid;
    }

    error LDMinusSD();
    error AmountSlippage(uint _amountLDSend, uint256 _minAmountLD);

    event SetInspector(address _inspector);
    event SendOFT(bytes32 indexed _guid, address indexed _fromAddress, uint _amountLD, bytes _composeMsg);
    event ReceiveOFT(bytes32 indexed _guid, address indexed _toAddress, uint _amountLD);

    function token() external view returns (address);

    function quoteSendFee(
        SendParam calldata _send,
        bytes calldata _options,
        bool _useLZToken,
        bytes calldata _composeMsg
    ) external view returns (uint nativeFee, uint lzTokenFee);

    function send(
        SendParam calldata _send,
        bytes calldata _options,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable returns (MessagingReceipt memory);
}
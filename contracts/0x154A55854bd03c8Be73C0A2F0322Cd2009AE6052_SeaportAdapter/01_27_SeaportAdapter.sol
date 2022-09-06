// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ISeaport} from "../interfaces/ISeaport.sol";

import {BaseAdapter, IERC721Upgradeable} from "./BaseAdapter.sol";

contract SeaportAdapter is BaseAdapter {
    string public constant NAME = "Seaport Downpayment Adapter";
    string public constant VERSION = "1.0";
    // keccak256("Params(address considerationToken,uint256 considerationIdentifier,uint256 considerationAmount,address offerer,address zone,address offerToken,uint256 offerIdentifier,uint256 offerAmount,uint8 basicOrderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 offererConduitKey,bytes32 fulfillerConduitKey,uint256 totalOriginalAdditionalRecipients,AdditionalRecipient[] additionalRecipients,bytes signature,uint256 nonce)AdditionalRecipient(uint256 amount,address recipient)");
    bytes32 private constant _PARAMS_TYPEHASH = 0x2cf1f32523d87995ff90f07dd49a8b22ec133776b00dcf3c2dc4d5fe006a37d6;
    // keccak256("AdditionalRecipient(uint256 amount,address recipient)");
    bytes32 internal constant _ADDITIONAL_RECIPIENT_TYPEHASH =
        0x186f4a3e3c9707a61b54896806864237cf24613b9acdee6a7ac9d738e7f85b6c;
    ISeaport public seaportExchange;
    address public conduitAddress;

    function initialize(
        address _downpayment,
        address _seaportExchange,
        address _conduitAddress
    ) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);
        seaportExchange = ISeaport(_seaportExchange);
        conduitAddress = _conduitAddress;
    }

    function _checkParams(
        address,
        uint256,
        uint256,
        bytes memory _params,
        uint256 _nonce
    ) internal view override returns (BaseParams memory) {
        ISeaport.BasicOrderParameters memory _orderParams = _decodeParams(_params);
        address _WETH = address(downpayment.WETH());

        // Check order params
        require(
            address(0) == _orderParams.considerationToken || _WETH == _orderParams.considerationToken,
            "Adapter: currency should be ETH or WETH"
        );

        uint256 sellPrice = _orderParams.considerationAmount;

        // Iterate over each additional recipient.
        for (uint256 i = 0; i < _orderParams.additionalRecipients.length; i++) {
            ISeaport.AdditionalRecipient memory additionalRecipient = _orderParams.additionalRecipients[i];
            sellPrice += additionalRecipient.amount;
        }

        return
            BaseParams({
                nftAsset: _orderParams.offerToken,
                nftTokenId: _orderParams.offerIdentifier,
                currency: _orderParams.considerationToken,
                salePrice: sellPrice,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(ISeaport.BasicOrderParameters memory _orderParams, uint256 _nonce)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _PARAMS_TYPEHASH,
                        _orderParams.considerationToken,
                        _orderParams.considerationIdentifier,
                        _orderParams.considerationAmount,
                        _orderParams.offerer,
                        _orderParams.zone,
                        _orderParams.offerToken,
                        _orderParams.offerIdentifier,
                        _orderParams.offerAmount,
                        _orderParams.basicOrderType,
                        _orderParams.startTime,
                        _orderParams.endTime
                    ),
                    abi.encode(
                        _orderParams.zoneHash,
                        _orderParams.salt,
                        _orderParams.offererConduitKey,
                        _orderParams.fulfillerConduitKey,
                        _orderParams.totalOriginalAdditionalRecipients,
                        _hashAdditionalRecipient(_orderParams.additionalRecipients),
                        keccak256(_orderParams.signature),
                        _nonce
                    )
                )
            );
    }

    function _hashAdditionalRecipient(ISeaport.AdditionalRecipient[] memory recipients)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < recipients.length; i++) {
            ISeaport.AdditionalRecipient memory recipient = (recipients[i]);
            encoded = bytes.concat(
                encoded,
                keccak256(abi.encode(_ADDITIONAL_RECIPIENT_TYPEHASH, recipient.amount, recipient.recipient))
            );
        }
        return keccak256(encoded);
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        ISeaport.BasicOrderParameters memory _orderParams = _decodeParams(_params);
        uint256 paymentValue = _baseParams.salePrice;
        if (_baseParams.currency == address(0)) {
            downpayment.WETH().withdraw(paymentValue);
            seaportExchange.fulfillBasicOrder{value: paymentValue}(_orderParams);
        } else {
            downpayment.WETH().approve(conduitAddress, paymentValue);
            seaportExchange.fulfillBasicOrder(_orderParams);
            downpayment.WETH().approve(conduitAddress, 0);
        }
    }

    function _decodeParams(bytes memory _params) internal pure returns (ISeaport.BasicOrderParameters memory) {
        return abi.decode(_params, (ISeaport.BasicOrderParameters));
    }
}
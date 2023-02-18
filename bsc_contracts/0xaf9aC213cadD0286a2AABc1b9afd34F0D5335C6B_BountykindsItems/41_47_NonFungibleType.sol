// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

error NonFungibleType__ExceedLimit(uint256 typeNFT);

abstract contract NonFungibleType {
    event SetTypeNFT(uint256 typeNFT, address paymentToken, uint256 price, uint256 limit, uint256 unboxQuantity);

    struct TypeInfo {
        address paymentToken;
        uint256 price; // USD
        uint256 limit;
        uint256 quantity;
    }

    mapping(uint256 => TypeInfo) internal _typeInfo;
    mapping(uint256 => uint256) internal _sold;

    function getSold(uint256 typeNFT) external view returns (uint256) {
        return _sold[typeNFT];
    }

    function _setSold(uint256 typeNFT_, uint256 quantity_) internal {
        _sold[typeNFT_] = _sold[typeNFT_] + quantity_;
        if (_sold[typeNFT_] > _typeInfo[typeNFT_].limit) revert NonFungibleType__ExceedLimit(typeNFT_);
    }

    function _setType(uint256 type_, address paymentToken_, uint256 price_, uint256 limit_, uint256 quantity_) internal {
        if (_sold[type_] > limit_) revert NonFungibleType__ExceedLimit(type_);
        _typeInfo[type_] = TypeInfo(paymentToken_, price_, limit_, quantity_);
        emit SetTypeNFT(type_, paymentToken_, price_, limit_, quantity_);
    }

    uint256[48] private __gap;
}
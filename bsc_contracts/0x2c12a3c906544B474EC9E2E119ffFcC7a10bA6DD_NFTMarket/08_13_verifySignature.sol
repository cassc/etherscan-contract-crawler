// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract VerifySignature is EIP712 {
    error invalidsignature();
    error invalidcoupon();
    error addressZero();
    error redeemedcoupon();

    string private SIGNING_DOMAIN = "Market Coupons";
    string private SIGNATURE_VERSION = "1";

    mapping(bytes => bool) public couponsregistry;

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    function validate(
        uint256 _value,
        uint256 _coupon,
        bytes memory _signature,
        address _owner,
        uint256 _nonce
    ) public returns (bool) {
        if (couponsregistry[_signature] == true) {
            revert redeemedcoupon();
        }
        //_domainSeparator();
        if (!check(_value, _coupon, _signature, _owner, _nonce)) {
            revert invalidcoupon();
        }
        couponsregistry[_signature] = true;

        return true;
    }

    function check(
        uint256 _value,
        uint256 _coupon,
        bytes memory _signature,
        address _owner,
        uint256 _nonce
    ) internal view returns (bool) {
        return _verify(_value, _coupon, _signature, _owner, _nonce);
    }

    function _verify(
        uint256 _value,
        uint256 _coupon,
        bytes memory _signature,
        address _owner,
        uint256 _nonce
    ) internal view returns (bool) {
        bytes32 _digest = _hash(_value, _coupon, _nonce);
        address signer = ECDSA.recover(_digest, _signature);
        if (signer != _owner) {
            return false;
        }
        if (signer == address(0)) {
            revert addressZero();
        }
        return true;
    }

    function _hash(
        uint256 _value,
        uint256 _coupon,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "MarketCoupons(uint256 value,uint256 coupon,uint256 nonce)"
                        ),
                        _value,
                        _coupon,
                        _nonce
                    )
                )
            );
    }
}
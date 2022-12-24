// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../domino/IERC1271.sol";
import "../contracts/LibOrder.sol";
import "../domino/LibSignature.sol";
import "../openzeppelin/AddressUpgradeable.sol";
import "../openzeppelin/ContextUpgradeable.sol";
import "../openzeppelin/EIP712Upgradeable.sol";

abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable
{
    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Exchange", "2");
    }

    function validate(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        if (order.salt == 0) {
            if (order.maker != address(0)) {
                require(_msgSender() == order.maker, "maker is not tx sender");
            } else {
                order.maker = _msgSender();
            }
        } else {
            if (_msgSender() != order.maker) {
                bytes32 hash = LibOrder.hash(order);
                address signer;
                if (signature.length == 65) {
                    signer = order.maker;
                }
                if (signer != order.maker) {
                    if (order.maker.isContract()) {
                        require(
                            IERC1271(order.maker).isValidSignature(
                                _hashTypedDataV4(hash),
                                signature
                            ) == MAGICVALUE,
                            "contract order signature verification error"
                        );
                    } else {
                        revert("order signature verification error");
                    }
                } else {
                    require(order.maker != address(0), "no maker");
                }
            }
        }
    }

    uint256[50] private __gap;
}
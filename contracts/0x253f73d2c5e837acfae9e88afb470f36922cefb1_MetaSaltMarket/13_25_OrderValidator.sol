// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;
import "./interfaces/IERC1271.sol";
import "./lib/LibOrder.sol";
import "./lib/LibSignature.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

abstract contract OrderValidator is Initializable, ContextUpgradeable, EIP712Upgradeable, ReentrancyGuardUpgradeable {
    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("MetaSaltMarket", "1");
    }

    function getSigner(LibOrder.Order memory order, bytes memory signature) internal view returns(address){
        address signer;
        if (_msgSender() != order.maker) {                      
            if (signature.length == 65) {
                bytes32 hash = LibOrder.hash(order);  
                signer = _hashTypedDataV4(hash).recover(signature);
            }
        }    
        return signer;          
    }

    function validate(LibOrder.Order memory order, bytes memory signature) internal view {
        if (_msgSender() != order.maker) {
            bytes32 hash = LibOrder.hash(order);
            address signer;
            if (signature.length == 65) {
                signer = _hashTypedDataV4(hash).recover(signature);
            }
            if  (signer != order.maker) {
                revert("order signature verification error");
            }  
        }              
    }

    uint256[50] private __gap;
}
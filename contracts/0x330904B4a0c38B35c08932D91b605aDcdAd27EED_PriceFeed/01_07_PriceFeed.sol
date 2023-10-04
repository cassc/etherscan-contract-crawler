// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PriceFeed is Ownable {
    using ECDSA for bytes32;
    uint256 test;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct PriceUpdate {
        uint256 price;
        uint256 minimumRefund;
        uint256 nonce;
    }

    bytes32 constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant PRICE_UPDATE_TYPEHASH =
        keccak256(
            "PriceUpdate(uint256 price,uint256 minimumRefund,uint256 nonce)"
        );

    bytes32 immutable DOMAIN_SEPARATOR;
    uint256 public lastPrice;

    mapping(bytes32 => bool) public hashExecuted;

    constructor(string memory name, string memory version) {
        DOMAIN_SEPARATOR = _hashDomain(
            EIP712Domain({
                name: name,
                version: version,
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    function updatePrice(
        PriceUpdate calldata priceUpdate,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        bytes32 priceUpdateHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                _hashPriceUpdate(priceUpdate)
            )
        );

        bool isValidSignature = _isValidSignature(
            priceUpdateHash,
            owner(),
            v,
            r,
            s
        );
        require(isValidSignature == true, "Invalid signature");

        require(
            msg.value >= priceUpdate.minimumRefund,
            "Insufficient refund amount"
        );

        hashExecuted[priceUpdateHash] = true;
        lastPrice = priceUpdate.price;
    }

    // This function is only used for sharing information to the mevshare relay by the oracle operator
    function sharePriceUpdateMEVShareUtil(
        PriceUpdate calldata, // priceUpdate
        uint8, //v
        bytes32, //r
        bytes32 //s
    ) public view onlyOwner {
        revert();
    }

    function _hashPriceUpdate(
        PriceUpdate calldata priceUpdate
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PRICE_UPDATE_TYPEHASH,
                    priceUpdate.price,
                    priceUpdate.minimumRefund,
                    priceUpdate.nonce
                )
            );
    }

    function _hashDomain(
        EIP712Domain memory domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR_TYPEHASH,
                    keccak256(bytes(domain.name)),
                    keccak256(bytes(domain.version)),
                    domain.chainId,
                    domain.verifyingContract
                )
            );
    }

    function _isValidSignature(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        require(hashExecuted[hash] == false, "Signature replay");
        return ecrecover(hash, v, r, s) == signer;
    }
}
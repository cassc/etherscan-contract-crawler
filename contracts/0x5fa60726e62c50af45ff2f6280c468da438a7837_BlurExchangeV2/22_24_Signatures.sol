// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./lib/Constants.sol";
import {
    TakeAsk,
    TakeBid,
    TakeAskSingle,
    TakeBidSingle,
    FeeRate,
    Order,
    OrderType,
    AssetType,
    Listing
} from "./lib/Structs.sol";
import { ISignatures } from "./interfaces/ISignatures.sol";

abstract contract Signatures is ISignatures {
    string private constant _NAME = "Blur Exchange";
    string private constant _VERSION = "1.0";

    bytes32 private immutable _FEE_RATE_TYPEHASH;
    bytes32 private immutable _ORDER_TYPEHASH;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    mapping(address => uint256) public oracles;
    mapping(address => uint256) public nonces;
    uint256 public blockRange;

    constructor(address proxy) {
        (_FEE_RATE_TYPEHASH, _ORDER_TYPEHASH, _DOMAIN_SEPARATOR) = _createTypehashes(proxy);
    }

    /**
     * @notice Verify the domain separator produced during deployment of the implementation matches that of the proxy
     */
    function verifyDomain() public view {
        bytes32 eip712DomainTypehash = keccak256(
            bytes.concat(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        bytes32 domainSeparator = _hashDomain(
            eip712DomainTypehash,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION)),
            address(this)
        );
        if (_DOMAIN_SEPARATOR != domainSeparator) {
            revert InvalidDomain();
        }
    }

    /**
     * @notice Return version and domain separator
     */
    function information() external view returns (string memory version, bytes32 domainSeparator) {
        version = _VERSION;
        domainSeparator = _DOMAIN_SEPARATOR;
    }

    /**
     * @notice Create a hash of TakeAsk calldata with an approved caller
     * @param inputs TakeAsk inputs
     * @param _caller Address approved to execute the calldata
     * @return Calldata hash
     */
    function hashTakeAsk(TakeAsk memory inputs, address _caller) external pure returns (bytes32) {
        return _hashCalldata(_caller);
    }

    /**
     * @notice Create a hash of TakeBid calldata with an approved caller
     * @param inputs TakeBid inputs
     * @param _caller Address approved to execute the calldata
     * @return Calldata hash
     */
    function hashTakeBid(TakeBid memory inputs, address _caller) external pure returns (bytes32) {
        return _hashCalldata(_caller);
    }

    /**
     * @notice Create a hash of TakeAskSingle calldata with an approved caller
     * @param inputs TakeAskSingle inputs
     * @param _caller Address approved to execute the calldata
     * @return Calldata hash
     */
    function hashTakeAskSingle(
        TakeAskSingle memory inputs,
        address _caller
    ) external pure returns (bytes32) {
        return _hashCalldata(_caller);
    }

    /**
     * @notice Create a hash of TakeBidSingle calldata with an approved caller
     * @param inputs TakeBidSingle inputs
     * @param _caller Address approved to execute the calldata
     * @return Calldata hash
     */
    function hashTakeBidSingle(
        TakeBidSingle memory inputs,
        address _caller
    ) external pure returns (bytes32) {
        return _hashCalldata(_caller);
    }

    /**
     * @notice Create an EIP712 hash of an Order
     * @dev Includes two additional parameters not in the struct (orderType, nonce)
     * @param order Order to hash
     * @param orderType OrderType of the Order
     * @return Order EIP712 hash
     */
    function hashOrder(Order memory order, OrderType orderType) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    order.trader,
                    order.collection,
                    order.listingsRoot,
                    order.numberOfListings,
                    order.expirationTime,
                    order.assetType,
                    _hashFeeRate(order.makerFee),
                    order.salt,
                    orderType,
                    nonces[order.trader]
                )
            );
    }

    /**
     * @notice Create a hash of a Listing struct
     * @param listing Listing to hash
     * @return Listing hash
     */
    function hashListing(Listing memory listing) public pure returns (bytes32) {
        return keccak256(abi.encode(listing.index, listing.tokenId, listing.amount, listing.price));
    }

    /**
     * @notice Create a hash of calldata with an approved caller
     * @param _caller Address approved to execute the calldata
     * @return hash Calldata hash
     */
    function _hashCalldata(address _caller) internal pure returns (bytes32 hash) {
        assembly {
            let nextPointer := mload(0x40)
            let size := add(sub(nextPointer, 0x80), 0x20)
            mstore(nextPointer, _caller)
            hash := keccak256(0x80, size)
        }
    }

    /**
     * @notice Create an EIP712 hash of a FeeRate struct
     * @param feeRate FeeRate to hash
     * @return FeeRate EIP712 hash
     */
    function _hashFeeRate(FeeRate memory feeRate) private view returns (bytes32) {
        return keccak256(abi.encode(_FEE_RATE_TYPEHASH, feeRate.recipient, feeRate.rate));
    }

    /**
     * @notice Create an EIP712 hash to sign
     * @param hash Primary EIP712 object hash
     * @return EIP712 hash
     */
    function _hashToSign(bytes32 hash) private view returns (bytes32) {
        return keccak256(bytes.concat(bytes2(0x1901), _DOMAIN_SEPARATOR, hash));
    }

    /**
     * @notice Generate all EIP712 Typehashes
     */
    function _createTypehashes(
        address proxy
    )
        private
        view
        returns (bytes32 feeRateTypehash, bytes32 orderTypehash, bytes32 domainSeparator)
    {
        bytes32 eip712DomainTypehash = keccak256(
            bytes.concat(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        bytes memory feeRateTypestring = "FeeRate(address recipient,uint16 rate)";

        orderTypehash = keccak256(
            bytes.concat(
                "Order(",
                "address trader,",
                "address collection,",
                "bytes32 listingsRoot,",
                "uint256 numberOfListings,",
                "uint256 expirationTime,",
                "uint8 assetType,",
                "FeeRate makerFee,",
                "uint256 salt,",
                "uint8 orderType,",
                "uint256 nonce",
                ")",
                feeRateTypestring
            )
        );

        feeRateTypehash = keccak256(feeRateTypestring);

        domainSeparator = _hashDomain(
            eip712DomainTypehash,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION)),
            proxy
        );
    }

    /**
     * @notice Create an EIP712 domain separator
     * @param eip712DomainTypehash Typehash of the EIP712Domain struct
     * @param nameHash Hash of the contract name
     * @param versionHash Hash of the version string
     * @param proxy Address of the proxy this implementation will be behind
     * @return EIP712Domain hash
     */
    function _hashDomain(
        bytes32 eip712DomainTypehash,
        bytes32 nameHash,
        bytes32 versionHash,
        address proxy
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(eip712DomainTypehash, nameHash, versionHash, block.chainid, proxy)
            );
    }

    /**
     * @notice Verify EIP712 signature
     * @param signer Address of the alleged signer
     * @param hash EIP712 hash
     * @param signatures Packed bytes array of order signatures
     * @param index Index of the signature to verify
     * @return authorized Validity of the signature
     */
    function _verifyAuthorization(
        address signer,
        bytes32 hash,
        bytes memory signatures,
        uint256 index
    ) internal view returns (bool authorized) {
        bytes32 hashToSign = _hashToSign(hash);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            let signatureOffset := add(add(signatures, One_word), mul(Signatures_size, index))
            r := mload(signatureOffset)
            s := mload(add(signatureOffset, Signatures_s_offset))
            v := shr(Bytes1_shift, mload(add(signatureOffset, Signatures_v_offset)))
        }
        authorized = _verify(signer, hashToSign, v, r, s);
    }

    modifier verifyOracleSignature(bytes32 hash, bytes calldata oracleSignature) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint32 blockNumber;
        address oracle;
        assembly {
            let signatureOffset := oracleSignature.offset
            r := calldataload(signatureOffset)
            s := calldataload(add(signatureOffset, OracleSignatures_s_offset))
            v := shr(Bytes1_shift, calldataload(add(signatureOffset, OracleSignatures_v_offset)))
            blockNumber := shr(
                Bytes4_shift,
                calldataload(add(signatureOffset, OracleSignatures_blockNumber_offset))
            )
            oracle := shr(
                Bytes20_shift,
                calldataload(add(signatureOffset, OracleSignatures_oracle_offset))
            )
        }
        if (blockNumber + blockRange < block.number) {
            revert ExpiredOracleSignature();
        }
        if (oracles[oracle] == 0) {
            revert UnauthorizedOracle();
        }
        if (!_verify(oracle, keccak256(abi.encodePacked(hash, blockNumber)), v, r, s)) {
            revert InvalidOracleSignature();
        }
        _;
    }

    /**
     * @notice Verify signature of digest
     * @param signer Address of expected signer
     * @param digest Signature digest
     * @param v v parameter
     * @param r r parameter
     * @param s s parameter
     */
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (bool valid) {
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner != address(0) && recoveredSigner == signer) {
            valid = true;
        }
    }

    uint256[47] private __gap;
}
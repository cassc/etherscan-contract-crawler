/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

// File: contracts/lib/WasabiStructs.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library WasabiStructs {
    enum OptionType {
        CALL,
        PUT
    }

    struct OptionData {
        bool active;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 tokenId; // Locked token for CALL options
    }

    struct PoolAsk {
        uint256 id;
        address poolAddress;
        OptionType optionType;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 tokenId; // Token to lock for CALL options
        uint256 orderExpiry;
    }

    struct PoolBid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        uint256 optionId;
    }

    struct Bid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        address collection;
        uint256 orderExpiry;
        address buyer;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 expiryAllowance;
        address optionTokenAddress;
    }

    struct Ask {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        address seller;
        uint256 optionId;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }
}

/**
 * @dev Signature Verification
 */
library Signing {

    /**
     * @dev Returns the message hash for the given request
     */
    function getMessageHash(WasabiStructs.PoolAsk calldata _request) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _request.id,
                _request.poolAddress,
                _request.optionType,
                _request.strikePrice,
                _request.premium,
                _request.expiry,
                _request.tokenId,
                _request.orderExpiry));
    }

    /**
     * @dev Returns the message hash for the given request
     */
    function getAskHash(WasabiStructs.Ask calldata _ask) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _ask.id,
                _ask.price,
                _ask.tokenAddress,
                _ask.orderExpiry,
                _ask.seller,
                _ask.optionId));
    }

    function getBidHash(WasabiStructs.Bid calldata _bid) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _bid.id,
                _bid.price,
                _bid.tokenAddress,
                _bid.collection,
                _bid.orderExpiry,
                _bid.buyer,
                _bid.optionType,
                _bid.strikePrice,
                _bid.expiry,
                _bid.expiryAllowance));
    }

    /**
     * @dev creates an ETH signed message hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function getSigner(
        WasabiStructs.PoolAsk calldata _request,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_request);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getAskSigner(
        WasabiStructs.Ask calldata _ask,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getAskHash(_ask);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

/**
 * @dev Signature Verification for PoolAsk
 */
library PoolAskVerifier {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant POOLASK_TYPEHASH =
        keccak256(
            "PoolAsk(uint256 id,address poolAddress,uint8 optionType,uint256 strikePrice,uint256 premium,uint256 expiry,uint256 tokenId,uint256 orderExpiry)"
        );

    /**
     * @dev Creates the hash of the EIP712 domain for this validator
     *
     * @param _eip712Domain the domain to hash
     * @return the hashed domain
     */
    function hashDomain(
        WasabiStructs.EIP712Domain memory _eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(_eip712Domain.name)),
                    keccak256(bytes(_eip712Domain.version)),
                    _eip712Domain.chainId,
                    _eip712Domain.verifyingContract
                )
            );
    }

    /**
     * @dev Creates the hash of the PoolAsk for this validator
     *
     * @param _poolAsk to hash
     * @return the poolAsk domain
     */
    function hashForPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    POOLASK_TYPEHASH,
                    _poolAsk.id,
                    _poolAsk.poolAddress,
                    _poolAsk.optionType,
                    _poolAsk.strikePrice,
                    _poolAsk.premium,
                    _poolAsk.expiry,
                    _poolAsk.tokenId,
                    _poolAsk.orderExpiry
                )
            );
    }

    /**
     * @dev Gets the signer of the given signature for the given _poolAsk
     *
     * @param _poolAsk the ask to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "PoolAskSignature",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForPoolAsk(_poolAsk))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Checks the signer of the given signature for the given poolAsk is the given signer
     *
     * @param _poolAsk the _poolAsk to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForPoolAsk(_poolAsk, _signature) == _signer;
    }

    /**
     * @return the current chain id
     */
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
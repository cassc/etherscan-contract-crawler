// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "../lib/Signing.sol";

/**
 * @dev Signature Verification for Bid and Ask
 */
abstract contract ConduitSignatureVerifier {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant BID_TYPEHASH =
        keccak256(
            "Bid(uint256 id,uint256 price,address tokenAddress,address collection,uint256 orderExpiry,address buyer,uint8 optionType,uint256 strikePrice,uint256 expiry,uint256 expiryAllowance,address optionTokenAddress)"
        );

    bytes32 constant ASK_TYPEHASH =
        keccak256(
            "Ask(uint256 id,uint256 price,address tokenAddress,uint256 orderExpiry,address seller,uint256 optionId)"
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
     * @dev Creates the hash of the Bid for this validator
     *
     * @param _bid to hash
     * @return the bid domain
     */
    function hashForBid(
        WasabiStructs.Bid memory _bid
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BID_TYPEHASH,
                    _bid.id,
                    _bid.price,
                    _bid.tokenAddress,
                    _bid.collection,
                    _bid.orderExpiry,
                    _bid.buyer,
                    _bid.optionType,
                    _bid.strikePrice,
                    _bid.expiry,
                    _bid.expiryAllowance,
                    _bid.optionTokenAddress
                )
            );
    }

    /**
     * @dev Creates the hash of the Ask for this validator
     *
     * @param _ask the ask to hash
     * @return the ask domain
     */
    function hashForAsk(
        WasabiStructs.Ask memory _ask
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASK_TYPEHASH,
                    _ask.id,
                    _ask.price,
                    _ask.tokenAddress,
                    _ask.orderExpiry,
                    _ask.seller,
                    _ask.optionId
                )
            );
    }

    /**
     * @dev Gets the signer of the given signature for the given bid
     *
     * @param _bid the bid to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForBid(
        WasabiStructs.Bid memory _bid,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "ConduitSignature",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForBid(_bid))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Gets the signer of the given signature for the given ask
     *
     * @param _ask the ask to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForAsk(
        WasabiStructs.Ask memory _ask,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "ConduitSignature",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForAsk(_ask))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Checks the signer of the given signature for the given bid is the given signer
     *
     * @param _bid the bid to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyBid(
        WasabiStructs.Bid memory _bid,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForBid(_bid, _signature) == _signer;
    }

    /**
     * @dev Checks the signer of the given signature for the given ask is the given signer
     *
     * @param _ask the ask to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyAsk(
        WasabiStructs.Ask memory _ask,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForAsk(_ask, _signature) == _signer;
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
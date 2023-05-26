// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Signing.sol";

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
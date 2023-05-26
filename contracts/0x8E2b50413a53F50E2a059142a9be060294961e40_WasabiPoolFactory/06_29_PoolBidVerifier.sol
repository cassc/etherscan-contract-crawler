// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Signing.sol";

/**
 * @dev Signature Verification for PoolBid
 */
library PoolBidVerifier {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant POOLBID_TYPEHASH =
        keccak256(
            "PoolBid(uint256 id,uint256 price,address tokenAddress,uint256 orderExpiry,uint256 optionId)"
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
     * @dev Creates the hash of the PoolBid for this validator
     *
     * @param _poolBid to hash
     * @return the poolBid hash
     */
    function hashForPoolBid(
        WasabiStructs.PoolBid memory _poolBid
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    POOLBID_TYPEHASH,
                    _poolBid.id,
                    _poolBid.price,
                    _poolBid.tokenAddress,
                    _poolBid.orderExpiry,
                    _poolBid.optionId
                )
            );
    }

    /**
     * @dev Gets the signer of the given signature for the given _poolBid
     *
     * @param _poolBid the bid to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForPoolBid(
        WasabiStructs.PoolBid memory _poolBid,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "PoolBidVerifier",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForPoolBid(_poolBid))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Checks the signer of the given signature for the given _poolBid is the given signer
     *
     * @param _poolBid the bid to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyPoolBid(
        WasabiStructs.PoolBid memory _poolBid,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForPoolBid(_poolBid, _signature) == _signer;
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
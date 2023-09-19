// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../mint/interfaces/IAbridgedMintVector.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @notice Instance of SingleEditionDFS contract (single edition, unlimited size)
 * @dev Uses Decentralized File Storage
 * @author highlight.xyz
 */
contract SingleEditionDFS is Proxy {
    /**
     * @notice Set up a SingleEdition instance
     * @param implementation_ ERC721SingleEdition implementation
     * @param initializeData Data to initialize SingleEdition instance
     * @ param creator Creator/owner of contract
     * @ param defaultRoyalty Default royalty object for contract (optional)
     * @ param _defaultTokenManager Default token manager for contract (optional)
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param _size Edition size
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinter Initial minter to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @ param _editionUri Edition uri (metadata)
     * @param mintVectorData Mint vector data
     * @ param mintManager
     * @ param paymentRecipient
     * @ param startTimestamp
     * @ param endTimestamp
     * @ param pricePerToken
     * @ param tokenLimitPerTx
     * @ param maxTotalClaimableViaVector
     * @ param maxUserClaimableViaVector
     * @ param allowlistRoot
     * @param _observability Observability contract address
     */
    constructor(
        address implementation_,
        bytes memory initializeData,
        bytes memory mintVectorData,
        address _observability
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(
            implementation_,
            abi.encodeWithSignature("initialize(bytes,address)", initializeData, _observability)
        );

        if (mintVectorData.length > 0) {
            (
                address mintManager,
                address paymentRecipient,
                uint48 startTimestamp,
                uint48 endTimestamp,
                uint192 pricePerToken,
                uint48 tokenLimitPerTx,
                uint48 maxTotalClaimableViaVector,
                uint48 maxUserClaimableViaVector,
                bytes32 allowlistRoot
            ) = abi.decode(
                    mintVectorData,
                    (address, address, uint48, uint48, uint192, uint48, uint48, uint48, bytes32)
                );

            IAbridgedMintVector(mintManager).createAbridgedVector(
                IAbridgedMintVector.AbridgedVectorData(
                    uint160(address(this)),
                    startTimestamp,
                    endTimestamp,
                    uint160(paymentRecipient),
                    maxTotalClaimableViaVector,
                    0,
                    0,
                    tokenLimitPerTx,
                    maxUserClaimableViaVector,
                    pricePerToken,
                    0,
                    true,
                    false,
                    allowlistRoot
                )
            );
        }
    }

    /**
     * @notice Return the contract type
     */
    function standard() external pure returns (string memory) {
        return "SingleEditionDFS";
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}
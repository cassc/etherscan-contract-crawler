// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @notice Instance of SingleEdition contract (single edition, unlimited size)
 * @author highlight.xyz
 */
contract SingleEdition is Proxy {
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
     * @ param metadataRendererAddress Contract returning metadata for each edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinter Initial minter to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @ param _editionInfo Edition info
     */
    constructor(address implementation_, bytes memory initializeData) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(implementation_, abi.encodeWithSignature("initialize(bytes)", initializeData));
    }

    /**
     * @notice Return the contract type
     */
    function contractType() external view returns (string memory) {
        return "SingleEdition";
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
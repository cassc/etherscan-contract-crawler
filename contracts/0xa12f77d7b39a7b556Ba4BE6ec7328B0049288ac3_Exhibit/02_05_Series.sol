// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @notice Instance of Series contract (unique metadata per token in collection)
 * @author highlight.xyz
 */
contract Series is Proxy {
    /**
     * @notice Set up Series instance
     * @param implementation_ General721 implementation
     * @param initializeData Data to initialize Series contract
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param defaultRoyalty Default royalty object for contract (optional)
     * @ param _defaultTokenManager Default token manager for contract (optional)
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinter Initial minter to register
     * @ param newBaseURI Base URI for contract
     * @ param _limitSupply Initial limit supply
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
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
        return "Series";
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
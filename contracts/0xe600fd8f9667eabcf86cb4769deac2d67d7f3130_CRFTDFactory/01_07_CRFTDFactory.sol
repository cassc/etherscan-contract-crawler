// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solady/utils/LibClone.sol";

import "solady/auth/Ownable.sol";

import "src/interfaces/IPaymentSplitter.sol";

import "src/interfaces/ICRFTDERC721A.sol";

/**
 * @title CRFTDFactory
 * @notice The CRFTDFactory is reponsible for the deploying clone of the CRFTD ERC721A tokens.
 */
contract CRFTDFactory is Ownable {
    error ZeroAddress();

    event CollectionDeployed(address deployed);

    event CRFTDImplementationSet(address newImplementation);

    /**
     * @dev Implementation contract address of the CRFTDERC721A.
     */
    address public crftdImplementation;

    constructor(address owner_, address impl_) {
        _initializeOwner(owner_);
        crftdImplementation = impl_;
    }

    /**
     * @dev Creates a new CRFTD collection by cloning the CRFTD implementation and initializing it with the provided parameters.
     *
     * @param name      The name of the collection.
     * @param symbol    The symbol of the collection.
     * @param tokenURI  The base URI for the tokens of the collection.
     * @param payee     An array of IPaymentSplitter.Payees struct that specifies the payees and their shares for royalty fees.
     * @param phases    An array of ICRFTDERC721A.PhaseSetting struct that specifies the phase settings for the collection.
     * @param initData  The encoded data of the abi.encodePacked(uint128(price), uint128(maxSupply), uint64(maxPerWallet), address(owner), address(royaltyRecevicer), uint16(flag), uint16(feeNumerator)).
     *
     * @return The address of the deployed CRFTD collection contract.
     */
    function createCRFTDCollection(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        IPaymentSplitter.Payees[] memory payee,
        ICRFTDERC721A.PhaseSetting[] memory phases,
        bytes memory initData
    ) external returns (address) {
        address deployedContract = LibClone.clone(crftdImplementation);

        ICRFTDERC721A(deployedContract).init(name, symbol, tokenURI, payee, phases, initData);

        emit CollectionDeployed(deployedContract);

        return deployedContract;
    }

    /**
     * @dev Updates the new address of CRFTD implementation.
     */
    function setImplementation(address newImplementation) external onlyOwner {
        if (newImplementation == address(0)) revert ZeroAddress();

        crftdImplementation = newImplementation;

        emit CRFTDImplementationSet(newImplementation);
    }
}
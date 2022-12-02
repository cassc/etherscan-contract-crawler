// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/proxy/Clones.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../assetRecovering/OwnableAssetRecoverer.sol";
import "./IFeeDistributorFactory.sol";
import "../feeDistributor/IFeeDistributor.sol";
import "../access/Ownable.sol";
import "../access/OwnableWithOperator.sol";

/**
* @notice Should be a FeeDistributor contract
* @param _passedAddress passed address that does not support IFeeDistributor interface
*/
error FeeDistributorFactory__NotFeeDistributor(address _passedAddress);

/**
* @notice Reference FeeDistributor should be set before calling `createFeeDistributor`
*/
error FeeDistributorFactory__ReferenceFeeDistributorNotSet();

/**
* @title Factory for cloning (EIP-1167) FeeDistributor instances pre client
*/
contract FeeDistributorFactory is OwnableAssetRecoverer, OwnableWithOperator, ERC165, IFeeDistributorFactory {
    // Type Declarations

    using Clones for address;

    // State variables

    /**
    * @notice The address of the reference implementation of FeeDistributor
    * @dev used as the basis for clones
    */
    address private s_referenceFeeDistributor;

    // Functions

    /**
    * @notice Set a new reference implementation of FeeDistributor contract
    * @param _referenceFeeDistributor the address of the new reference implementation contract
    */
    function setReferenceInstance(address _referenceFeeDistributor) external onlyOwner {
        if (!ERC165Checker.supportsInterface(_referenceFeeDistributor, type(IFeeDistributor).interfaceId)) {
            revert FeeDistributorFactory__NotFeeDistributor(_referenceFeeDistributor);
        }

        s_referenceFeeDistributor = _referenceFeeDistributor;
        emit ReferenceInstanceSet(_referenceFeeDistributor);
    }

    /**
    * @notice Creates a FeeDistributor instance for a client
    * @dev Emits `FeeDistributorCreated` event with the address of the newly created instance
    * @dev _referrerConfig can be zero if there is no referrer.
    * @param _clientConfig address and basis points (percent * 100) of the client
    * @param _referrerConfig address and basis points (percent * 100) of the referrer.
    */
    function createFeeDistributor(
        IFeeDistributor.FeeRecipient calldata _clientConfig,
        IFeeDistributor.FeeRecipient calldata _referrerConfig
    ) external onlyOperatorOrOwner {
        if (s_referenceFeeDistributor == address(0)) {
            revert FeeDistributorFactory__ReferenceFeeDistributorNotSet();
        }

        // clone the reference implementation of FeeDistributor
        address newFeeDistributorAddress = s_referenceFeeDistributor.clone();

        // cast address to FeeDistributor
        IFeeDistributor newFeeDistributor = IFeeDistributor(newFeeDistributorAddress);

        // set the client address to the cloned FeeDistributor instance
        newFeeDistributor.initialize(_clientConfig, _referrerConfig);

        // emit event with the address of the newly created instance for the external listener
        emit FeeDistributorCreated(newFeeDistributorAddress, _clientConfig.recipient);
    }

    /**
     * @dev Returns the reference FeeDistributor contract address
     */
    function getReferenceFeeDistributor() external view returns (address) {
        return s_referenceFeeDistributor;
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IFeeDistributorFactory).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override(Ownable, OwnableBase, IOwnable) returns (address) {
        return super.owner();
    }
}
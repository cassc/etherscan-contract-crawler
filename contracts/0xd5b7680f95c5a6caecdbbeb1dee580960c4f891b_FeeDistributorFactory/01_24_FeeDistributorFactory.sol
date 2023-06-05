// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
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
import "../p2pEth2Depositor/IP2pEth2Depositor.sol";

/**
* @notice Should be a FeeDistributor contract
* @param _passedAddress passed address that does not support IFeeDistributor interface
*/
error FeeDistributorFactory__NotFeeDistributor(address _passedAddress);

/**
* @notice Should be a P2pEth2Depositor contract
* @param _passedAddress passed address that does not support IP2pEth2Depositor interface
*/
error FeeDistributorFactory__NotP2pEth2Depositor(address _passedAddress);

/**
* @notice Reference FeeDistributor should be set before calling `createFeeDistributor`
*/
error FeeDistributorFactory__ReferenceFeeDistributorNotSet();

/**
* @notice caller should be owner, operator, or P2pEth2Depositor contract
* @param _caller calling address
*/
error FeeDistributorFactory__CallerNotAuthorized(address _caller);

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

    /**
    * @notice Default Client Basis Points
    * @dev Used when no client config provided.
    * @dev Default Referrer Basis Points is zero.
    */
    uint96 s_defaultClientBasisPoints;

    /**
    * @notice The address of P2pEth2Depositor
    */
    address private s_p2pEth2Depositor;

    /**
    * @dev Set values known at the initial deploy time.
    * @param _defaultClientBasisPoints Default Client Basis Points
    */
    constructor(uint96 _defaultClientBasisPoints) {
        s_defaultClientBasisPoints = _defaultClientBasisPoints;
    }

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
    * @notice Set a new version of P2pEth2Depositor contract
    * @param _p2pEth2Depositor the address of the new P2pEth2Depositor contract
    */
    function setP2pEth2Depositor(address _p2pEth2Depositor) external onlyOwner {
        if (!ERC165Checker.supportsInterface(_p2pEth2Depositor, type(IP2pEth2Depositor).interfaceId)) {
            revert FeeDistributorFactory__NotP2pEth2Depositor(_p2pEth2Depositor);
        }

        s_p2pEth2Depositor = _p2pEth2Depositor;
        emit P2pEth2DepositorSet(_p2pEth2Depositor);
    }

    /**
    * @notice Set a new Default Client Basis Points
    * @param _defaultClientBasisPoints Default Client Basis Points
    */
    function setDefaultClientBasisPoints(uint96 _defaultClientBasisPoints) external onlyOwner {
        s_defaultClientBasisPoints = _defaultClientBasisPoints;
    }

    /**
    * @notice Creates a FeeDistributor instance for a client
    * @dev Emits `FeeDistributorCreated` event with the address of the newly created instance
    * @dev _referrerConfig can be zero if there is no referrer.
    * @param _clientConfig address and basis points (percent * 100) of the client
    * @param _referrerConfig address and basis points (percent * 100) of the referrer.
    * @param _validatorData clientOnlyClRewards, firstValidatorId, and validatorCount
    * @return newFeeDistributorAddress user FeeDistributor instance that has just been deployed
    */
    function createFeeDistributor(
        IFeeDistributor.FeeRecipient memory _clientConfig,
        IFeeDistributor.FeeRecipient calldata _referrerConfig,
        IFeeDistributor.ValidatorData calldata _validatorData
    ) external returns (address newFeeDistributorAddress) {
        address currentOwner = owner();
        address currentOperator = operator();
        address p2pEth2Depositor = s_p2pEth2Depositor;

        if (currentOperator != _msgSender()
            && currentOwner != _msgSender()
            && p2pEth2Depositor != _msgSender()
        ) {
            revert FeeDistributorFactory__CallerNotAuthorized(_msgSender());
        }

        if (s_referenceFeeDistributor == address(0)) {
            revert FeeDistributorFactory__ReferenceFeeDistributorNotSet();
        }

        if (_clientConfig.basisPoints == 0) {
            _clientConfig.basisPoints = s_defaultClientBasisPoints;
        }

        // clone the reference implementation of FeeDistributor
        newFeeDistributorAddress = s_referenceFeeDistributor.clone();

        // cast address to FeeDistributor
        IFeeDistributor newFeeDistributor = IFeeDistributor(newFeeDistributorAddress);

        // set the client address to the cloned FeeDistributor instance
        newFeeDistributor.initialize(_clientConfig, _referrerConfig, _validatorData);

        // emit event with the address of the newly created instance for the external listener
        emit FeeDistributorCreated(newFeeDistributorAddress, _clientConfig.recipient);

        return newFeeDistributorAddress;
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
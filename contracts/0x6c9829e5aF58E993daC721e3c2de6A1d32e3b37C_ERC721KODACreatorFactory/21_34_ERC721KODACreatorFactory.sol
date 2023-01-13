// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ICollabFundsHandler} from "../handlers/ICollabFundsHandler.sol";
import {IERC721KODACreatorFactory} from "./interfaces/IERC721KODACreatorFactory.sol";
import {IKOAccessControlsLookup} from "../interfaces/IKOAccessControlsLookup.sol";

import {ERC721KODACreator} from "./ERC721KODACreator.sol";
import {KODASettings} from "../KODASettings.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice Smart contract that facilitates the deployment of self sovereign ERC721 tokens
contract ERC721KODACreatorFactory is
    UUPSUpgradeable,
    PausableUpgradeable,
    IERC721KODACreatorFactory
{
    /// @notice Address of the access controls contract that track legitimate artists within the platform
    IKOAccessControlsLookup public accessControls;

    /// @notice global primary and secondary sale platform settings
    KODASettings public platformSettings;

    /// @notice Name of contract that will be deployed as the self sovereign unless otherwise specified
    string public defaultSelfSovereignContractName;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(string => address) public contractImplementations;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(address => string) public implementationIdentifiers;

    /// @notice Address of the cloneable fund handler contract
    address public receiverImplementation;

    /// @notice Funds handler ID and the smart contract address deployed to handle it
    mapping(bytes32 => address) public deployedHandler;

    /// @notice A simple on chain pointer to contracts which have been flagged
    mapping(address => bool) public flaggedContracts;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings
    ) external initializer {
        if (_erc721Implementation == address(0)) revert ZeroAddress();
        if (_receiverImplementation == address(0)) revert ZeroAddress();
        if (bytes(_erc721ImplementationName).length == 0) revert EmptyString();

        accessControls = _accessControls;
        receiverImplementation = _receiverImplementation;

        // when initialising the factory, configure the default self sovereign implementation that will be deployed
        // other self sovereign contracts can be configured and labelled offering the ability to deploy them by supplying the label on deploy
        contractImplementations[
            _erc721ImplementationName
        ] = _erc721Implementation;

        implementationIdentifiers[
            _erc721Implementation
        ] = _erc721ImplementationName;

        defaultSelfSovereignContractName = _erc721ImplementationName;

        platformSettings = _settings;

        __Pausable_init();
        __UUPSUpgradeable_init();

        emit ContractDeployed();
    }

    ///////////////
    /// External  /
    ///////////////

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry,
            _deploymentParams.subscriptionOrRegistrantToCopy
        );
    }

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry,
            _deploymentParams.subscriptionOrRegistrantToCopy
        );
    }

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused returns (address) {
        return
            _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
    }

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                contractImplementations[_nftIdentifier],
                _computeSalt(_artist, _name, _symbol),
                address(this)
            );
    }

    /// @notice The unique handler ID for a given list of recipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_recipients, _splitAmounts));
    }

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address) {
        bytes32 id = getHandlerId(_recipients, _splitAmounts);
        return deployedHandler[id];
    }

    ///////////////
    /// Admin     /
    ///////////////

    /// @dev Only authorize upgrade if user has admin role
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    function flagBannedContract(address _contract, bool _banned) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        flaggedContracts[_contract] = _banned;
        emit CreatorContractBanned(_contract, _banned);
    }

    /// @notice Disable certain actions
    function pause() external whenNotPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _pause();
    }

    /// @notice Enable all paused actions
    function unpause() external whenPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _unpause();
    }

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        accessControls = _access;
    }

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_receiver == address(0)) revert ZeroAddress();
        receiverImplementation = _receiver;
    }

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_newSettings == address(0)) revert ZeroAddress();
        platformSettings = KODASettings(_newSettings);
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry,
            _deploymentParams.subscriptionOrRegistrantToCopy
        );
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry,
            _deploymentParams.subscriptionOrRegistrantToCopy
        );
    }

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();

        if (contractImplementations[_identifier] != address(0))
            revert DuplicateIdentifier();
        if (bytes(implementationIdentifiers[_implementation]).length != 0)
            revert DuplicateImplementation();

        contractImplementations[_identifier] = _implementation;
        implementationIdentifiers[_implementation] = _identifier;

        emit NewImplementationAdded(_identifier);
    }

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        defaultSelfSovereignContractName = _default;
        emit DefaultImplementationUpdated(_default);
    }

    ///////////////
    /// Internal  /
    ///////////////

    /// @dev Deploy a fund handler for a given set of recipients or splits if one has not already been deployed
    function _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) internal returns (address) {
        // Deploy a fund handler if not already deployed
        bytes32 handlerId = getHandlerId(_recipients, _splitAmounts);

        address handler = deployedHandler[handlerId];
        if (handler == address(0)) {
            address receiverClone = Clones.clone(receiverImplementation);
            ICollabFundsHandler(receiverClone).init(_recipients, _splitAmounts);

            deployedHandler[handlerId] = receiverClone;

            emit FundsHandlerDeployed(receiverClone);

            return receiverClone;
        }

        return handler;
    }

    /// @dev Business logic for deploying a cloneable ERC721
    function _deploySelfSovereignERC721(
        address _artist,
        string calldata _name,
        string calldata _symbol,
        address _fundsHandler,
        uint256 _secondaryRoyaltyPercentage,
        string calldata _implementationName,
        address _operatorRegistry,
        address _subscriptionOrRegistrantToCopy
    ) internal {
        // Deploy the NFT
        address erc721Clone = Clones.cloneDeterministic(
            contractImplementations[_implementationName],
            _computeSalt(_artist, _name, _symbol)
        );

        ERC721KODACreator(erc721Clone).initialize(
            _artist,
            _name,
            _symbol,
            _fundsHandler,
            platformSettings,
            _secondaryRoyaltyPercentage,
            _operatorRegistry, // optional
            _subscriptionOrRegistrantToCopy // optional
        );

        emit SelfSovereignERC721Deployed(
            msg.sender,
            _artist,
            erc721Clone,
            contractImplementations[_implementationName],
            _fundsHandler
        );
    }

    /// @dev Compute a deployment salt based on an address and NFT metadata
    function _computeSalt(
        address _sender,
        string calldata _name,
        string calldata _symbol
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _name, _symbol));
    }
}
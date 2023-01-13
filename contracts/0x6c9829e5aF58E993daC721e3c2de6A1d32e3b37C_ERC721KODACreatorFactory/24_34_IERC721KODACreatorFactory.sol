// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "../../interfaces/IKOAccessControlsLookup.sol";
import {KODASettings} from "../../KODASettings.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreatorFactory {
    error DuplicateIdentifier();
    error DuplicateImplementation();
    error EmptyString();
    error OnlyAdmin();
    error OnlyVerifiedArtist();
    error ZeroAddress();

    /// @notice Emitted when the contract is deployed in order to capture initial params
    event ContractDeployed();

    /// @notice Emitted every time a self sovereign ERC721 contract is deployed
    event SelfSovereignERC721Deployed(
        address indexed deployer,
        address indexed artist,
        address indexed selfSovereignNFT,
        address implementation,
        address fundsHandler
    );

    /// @notice Emitted when a fund handler is deployed
    event FundsHandlerDeployed(address indexed _handler);

    /// @notice Emitted when a new deployable contract is added
    event NewImplementationAdded(string _identifier);

    /// @notice Emitted when default contract name that is deployed is updated
    event DefaultImplementationUpdated(string _identifier);

    /// @notice Emitted when a creator contract has been banned from participating in the platform marketplace
    event CreatorContractBanned(address indexed _contract, bool _banned);

    /// @notice The base deployment parameters of a self sovereign contract
    struct SelfSovereignDeployment {
        string name; // Name that will be assigned to the NFT
        string symbol; // Symbol that will be assigned to the NFT
        string contractIdentifier; // Factory identifier for the contract being deployed
        uint256 secondaryRoyaltyPercentage; // Artist specified secondary EIP2981 royalty for items sold outside platform
        address filterRegistry; // Address of a filter registry that an artist wishes to use or zero address if they want none
        address subscriptionOrRegistrantToCopy; // Address of the subscription to copy
    }

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings
    ) external;

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
    ) external;

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof
    ) external;

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external returns (address);

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address);

    /// @notice The unique handler ID for a given list of receipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external pure returns (bytes32);

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address);

    function flagBannedContract(address _contract, bool _banned) external;

    /// @notice Disable certain actions
    function pause() external;

    /// @notice Enable all paused actions
    function unpause() external;

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external;

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external;

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external;

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external;

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default) external;
}
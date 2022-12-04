// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IPassageAccess.sol";

interface IPassport2 is IPassageAccess {
    event BaseUriUpdated(string uri);
    event MaxSupplyLocked();
    event MaxSupplyUpdated(uint256 maxSupply);
    event PassportInitialized(
        address registryAddress,
        address passportAddress,
        string symbol,
        string name,
        uint256 maxSupply
    );
    event RenderModuleSet(address moduleAddress);
    event BeforeTransferModuleSet(address moduleAddress);
    event MintingModuleAdded(address moduleAddress, uint256 index);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();
    event RoyaltyInfoSet(address wallet, uint96 basisPoints);

    function claim(
        uint256 mintingModuleIndex,
        uint256[] calldata tokenIds,
        uint256[] calldata mintAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external payable;

    function eject() external;

    function initialize(
        address _creator,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _initialTokenId,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external;

    function lockMaxSupply() external;

    function lockVersion() external;

    function mintPassports(address[] calldata _addresses, uint256[] calldata _amounts)
        external
        returns (uint256, uint256);

    function passportVersion() external pure returns (uint256 version);

    function setBaseURI(string memory _uri) external;

    function setOwnership(address newOwner) external;

    function setTrustedForwarder(address forwarder) external;

    function withdraw() external;

    function isManaged() external returns (bool);

    function setMaxSupply(uint256 _maxSupply) external;

    function setRenderModule(address _contractAddress) external;

    function setBeforeTransfersModule(address _contractAddress) external;

    function setMintingModule(uint256 index, address _contractAddress) external;

    function setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}
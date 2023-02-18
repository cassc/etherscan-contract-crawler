// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "./modules/minting/IMintingModule.sol";

interface ILoyaltyLedger2 is IAccessControlUpgradeable {
    struct Token {
        string name;
        uint256 maxSupply; // 0 is no max
        uint256 totalMinted;
        mapping(uint256 => IMintingModule) mintingModules;
    }

    // ---- events ----
    event BaseUriUpdated(string uri);
    event TokenCreated(uint256 id, string name, uint256 maxSupply);
    event MaxSupplyUpdated(uint256 id, uint256 maxSupply);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();
    event RenderModuleSet(address moduleAddress);
    event BeforeTransferModuleSet(address moduleAddress);
    event MintingModuleSet(uint256 id, uint256 index, address moduleAddress);
    event RoyaltyInfoSet(address wallet, uint96 basisPoints);
    event LoyaltyLedgerInitialized(address creator, address ll, address royaltyWallet, uint96 royaltyPoints);

    function claim(
        uint256 id,
        uint256 mmIndex,
        uint256[] calldata tokenIds,
        uint256[] calldata claimAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external payable;

    function createToken(string memory _name, uint256 _maxSupply) external returns (uint256);

    function eject() external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function initialize(
        address _creator,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external;

    function isManaged() external view returns (bool);

    function lockVersion() external;

    function loyaltyLedgerVersion() external pure returns (uint256);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    function mintBulk(
        address[] calldata _addresses,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    function setOwnership(address newOwner) external;

    function setTokenMaxSupply(uint256 _id, uint256 _maxSupply) external;

    function setRenderModule(address _contractAddress) external;

    function setBeforeTransfersModule(address _contractAddress) external;

    function setTokenMintingModule(
        uint256 _id,
        uint256 _index,
        address _contractAddress
    ) external;

    function getTokenMintingModule(uint256 _id, uint256 _index) external view returns (address);

    function setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function supportsInterface(bytes4 interfaceId) external returns (bool);

    function withdraw() external;
}
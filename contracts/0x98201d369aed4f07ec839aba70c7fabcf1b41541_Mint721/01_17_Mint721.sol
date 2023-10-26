// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/ERC721AStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";
import {IERC165} from "openzeppelin/interfaces/IERC165.sol";
import {IMetadataRenderer} from "create/interfaces/v1/IMetadataRenderer.sol";
import {IMintContract} from "create/interfaces/v1/IMintContract.sol";
import {IMint721} from "create/interfaces/v1/IMint721.sol";
import {Mint721Configuration} from "create/interfaces/v1/Mint721Configuration.sol";
import {IMintModuleRegistry} from "create/interfaces/v1/IMintModuleRegistry.sol";
import {IERC4906} from "create/interfaces/v1/IERC4906.sol";
import {Version} from "create/contracts/v1/Version.sol";

contract Mint721 is ERC721AUpgradeable, IMintContract, IMint721, IERC4906, IERC2981, Ownable, Version {
    bytes4 private constant _updateConfigurationSelector = bytes4(keccak256("updateConfiguration(bytes)"));

    IMintModuleRegistry private _mintModuleRegistry;

    /// @inheritdoc IMintContract
    IMetadataRenderer public metadataRenderer;
    /// @inheritdoc IMintContract
    mapping(address => bool) public isMintModuleApproved;
    /// @inheritdoc IMintContract
    uint256 public royaltyBps;

    error UnapprovedMintModule();
    error OnlyEOAAdminMintAllowed();
    error AlreadyInitialized();
    error ModuleUpdateFailed();
    error InvalidMintModuleData();
    error InvalidRoyalty();

    constructor() Version(1) {}

    /// @inheritdoc IMint721
    function initialize(
        Mint721Configuration calldata config,
        address mintModuleRegistry_,
        IMetadataRenderer _metadataRenderer,
        bytes calldata metadataRendererConfig,
        address[] calldata mintModules,
        bytes[] calldata mintModuleData,
        address creator
    ) external {
        if (ERC721AStorage.layout()._currentIndex != 0) revert AlreadyInitialized();

        ERC721AStorage.layout()._name = config.name;
        ERC721AStorage.layout()._symbol = config.symbol;
        ERC721AStorage.layout()._currentIndex = _startTokenId();

        _mintModuleRegistry = IMintModuleRegistry(mintModuleRegistry_);

        _initializeOwner(creator);
        _setMetadataRenderer(_metadataRenderer);

        if (mintModules.length != mintModuleData.length) revert InvalidMintModuleData();

        for (uint256 i; i < mintModules.length;) {
            address mintModule = mintModules[i];
            _addMintModule(mintModule);
            _updateExternalConfiguration(mintModule, mintModuleData[i]);
            unchecked {
                ++i;
            }
        }

        if (metadataRendererConfig.length > 0) {
            _updateExternalConfiguration(address(_metadataRenderer), metadataRendererConfig);
        }
    }

    /// @inheritdoc IMintContract
    function mint(address to, uint256 quantity) external {
        if (!isMintModuleApproved[msg.sender]) revert UnapprovedMintModule();
        _mint(to, quantity);
    }

    /// @inheritdoc IMintContract
    function adminMint(address to, uint256 quantity) external onlyOwner {
        if (tx.origin != msg.sender) revert OnlyEOAAdminMintAllowed();
        _mint(to, quantity);
    }

    /// @inheritdoc IMintContract
    function payoutRecipient() external view override returns (address) {
        return owner();
    }

    /// @inheritdoc IMintContract
    function totalMinted() external view override returns (uint256) {
        return _totalMinted();
    }

    /// @inheritdoc IMintContract
    function addMintModule(address mintModule) external onlyOwner {
        _addMintModule(mintModule);
    }

    function _addMintModule(address mintModule) internal {
        _mintModuleRegistry.checkModule(mintModule);
        isMintModuleApproved[mintModule] = true;
        emit ModuleAdded(mintModule);
    }

    /// @inheritdoc IMintContract
    function removeMintModule(address mintModule) external onlyOwner {
        _removeMintModule(mintModule);
    }

    /// @dev We don't check if it is a valid module intentionally while removing.
    function _removeMintModule(address mintModule) internal {
        delete isMintModuleApproved[mintModule];
        emit ModuleRemoved(mintModule);
    }

    /// @inheritdoc IMintContract
    function setRoyalty(uint256 bps) external onlyOwner {
        if (bps > 1000) revert InvalidRoyalty(); // disallow over 10%
        royaltyBps = bps;
        emit RoyaltyUpdated(bps);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * royaltyBps) / 10000;
        return (owner(), royaltyAmount);
    }

    /// @inheritdoc IMintContract
    function refreshMetadata() external onlyOwner {
        emit BatchMetadataUpdate(_startTokenId(), type(uint256).max);
    }

    /// @inheritdoc IMintContract
    function updateExternalConfiguration(address[] memory configurable, bytes[] calldata configData)
        external
        override
        onlyOwner
    {
        if (configurable.length != configData.length) revert InvalidMintModuleData();

        for (uint256 i; i < configurable.length;) {
            _updateExternalConfiguration(configurable[i], configData[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _updateExternalConfiguration(address configurable, bytes calldata configData) internal {
        (bool ok,) = configurable.call(abi.encodeWithSelector(_updateConfigurationSelector, configData));
        if (!ok) revert ModuleUpdateFailed();
    }

    /// @inheritdoc IMintContract
    function setMetadataRenderer(IMetadataRenderer _metadataRenderer) external onlyOwner {
        _setMetadataRenderer(_metadataRenderer);
    }

    function _setMetadataRenderer(IMetadataRenderer _metadataRenderer) internal {
        metadataRenderer = _metadataRenderer;
        emit MetadataRendererUpdated(address(_metadataRenderer));
    }

    /// @inheritdoc ERC721AUpgradeable
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721AUpgradeable
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return metadataRenderer.tokenURI(tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IMint721).interfaceId
            || interfaceId == type(IMintContract).interfaceId || interfaceId == type(IERC4906).interfaceId
            || interfaceId == type(IERC2981).interfaceId;
    }
}
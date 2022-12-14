// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IERC2981Upgradeable.sol";
import "./interfaces/IBitBrandNFT.sol";

/// @notice BitBrand NFT Rares V1
/// @author thev.eth
/// @custom:security-contact [email protected]
contract BitBrandV1RaresUpgradeable is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IBitBrandNFT,
    IERC2981Upgradeable
{
    uint256 public maxSupply;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant ONE_PERCENT = 100;
    uint256 private constant MAX_ROYALTY = 100 * ONE_PERCENT;

    address royaltyReceiver;
    uint256 royaltyPercentage;

    string private _overrideBaseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address deployer_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyPercentage_,
        string memory baseURI_,
        uint256 maxSupply_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, deployer_);
        _grantRole(PAUSER_ROLE, deployer_);
        _grantRole(MINTER_ROLE, deployer_);

        royaltyReceiver = royaltyReceiver_;
        royaltyPercentage = royaltyPercentage_;
        _overrideBaseURI = baseURI_;
        maxSupply = maxSupply_;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyRole(MINTER_ROLE)
    {
        if (tokenId >= maxSupply) {
            revert InvalidTokenId(tokenId);
        }
        _safeMint(to, tokenId, "");
    }

    /// @notice Set the base URI for all tokens
    function _baseURI() internal view override returns (string memory) {
        return _overrideBaseURI;
    }

    /// @dev See {IERC2981-royaltyInfo}
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 royalty = (_salePrice * royaltyPercentage) / MAX_ROYALTY;
        return (royaltyReceiver, royalty);
    }

    // The following functions are overrides required by Solidity.

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            IERC165Upgradeable,
            ERC721Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            type(IBitBrandNFT).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
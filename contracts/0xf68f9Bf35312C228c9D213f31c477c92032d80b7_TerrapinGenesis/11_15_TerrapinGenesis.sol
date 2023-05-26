//SPDX-License-Identifier: MIT

/*
 ************************************************************************************************************************
 *                                                                                                                      *
 * ___________                                     .__            ________                                 .__          *
 * \__    ___/____ _______ _______ _____   ______  |__|  ____    /  _____/   ____    ____    ____    ______|__|  ______ *
 *   |    | _/ __ \\_  __ \\_  __ \\__  \  \____ \ |  | /    \  /   \  ___ _/ __ \  /    \ _/ __ \  /  ___/|  | /  ___/ *
 *   |    | \  ___/ |  | \/ |  | \/ / __ \_|  |_> >|  ||   |  \ \    \_\  \\  ___/ |   |  \\  ___/  \___ \ |  | \___ \  *
 *   |____|  \___  >|__|    |__|   (____  /|   __/ |__||___|  /  \______  / \___  >|___|  / \___  >/____  >|__|/____  > *
 *               \/                     \/ |__|             \/          \/      \/      \/      \/      \/          \/  *
 *                                                                                                                      *
 ************************************************************************************************************************
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

error MintNotActive();
error MaxSupplyExceeded();
error InvalidSignature();
error AccountPreviouslyMinted();
error InvalidValue();
error ValueUnchanged();

contract OSOwnableDelegateProxy {}

contract OSProxyRegistry {
    mapping(address => OSOwnableDelegateProxy) public proxies;
}

/**
 * @title Terrapin Genesis
 *
 * @notice ERC-721 NFT Token Contract.
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
contract TerrapinGenesis is Ownable, AccessControl, EIP712, ERC721AQueryable {
    using Address for address payable;
    using ECDSA for bytes32;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINT_SIGNER_ROLE = keccak256("MINT_SIGNER_ROLE");
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address account)");
    uint256 public constant maxSupply = 333;

    bool public mintActive;
    string public baseURI;

    OSProxyRegistry internal _osProxyRegistry;

    event MintActiveUpdated(bool mintActive);
    event BaseURIUpdated(string oldBaseURI, string baseURI);

    constructor(
        string memory baseURI_,
        address osProxyRegistryAddress,
        address[] memory operators,
        address[] memory mintSigners
    ) EIP712("TerrapinGenesis", "1") ERC721A("TerrapinGenesis", "TG") {
        baseURI = baseURI_;
        _osProxyRegistry = OSProxyRegistry(osProxyRegistryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 index = 0; index < operators.length; ++index) {
            _grantRole(OPERATOR_ROLE, operators[index]);
        }
        for (uint256 index = 0; index < mintSigners.length; ++index) {
            _grantRole(MINT_SIGNER_ROLE, mintSigners[index]);
        }
    }

    /**
     * @dev Mint function, only whitelisted accounts allowed. With a valid
     * signature from an account with a MINT_SIGNER_ROLE role, accounts may mint
     * up to 1 token.
     */
    function mint(bytes calldata sig) external {
        if (mintActive != true) revert MintNotActive();
        if (numberMinted(_msgSender()) > 0) revert AccountPreviouslyMinted();
        if ((_totalMinted() + 1) > maxSupply) revert MaxSupplyExceeded();

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _msgSender()))
        );
        address signer = ECDSA.recover(digest, sig);
        if (hasRole(MINT_SIGNER_ROLE, signer) != true)
            revert InvalidSignature();

        _safeMint(_msgSender(), 1);
    }

    /**
     * @dev Special Mint function. For miscellaneous purposes, e.g. raffles.
     */
    function mintSpecial(address[] calldata addresses)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (_totalMinted() + addresses.length > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 index = 0; index < addresses.length; ++index) {
            _safeMint(addresses[index], 1);
        }
    }

    /**
     * @dev Reserve Mint function.
     */
    function mintReserve(address to, uint256 quantity)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyExceeded();

        _safeMint(to, quantity);
    }

    function setMintActive(bool mintActive_) external onlyRole(OPERATOR_ROLE) {
        if (mintActive == mintActive_) revert ValueUnchanged();

        mintActive = mintActive_;

        emit MintActiveUpdated(mintActive);
    }

    function setBaseURI(string memory baseURI_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (
            keccak256(abi.encodePacked(baseURI_)) ==
            keccak256(abi.encodePacked(_baseURI()))
        ) revert ValueUnchanged();

        string memory oldBaseURI = _baseURI();
        baseURI = baseURI_;

        emit BaseURIUpdated(oldBaseURI, baseURI_);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    /**
     * @dev Number of tokens minted.
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns number of tokens `account` has minted.
     */
    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner_, operator)) {
            return true;
        }

        if (
            address(_osProxyRegistry) != address(0) &&
            address(_osProxyRegistry.proxies(owner_)) == operator
        ) {
            return true;
        }

        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
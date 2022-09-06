// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// @title:      Asura
// @url:        https://theasuraproject.com

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IAsuraMetadata.sol";

contract AsuraToken is ERC721A, AccessControl, Ownable, IERC2981 {
    // -=-=-=-=- Errors -=-=-=-=-
    error SenderNotMinter();
    error MinterOwnershipRenounced();
    error MetadataOwnershipRenounced();
    error TokenSoldOut();
    error AmountHigherThanMaxSupply();
    error Nesting();

    // -=-=-=-=- Minter -=-=-=-=-
    address public minteraddress;
    bool public isMinterLocked = false;
    uint256 MAX_SUPPLY = 7777;

    // -=-=-=-=- Metadata -=-=-=-=-
    string public baseTokenURI;
    address public metadataAddress;
    bool public isMetadataLocked = false;

    // -=-=-=-=- Nesting -=-=-=-=-
    mapping(uint256 => bool) public nested;
    bytes32 NEST_CONTROLLER = keccak256("NEST_CONTROLLER");

    // -=-=-=-=- Royalties -=-=-=-=-
    address public royaltyAddress = 0xa3FF74eF802836dBd4d2C2c5AC950B88EAE237d5;
    uint256 public royaltyPercent = 5;

    // -=-=-=-=- Events -=-=-=-=-

    event Nested(uint256 indexed tokenId);
    event Unnested(uint256 indexed tokenId);

    modifier onlyMinter() {
        if (msg.sender != minteraddress) revert SenderNotMinter();
        _;
    }

    // -=-=-=-=- Constructors -=-=-=-=-

    constructor(string memory _baseTokenURI) ERC721A("Asura", "ASURA") {
        baseTokenURI = _baseTokenURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // -=-=-=-=- Minting -=-=-=-=-

    /**
     * @dev Since only minter address can mint, we don't need other checks in place since checks are done via mint contract
     **/

    function mint(address _to, uint256 _amount) external onlyMinter {
        if (totalSupply() + _amount > MAX_SUPPLY) revert TokenSoldOut();

        _safeMint(_to, _amount);
    }

    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    function lowerMaxSupply(uint256 _amount) external onlyOwner {
        if (_amount > MAX_SUPPLY) revert AmountHigherThanMaxSupply();

        MAX_SUPPLY = _amount;
    }

    // -=-=-=-=- Minter -=-=-=-=-
    function setMinterAddress(address _minteraddress) external onlyOwner {
        if (isMinterLocked) revert MinterOwnershipRenounced();
        minteraddress = _minteraddress;
    }

    function lockMinter() external onlyOwner {
        isMinterLocked = true;
    }

    // -=-=-=-=- Metadata -=-=-=-=-

    /**
     * @dev Token contract has Metadata implementation, but able to offload implementation to external contract
     *
     * Provenance hash will be implemented in external metadata contract
     *
     **/

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (address(metadataAddress) != address(0)) {
            if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
            return IAsuraMetadata(metadataAddress).tokenURI(_tokenId);
        }
        return super.tokenURI(_tokenId);
    }

    function setMetadataAddress(address _metadataAddress) external onlyOwner {
        if (isMetadataLocked) revert MetadataOwnershipRenounced();
        metadataAddress = _metadataAddress;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function lockMetadata() public onlyOwner {
        isMetadataLocked = true;
    }

    // -=-=-=-=- Nesting -=-=-=-=-

    /**
     * @dev Nesting implementation inspired by Moonbirds
     *
     * The Token Contract only holds the toggle implementation. Nesting logic is offloaded to future Controller
     **/

    function toggleNesting(uint256 _tokenId)
        external
        onlyRole(NEST_CONTROLLER)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        nested[_tokenId] = !nested[_tokenId];

        if (nested[_tokenId]) emit Nested(_tokenId);
        else emit Unnested(_tokenId);
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (nested[tokenId]) revert Nesting();
        }
    }

    // -=-=-=-=- Misc -=-=-=-=-

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyPercent(uint256 _royaltyPercent) external onlyOwner {
        royaltyPercent = _royaltyPercent;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
}

// @dev: marcelc63
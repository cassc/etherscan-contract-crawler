// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './CardMetadata.sol';

contract PassportNFT is ERC721A, Ownable, AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    CardMetadata public metadata;
    uint256 public defaultNameId = 0;
    mapping(uint256 => uint256) nameIds;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }

    constructor(
        CardMetadata _metadata,
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        metadata = _metadata;
        _safeMint(_msgSender(), 1);
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    function currentIndex() external view returns (uint256) {
        return _nextTokenId();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert('setApprovalForAll is not available');
    }

    function approve(address, uint256) public payable virtual override {
        revert('approve is not available');
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return metadata.tokenURI(tokenId, ownerOf(tokenId), nameIds[tokenId]);
    }

    function setMetadata(CardMetadata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    function setDefaultNameId(uint256 _defaultNameId) external onlyOwner {
        defaultNameId = _defaultNameId;
    }

    // internal
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0) || to == address(0), 'Transfer is not available');
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (from == address(0)) {
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                nameIds[i] = defaultNameId;
            }
        }
    }
}
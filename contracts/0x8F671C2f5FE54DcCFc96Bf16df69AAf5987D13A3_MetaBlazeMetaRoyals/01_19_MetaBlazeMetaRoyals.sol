/*
Crafted with love by
Metablaze
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//MetaRoyal contract, receive the royalties from 10000NFTs contract

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';


import "./ShareHolder.sol";


contract MetaBlazeMetaRoyals is ShareHolder, Ownable, AccessControl {

    uint256 private constant _MAX_SUPPLY = 200;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using Strings for uint256;
    string private _baseUri;

    constructor(
      string memory name,
      string memory symbol,
      uint96 feeNumerator,
      address royaltyReceiver,
      address minterRole
    ) ERC721A(name, symbol) {
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, minterRole);
    }

    function mint(address receiver, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= _MAX_SUPPLY, "Amount reaches max supply");
        _mint(receiver, amount, "", false);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /** Royalties */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        ShareHolder.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        ShareHolder.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        ShareHolder.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721ARoyalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice contract ether handlers
    /// @dev is called every time when theres ETH comming in from the 10000NFTs contract royalties
    receive() external payable {
        ethReflectionBasis += msg.value;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
          if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

          string memory baseURI = _baseURI();

          return bytes(baseURI).length != 0 ? string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    ".json"
                )) : '';
    }


}
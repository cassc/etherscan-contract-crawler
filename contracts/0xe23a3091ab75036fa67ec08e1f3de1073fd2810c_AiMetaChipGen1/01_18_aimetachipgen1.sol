/*
Crafted with love by
Metablaze.xyz
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721ARoyalty.sol";


contract AiMetaChipGen1 is ERC721ARoyalty, Ownable, AccessControl {
  
    using Strings for uint256;
    uint256 private constant MAX_AIRDROP = 150;
    uint256 private constant AIRDROP_SIZE = 600;

    uint256 public _maxSupply = 1000;
    uint256 public salePrice = 0.07 ether;
    uint256 public _airdroppedTokens;
    string private _baseUri;

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        uint96 feeNumerator,
        address royaltyReceiver,
        address airdropRole
    ) ERC721A(name, symbol) {
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(AIRDROP_ROLE, airdropRole);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setSalePrice(uint256 newSalePrice) external onlyOwner {
        require(newSalePrice > 0, "Wrong sale price");
        salePrice = newSalePrice;
    }

    function reduceMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < _maxSupply, "New max supply exceeds max supply");
        require(totalSupply() <= newMaxSupply, "Total supply exceeds new max supply");
        _maxSupply = newMaxSupply;
    }


    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Wrong Quantity");
        require(totalSupply() + quantity <= _maxSupply, "Exceeds max supply");
        require(msg.value == salePrice*quantity, "Wrong mint price");
        address sender = _msgSender();
        _safeMint(sender, quantity);
    }

    function airdrop(address[] memory receivers) external onlyRole(AIRDROP_ROLE) {
        uint256 size = receivers.length;
        require(size <= MAX_AIRDROP, "Receiver array too long");
        require(_airdroppedTokens + size <= AIRDROP_SIZE, "Exceeds airdrop size");
        require(totalSupply() + size <= _maxSupply, "Exceeds max supply");
        _airdroppedTokens += size;
        for(uint16 i; i < size; i++) {
            _safeMint(receivers[i], 1);
        }
    }
    /** Royalties */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw(address payable receiver) external onlyOwner {
        receiver.transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721ARoyalty, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
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
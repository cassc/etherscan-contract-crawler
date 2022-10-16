/*
Crafted with love by
Metablaze
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//200NFTs contract, receive the royalties from 10000NFTs contract

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';


import "./ERC721ARoyalty.sol";


contract MetaBlazeMetaGoblins is ERC721ARoyalty, Ownable, AccessControl {

    event NewPhase(uint8 phase);
    using Strings for uint256;


    // 10 phases of 1000 Nfts each
    uint256 private constant PHASE_SIZE = 1000;
    uint256 private constant AIRDROP_SIZE = 1000;
    uint256 private constant MAX_AIRDROP = 250;
    uint256 private _maxSupply = 10000;

    uint256 private _airdroppedTokens;
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    uint8 public currentPhase;
    uint256 public salePrice = 0.2 ether;

    string private _baseUri;

    mapping(uint8 => uint256) public phaseMintedTokens;

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

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setNextPhase() external onlyOwner {
        require(currentPhase < 8, "All phases done");
        currentPhase += 1;
        emit NewPhase(currentPhase);
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

    function mint(uint256 quantity) external payable {
        uint8 phase = currentPhase;
        require(quantity > 0, "Wrong Quantity");
        require(totalSupply() + quantity <= _maxSupply, "Exceeds max supply");
        require(msg.value == salePrice*quantity, "Wrong mint price");
        address sender = _msgSender();
        phaseMintedTokens[phase] += quantity;
        require(phaseMintedTokens[phase] <= PHASE_SIZE, "Reached phase size");
        _safeMint(sender, quantity);
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
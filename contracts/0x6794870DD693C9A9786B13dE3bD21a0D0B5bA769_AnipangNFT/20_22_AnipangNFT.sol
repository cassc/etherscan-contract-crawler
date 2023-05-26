// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC4906/ERC4906.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract AnipangNFT is
    ERC4906,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    AccessControl,
    Ownable
{
    // utils
    using Counters for Counters.Counter;
    using Address for address;
    using Strings for uint256;

    // token id counter
    Counters.Counter private _tokenIdCounter;

    // role
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // variables
    string BASE_URI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC4906(name, symbol) {
        BASE_URI = baseURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
                keccak256(abi.encodePacked((BASE_URI))),
            "baseURI is same"
        );
        BASE_URI = baseURI;

        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function triggerBatchMetadataUpdate() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC4906)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  /*
  * 오픈씨 메타데이터
  */
  function contractURI() public pure returns (string memory) {

    string memory name = 'ANIPANG SUPPORTER CLUB';
    //로열티 퍼센트
    string memory seller_fee_basis_points = '750';
    //로열티 지갑
    string memory fee_recipient = '0xE4c28D47BC64509892590E9f680195012FaBC4B1';

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            name,
            '", "seller_fee_basis_points": ',
            seller_fee_basis_points,
            ', "fee_recipient": "',
            fee_recipient,
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
  }
}
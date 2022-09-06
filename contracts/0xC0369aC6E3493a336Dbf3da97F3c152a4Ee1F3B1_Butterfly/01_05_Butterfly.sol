// SPDX-License-Identifier: None
pragma solidity ^0.8.5;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Butterfly is ERC721A, Ownable {
  address OpenSea = 0x1E0049783F008A0085193E00003D00cd54003c71;

  uint256 constant supply_plus_one = 1001;
  uint256 mintStartTime = 1659380400;

  string tokenBaseUri = "ipfs://QmQe3ZMJumtwUu6C7gWgRxsiTFmZJxFjuPTJH4TeoHtkdg/";
  mapping (address => uint256) public minted;

  

  constructor() ERC721A("Butterfly", "FLY") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "not allowed");
    _;
  }

  function mint() public callerIsUser {
    uint256 _mintStartTime = mintStartTime;
    require(_mintStartTime != 0 && block.timestamp >= _mintStartTime, "mint has not started yet");

    require(minted[msg.sender] == 0, "only one NFT per wallet");

    uint256 _totalSupply = totalSupply();
    require(_totalSupply + 1 < supply_plus_one, "SOLD OUT");

    minted[msg.sender] ++;    
    _mint(msg.sender, 1);
  }

  function mint(address _address, uint256 _quantity) public onlyOwner {
      _mint(_address, _quantity);
  }

  function isApprovedForAll(address owner, address operator) public override view returns (bool) {
    if (address(OpenSea) == operator) {
        return true;
        }

      else
      return super.isApprovedForAll(owner, operator);
    }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }



  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newBaseUri) public onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

    function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setMintStartTime(uint256 timestamp) public onlyOwner {
    mintStartTime = timestamp;
  }

  function MintStartTime() public view returns (uint256) {
    return mintStartTime;
  }
}
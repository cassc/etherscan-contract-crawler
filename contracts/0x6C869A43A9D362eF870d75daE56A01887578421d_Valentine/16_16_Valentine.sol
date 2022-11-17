// SPDX-License-Identifier: Unlicensed
// Crafted with ❤️ by [ @esawwh (1619058420), @dankazenoff ] @ HOMA;

pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DefaultOperatorFilterer } from "./opensea/DefaultOperatorFilterer.sol";

contract Valentine is ERC721, Pausable, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;
  using Address for address;

  enum MintPhase { INACTIVE, HOMALIST, PUBLIC }

  uint256 private _count = 0;
  uint256 private _MAX_SUPPLY = 7000;

  string private _BASE_URI = 'https://apricot-petite-magpie-306.mypinata.cloud/ipfs/Qme6SctvCoXt2t6vBRmUQMhAMFX9KVn1dvi1nbJCPSj8wv/';

  uint256 private allowlistCanMintAt = 1668672000;
  uint256 private publicCanMintAt = 1668715200;
  uint256 private canNoLongerPauseAfter = 1669696969;

  mapping(address => uint256) private mintStatus;
  mapping(address => bool) private admins;

  constructor() ERC721("Valentine", "VAL") {
    admins[msg.sender] = true;
  } 

  function pause() external onlyAdmins {
    require(block.timestamp < canNoLongerPauseAfter);
    _pause();
  }

  function unpause() external onlyAdmins {
    _unpause();
  }

  function mintAdmin() public onlyAdmins {
    require(_count < _MAX_SUPPLY);
    ERC721._mint(msg.sender, ++_count);
  }

  function batchMintAdmin(address[] calldata _addresses) external onlyAdmins {
    require (_addresses.length + _count < _MAX_SUPPLY + 1);
    for(uint256 i; i < _addresses.length; i++){
      mintAdmin();
    }
  }

  function getMintPhase() public view returns (MintPhase) {
    if (block.timestamp < allowlistCanMintAt) {
      return MintPhase.INACTIVE;
    } else if (block.timestamp < publicCanMintAt) {
      return MintPhase.HOMALIST;
    }

    return MintPhase.PUBLIC;
  }

  function mint() external {
    bool canMint = getCanMint(msg.sender);
    require(canMint, 'User not allowed to mint at this time');

    ERC721._mint(msg.sender, ++_count);

    if (mintStatus[msg.sender] == 0) {
      mintStatus[msg.sender] = 2;
    } else if (mintStatus[msg.sender] == 1) {
      if (getMintPhase() == MintPhase.HOMALIST) {
        mintStatus[msg.sender] = 3;
      } else {
        mintStatus[msg.sender] = 4;
      }
    } else if (mintStatus[msg.sender] == 3) {
      mintStatus[msg.sender] = 4;
    }
  }

  function getCanMint(address _address) public view returns (bool) {
    if (_count >= _MAX_SUPPLY) {
      return false;
    }

    MintPhase currentPhase = getMintPhase();

    if (currentPhase == MintPhase.INACTIVE) {
      return false;
    }

    if (currentPhase == MintPhase.HOMALIST) {
      if (mintStatus[_address] == 1) {
        return true;
      }
    } else {
      if (
        mintStatus[_address] == 1 ||
        mintStatus[_address] == 3 ||
        mintStatus[_address] == 0
      ) {
        return true;
      }
    }

    return false;
  }

  function getCount() external view returns (uint256) {
    return _count;
  }

  function setAllowlistCanMintAt(uint256 _timestamp) external onlyAdmins {
    allowlistCanMintAt = _timestamp;
  }

  function setPublicCanMintAt(uint256 _timestamp) external onlyAdmins {
    publicCanMintAt = _timestamp;
  }

  function setMintStatus(address[] calldata _addresses, uint256[] calldata _status) external onlyAdmins {
    for(uint256 i; i < _addresses.length; i++){
      mintStatus[_addresses[i]] = _status[i];
    }
  }

  function getMintStatus(address _address) external view returns(uint256) {
    return mintStatus[_address];
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return _BASE_URI;
  }

  function _setBaseURI(string calldata _baseURIParam) external onlyAdmins {
    _BASE_URI = _baseURIParam;
  }

  function withdraw(address _to) public onlyOwner {
    address payable payableTo = payable(_to);

    payableTo.transfer(address(this).balance);
	}

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override
  {
    ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  modifier onlyAdmins {
    require(admins[msg.sender] == true, 'Needs admin permissions');
    _;
  }

  function setAdmins(address[] calldata _addresses, bool[] calldata _isAdmin) external onlyOwner {
    for(uint256 i; i < _addresses.length; i++){
      admins[_addresses[i]] = _isAdmin[i];
    }
  }
  
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    ERC721.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
    ERC721.safeTransferFrom(from, to, tokenId, data);
  }
}
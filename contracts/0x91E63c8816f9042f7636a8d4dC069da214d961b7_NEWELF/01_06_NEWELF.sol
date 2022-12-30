// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "erc721a/contracts/ERC721A.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract NEWELF is
  Ownable,
  ReentrancyGuard
{
  address public NANOHUB;
  string public symbol = "ELF";
  string public name = "ELFOOZ";

  string public baseURI;
  string public baseExtension = '.json';

  uint256 public totalSupply = 0;

  mapping (uint256 => address) owners;
  mapping (address => uint256) balances;

  uint256 teamMintAmount = 303;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  constructor(
    string memory uri
  ) 
    ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
  {
    setBaseURI(uri);

    for ( uint i = 0; i < teamMintAmount; i ++ ) {
      _mint(msg.sender, i + 1);
    }
  }

  function setNANOHUB(address _NANOHUB)
    public onlyOwner 
  {
    NANOHUB = _NANOHUB;
  }

  function setBaseURI(string memory _tokenBaseURI) 
    public onlyOwner 
  {
    baseURI = _tokenBaseURI;
  }

  function _baseURI() internal view returns (string memory) {
    return baseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) 
    public onlyOwner 
  {
    baseExtension = _newBaseExtension;
  }

  function mintNEWELF(address to, uint tokenId)
    public 
  {
    require(msg.sender == NANOHUB, "error NANOHUB");
    _mint(to, tokenId);
  }

  function transferFrom(address from, address to, uint tokenId)
    public 
  {
    require(msg.sender == NANOHUB, "error NANOHUB");
    _transfer(from, to, tokenId);
  }

  function exist(uint tokenId)
    public view returns (bool) 
  {
    return owners[tokenId] != address(0);
  }

  function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) 
  {
    return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
  }

  function balanceOf(address owner)
    public view returns (uint) 
  {
    require(address(0) != owner, "error owner");
    return balances[owner];
  }

  function ownerOf(uint id)
    public view returns (address) 
  {
      require(exist(id), "error exist");
      return owners[id];
  }

  function tokenURI(uint256 id)
    public view returns (string memory) 
  {
    require(exist(id), "error exist");
      
    string memory currentBaseURI = _baseURI();

    return
    bytes(currentBaseURI).length > 0
      ? string(
        abi.encodePacked(currentBaseURI, _toString(id), baseExtension)
      )
      : '';
  }

  function _mint(address to, uint id)
    private 
  {
      require(to != address(0), "error to");
      require(owners[id] == address(0), "error owner");

      balances[to]++;
      owners[id] = to;
      totalSupply++;

      emit Transfer(address(0), to, id);
      require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
  }

  function _transfer(address from, address to, uint id)
    private 
  {
      require(exist(id), "error exist");
      require(to != address(0), "error to");
      require(from == ownerOf(id), "error owner");

      balances[from]--;
      balances[to]++;
      owners[id] = to;

      emit Transfer(from, to, id);
      require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
  }

  function _checkOnERC721Received(address from, address to, uint id, bytes memory _data)
    internal returns (bool) 
  {
      uint size;

      assembly {
          size := extcodesize(to)
      }

      if (size > 0)
          try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
              return retval == ERC721TokenReceiver(to).onERC721Received.selector;
          } catch (bytes memory reason) {
              if (reason.length == 0) revert("error ERC721Receiver");
              else assembly {
                      revert(add(32, reason), mload(reason))
                  }
          }
      else return true;
  }

  function _toString(uint value)
    private pure returns (string memory) 
  {
      if (value == 0) return "0";

      uint digits;
      uint tmp = value;

      while (tmp != 0) {
          digits++;
          tmp /= 10;
      }

      bytes memory buffer = new bytes(digits);
      while (value != 0) {
          digits -= 1;
          buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
          value /= 10;
      }

      return string(buffer);
  }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

struct TokenMapState {
  uint256 e1;
  uint256 f2;
}

contract Momentum is ERC721AQueryable, Ownable, ReentrancyGuard, Pausable {
  
  string public baseTokenURI;

  mapping(uint256 => bool) e1Usage;
  mapping(uint256 => bool) f2Usage;
  mapping(uint256 => TokenMapState) tokensMapState;

  ERC721AQueryable E1_CONTRACT;
  ERC721AQueryable F2_CONTRACT;

  constructor(address _e1, address _f2, string memory _baseTokenURI) ERC721A("momentum.", "momentum.")  {
    setContracts(_e1, _f2);
    setBaseURI(_baseTokenURI);
    pause();
  }

  function availableOf(uint256 _tokenId, uint256 _collection) public view returns (bool) {
    if(_collection == 1) {
      return !e1Usage[_tokenId];
    } else {
      return !f2Usage[_tokenId];
    }
  }

  function mapStateOf(uint256 _tokenId) public view returns(TokenMapState memory) {
    return tokensMapState[_tokenId];
  }

  function tokensOfOwner(address _owner, uint256 _collection) external view virtual returns (uint256[] memory) {
    if(_collection == 1) {
      return E1_CONTRACT.tokensOfOwner(_owner);
    } else {
      return F2_CONTRACT.tokensOfOwner(_owner);
    }
  }

  function mint(uint256 _e1, uint256 _f2) public whenNotPaused {
    require(
      E1_CONTRACT.ownerOf(_e1) == msg.sender && F2_CONTRACT.ownerOf(_f2) == msg.sender,
      "Not authorized to mint"
    );
    require(availableOf(_e1, 1) && availableOf(_f2, 2), "Token already used");

    e1Usage[_e1] = true;
    f2Usage[_f2] =  true;
    tokensMapState[_nextTokenId()] = TokenMapState(_e1, _f2);

    _safeMint(msg.sender, 1);
  }

  function airdrop(address _address, uint256 _amount) public onlyOwner {
    _safeMint(_address, _amount);
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setContracts(address _e1, address _f2) public onlyOwner {
    E1_CONTRACT = ERC721AQueryable(_e1);
    F2_CONTRACT = ERC721AQueryable(_f2);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}
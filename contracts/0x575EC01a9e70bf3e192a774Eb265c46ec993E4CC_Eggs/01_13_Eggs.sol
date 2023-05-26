// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract Eggs is ERC721A, ReentrancyGuard, Ownable {
  string public _tokenUriBase;
  State public _state;
  IERC721 public flufAssets;
  uint256[] specialFlufs = [4997, 6820, 6305, 6663, 158, 4485, 7167, 9277];
  mapping(uint256 => bool) public tokenMinted;

  enum State {
    Open,
    Closed
  }

  event Minted(address from, uint256 flufTokenId, uint256 tokenId);

  constructor(address _flufAssets) ERC721A("FLUF World: EGGs", "EGGs") {
    _state = State.Closed;
    flufAssets = IERC721(_flufAssets);
  }

  function updateFlufAssets(address _flufAssets) external onlyOwner {
    flufAssets = IERC721(_flufAssets);
  }

  function setOpen() external onlyOwner {
    _state = State.Open;
  }

  function setClosed() external onlyOwner {
    _state = State.Closed;
  }

  function updateSpecialFlufs(uint256[] calldata _specials) external onlyOwner {
    specialFlufs = _specials;
  }

  function mintToSuperSpecialFlufs() external onlyOwner {
    // Gold and Silver FLUFs
    for (uint256 i = 0; i < specialFlufs.length; i++) {
      address currentOwner = flufAssets.ownerOf(specialFlufs[i]);
      tokenMinted[specialFlufs[i]] = true;
      _safeMint(currentOwner, 1);
    }
  }

  function mintScroogeMcFlufEggs(uint256[] calldata _tokenIds, address to)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokenMinted[_tokenIds[i]] = true;
    }
    _safeMint(to, _tokenIds.length);
  }

  function adminMint(uint256 amount) external onlyOwner {
    require(_state == State.Closed, "claim is still ongoing for public");
    require(totalSupply() + amount <= 10000, "max supply reached");
    _safeMint(msg.sender, amount);
  }

  function mint(uint256[] calldata tokenIds) external nonReentrant {
    require(_state == State.Open, "claim has not started yet");
    require(msg.sender == tx.origin, "contracts cant mint");
    require(tokenIds.length <= 10, "max array length reached");
    require(totalSupply() + tokenIds.length <= 10000, "max supply reached");
    uint256 start = totalSupply();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(!tokenMinted[tokenIds[i]], "token has already minted");
      require(flufAssets.ownerOf(tokenIds[i]) == msg.sender, "not your asset");
      tokenMinted[tokenIds[i]] = true;
      emit Minted(msg.sender, tokenIds[i], start + i);
    }
    _safeMint(msg.sender, tokenIds.length);
  }

  function getFlufMintedStatus(uint256[] calldata tokenIds)
    public
    view
    returns (bool[] memory)
  {
    bool[] memory flufStatus = new bool[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      flufStatus[i] = tokenMinted[tokenIds[i]];
    }
    return flufStatus;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    return string(abi.encodePacked(_tokenUriBase, Strings.toString(tokenId)));
  }

  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    _tokenUriBase = tokenUriBase_;
  }
}
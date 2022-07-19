// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../lib/Controllable.sol";

interface MiniBlockBurnable is IERC721 {
  function burn(uint256[] calldata tokenIds) external;
}

contract MetroPrime is ERC721, Controllable {

  uint256 public constant MAX_BLOCKS = 5_000;
  uint256 public constant BLOCK_ID_OFFSET = 70_000;

  uint256 constant MINIS_PER_PRIME = 10;
  uint256 constant MINI_ID_MASK = 0xffffff;

  address immutable public metroPassAddress;
  address immutable public miniBlockAddress;

  bool public saleActive = false;
  uint256 private _blockIdCounter = BLOCK_ID_OFFSET;

  constructor(address _metroPassAddress, address _miniBlockAddress) ERC721("Metroverse Prime City Block", "METROPRIMEBLOCK") {
    metroPassAddress = _metroPassAddress;
    miniBlockAddress = _miniBlockAddress;
  }

  function startSale() external onlyOwner {
    saleActive = true;
  }

  function stopSale() external onlyOwner {
    saleActive = false;
  }

  function totalSupply() public view returns (uint256 supply) {
      return _blockIdCounter - BLOCK_ID_OFFSET;
  }

  function mint(address to, uint256 packedMiniIds) external onlyController returns (uint256 tokenId) {
    require(saleActive, 'Sale is not active');
    require(totalSupply() < MAX_BLOCKS, 'Exceeded max block count');

    IERC721 metroPass = IERC721(metroPassAddress);
    require(metroPass.balanceOf(to) > 0, "Only MetroPass holders are eligible");

    burnMiniBlocks(to, packedMiniIds);

    tokenId = ++_blockIdCounter;
    _mint(to, tokenId);
  }

  function burnMiniBlocks(address tokenOwner, uint256 packedMiniIds) internal {
    uint256 prevTokenId;
    uint256[] memory tokenIds = new uint256[](MINIS_PER_PRIME);
    MiniBlockBurnable miniBlockNft = MiniBlockBurnable(miniBlockAddress);

    unchecked {
      for (uint256 i; i < MINIS_PER_PRIME; ++i) {
        uint256 tokenId = (packedMiniIds >> 24 * i) & MINI_ID_MASK;
        require(prevTokenId < tokenId, 'no duplicates allowed');
        require(miniBlockNft.ownerOf(tokenId) == tokenOwner, 'Token does not belong to user');
        tokenIds[i] = tokenId;
      }
    }

    miniBlockNft.burn(tokenIds);
  }
}
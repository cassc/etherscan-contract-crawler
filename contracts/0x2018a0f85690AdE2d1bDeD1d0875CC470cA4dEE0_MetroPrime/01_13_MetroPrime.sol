// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "../../lib/enumerable/ERC721.sol";
import "../../lib/Controllable.sol";
import "../../opensea/ContextMixin.sol";

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

  string public baseTokenURI = "https://s3.us-east-2.amazonaws.com/data.metroverse.com/metadata/";

  address public proxyRegistryAddress;
  bool public saleActive = false;

  uint256 private _blockIdCounter = BLOCK_ID_OFFSET;

  constructor(address _metroPassAddress, address _miniBlockAddress, address _proxyRegistryAddress) ERC721("Metroverse Prime City Block", "METROPRIMEBLOCK") {
    metroPassAddress = _metroPassAddress;
    miniBlockAddress = _miniBlockAddress;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
      proxyRegistryAddress = _proxyRegistryAddress;
  }

  function startSale() external onlyOwner {
    saleActive = true;
  }

  function stopSale() external onlyOwner {
    saleActive = false;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenURI;
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
        prevTokenId = tokenId;
      }
    }

    miniBlockNft.burn(tokenIds);
  }

  function isApprovedForAll(address owner, address operator) public view override 
      returns (bool)
  {
      // whitelist OpenSea proxy contract for easy trading.
      if (proxyRegistryAddress != address(0x0)) {
          ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
          if (address(proxyRegistry.proxies(owner)) == operator) {
              return true;
          }
      }

      return isController(operator) || super.isApprovedForAll(owner, operator);
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address _owner) external view 
      returns (uint256[] memory ownerTokens)
  {
      uint256 tokenCount = balanceOf(_owner);

      if (tokenCount == 0) {
          return new uint256[](0);
      } else {
          uint256[] memory result = new uint256[](tokenCount);
          uint256 resultIndex = 0;
          uint256 tokenId;
          uint supply = totalSupply();

          for (tokenId = BLOCK_ID_OFFSET + 1; tokenId <= BLOCK_ID_OFFSET + supply; tokenId++) {
              if (_owners[tokenId] == _owner) {
                  result[resultIndex] = tokenId;
                  resultIndex++;
                  if (resultIndex >= tokenCount) { break; }
              }
          }
          return result;
      }
  }
}
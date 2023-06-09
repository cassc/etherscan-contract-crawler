// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract GenomeBlocks is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  using Strings for uint256;

  constructor
  (string memory customBaseURI_, address accessTokenAddress_, address proxyRegistryAddress_)
    ERC721("GenomeBlocks", "GNBL")
  {
    customBaseURI = customBaseURI_;

    accessTokenAddress = accessTokenAddress_;

    proxyRegistryAddress = proxyRegistryAddress_;

    allowedMintCountMap[owner()] = 1;

    allowedMintCountMap[0x81EF21e7b06382dc1721C06eaf2CFa9fe3e0eC15] = 1;
  }

  /** TOKEN PARAMETERS **/

  struct TokenParameters {
    uint256 seed;
  }

  mapping(uint256 => TokenParameters) private tokenParametersMap;

  function tokenParameters(uint256 tokenId) external view
    returns (TokenParameters memory)
  {
    return tokenParametersMap[tokenId];
  }

  /** ALLOWLIST **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  function allowedMintCount(address minter) public view returns (uint256) {
    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  address public accessTokenAddress;

  uint256 public constant MAX_SUPPLY = 1000;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 50000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256[] calldata ids, TokenParameters[] calldata parameters)
    public
    payable
    nonReentrant
  {
    uint256 count = ids.length;

    if (!saleIsActive) {
      if (allowedMintCount(_msgSender()) >= count) {
        updateMintCount(_msgSender(), count);
      } else {
        require(saleIsActive, "Sale not active");
      }
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.05 ETH per item"
    );

    ERC721 accessToken = ERC721(accessTokenAddress);

    for (uint256 i = 0; i < count; i++) {
      uint256 id = ids[i];

      require(
        accessToken.ownerOf(id) == _msgSender(),
        "Access token not owned"
      );

      _safeMint(_msgSender(), id);

      tokenParametersMap[id] = parameters[i];

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  function setAccessTokenAddress(address accessTokenAddress_) external onlyOwner
  {
    accessTokenAddress = accessTokenAddress_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    TokenParameters memory parameters = tokenParametersMap[tokenId];

    return (
      string(
        abi.encodePacked(
          super.tokenURI(tokenId),
          "?",
          "seed=",
          parameters.seed.toString()
        )
      )
    );
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x81EF21e7b06382dc1721C06eaf2CFa9fe3e0eC15;

  function withdraw() public {
    uint256 balance = address(this).balance;

    payable(owner()).transfer(balance * 40 / 100);

    payable(payoutAddress1).transfer(balance * 60 / 100);
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

// Contract created with Studio 721 v1.1.0
// https://721.so
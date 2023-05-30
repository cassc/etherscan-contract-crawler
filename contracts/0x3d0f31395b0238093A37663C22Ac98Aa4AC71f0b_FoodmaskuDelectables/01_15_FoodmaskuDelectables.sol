// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
/*

   __   ___       ___  __  ___       __        ___  __
  |  \ |__  |    |__  /  `  |   /\  |__) |    |__  /__`
  |__/ |___ |___ |___ \__,  |  /~~\ |__) |___ |___ .__/
 __          ___  __   __   __              __
|__) \ /    |__  /  \ /  \ |  \  |\/|  /\  /__` |__/ |  |
|__)  |     |    \__/ \__/ |__/  |  | /~~\ .__/ |  \ \__/

             Artists Antonius Oki Wiriadjaja,
               farah manley, and tonsoccr.
                     foodmasku.com

                  Development 0x420.io

 */
contract FoodmaskuDelectables is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using ECDSA for bytes32;
  mapping(bytes => uint256) private usedTickets;
  string public baseTokenURI;
  uint256 public startPresaleDate = 1636489800;
  uint256 public startMintDate = 1636497000;
  uint256 public maxSupply = 2000;
  uint256 public mintPrice = 0.06 ether;
  uint256 public presaleMaxMint = 4;
  uint256 public maxPurchaseCount = 20;
  uint256 public totalMinted = 0;
  uint256 public season = 1;
  address private wonka;

  struct TokenBucket {
    uint256 min;
    uint256 max;
    string prefix;
    bool deleted;
  }
  TokenBucket[] public buckets;

  constructor
  (
    string memory name,
    string memory symbol,
    string memory _baseTokenURI,
    uint256 _startPresaleDate,
    uint256 _startMintDate,
    address _wonka
  )
    ERC721(name, symbol)
  {
    baseTokenURI = _baseTokenURI;
    startPresaleDate = _startPresaleDate;
    startMintDate = _startMintDate;
    wonka = _wonka;
  }

  function mint(uint256 numberOfTokens, bytes memory goldenTicket)
    public
    payable
    nonReentrant
  {
    if (startPresaleDate <= block.timestamp &&
        startMintDate > block.timestamp) {
      require(
        numberOfTokens <= presaleMaxMint,
        "FMD: Minting Too Many Presale"
      );
      validateTicket(goldenTicket);
      useTicket(goldenTicket);
    } else {
      require(
        startMintDate <= block.timestamp,
        "FMD: Sale Not Started"
      );
      require(
        numberOfTokens <= maxPurchaseCount,
        "FMD: Minting Too Many"
      );
    }

    require(
      totalMinted + numberOfTokens <= maxSupply,
      "FMD: Sold Out"
    );

    require(
      msg.value >= numberOfTokens * mintPrice,
      "FMD: Insufficient Payment"
    );

    for (uint256 i = 0; i < numberOfTokens; i++) {
      totalMinted = totalMinted + 1;
      _safeMint(msg.sender, totalMinted);
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override returns (string memory)
  {
    require(_exists(tokenId), "FMD: 404");

    string memory prefix = baseTokenURI;
    for (uint256 i = 0; i < buckets.length; i++) {
      if (
        buckets[i].min <= tokenId &&
        buckets[i].max >= tokenId &&
        !buckets[i].deleted
      ) {
        prefix = buckets[i].prefix;
        break;
      }
    }
    return bytes(prefix).length > 0 ? string(abi.encodePacked(prefix, tokenId.toString())) : "";
  }

  function updateSigner(address _wonka) external onlyOwner {
    wonka = _wonka;
  }

  function getHash() internal view returns (bytes32) {
    return keccak256(abi.encodePacked("FoodmaskuDelectables", msg.sender));
  }

  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    return hash.toEthSignedMessageHash().recover(signature);
  }

  function validateTicket(bytes memory goldenTicket)
    internal
    view
  {
    bytes32 hash = getHash();
    address signer = recover(hash, goldenTicket);
    require(usedTickets[goldenTicket] < season, "FMD: Presale Used");
    require(signer == wonka, "FMD: Presale Invalid");
  }

  function useTicket(bytes memory goldenTicket) internal {
    usedTickets[goldenTicket] = season;
  }

  function newSeason(
    uint256 _season,
    uint256 _mintPrice,
    uint256 _maxSupply,
    uint256 _presaleMaxMint,
    uint256 _startPresaleDate,
    uint256 _startMintDate
  ) external onlyOwner {
    season = _season;
    mintPrice = _mintPrice;
    maxSupply = _maxSupply;
    presaleMaxMint = _presaleMaxMint;
    startPresaleDate = _startPresaleDate;
    startMintDate = _startMintDate;
  }

  function setSeason(uint256 _season) external onlyOwner {
    season = _season;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
    presaleMaxMint = _presaleMaxMint;
  }

  function setStartPresaleDate(uint256 _startPresaleDate) external onlyOwner {
    startPresaleDate = _startPresaleDate;
  }

  function setStartMintDate(uint256 _startMintDate) external onlyOwner {
    startMintDate = _startMintDate;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function addBucket(uint256 min, uint256 max, string memory prefix) external onlyOwner {
    require(min < max, "FMD: Min must be less than Max");
    for (uint256 i = 0; i < buckets.length; i++) {
      if (!buckets[i].deleted) {
        require(min > buckets[i].max, "FMD: Overlapping Bucket");
      }
    }
    buckets.push(TokenBucket(min, max, prefix, false));
  }

  function deleteBucket(uint256 index) external onlyOwner {
    buckets[index].deleted = true;
  }

  function withdraw(address payable to) external onlyOwner {
    to.transfer(address(this).balance);
  }

  function withdrawERC20(IERC20 token, address to) external onlyOwner {
    token.transfer(to, token.balanceOf(address(this)));
  }
}
// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoPhunks is Ownable, ERC721Enumerable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  // You can use this hash to verify the image file containing all the phunks
  string public constant imageHash =
    "122dab9670c21ad538dafdbb87191c4d7114c389af616c42c54556aa2211b899";

  constructor() ERC721("CryptoPhunks", "PHUNK") {}

  bool public isSaleOn = false;
  bool public isFreeSaleOn = false;

  // this is to ensure free sale only happens once before real sale starts
  bool public freeSaleHasHappened = false;
  bool public saleHasBeenStarted = false;

  uint256 public constant MAX_MINTABLE_AT_ONCE = 50;

  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;

  function numTotalPhunks() public view virtual returns (uint256) {
    return 10000;
  }

  function maxNumFreeDevPhunks() public view virtual returns (uint256) {
    // max number of phunks we keeping
    return 500;
  }

  function maxNumFreePhunks() public view virtual returns (uint256) {
    // how many phunks that will cost 0.
    // the number we give away will be (700 - however many free dev phunks are minted)
    return 700;
  }

  function mint(uint256 _numToMint) public payable nonReentrant() {
    require(isSaleOn || isFreeSaleOn, "Sale hasn't started.");
    uint256 totalSupply = totalSupply();

    if (isFreeSaleOn) {
      require(
        totalSupply < maxNumFreePhunks(),
        "No more free phunks for sale."
      );
      require(_numToMint == 1, "Can only mint one free phunk.");
      require(
        balanceOf(msg.sender) == 0,
        "Can only receive a free phunk if you don't have a phunk already."
      );
    } else {
      require(
        totalSupply < numTotalPhunks(),
        "All phunks have been sold already."
      );
      require(
        totalSupply + _numToMint <= numTotalPhunks(),
        "There aren't this many phunks left."
      );
      uint256 costForMintingPhunks = getCostForMintingPhunks(_numToMint);
      require(
        msg.value >= costForMintingPhunks,
        "Too little sent, please send more eth."
      );
      if (msg.value > costForMintingPhunks) {
        payable(msg.sender).transfer(msg.value - costForMintingPhunks);
      }
    }

    _mint(_numToMint);
  }

  // internal minting function
  function _mint(uint256 _numToMint) internal {
    require(_numToMint <= MAX_MINTABLE_AT_ONCE, "Minting too many at once.");

    uint256 updatedNumAvailableTokens = _numAvailableTokens;
    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 newTokenId = useRandomAvailableToken(_numToMint, i);
      _safeMint(msg.sender, newTokenId);
      updatedNumAvailableTokens--;
    }
    _numAvailableTokens = updatedNumAvailableTokens;
  }

  function useRandomAvailableToken(uint256 _numToFetch, uint256 _i)
    internal
    returns (uint256)
  {
    uint256 randomNum =
      uint256(
        keccak256(
          abi.encode(
            msg.sender,
            tx.gasprice,
            block.number,
            block.timestamp,
            blockhash(block.number - 1),
            _numToFetch,
            _i
          )
        )
      );

    uint256 randomIndex = randomNum % _numAvailableTokens;

    uint256 valAtIndex = _availableTokens[randomIndex];
    uint256 result;
    if (valAtIndex == 0) {
      // This means the index itself is still an available token
      result = randomIndex;
    } else {
      // This means the index itself is not an available token, but the val at that index is.
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (randomIndex != lastIndex) {
      // Replace the value at randomIndex, now that it's been used.
      // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        // This means the index itself is still an available token
        _availableTokens[randomIndex] = lastIndex;
      } else {
        // This means the index itself is not an available token, but the val at that index is.
        _availableTokens[randomIndex] = lastValInArray;
      }
    }

    _numAvailableTokens--;
    return result;
  }

  function getCostForMintingPhunk(uint256 _numMinted)
    private
    view
    returns (uint256)
  {
    if (isFreeSaleOn) {
      return 0.00 ether;
    } else if (_numMinted < 900) {
      return 0.03 ether;
    } else if (_numMinted < 1500) {
      return 0.05 ether;
    } else if (_numMinted < 3000) {
      return 0.08 ether;
    } else if (_numMinted < 4500) {
      return 0.10 ether;
    } else if (_numMinted < 5900) {
      return 0.15 ether;
    } else if (_numMinted < 7300) {
      return 0.25 ether;
    } else if (_numMinted < 8600) {
      return 0.30 ether;
    } else if (_numMinted < 9300) {
      return 0.45 ether;
    } else if (_numMinted < 9900) {
      return 0.60 ether;
    } else if (_numMinted < 10000) {
      return 0.75 ether;
    }

    return 0.0 ether;
  }

  function getCostForMintingPhunks(uint256 _numToMint)
    public
    view
    returns (uint256)
  {
    require(
      totalSupply() + _numToMint <= numTotalPhunks(),
      "There aren't this many phunks left."
    );

    uint256 _cost;
    uint256 _index;

    for (_index; _index < _numToMint; _index++) {
      _cost += getCostForMintingPhunk(totalSupply() + _index);
    }
    return _cost;
  }

  function getPhunksBelongingToOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 numPhunks = balanceOf(_owner);
    if (numPhunks == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](numPhunks);
      for (uint256 i = 0; i < numPhunks; i++) {
        result[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return result;
    }
  }

  /*
   * Dev stuff.
   */

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory base = _baseURI();
    string memory _tokenURI = Strings.toString(_tokenId);

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(base, _tokenURI));
  }

  // contract metadata URI for opensea
  string public contractURI;

  /*
   * Owner stuff
   */

  function startSale() public onlyOwner {
    require(
      !isFreeSaleOn,
      "Can not start sale while free sale is on. End the free sale first."
    );
    isSaleOn = true;
    saleHasBeenStarted = true;
  }

  function endSale() public onlyOwner {
    isSaleOn = false;
  }

  function startFreeSale() public onlyOwner {
    require(
      !saleHasBeenStarted,
      "Can only start the free sale if the real sale hasn't started yet."
    );
    isFreeSaleOn = true;
  }

  function endFreeSale() public onlyOwner {
    isFreeSaleOn = false;
    freeSaleHasHappened = true;
  }

  // URIs
  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    contractURI = _contractURI;
  }

  function withdrawMoney() public payable onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // special, reserved for devs
  function ownerMint(uint256 _numToMint) public onlyOwner {
    require(
      !isSaleOn && !isFreeSaleOn && !freeSaleHasHappened && !saleHasBeenStarted,
      "Owner mint cannot happen after free sale or real sale has started."
    );

    require(
      balanceOf(msg.sender) < maxNumFreeDevPhunks(),
      "Devs have already minted all available dev phunks."
    );

    // limit the number for minting
    uint256 toMint;
    if (_numToMint < MAX_MINTABLE_AT_ONCE) {
      toMint = _numToMint;
    } else {
      toMint = MAX_MINTABLE_AT_ONCE;
    }

    // mint the max number if possible
    if (balanceOf(msg.sender) + toMint <= maxNumFreeDevPhunks()) {
      _mint(toMint);
    } else {
      uint256 phunksLeftForDevs = maxNumFreeDevPhunks() - balanceOf(msg.sender);
      // else mint as many as possible
      _mint(phunksLeftForDevs);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
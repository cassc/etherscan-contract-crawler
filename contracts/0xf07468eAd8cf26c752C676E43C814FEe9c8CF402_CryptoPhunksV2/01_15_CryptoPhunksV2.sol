// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoPhunksV2 is Ownable, ERC721Enumerable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  // You can use this hash to verify the image file containing all the phunks
  string public constant imageHash =
    "122dab9670c21ad538dafdbb87191c4d7114c389af616c42c54556aa2211b899";

  constructor() ERC721("CryptoPhunksV2", "PHUNK") {}

  bool public isSaleOn = false;

  bool public saleHasBeenStarted = false;

  uint256 public constant MAX_MINTABLE_AT_ONCE = 50;

  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;
  uint256 private _numFreeRollsGiven = 0;

  mapping(address => uint256) public freeRollPhunks;

  uint256 private _lastTokenIdMintedInInitialSet = 10000;

  function numTotalPhunks() public view virtual returns (uint256) {
    return 10000;
  }

  function freeRollMint() public nonReentrant() {
    uint256 toMint = freeRollPhunks[msg.sender];
    freeRollPhunks[msg.sender] = 0;
    uint256 remaining = numTotalPhunks() - totalSupply();
    if (toMint > remaining) {
      toMint = remaining;
    }
    _mint(toMint);
  }

  function getNumFreeRollPhunks(address owner) public view returns (uint256) {
    return freeRollPhunks[owner];
  }

  function mint(uint256 _numToMint) public payable nonReentrant() {
    require(isSaleOn, "Sale hasn't started.");
    uint256 totalSupply = totalSupply();
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
    return useAvailableTokenAtIndex(randomIndex);
  }

  function useAvailableTokenAtIndex(uint256 indexToUse)
    internal
    returns (uint256)
  {
    uint256 valAtIndex = _availableTokens[indexToUse];
    uint256 result;
    if (valAtIndex == 0) {
      // This means the index itself is still an available token
      result = indexToUse;
    } else {
      // This means the index itself is not an available token, but the val at that index is.
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (indexToUse != lastIndex) {
      // Replace the value at indexToUse, now that it's been used.
      // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        // This means the index itself is still an available token
        _availableTokens[indexToUse] = lastIndex;
      } else {
        // This means the index itself is not an available token, but the val at that index is.
        _availableTokens[indexToUse] = lastValInArray;
      }
    }

    _numAvailableTokens--;
    return result;
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
    if (_numToMint == 1) {
      return 0.02 ether;
    } else if (_numToMint == 3) {
      return 0.05 ether;
    } else if (_numToMint == 5) {
      return 0.07 ether;
    } else if (_numToMint == 10) {
      return 0.10 ether;
    } else {
      revert("Unsupported mint amount");
    }
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
    isSaleOn = true;
    saleHasBeenStarted = true;
  }

  function endSale() public onlyOwner {
    isSaleOn = false;
  }

  function giveFreeRoll(address receiver) public onlyOwner {
    // max number of free mints we can give to the community for promotions/marketing
    require(_numFreeRollsGiven < 200, "already given max number of free rolls");
    uint256 freeRolls = freeRollPhunks[receiver];
    freeRollPhunks[receiver] = freeRolls + 1;
    _numFreeRollsGiven = _numFreeRollsGiven + 1;
  }

  // for handing out free rolls to v1 phunk owners
  // details on seeding info here: https://gist.github.com/cryptophunks/7f542feaee510e12464da3bb2a922713
  function seedFreeRolls(
    address[] memory tokenOwners,
    uint256[] memory numOfFreeRolls
  ) public onlyOwner {
    require(
      !saleHasBeenStarted,
      "cannot seed free rolls after sale has started"
    );
    require(
      tokenOwners.length == numOfFreeRolls.length,
      "tokenOwners does not match numOfFreeRolls length"
    );

    // light check to make sure the proper values are being passed
    require(numOfFreeRolls[0] <= 3, "cannot give more than 3 free rolls");

    for (uint256 i = 0; i < tokenOwners.length; i++) {
      freeRollPhunks[tokenOwners[i]] = numOfFreeRolls[i];
    }
  }

  // for seeding the v2 contract with v1 state
  // details on seeding info here: https://gist.github.com/cryptophunks/7f542feaee510e12464da3bb2a922713
  function seedInitialContractState(
    address[] memory tokenOwners,
    uint256[] memory tokens
  ) public onlyOwner {
    require(
      !saleHasBeenStarted,
      "cannot initial phunk mint if sale has started"
    );
    require(
      tokenOwners.length == tokens.length,
      "tokenOwners does not match tokens length"
    );

    uint256 lastTokenIdMintedInInitialSetCopy = _lastTokenIdMintedInInitialSet;
    for (uint256 i = 0; i < tokenOwners.length; i++) {
      uint256 token = tokens[i];
      require(
        lastTokenIdMintedInInitialSetCopy > token,
        "initial phunk mints must be in decreasing order for our availableToken index to work"
      );
      lastTokenIdMintedInInitialSetCopy = token;

      useAvailableTokenAtIndex(token);
      _safeMint(tokenOwners[i], token);
    }
    _lastTokenIdMintedInInitialSet = lastTokenIdMintedInInitialSetCopy;
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
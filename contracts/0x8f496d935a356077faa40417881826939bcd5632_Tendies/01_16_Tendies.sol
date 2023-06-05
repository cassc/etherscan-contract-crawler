// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Tendies is Ownable, ERC721Enumerable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  IERC20 private _apronsToken;

  // Emitting exactly one of these per successful mint tendies transaction
  event ApronsMintedInTransaction(
    address indexed receiver,
    uint256 indexed numAprons
  );

  constructor(address apronsToken) ERC721("Tendies", "TENDIES") {
    _apronsToken = IERC20(apronsToken);
  }

  bool public isSaleOn = false;
  bool public hasOwnerMintOne = false;
  uint256 public numOfSingleMints = 0;
  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;

  function numTotalTendies() public view virtual returns (uint256) {
    return 10000;
  }

  function maxFreeSingleMints() public view virtual returns (uint256) {
    return 200;
  }

  function mintOne() public payable nonReentrant() {
    _mint(1);
    if (numOfSingleMints < maxFreeSingleMints()) {
      numOfSingleMints++;
    }
  }

  function mintFive() public payable nonReentrant() {
    _mint(5);
  }

  function mintTwenty() public payable nonReentrant() {
    _mint(20);
  }

  // internal minting function
  function _mint(uint256 _numToMint) internal {
    require(isSaleOn, "Sale hasn't started.");
    uint256 totalSupply = totalSupply();
    require(
      totalSupply + _numToMint <= numTotalTendies(),
      "There aren't this many tendies left."
    );
    uint256 costForMintingTendies = getCostForMintingTendies(_numToMint);
    require(
      msg.value >= costForMintingTendies,
      "Too little sent, please send more eth."
    );

    uint256 updatedNumAvailableTokens = _numAvailableTokens;
    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 newTokenId = getRandomAvailableToken(_numToMint, i);
      _safeMint(msg.sender, newTokenId);
      updatedNumAvailableTokens--;
    }
    _numAvailableTokens = updatedNumAvailableTokens;

    uint256 contractApronBalance = _apronsToken.balanceOf(address(this));
    if (contractApronBalance > 0) {
      uint256 numAprons = numApronsToMint(_numToMint);
      if (numAprons > contractApronBalance) {
        numAprons = contractApronBalance;
      }
      _apronsToken.transfer(msg.sender, numAprons);
      emit ApronsMintedInTransaction(msg.sender, numAprons);
    } else {
      emit ApronsMintedInTransaction(msg.sender, 0);
    }
  }

  function getRandomAvailableToken(uint256 _numToFetch, uint256 _i)
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
    return getAvailableTokenAtIndex(randomIndex);
  }

  function getAvailableTokenAtIndex(uint256 indexToUse)
    internal
    returns (uint256)
  {
    uint256 valAtIndex = _availableTokens[indexToUse];
    uint256 result;
    if (valAtIndex == 0) {
      result = indexToUse;
    } else {
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (indexToUse != lastIndex) {
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        _availableTokens[indexToUse] = lastIndex;
      } else {
        _availableTokens[indexToUse] = lastValInArray;
      }
    }

    _numAvailableTokens--;
    return result;
  }

  // The probability of an apron occurring on the Nth attempt since
  // the last successful attempt is given as P(N) = C * N. C is a
  // constant derived from the expected probability of the attempt
  // occurring. C serves as both the initial probability of the
  // attempt and the increment by which it increases every time the
  // attempt fails.
  function numApronsToMint(uint256 _numToMint)
    internal
    view
    virtual
    returns (uint256)
  {
    uint256 basisPoints = 10000;
    // c starts out at 23, by total chance for an apron after 20 tries is ~48%
    uint256 initialC = 23;
    uint256 c = initialC;
    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 randomNum =
        uint256(
          keccak256(
            abi.encode(
              msg.sender,
              tx.gasprice,
              block.number,
              block.timestamp,
              blockhash(block.number - 1),
              _numToMint,
              i
            )
          )
        );

      // random number from 0-1000
      uint256 random = randomNum % basisPoints;
      if (random <= c) {
        return 1;
      } else {
        // if user mints 20 and doesn't receive a apron on first 19 tries,
        // c will be 500, giving user 50% at a apron
        c = c + initialC;
      }
    }
    return 0;
  }

  function getCostForMintingTendies(uint256 _numToMint)
    public
    view
    returns (uint256)
  {
    require(
      totalSupply() + _numToMint <= numTotalTendies(),
      "There aren't this many tendies left."
    );
    if (_numToMint == 1) {
      if (numOfSingleMints < maxFreeSingleMints()) {
        return 0.000 ether;
      }
      return 0.040 ether;
    } else if (_numToMint == 5) {
      return 0.195 ether;
    } else if (_numToMint == 20) {
      return 0.760 ether;
    } else {
      revert("Unsupported mint amount");
    }
  }

  function getTendiesBelongingToOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 numTendies = balanceOf(_owner);
    if (numTendies == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](numTendies);
      for (uint256 i = 0; i < numTendies; i++) {
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

  // we will mint the first one for promotional purposes
  function ownerMintOne() public onlyOwner {
    require(!hasOwnerMintOne, "owner has already mint one");
    uint256 newTokenId = getRandomAvailableToken(1, 1);
    _safeMint(msg.sender, newTokenId);
    _numAvailableTokens--;
    hasOwnerMintOne = true;
  }

  function startSale() public onlyOwner {
    isSaleOn = true;
  }

  function endSale() public onlyOwner {
    isSaleOn = false;
  }

  // URIs
  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
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
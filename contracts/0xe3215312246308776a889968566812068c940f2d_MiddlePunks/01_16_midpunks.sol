// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MiddlePunks is Initializable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;

  // You can use this hash to verify the image file containing all the MidPunks in IPFS
  string public constant imageHash =
    "QmZ4Us4RPRvTh8g4k69ghMbjkVZATvMLCgjwFjgt4oGLhp";

  function initialize() initializer public {
      __ERC721_init_unchained("MiddlePunks", "MIDPUNK");
      __Ownable_init_unchained();
  }

  bool public isFreeSaleOn = false;

  uint256 public constant MAX_MINTABLE_AT_ONCE = 50;

  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;

  function numTotalMidPunks() public view virtual returns (uint256) {
    return 10000;
  }

  function maxNumFreeDevMidPunks() public view virtual returns (uint256) {
    // max number of MidPunks The Goblin Master keeps
    return 50;
  }


  function mint(uint256 _numToMint) public nonReentrant() {
    require(isFreeSaleOn, "Free Sale hasn t started.");
    uint256 totalSupply = totalSupply();

    if (isFreeSaleOn) {
      require(
        totalSupply < numTotalMidPunks(),
        "No more free MidPunks for sale."
      );
      require(
        totalSupply + _numToMint <= numTotalMidPunks(),
        "There aren t this many MidPunks left."
      );
      require(_numToMint <= 2, "Can only mint a maximum of two free MidPunks.");
      require(
        balanceOf(msg.sender) <= 1,
        "Can only receive free MidPunks if you don t already have two MidPunks."
      );
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
      // Replace the value at randomIndex, now that it s been used.
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


  function getMidPunksBelongingToOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 numMidPunks = balanceOf(_owner);
    if (numMidPunks == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](numMidPunks);
      for (uint256 i = 0; i < numMidPunks; i++) {
        result[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return result;
    }
  }

  /*
   * Goblin Master stuff.
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
    string memory _tokenURI = StringsUpgradeable.toString(_tokenId);

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

  function startFreeSale() public onlyOwner {
    require(
      !isFreeSaleOn,
      "Free sale has already started."
    );
    isFreeSaleOn = true;
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

  // special, reserved for The Goblin Master
  function ownerMint(uint256 _numToMint) public onlyOwner {
    require(
      !isFreeSaleOn,
      "Owner mint cannot happen after free sale has started."
    );

    require(
      balanceOf(msg.sender) < maxNumFreeDevMidPunks(),
      "Goblin Master have already minted all available dev MidPunks."
    );

    // limit the number for minting
    uint256 toMint;
    if (_numToMint < MAX_MINTABLE_AT_ONCE) {
      toMint = _numToMint;
    } else {
      toMint = MAX_MINTABLE_AT_ONCE;
    }

    // mint the max number if possible
    if (balanceOf(msg.sender) + toMint <= maxNumFreeDevMidPunks()) {
      _mint(toMint);
    } else {
      uint256 MidPunksLeftForDevs = maxNumFreeDevMidPunks() - balanceOf(msg.sender);
      // else mint as many as possible
      _mint(MidPunksLeftForDevs);
    }
  }

}
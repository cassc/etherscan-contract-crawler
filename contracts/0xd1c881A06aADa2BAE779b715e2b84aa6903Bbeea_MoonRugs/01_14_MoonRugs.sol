// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MoonRugs is ERC721Enumerable, Ownable, ReentrancyGuard {
  
  using Strings for uint256;

  constructor() ERC721("MoonRugs", "RUGS") {}

  uint256 private constant MAX_MINTABLE = 10;
  uint256 private constant TOTAL_TOKENS = 10000;

  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;

  mapping(address => uint256) private _addressMinted;

  function mint(uint256 _numToMint) external payable nonReentrant() {
    require(block.timestamp > 1660696969, "Sale hasn't started.");	
	require(msg.sender == tx.origin, "Contracts cannot mint");
	require(msg.sender != address(0), "ERC721: mint to the zero address");	
    require(_numToMint > 0, "ERC721r: need to mint at least one token");
    uint256 totalSupply = totalSupply();
    require(
      totalSupply + _numToMint <= TOTAL_TOKENS,
      "There aren't this many left."
    );
	require(_addressMinted[msg.sender] + _numToMint <= MAX_MINTABLE, "Minting to many.");
    uint256 costForMinting = 0.0069 ether * _numToMint; 
    require(
      msg.value >= costForMinting,
      "Too little sent, please send more eth."
    );
    if (msg.value > costForMinting) {
      payable(msg.sender).transfer(msg.value - costForMinting);
    }

	_addressMinted[msg.sender] += _numToMint;
    _mint(_numToMint);
  }

  // internal minting function
  function _mint(uint256 _numToMint) internal {
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

  function tokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 numTokens = balanceOf(_owner);
    if (numTokens == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](numTokens);
      for (uint256 i = 0; i < numTokens; i++) {
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

  /*
   * Owner stuff
   */

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
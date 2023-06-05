// contracts/PixelPrimates.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PixelPrimates721 is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  event ItemCreated(
    address indexed _owner,
    uint256 _setIndex,
    uint256 _itemId,
    string _primateType,
    uint256 _value
  );
  event PrimateCreated(
    address indexed _owner,
    uint256 indexed _id,
    string _primateType,
    uint256 _value
  );

  string private baseUri;
  bool public allowPrimateMinting = false;
  bool public allowItemMinting = false;
  bool private _isInitialized = false;
  mapping(address => bool) private _whitelistAddr;

  constructor() ERC721("PixelPrimates", "PXPR") {}

  function withdraw() external onlyOwner {
    address payable _owner = payable(owner());
    _owner.transfer(address(this).balance);
  }

  function initialize(string memory baseUri_, address relayContractAddr_)
    external
    onlyOwner
  {
    require(!_isInitialized, "Contract already initialized");
    whitelistAddress(relayContractAddr_);
    setBaseUri(baseUri_);
    // reserve 10 for giveaways and testing
    uint256 mintIndex = totalSupply();
    for (uint256 i = 0; i < 10; i++) {
      _safeMint(owner(), mintIndex + i);
      emit PrimateCreated(owner(), mintIndex + i, "random", 0);
    }
    _isInitialized = true;
  }

  function toggleAllowPrimateMinting() public onlyOwner {
    allowPrimateMinting = !allowPrimateMinting;
  }

  function toggleAllowItemMinting() public onlyOwner {
    allowItemMinting = !allowItemMinting;
  }

  function whitelistAddress(address address_) public onlyOwner {
    _whitelistAddr[address_] = true;
  }

  function setBaseUri(string memory baseUri_) public onlyOwner {
    baseUri = baseUri_;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function checkIfRelayContractIsCalling() private view {
    require(_whitelistAddr[msg.sender], "Must be called from a relay contract");
  }

  function mintPrimates(
    address sender,
    uint256 numberOfTokens,
    string memory primateType
  ) external payable {
    checkIfRelayContractIsCalling();
    require(
      allowPrimateMinting,
      "Minting is currently not available at this time!"
    );
    uint256 mintIndex = totalSupply();
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(sender, mintIndex + i);
      emit PrimateCreated(sender, mintIndex + i, primateType, msg.value);
    }
  }

  function mintItems(
    address sender,
    uint256 numberOfTokens,
    string memory primateType
  ) external payable {
    checkIfRelayContractIsCalling();
    require(
      allowItemMinting,
      "Minting is currently not available at this time!"
    );
    uint256 mintIndex = totalSupply();
    uint256 setIndex = totalSupply();
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(sender, mintIndex + i);
      emit ItemCreated(sender, setIndex, mintIndex + i, primateType, msg.value);
    }
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burnSingle(address sender, uint256 tokenId) public payable {
    checkIfRelayContractIsCalling();
    require(
      _isApprovedOrOwner(sender, tokenId),
      "ERC721Burnable: caller is not owner nor approved"
    );
    _burn(tokenId);
  }

  function burnBatch(address sender, uint256[] memory tokenIds)
    external
    payable
  {
    checkIfRelayContractIsCalling();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      burnSingle(sender, tokenIds[i]);
    }
  }
}
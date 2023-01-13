// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "operator-filter-registry/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Draugr is  ERC721, IERC721Receiver  , OperatorFilterer {


  /* Add minting logic here */

  using Strings for uint256;
  /* Add metadata logic here */
  ERC721Burnable immutable aerin;

  uint256 public tokenId;

  string baseURI;
  mapping(address => uint256) public burnedByAddress;

  error AerinTokensOnly();

  address public deployer;
  constructor(
    address aerin_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) OperatorFilterer(address(0), false)   {
    aerin = ERC721Burnable(aerin_);
    baseURI = "ipfs://QmcQ3V15m24yX9nxs6hDvhWUVqTrHfoadVrTxXmyyHfyfr/";
    deployer = msg.sender;
  }

  /**
   *
   * @dev totalSupply: Return supply without need to be enumerable:
   *
   */
  function totalSupply() external view returns (uint256) {
    return (tokenId);
  }

  /**
   *
   * @dev onERC721Received:
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory
  ) external override returns (bytes4) {
    // Check this is an Aerin!
    if (msg.sender != address(aerin)) {
      revert AerinTokensOnly();
    }

    // Burn the sent token:
    aerin.burn(tokenId_);

    // Increment the user's burn counter:
    burnedByAddress[from_]++;

    // If we have received a multiple of four mint a Draugr
    if ((burnedByAddress[from_] % 4) == 0) {
      // Send Draugr

      // Collection is 1 indexed (i.e. first token will be 1, not 0)
      tokenId++;

      _mint(from_, tokenId);
    }

    return this.onERC721Received.selector;
  }

  function transferFrom(address from, address to, uint256 tokenId)
  public

  override
  onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
  public

  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public

  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setDeployer(address newDeployer) public {
    require(msg.sender == deployer);
    deployer = newDeployer;
  }
  function setBaseURI(string memory uri) public  {
    require(msg.sender == deployer);
    baseURI = uri;

  }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NeverFearTruth
 * @dev Extends ERC721 Non-Fungible Token Standard implementation including the Metadata extension.
 * Supports ERC2981 for royalties distribution.
 */
contract NeverFearTruth is ERC721, Ownable, IERC2981 {
  // Royalty base value 10000 = 100%
  uint256 public constant ROYALTY_BASE = 10000;

  // The max amount of tokens that can be minted. Can't be changed
  uint256 public immutable MAX_SUPPLY;
  // Royalty receiver
  address public immutable ROYALTY_RECEIVER;
  // Royalty percentage with two decimals
  uint256 public immutable ROYALTY_PERCENTAGE;
  // The address of the sale contract that can mint tokens
  address public minter;
  // Keeps track of the total supply of tokens
  uint256 public totalSupply;
  // The base uri for the token uri
  string public baseTokenURI;

  // Event emitted when a new address is set as minter
  event MinterRoleGranted(address indexed account);
  // Event emitted when a new uri is set
  event URISet(string uri);

  /**
   * @dev Initializes the contract by setting a name, a symbol and the max supply of the token collection.
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param maxSupply The max amount of tokens that can be minted
   * @param royaltyReceiver recipient of the royalties
   * @param royaltyPercentage percentage (using 2 decimals - 10000 = 100, 0 = 0)
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 maxSupply,
    address royaltyReceiver,
    uint256 royaltyPercentage
  ) ERC721(name, symbol) {
    require(royaltyReceiver != address(0), "receiver is address zero");
    require(royaltyPercentage <= ROYALTY_BASE, "royalty value too high");
    MAX_SUPPLY = maxSupply;
    ROYALTY_RECEIVER = royaltyReceiver;
    ROYALTY_PERCENTAGE = royaltyPercentage;
  }

  /**
   * @notice Mints a new token to the the receiver. Validates that the max supply has not been reached.
   * Only the minter can call this function.
   * @dev Assigns an auto-incrementing unique `id` starting from 0.
   * @param receiver The address to mint the token to.
   */
  function mint(address receiver) external {
    require(minter == msg.sender, "caller is not the minter");
    uint256 currentSupply = totalSupply;
    require(currentSupply < MAX_SUPPLY, "max supply reached");

    // Use the current total supply as the token id
    _safeMint(receiver, currentSupply);
  }

  /**
   * @dev Assigns a new minter to the contract. Only the owner can call this function.
   * It is intended to use the NFTSale contract as the minter role.
   * Allows to set the minter role to the zero address as a mechanism to pause the minting
   * and/or disable the current minter address.
   * @param newMinter The address of the new minter.
   */
  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
    emit MinterRoleGranted(newMinter);
  }

  /**
   * @dev Sets the base URI for all token IDs. Only the owner can call this function.
   * @param newBaseURI The new base uri
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseTokenURI = newBaseURI;
    emit URISet(newBaseURI);
  }

  /**
   * @dev Interface implementation for the NFT Royalty Standard (ERC-2981).
   * Called by marketplaces that supports the standard with the sale price to determine how much royalty is owed and
   * to whom.
   * The first parameter tokenId (the NFT asset queried for royalty information) is not used as royalties are
   * calculated equally for all tokens.
   * @param salePrice - the sale price of the NFT asset specified by `tokenId`
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for `salePrice`
   */
  function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
    return (ROYALTY_RECEIVER, (salePrice * ROYALTY_PERCENTAGE) / ROYALTY_BASE);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Overrides ERC721 _mint() method. Mints `tokenId` and transfers it to `to` and
   * increases the total supply. This method is called as part of the _safeMint() method
   * before the external call onERC721Received() to the receiver.
   *
   * @param to The address of the receiver
   * @param tokenId The id of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal virtual override {
    super._mint(to, tokenId);

    totalSupply += 1;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }
}
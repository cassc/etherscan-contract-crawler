// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './extensions/Purchasable/SlicerPurchasableConstructor.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/interfaces/IERC2981.sol';
import '@openzeppelin/interfaces/IERC721.sol';
import '@openzeppelin/access/Ownable.sol';
import '@openzeppelin/utils/cryptography/MerkleProof.sol';

/// @title ERC721 contract for Gabriel Haines Merch, integrated with Slice stores
/// @notice ERC721A NFTs, with optional allowlist and nft gating
/// @author jacopo <[email protected]>
contract GabrielHainesMerchDrop is ERC721A, Ownable, SlicerPurchasableConstructor, IERC2981 {
  // =============================================================
  //                          Errors
  // =============================================================

  error Invalid();

  // =============================================================
  //                          Storage
  // =============================================================

  // Max percentage possible for the royalties
  uint256 public constant MAX_ROYALTY = 10_000;
  // Royalties amount
  uint256 public royaltyFraction;
  // Receiver of the royalties
  address public royaltyReceiver;
  // Token metadata uri
  string public uri;
  // ERC721 contracts used for gating
  IERC721[] public _erc721;
  // Merkle root for allowlist
  bytes32 public _merkleRoot;

  // =============================================================
  //                        Constructor
  // =============================================================

  /**
   * @notice Initializes the contract.
   *
   * @param productsModuleAddress_ {ProductsModule} address
   * @param slicerId_ ID of the slicer linked to this contract
   * @param name_ Name of the ERC721 contract
   * @param symbol_ Symbol of the ERC721 contract
   * @param royaltyFraction_ ERC2981 royalty amount, to be divided by 10000
   * @param tokenURI_ URI which is returned as token URI
   * @param owner_ The owner of the contract
   * @param erc721_ Address of the ERC721 contract used for gating
   */
  constructor(
    address productsModuleAddress_,
    uint256 slicerId_,
    string memory name_,
    string memory symbol_,
    uint256 royaltyFraction_,
    string memory tokenURI_,
    address owner_,
    IERC721[] memory erc721_
  ) SlicerPurchasableConstructor(productsModuleAddress_, slicerId_) ERC721A(name_, symbol_) {
    // Override ownable's default owner due to CREATE3 deployment
    _transferOwnership(owner_);

    // set the amount reserved
    royaltyFraction = royaltyFraction_;

    // Set the royaltyRof the royalties
    royaltyReceiver = owner_;

    // Set the uri if provided
    if (bytes(tokenURI_).length != 0) uri = tokenURI_;

    _erc721 = erc721_;
  }

  // =============================================================
  //                   Purchase hook - general
  // =============================================================

  /**
   * @notice Override function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
   */
  function onProductPurchase(
    uint256 slicerId,
    uint256,
    address buyer,
    uint256 quantity,
    bytes memory,
    bytes memory
  ) public payable override onlyOnPurchaseFrom(slicerId) {
    // mint one or a defined quantity of tokens in batch
    _mint(buyer, quantity);
  }

  // =============================================================
  //                Purchase hook - allowlisted
  // =============================================================

  /**
   * @notice Used in onProductPurchaseAllowlisted. See {ISlicerPurchasable}.
   */
  function isPurchaseAllowedAllowlisted(
    uint256,
    uint256,
    address buyer,
    uint256,
    bytes memory,
    bytes memory buyerCustomData
  ) public view returns (bool isAllowed) {
    // Get Merkle proof from buyerCustomData
    bytes32[] memory proof = abi.decode(buyerCustomData, (bytes32[]));

    // Generate leaf from account address
    bytes32 leaf = keccak256(abi.encodePacked(buyer));

    // Check if Merkle proof is valid
    isAllowed = MerkleProof.verify(proof, _merkleRoot, leaf);
  }

  /**
   * @notice Override function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
   */
  function onProductPurchaseAllowlisted(
    uint256 slicerId,
    uint256 productId,
    address buyer,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
  ) public payable onlyOnPurchaseFrom(slicerId) {
    // Check whether the account is allowed to buy a product.
    if (
      !isPurchaseAllowedAllowlisted(
        slicerId,
        productId,
        buyer,
        quantity,
        slicerCustomData,
        buyerCustomData
      )
    ) revert NotAllowed();

    // mint one or a defined quantity of tokens in batch
    _mint(buyer, quantity);
  }

  // =============================================================
  //                Purchase hook - nft gated
  // =============================================================

  /**
   * @notice Used in onProductPurchaseERC721Gated. See {ISlicerPurchasable}.
   */
  function isPurchaseAllowedERC721Gated(
    uint256,
    uint256,
    address buyer,
    uint256,
    bytes memory,
    bytes memory
  ) public view returns (bool) {
    for (uint256 i; i < _erc721.length; ++i) {
      if (_erc721[i].balanceOf(buyer) != 0) return true;
    }
    return false;
  }

  /**
   * @notice Override function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
   */
  function onProductPurchaseERC721Gated(
    uint256 slicerId,
    uint256 productId,
    address buyer,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
  ) public payable onlyOnPurchaseFrom(slicerId) {
    // Check whether the account is allowed to buy a product.
    if (
      !isPurchaseAllowedERC721Gated(
        slicerId,
        productId,
        buyer,
        quantity,
        slicerCustomData,
        buyerCustomData
      )
    ) revert NotAllowed();

    // mint one or a defined quantity of tokens in batch
    _mint(buyer, quantity);
  }

  // =============================================================
  //                         IERC2981
  // =============================================================

  /**
   * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
   * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
   */
  function royaltyInfo(
    uint256,
    uint256 salePrice
  ) external view override returns (address _receiver, uint256 _royaltyAmount) {
    // return the receiver from storage
    _receiver = royaltyReceiver;

    // calculate and return the _royaltyAmount
    _royaltyAmount = (salePrice * royaltyFraction) / MAX_ROYALTY;
  }

  // =============================================================
  //                      IERC721Metadata
  // =============================================================

  /**
   * @dev See {ERC721A}
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    // check if the token exists, otherwise revert
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return uri;
  }

  // =============================================================
  //                    Safe batch transfer
  // =============================================================

  /**
   * @dev Transfer tokens in batch
   *
   */
  function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds) external {
    // loop through the tokenIds and perform a single transfer
    for (uint256 i; i < tokenIds.length; ) {
      safeTransferFrom(from, to, tokenIds[i]);

      unchecked {
        ++i;
      }
    }
  }

  // =============================================================
  //                      External setter
  // =============================================================

  /**
   * @dev Set merkle root for allowlist, only Owner is allowed
   *
   */
  function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    _merkleRoot = merkleRoot_;
  }

  /**
   * @dev Set royalty receiver and fraction to be paid, only Owner is allowed
   *
   */
  function setRoyaltyInfo(address receiver_, uint256 royaltyFraction_) external onlyOwner {
    // check if the royaltyFraction_ is above the limit, if so revert
    if (royaltyFraction_ > MAX_ROYALTY) revert Invalid();

    royaltyReceiver = receiver_;
    royaltyFraction = royaltyFraction_;
  }

  /**
   * @dev Set token URI, only Owner is allowed
   *
   */
  function setTokenURI(string memory uri_) external onlyOwner {
    uri = uri_;
  }

  // =============================================================
  //                           IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721A, IERC165) returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
  }
}
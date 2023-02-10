// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../extensions/Purchasable/SlicerPurchasableConstructor.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * ERC721AMint purchase hook.
 */
contract ERC721AMintImmutable is ERC721A, IERC2981, SlicerPurchasableConstructor {
    // =============================================================
    //                          Errors
    // =============================================================

    error Invalid();

    // =============================================================
    //                           Storage
    // =============================================================

    uint256 public constant MAX_ROYALTY = 10_000;
    uint256 public immutable royaltyFraction;
    address public immutable royaltyReceiver;
    string public baseURI_;
    string public tokenURI_;

    // =============================================================
    //                         Constructor
    // =============================================================

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     * @param name_ Name of the ERC721 contract
     * @param symbol_ Symbol of the ERC721 contract
     * @param royaltyReceiver_ ERC2981 royalty receiver address
     * @param royaltyFraction_ ERC2981 royalty amount, to be divided by 10000
     * @param baseURI__ URI which concatenated with token ID forms the token URI
     * @param tokenURI__ URI which is returned as token URI
     */
    constructor(
        address productsModuleAddress_,
        uint256 slicerId_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyFraction_,
        string memory baseURI__,
        string memory tokenURI__
    ) SlicerPurchasableConstructor(productsModuleAddress_, slicerId_) ERC721A(name_, symbol_) {
        if (royaltyFraction_ > MAX_ROYALTY) revert Invalid();

        royaltyReceiver = royaltyReceiver_;
        royaltyFraction = royaltyFraction_;
        if (bytes(baseURI__).length != 0) baseURI_ = baseURI__;
        else if (bytes(tokenURI__).length != 0) tokenURI_ = tokenURI__;
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev See {ERC721A}
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : tokenURI_;
    }

    /**
     * @dev See {ERC721A}
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    // =============================================================
    //                            IERC2981
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
    //                         Purchase hook
    // =============================================================

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256,
        address buyer,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) public payable override onlyOnPurchaseFrom(slicerId) {
        // Mint tokens
        _mint(buyer, quantity);
    }

    // =============================================================
    //                            IERC165
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
    ) public view virtual override(ERC721A, IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./Mintable.sol";
import "./interfaces/EIP2981.sol";

contract Asset is DefaultOperatorFilterer, ERC721, EIP2981, Mintable {
    // base URI for token metadata
    string private baseURI;

    // royalty fee for secondary sales, 2000 means 20%
    uint16 public royaltyFraction;

    // Address to receive EIP-2981 royalties from secondary sales
    address public royaltyReceiver;

    error RoyaltyFractionOverflow();
    error ZeroAddress();

    event BaseURIUpdated(string newBaseURI);
    event RoyaltyFractionUpdated(uint16 newRoyaltyFraction);
    event RoyaltyReceiverUpdated(address newRoyaltyReceiver);

    /**
     * @param owner_ owner of the contract
     * @param name_ name of the token
     * @param symbol_ symbol of the token
     * @param baseURI_ baseURI of the token
     * @param imx_ address of the IMX contract
     * @param royaltyReceiver_ address of the royalties receiver
     * @param royaltyFraction_ royalty fraction for secondary sales, 2000 means 20%
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address imx_,
        address royaltyReceiver_,
        uint16 royaltyFraction_
    ) ERC721(name_, symbol_) Mintable(owner_, imx_) {
        if (address(owner_) == address(0) || address(imx_) == address(0)) {
            revert ZeroAddress();
        }
        transferOwnership(owner_);
        setBaseURI(baseURI_);
        imx = imx_;
        setRoyaltyReceiver(royaltyReceiver_);
        setRoyaltyFraction(royaltyFraction_);
    }

    /**
     * @dev See {Mintable-_mintFor}.
     */
    function _mintFor(
        address to,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(to, id);
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {ERC721-setApprovalForAll}.
     * 
     * The only difference is onlyAllowedOperatorApproval modifier coming from operator-filter-registry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {ERC721-approve}.
     * 
     * The only difference is onlyAllowedOperatorApproval modifier coming from operator-filter-registry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {ERC721-transferFrom}.
     * 
     * The only difference is onlyAllowedOperator modifier coming from operator-filter-registry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     * 
     * The only difference is onlyAllowedOperator modifier coming from operator-filter-registry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     * 
     * The only difference is onlyAllowedOperator modifier coming from operator-filter-registry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Allows the owner to update base URI.
     *
     * @param newBaseURI new baseURI
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev Allows the owner to update royalty fraction.
     *
     * @param newRoyaltyFraction new royalty fraction
     */
    function setRoyaltyFraction(uint16 newRoyaltyFraction) public onlyOwner {
        if (newRoyaltyFraction > 10000) {
            revert RoyaltyFractionOverflow();
        }
        royaltyFraction = newRoyaltyFraction;
        emit RoyaltyFractionUpdated(newRoyaltyFraction);
    }

    /**
     * @dev Allows the owner to update royalty receiver.
     *
     * @param newRoyaltyReceiver new royalty receiver
     */
    function setRoyaltyReceiver(address newRoyaltyReceiver) public onlyOwner {
        if (address(newRoyaltyReceiver) == address(0)) {
            revert ZeroAddress();
        }
        royaltyReceiver = newRoyaltyReceiver;
        emit RoyaltyReceiverUpdated(newRoyaltyReceiver);
    }

    /**
     * @dev We use global fixed price for all the tokens.
     * 
     * @inheritdoc EIP2981
     */
    function royaltyInfo(uint256, uint256 _salePrice) public view virtual override returns (address, uint256) {
        return (royaltyReceiver, _salePrice * royaltyFraction / 10000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(EIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override to avoid accidental renouncing ownership.
     */
    function renounceOwnership() public virtual override {}
}
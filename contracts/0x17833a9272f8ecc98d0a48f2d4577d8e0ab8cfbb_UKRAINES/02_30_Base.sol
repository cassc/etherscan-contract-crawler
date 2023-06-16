// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@erc721a/extensions/ERC721AQueryable.sol";

import "@openzeppelin/token/common/ERC2981.sol";

import "@openzeppelin/access/Ownable.sol";

import "@operator-filter-registry/RevokableDefaultOperatorFilterer.sol";
import "@operator-filter-registry/UpdatableOperatorFilterer.sol";

import "../interfaces/IERC4906.sol";

import "./SignatureCheck.sol";
import "./ErrorsAndEvents.sol";
import "./Structs.sol";

contract Base is
    ErrorsAndEvents,
    Structs,
    ERC721AQueryable,
    SignatureCheck,
    IERC4906,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    address private _receiver;

    string private _baseTokenURI;

    uint16 public currentThread = 0;

    mapping(uint => Curio) private _curios;

    mapping(address => bool) private _soulboundExempt;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory uri_
    ) ERC721A(name_, symbol_) SignatureCheck(name_, signer_) {
       _setURI(uri_);
    }

    // ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████
    // ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██
    // ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████
    // ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██
    // ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████

    
   modifier checkSupply(uint256 howMany) {
        if(_totalMinted() + howMany > 3_333 - 666) {
            revert ExceedsMaxSupply();
        }
        _;
   }

    //  █████  ██████  ███    ███ ██ ███    ██
    // ██   ██ ██   ██ ████  ████ ██ ████   ██
    // ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██
    // ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██
    // ██   ██ ██████  ██      ██ ██ ██   ████

    function setSigner(address signer_) external payable onlyOwner {
        _setSigner(signer_);
    }

   

    function setURI(string calldata uri_) external payable onlyOwner {
        _setURI(uri_);
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
    }

    function _setURI(string memory uri_) internal {
        _baseTokenURI = uri_;
    }



    //  ██████  ███████ ████████ ████████ ███████ ██████  ███████
    // ██       ██         ██       ██    ██      ██   ██ ██
    // ██   ███ █████      ██       ██    █████   ██████  ███████
    // ██    ██ ██         ██       ██    ██      ██   ██      ██
    //  ██████  ███████    ██       ██    ███████ ██   ██ ███████

    

    //  ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████
    // ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██
    // ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████
    // ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██
    //  ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████
    //
    // Functions that override ERC-standards, primarily for the OS Operator Filter
    // and soulbound tokens

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, IERC165, ERC2981) returns (bool) {
        return interfaceId == bytes4(0x49064906) || // ERC-4906
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    
    // ███████ ██ ███    ██  █████  ███    ██  ██████ ███████ ███████
    // ██      ██ ████   ██ ██   ██ ████   ██ ██      ██      ██
    // █████   ██ ██ ██  ██ ███████ ██ ██  ██ ██      █████   ███████
    // ██      ██ ██  ██ ██ ██   ██ ██  ██ ██ ██      ██           ██
    // ██      ██ ██   ████ ██   ██ ██   ████  ██████ ███████ ███████

    function withdraw() public payable {
        (bool sent, bytes memory data) = payable(_receiver).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public payable onlyOwner {
        _receiver = receiver;
        _setDefaultRoyalty(_receiver, feeNumerator);
    }
}
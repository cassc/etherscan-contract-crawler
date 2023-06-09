// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./base/ERC721Enumerable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITokenURI.sol";
import "./interfaces/IBandSaurus.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract BandSaurus is IBandSaurus,  RevokableDefaultOperatorFilterer, ERC2981, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    ITokenURI public tokenuri;
    uint256 public maxSupply = 365;

    // An address who has permissions to mint
    address public minter;

    // The internal token ID tracker
    uint256 private _currentTokenId = 1;

    string public baseURI = "https://metadata.ctdao.io/bs/";
    string public baseExtension = ".json";


    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }


    constructor() ERC721('BAND SAURUS', 'SAURUS') {
        _setDefaultRoyalty( owner(), 1000 );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if(address(tokenuri) == address(0)){
            return string(abi.encodePacked(baseURI, tokenId.toString(),baseExtension));
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Mint a BandSaurus to the minter.
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        require(_currentTokenId <= maxSupply  , 'can not mint, over max size');
        return _mintTo(minter, _currentTokenId++);
    }

    /**
     * @notice Burn a BandSaurus.
     */
    function burn(uint256 tokenId) public override onlyMinter {
        _burn(tokenId);
        emit BandSaurusBurned(tokenId);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner.
     */
    function setMinter(address _minter) external override onlyOwner {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    function setMaxSupply(uint256 _maxSupply) external override onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Mint a BandSaurus with `tokenId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 tokenId) internal returns (uint256) {

        _mint(owner(), to, tokenId);
        emit BandSaurusCreated(tokenId);

        return tokenId;
    }

    // ERC2981 section
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // opensea section
        /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract LancetPasscard is
    ERC721AQueryable,
    OperatorFilterer,
    Ownable,
    ERC2981
{

    using Strings for uint256;
    // =========================================================================
    //                                Storage
    // =========================================================================

    bool public operatorFilteringEnabled;

    string  public baseURI;
   
    address public controller;

    uint256 public maxSupply = 777;
    uint256 public totalMinted;

    // =========================================================================
    //                               Constructor
    // =========================================================================

    constructor(string memory name, string memory symbol) ERC721A (name, symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        
        //Creator earnings 0.5%
        _setDefaultRoyalty(msg.sender, 950);
    }


    // =========================================================================
    //                                 Function
    // =========================================================================

    function mint(address recipient) external{
        require(msg.sender == controller,"Only Controller Allowed");
        require(totalMinted < maxSupply,"Sold out");
        totalMinted ++;
        _safeMint(recipient,1);
    }

    function mintZeroPass() onlyOwner external{
        require(totalSupply() == 0);
        _safeMint(msg.sender,1);
    }

    function burnZeroPass() onlyOwner external{
        _burn(0);
    }

    function setController(address _controller) external onlyOwner{
       controller = _controller;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A,ERC721A) returns(string memory){
        require(_exists(tokenId));
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setBaseURI(string memory uri) external onlyOwner{
        baseURI = uri;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory){
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256){
        return 0;
    }

    // =========================================================================
    //                               Operator filter
    // =========================================================================

    /**
     * @notice Global approval for given operator
     * @param operator - address of operator
     * @param approved - true | false
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Operator approval for a given tokenId
     * @param operator - address of operator
     * @param tokenId - tokenId to grant approval for
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Safe transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Safe transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     * @param data - additional bytes data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Check that various interfaces are supported
     * @param interfaceId - id of interface to check
     * @return bool for support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Set royalties for all tokens.
     * @param receiver - Address receiving royalties.
     * @param feeNumerator - Fee as Basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set operator filtering on or off
     * @param value - desired state value
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * @notice Internally check operator filter state
     * @return state as boolean
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @notice Internally check if operator is priority
     * @return priority as boolean
     */
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
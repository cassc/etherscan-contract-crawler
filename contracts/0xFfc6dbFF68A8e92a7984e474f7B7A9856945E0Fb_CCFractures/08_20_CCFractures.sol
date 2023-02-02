//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&          &&&&&&&&&&&&&&&&&&&&&&&          &&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&    &&&&&&&&%    &&&&&&&&&&&&&&&    %&&&&&&&&    &&&&&&&&&&&&&&&
//&&&&&&&&&&&&&   &&&       &&&&   &&&&&&&&&&&   &&&&       &&&   (&&&&&&&&&&&&&
//&&&&&&&&&&&&  &&&            &&&   &&&&&&&   &&&            &&&  &&&&&&&&&&&&&
//&&&&&&&&&&&   &&              &&&   &&&&&   &&&              &&   &&&&&&&&&&&&
//&&&&&&&&&&&  &&&                &&,       /&&                &&&  &&&&&&&&&&&&
//&&&&&&&&&&   &&(                /&&&&&&&&&&&/                #&&   &&&&&&&&&&&
//&&&&&&&&&&   &&                #             #                &&   &&&&&&&&&&&
//&&&&&&&&&&   ,.                                                    &&&&&&&&&&&
//&&&&&&&&&&   %                                                 #   &&&&&&&&&&&
//&&&&&&&&&   &&&                                               &&&   &&&&&&&&&&
//&&&&&&&&&  %&&                                                 &&&  &&&&&&&&&&
//&&&*       &&&       &&&&&                         &&&&&       &&&       &&&&&
//&&&  &&&&&&&&       &&   &&&                     &&&   &&       &&&&&&&,  &&&&
//&&&&      &&&      &&&   &&&   &&&&&&&&&&&&&&&   &&%   &&%      &&&      &&&&&
//&&&   &&&&&&&       &&   &&&  &&&&&&&&&&&&&&&&&  &&&  &&&       &&&&&&   &&&&&
//&&&&       &&&       ,&&&&     &&&         &&&%    &&&&&       &&&       &&&&&
//&&&&&&&&&   &&&                  &&&&&&&&&&&                  &&&   &&&&&&&&&&
//&&&&&&&&&&   #&&&                                           &&&   /&&&&&&&&&&&
//&&&&&&&&&&&&    &&&                                      &&&&    &&&&&&&&&&&&&
//&&&&&&&&&&&&&&&   .&&&&                               &&&&    &&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&&    *&&&&&&                   &&&&&&*    &&&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                   (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//FOUR CATACLYSMIC EVENTS ON THE SAME DAY.........I SHOULD HAVE PREDICTED THIS&&
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './InventoryAccessControl.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract CCFractures is
    ERC721A,
    InventoryAccessControl,
    ERC721AQueryable,
    ERC721ABurnable,
    DefaultOperatorFilterer,
    ERC2981
{
    //Uniform Resource Identifier (URI) for `tokenId` token.
    string public baseURI;

    //contractURI uri of contract metadata
    string public contractURI;

    /**
     * Constructor.
     * @param _name the name of the ERC721A token.
     * @param _symbol the symbol to represnt the token.
     * @param baseURI_ the base URI of the token.
     * @param _royaltyFeesInBips royalty fee percentage * 100 (if royalty fee is 5% , _royaltyFeesInBips = 5 *100 = 500)
     * @param _receiver addres of the roylaty receiver
     * @param contractURI_ uri of contract metadata
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        uint96 _royaltyFeesInBips,
        address _receiver,
        string memory contractURI_
    ) ERC721A(_name, _symbol) InventoryAccessControl() {
        baseURI = baseURI_;
        setRoyaltyInfo(_receiver, _royaltyFeesInBips);
        contractURI = contractURI_;
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `_beneficiary`.
     *
     * Requirements:
     *  -minter address must have minter role
     *  -pause status must be false
     * Emits a {Transfer} event for each mint.
     */

    function mint(address _beneficiary, uint256 quantity) public onlyMinter {
        _safeMint(_beneficiary, quantity);
    }

    /**
     * @dev Public function with onlyOwner role to change the baseURI value
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**@dev get the baseURI*/

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**@dev sets the royalty info
     * @param _receiver receiver of the roylaties
     * @param _royaltyFeesInBips  royalty fee percentage * 100
     */

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    /**@dev sets the contractURI
     * @param _newContractURI uri of contract metadata
     */

    function setContractURI(string calldata _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    /**
     * @dev override the function by adding `whenNotPaused` modifier
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {}

    /**
     * @dev Check Interface of ERC721A
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**@dev overide with onlyAllowedOperatorApproval for opensea royalty */

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
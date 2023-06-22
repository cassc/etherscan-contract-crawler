// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                                    *########/
//                              ,(#################(/
//                           /#########################(
//                        .((((((((#(##((((#((#((((#(###(((,
//                      /#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#((
//                   .((((((((((((((((((((((((((((((((((((((((((,
//                 /((((((((((((((((((((((((((((((((((((((((((((((.
//               ,((((((((((((((((((((((((((((((((((((((((((((((((((*
//              /(((((((((((((((((((((((((((((((((((((((((((((((((((((.
//            (((((((((((((((((((((((((((((((((((((((((((((((((((((((((/
//          ,((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((*
//         /((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((/.
//       .((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((.
//      ((/**,,,**/((((((((((((((((((((((((((((((((((((((((((((((((((((((((((*
//     **,,,,,,,,,,,,,*/(((((((((((((((((((((((((((((((((((((((((((((((((((((((
//    ,,,,,,,,,,,,,,,,,,,,*/(((((((((((((((((((((((((((((((((((((((((((((((((((/
//   .,,,,,,,,,,,,,,,,,,,,,,,*/(((((((((((((((((((((((((((((((((((((((((((((((((*
//  .,,,,,,,,,,,,,,,,,,,,,,,,,,,*/(((((((((((((((((((((((((((((((((((((((((((((((.
//  ********************************/(((((((((((((((((((((((((((((((((((((((((((((
// ***********************************/((((((((((((((((((((((((((((((((((((((((((((
// **************************************/(((((((((((((((((((((((((((((((((((((((((
// **************************************, ,/((((((((((((((((((((((((((((((((((((((
// ************************************       /((((((((((((((((((((((((((((((((((((
// *********************************,            ,((((((((((((((((((((((((((((((((/
//  ////////////////////////////*.                   ((((((((((((((((((((((((((((/
//   /////////////////////////                          /(((((((((((((((((((((((,
//     */////////////////                                    /((((((((((((((((
//
// Aerial Explorers - Helping Fight Climate Change
// https://aerialexplorers.xyz/

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@mintdrop/contracts/minting/AllowListMintable.sol";
import "@mintdrop/contracts/minting/PublicMintable.sol";
import "@mintdrop/contracts/extensions/Metadata.sol";
import "@mintdrop/contracts/extensions/Royalties.sol";
import "@mintdrop/contracts/extensions/MaxSupply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AerialExplorers is
    ERC721A,
    AllowListMintable,
    PublicMintable,
    Metadata,
    MaxSupply,
    Royalties,
    Ownable,
    Pausable,
    DefaultOperatorFilterer
{
    constructor(
        string memory _baseTokenURI,
        address _beneficiary,
        uint96 _bips,
        address _allowList
    )
        ERC721A("Aerial Explorers Launcher", "AEX")
        PublicMintable(
            PublicMintable.Config({
                enabled: true,
                mintPrice: 0,
                startTime: 1674237600,
                endTime: 0,
                maxPerWallet: 1
            })
        )
        AllowListMintable()
        MaxSupply(5000)
        Metadata(_baseTokenURI)
        Royalties(_beneficiary, _bips)
    {
        _addList(
            AllowList.ListConfig({
                signer: _allowList,
                mintPrice: 0,
                startTime: 1674230400,
                endTime: 0,
                maxPerWallet: 1
            })
        );
    }

    /**
     * @dev abstract functions required for implementation
     */

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _mint(address to, uint256 quantity)
        internal
        override(ERC721A, Mintable)
        whenNotPaused
        wontExceedMaxSupply(quantity)
    {
        ERC721A._mint(to, quantity);
    }

    function _mintCount(address owner)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return ERC721A._numberMinted(owner);
    }

    function _totalSupply() internal view virtual override returns (uint256) {
        return ERC721A._totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return Metadata.baseTokenURI;
    }

    /**
     * @dev owner controls on contract
     */

    function setRoyalties(address _beneficiary, uint96 _bips) public onlyOwner {
        _setDefaultRoyalty(_beneficiary, _bips);
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _setBaseTokenURI(_uri);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function ownerMint(address _to, uint256 _quantity)
        external
        onlyOwner
        wontExceedMaxSupply(_quantity)
    {
        _mint(_to, _quantity);
    }

    /**
     * @dev OpenSea Operator filtering (https://github.com/ProjectOpenSea/operator-filter-registry#readme)
     */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev override both ERC721A and ERC2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
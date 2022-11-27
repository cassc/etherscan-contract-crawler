//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@promos/contracts/Promos.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {DefaultOperatorFilterer} from "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";

/*

This smart-contract is powered by GOMINT and Promos.
https://gomint.art
https://promos.wtf

*/

contract Konbini is
    Ownable,
    ERC721A,
    Promos,
    PaymentSplitter,
    DefaultOperatorFilterer
{
    using SafeMath for uint256;

    bool public publicMint;
    bool public promosMint;

    string public baseTokenURI;

    uint256 public maxSupply = 100;
    uint256 public maxPerWallet = 10;
    uint256 public maxPerTransaction = 10;
    uint256 public price = 0.09 ether;

    uint256[] private _shares = [97, 3];
    address[] private _shareholders = [
        0xEf25Db6F8BfA2a8cF7c712Ea2fE8fFC170f7bbC2,
        0xBE8106153690192865E6b601f92671b93A1fb498
    ];

    constructor()
        ERC721A("Konbini", "Konbini")
        Promos(10, promosProxyContractMainnet)
        PaymentSplitter(_shareholders, _shares)
    {}

    // Mint functions

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        _safeMint(_to, _amount);
    }

    function mintPublic(uint256 _amount) external payable {
        uint256 requiredPrice = price.mul(_amount);
        require(publicMint, "Public mint turned off");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(_amount <= maxPerTransaction, "Max per transaction");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        _safeMint(msg.sender, _amount);
    }

    function mintPromos(address _to, uint256 _amount)
        external
        payable
        override
        MintPromos(_to, _amount)
    {
        require(promosMint, "Promos mint turned off");
        require(_amount <= maxPerTransaction, "Max per transaction");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        _safeMint(_to, _amount);
    }

    // ETH withdrawal

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function withdraw(address _receiver, uint256 _amount)external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    // Setters

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }

    function setPromosMint(bool _promosMint) external onlyOwner {
        promosMint = _promosMint;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction)
        external
        onlyOwner
    {
        maxPerTransaction = _maxPerTransaction;
    }

    // Overrides

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, Promos)
        returns (bool)
    {
        return
            Promos.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable override(IPromos, PaymentSplitter) {}

    /**
     * @notice This contract is configured to use the DefaultOperatorFilterer, which automatically registers the
     *         token and subscribes it to OpenSea's curated filters. Adding the onlyAllowedOperator modifier to the
     *         transferFrom and both safeTransferFrom methods ensures that the msg.sender (operator) is allowed by the
     *         OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval modifier to the approval methods ensures
     *         that owners do not approve operators that are not allowed.
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
}
// SPDX-License-Identifier: MIT

/// @title: ThePePunks
/// @creator: ArmTheGray

       ///////////////////////////////////////////////////////////////
      //        ____       ____              __ _______            //
     //        / __ \___  / __ \__  ______  / //_/ ___/           //
    //        / /_/ / _ \/ /_/ / / / / __ \/ ,<  \__ \           //
   //        / ____/  __/ ____/ /_/ / / / / /| |___/ /          //
  //        /_/    \___/_/    \__,_/_/ /_/_/ |_/____/          //
 //    "Nos esse quasi nanos gigantium humeris insidentes."   //
///////////////////////////////////////////////////////////////


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./src/DefaultOperatorFilterer.sol";

contract Pepunk is ERC721, Ownable, IERC2981, DefaultOperatorFilterer {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 9696;
    /// for devs
    uint256 private constant TOKENS_RESERVED = 1000;
    uint256 public price = 4206900000000000;
    uint256 public constant MAX_MINT_PER_TX = 1;
    uint256 public constant ROYALTY_PRECISION = 100;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;
    mapping(uint256 => address payable) public tokenRoyaltyReceiver;
    uint256 public royaltyPercentage = 7; // 7%

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("ThePePunks", "69") {
        baseUri = "ipfs://QmfNX3v9MP98Fxt9HPkp9ygXf21y2jXXeYXZxbXqyyA121/";
       
    }

    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(_numTokens <= MAX_MINT_PER_TX, "1 for Wallet my friend.");
        require(
            mintedPerWallet[msg.sender] + _numTokens <= 1,
            "Dont be greedy my friend 1 for wallet."
        );
        uint256 curTotalSupply = totalSupply;
        require(
            curTotalSupply + _numTokens <= MAX_TOKENS,
            "Exceeds total supply."
        );
        require(_numTokens * price <= msg.value, "Insufficient funds.");

        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

       function reserveTokens() external onlyOwner {
        require(totalSupply + TOKENS_RESERVED <= MAX_TOKENS, "Exceeds total supply.");

        for (uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, totalSupply + i);
        }
        totalSupply += TOKENS_RESERVED;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRoyaltyPercentage(uint256 _percentage) external onlyOwner {
        royaltyPercentage = _percentage;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
{
    receiver = 0xD178fAd2a27F98a8f5513cFaB2785c62f3E80C2f;
    royaltyAmount = (_salePrice.mul(royaltyPercentage)).div(ROYALTY_PRECISION);
}

      function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = (balance * 50) / 100;
        uint256 balanceTwo = balance - balanceOne;

        require(balanceOne > 0 && balanceTwo > 0, "Insufficient balance for withdrawal.");

        (bool transferOne, ) = payable(0xAcd3462e07a001E2513aFE2C189c52955C292233).call{value: balanceOne}("");
        require(transferOne, "Transfer to first address failed.");

        (bool transferTwo, ) = payable(0xAcd3462e07a001E2513aFE2C189c52955C292233).call{value: balanceTwo}("");
        require(transferTwo, "Transfer to second address failed.");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

     // Enforcer functions


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
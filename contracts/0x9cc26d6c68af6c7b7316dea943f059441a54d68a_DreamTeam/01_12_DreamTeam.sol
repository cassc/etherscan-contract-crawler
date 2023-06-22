// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract DreamTeam is ERC721, Ownable {
    using SafeMath for uint256;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    string public TOKEN_PROVENANCE = "";

    uint256 public constant TOKEN_PRICE = 0;

    uint256 public constant MAX_TOKENS_PURCHASE_PER_WALLET = 2;

    uint256 public constant MAX_TOKENS = 9999;

    bool public saleIsActive = true;

    uint256 public totalSupply = 0;

    string private _baseURIextended =
        "https://us-central1-nfts-325111.cloudfunctions.net/DreamTeam";

    function withdraw(address founder1, address founder2) public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 founder1Portion = balance / 2;
        uint256 founder2Portion = balance - founder1Portion;
        payable(founder1).transfer(founder1Portion);
        payable(founder2).transfer(founder2Portion);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        TOKEN_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function tokensAmountOfOwner(address _owner)
        external
        view
        returns (uint256)
    {
        uint256 tokenCount = balanceOf(_owner);
        return tokenCount;
    }

    function mintToken(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a token");
        require(
            this.tokensAmountOfOwner(msg.sender).add(numberOfTokens) <=
                MAX_TOKENS_PURCHASE_PER_WALLET,
            "You can only mint 2 tokens"
        );
        require(
            totalSupply.add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= TOKEN_PRICE.mul(numberOfTokens),
            "Ether value sent is not correct"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply;
            if (mintIndex < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                totalSupply++;
            }
        }
    }
}
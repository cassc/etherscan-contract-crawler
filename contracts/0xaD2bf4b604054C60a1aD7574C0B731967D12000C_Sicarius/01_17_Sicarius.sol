// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

contract Sicarius is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint public MINT_PRICE;
    uint public TOTAL_SUPPLY;
    uint public CURRENT_SUPPLY;
    bool public isSaleActive;

    mapping(address => uint) private userMintedAmount;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("Sicarius", "SCRS") {
        MINT_PRICE = 13370000000000000 wei; //0.01337 ETH
        TOTAL_SUPPLY = 2222;
        baseUri = "ipfs://?/";
    }

    function mint(uint _amount) public payable {
        require(isSaleActive, "The sale is paused.");
        require(
            CURRENT_SUPPLY + _amount <= TOTAL_SUPPLY,
            "Mint cap has been reached."
        );
        require(msg.value >= MINT_PRICE * _amount, "Not enough funds to mint.");
        require(
            userMintedAmount[msg.sender] + _amount <= 2,
            "User mint cap reached."
        );
        require(_amount > 0 && _amount <= 2, "Invalid amount");

        userMintedAmount[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            _safeMint(msg.sender, CURRENT_SUPPLY + 1);
            tokenURI(CURRENT_SUPPLY + 1);
            CURRENT_SUPPLY++;
        }
    }

    function userMintedCount(address _address) public view returns (uint) {
        return userMintedAmount[_address];
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdrawAll() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
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
}
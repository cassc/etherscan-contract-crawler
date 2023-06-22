// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Inspired/Copied from DystoPunks V2 (dystopunksv2.com)
contract OctoHedz is Ownable, ERC721Enumerable {

    uint public constant MAX_SOCTOS = 888;
    bool public hasSaleStarted = false;
    string private _baseTokenURI;
    string private _baseContractURI;
    uint256 private _price = 0.07 ether;

    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("OctoHedz","Octo")  {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
       return _baseContractURI;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function Price() public view returns (uint256) {
        require(hasSaleStarted == true, "Invasion hasn't started");
        require(totalSupply() < MAX_SOCTOS, "Invasion has ended");
        return _price;
    }

   function getOctoHedz(uint256 numOctoHedz) public payable {
        require(totalSupply() < MAX_SOCTOS, "Invasion has already ended");
        require(numOctoHedz > 0 && numOctoHedz <= 5, "You can mint minimum 1, maximum 5 OctoHedz");
        require(totalSupply()+numOctoHedz <= MAX_SOCTOS, "Exceeds MAX_SOCTOS");
        require(msg.value >= Price() * numOctoHedz, "Ether value sent is below the price");

        for (uint i = 0; i < numOctoHedz; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveAirdrop(uint256 numOctoHedz) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numOctoHedz <= 50, "Exceeded airdrop supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for airdrops and giveaways
        for (index = 0; index < numOctoHedz; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }


   function octosTokenBalance(address tokenContractAddress) private view returns(uint) {
       ERC721 token = ERC721(tokenContractAddress); // token is cast as type ERC721, so it's a contract
       return token.balanceOf(msg.sender);
   }



}
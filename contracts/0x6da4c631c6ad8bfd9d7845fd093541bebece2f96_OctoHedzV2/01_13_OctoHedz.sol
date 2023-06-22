// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


contract OctoHedzV2 is Ownable, ERC721Enumerable {

    uint public MAX_SOCTOS = 8001;
    bool public hasSaleStarted = false;
    bool public preSaleIsActive = false;
        string private _baseTokenURI;
    string private _baseContractURI;
    uint256 private _price = 0.08 ether;
    
    
    mapping(address => uint8) private _allowList;
     
    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("OctoHedz V2","OctoV2")  {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
    }

    function setIsAllowListActive() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
     function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    
    function mintOctoHedzV2PreSale(uint8 numOctoHedz) public payable {
        uint256 mintIndex = totalSupply();
        require(preSaleIsActive, "Pre Sale not active");
        require(numOctoHedz <= _allowList[msg.sender], "Exceeded max available per wallet");
        require(mintIndex + numOctoHedz <= MAX_SOCTOS, "Purchase would exceed max tokens");
        require(msg.value >= Price() * numOctoHedz, "Ether value sent is below the price");

        _allowList[msg.sender] -= numOctoHedz;
        for (uint256 i = 0; i < numOctoHedz; i++) {
        _safeMint(msg.sender, mintIndex + i);
        }
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

        function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
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
        require(totalSupply() < MAX_SOCTOS, "Invasion has ended");
        return _price;
    }

   

    function flipSaleState() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
     



    function reserveAirdrop(uint256 numOctoHedz) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numOctoHedz <= 151, "Exceeded airdrop supply");
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
   
   function getOctoHedz(uint256 numOctoHedz) public payable {
        require(hasSaleStarted, "Sale must be active to mint OctoHedz");
        require(numOctoHedz + balanceOf(msg.sender) <= 50, "Can't have more than 50 OctoHedz per wallet");
        require(totalSupply() < MAX_SOCTOS, "Invasion has already ended");
        require(numOctoHedz > 0 && numOctoHedz <= 8, "You can mint up to 8 OctoHedz");
        require(totalSupply()+numOctoHedz <= MAX_SOCTOS, "Exceeds Total Supply");
        require(msg.value >= Price() * numOctoHedz, "Ether value sent is below the price");

        for (uint i = 0; i < numOctoHedz; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

   function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}
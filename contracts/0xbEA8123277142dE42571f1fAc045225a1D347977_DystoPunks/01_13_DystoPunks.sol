// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Inspired/Copied from BGANPUNKS V2 (bastardganpunks.club) and Chubbies (chubbies.io)
contract DystoPunks is  Ownable, ERC721Enumerable {

    uint public constant MAX_SPUNKS = 2077;
    bool public hasSaleStarted = false;
    mapping (address => uint) private _DystoPunksV1Owners;
    string private _baseTokenURI;
    string private _baseContractURI;

    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("DystoPunks V2","DYSTO")  {
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

    function isAuthClaim(address _to) public view returns(uint) {
      return _DystoPunksV1Owners[_to];
    }

    function authClaim(address _to, uint  _NumberOfPunks) public onlyOwner{
         _DystoPunksV1Owners[_to] = _NumberOfPunks;
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

    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_SPUNKS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 2000) {
            return 100000000000000000;        // 2000-2077:  0.10 ETH
        } else if (currentSupply >= 1667) {
            return 80000000000000000;         // 1667-1999:  0.08 ETH
        } else if (currentSupply >= 1334) {
            return 60000000000000000;         // 1334-1666:  0.06 ETH
        } else if (currentSupply >= 1001) {
            return 40000000000000000;         // 1001-1333:  0.04 ETH
        } else if (currentSupply >= 501) {
            return 30000000000000000;         // 501-1000:   0.03 ETH
        } else {
            return 20000000000000000;         // 1 - 500:    0.02 ETH
        }
    }

   function getDystoPunk(uint256 numDystoPunks) public payable {
        require(totalSupply() < MAX_SPUNKS, "Sale has already ended");
        require(numDystoPunks > 0 && numDystoPunks <= 20, "You can mint minimum 1, maximum 20 DystoPunks");
        require(totalSupply()+numDystoPunks <= MAX_SPUNKS, "Exceeds MAX_SPUNKS");
        require(msg.value >= calculatePrice() * numDystoPunks, "Ether value sent is below the price");

        for (uint i = 0; i < numDystoPunks; i++) {
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

    function reserveAirdrop(uint256 numDystoPunks) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numDystoPunks <= 130, "Exceeded airdrop supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for DystoPunks V1 holders airdrop, DystoFactory Upgrade and giveaways
        for (index = 0; index < numDystoPunks; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }


   function punksTokenBalance(address tokenContractAddress) private view returns(uint) {
       ERC721 token = ERC721(tokenContractAddress); // token is cast as type ERC721, so it's a contract
       return token.balanceOf(msg.sender);
   }

   function claimDystoPunk() public {
     require(totalSupply() < MAX_SPUNKS, "Sale end");
     require(hasSaleStarted == true, "Sale has not already started");
     require(_DystoPunksV1Owners[msg.sender] > 0, "Not owner");
     address _to = msg.sender;
     uint _NumberToClaim = _DystoPunksV1Owners[_to];
     for(uint i = 0; i < _NumberToClaim; i++){
       _safeMint(_to, totalSupply());
     }
     _DystoPunksV1Owners[_to]=0;
   }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



    contract GoldenTicket is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public mintPrice = 0.42 ether;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;

    
       constructor() payable ERC721('GoldenTicket', 'GT') {
        setBaseURI("ipfs://QmY5BkzzqZmREFWwfJcQYsY6bo84Zryq2HSL368Q9U3kXz/");
        maxSupply = 9850;

    }
        //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;

    }
   
     function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

   function setMaxSupply(uint256 maxSupply_) public onlyOwner {
    require(maxSupply_ > totalSupply, "Error: new max supply must be greater than current total supply");
    maxSupply = maxSupply_;
    }
   
        function mint() external payable {
          require(isMintEnabled, 'minting not enabled');
          require(mintedWallets[msg.sender] < 1, 'exceeds max perwallet');
          require(msg.value == mintPrice, 'wrong value');
          require(maxSupply > totalSupply, 'sold out');
          require(totalSupply < maxSupply, 'maximum supply reached');

          mintedWallets[msg.sender]++;
          totalSupply++;
          uint256 tokenId = totalSupply;
          _safeMint(msg.sender, tokenId);
         
      }
function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
     
    }

          function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;



        }

         function withdraw() public onlyOwner nonReentrant{
          (bool success, ) = msg.sender.call{value: address(this).balance}("");
          require(success, "Withdrawal failed");


      }
       }
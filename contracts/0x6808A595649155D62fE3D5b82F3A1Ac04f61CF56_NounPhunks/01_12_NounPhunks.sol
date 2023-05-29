// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*

        ┏━┓━┏┓━━━━━━━━━━━━━━━━┏┓━━━━━━━━━━┏┓━━━━━━
        ┃┃┗┓┃┃━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━┃┃━━━━━━
        ┃┏┓┗┛┃┏━━┓┏┓┏┓┏━┓━┏━━┓┃┗━┓┏┓┏┓┏━┓━┃┃┏┓┏━━┓
        ┃┃┗┓┃┃┃┏┓┃┃┃┃┃┃┏┓┓┃┏┓┃┃┏┓┃┃┃┃┃┃┏┓┓┃┗┛┛┃━━┫
        ┃┃━┃┃┃┃┗┛┃┃┗┛┃┃┃┃┃┃┗┛┃┃┃┃┃┃┗┛┃┃┃┃┃┃┏┓┓┣━━┃
        ┗┛━┗━┛┗━━┛┗━━┛┗┛┗┛┃┏━┛┗┛┗┛┗━━┛┗┛┗┛┗┛┗┛┗━━┛
        ━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━
        ━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━
   
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NounPhunks is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 9969;
    uint256 public constant MAX_MINT = 20;
    uint256 public constant EARLY_PHUNKS = 0 ether;  // 2500 Available
    uint256 public MINT_COST = 0.069 ether;  // 7469 Available
 
    bool public saleIsActive;

    constructor() ERC721("NounPhunks", "NPh") {
        _nextTokenId.increment(); // Start Token IDs at 1
        saleIsActive = false;
    }

    function mint(uint256 _mintAmount) public payable {
        require(saleIsActive, "NounPhunks are not on sale, ser!");
        require(_mintAmount > 0, "Cannot mint zero, ser!");
        require(_mintAmount <= MAX_MINT, "Ser, save some for the rest of us! Max mint is 20 NounPhunks.");
        require(tokenSupply() + _mintAmount <= MAX_SUPPLY, "Not enough NounPhunks remaining, ser!");
        require(msg.value >= currentPrice() * _mintAmount, "Not enough ETH to buy NounPhunks, ser!");
  
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 mintIndex = _nextTokenId.current(); // Get next ID to mint
            _nextTokenId.increment();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function currentPrice() public view returns (uint256) {

        uint256 totalMinted = tokenSupply();

        if (totalMinted <= 2000) {
            return EARLY_PHUNKS;

        } else {
            return MINT_COST;
        }
    }

    function remainingSupply() public view returns (uint256) {
        uint256 numberMinted = tokenSupply();
        return MAX_SUPPLY - numberMinted;
    }

    function tokenSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        MINT_COST = _newMintPrice;
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}
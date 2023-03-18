// SPDX-License-Identifier: MIT

/*
  /$$$$$$$                            /$$ /$$                                       /$$     /$$ /$$ /$$   /$$              
 | $$__  $$                          | $$| $$                                      | $$    |__/| $$|__/  | $$              
 | $$  \ $$  /$$$$$$   /$$$$$$   /$$$$$$$| $$  /$$$$$$   /$$$$$$$       /$$   /$$ /$$$$$$   /$$| $$ /$$ /$$$$$$   /$$   /$$
 | $$  | $$ /$$__  $$ /$$__  $$ /$$__  $$| $$ /$$__  $$ /$$_____/      | $$  | $$|_  $$_/  | $$| $$| $$|_  $$_/  | $$  | $$
 | $$  | $$| $$  \ $$| $$  \ $$| $$  | $$| $$| $$$$$$$$|  $$$$$$       | $$  | $$  | $$    | $$| $$| $$  | $$    | $$  | $$
 | $$  | $$| $$  | $$| $$  | $$| $$  | $$| $$| $$_____/ \____  $$      | $$  | $$  | $$ /$$| $$| $$| $$  | $$ /$$| $$  | $$
 | $$$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$| $$|  $$$$$$$ /$$$$$$$/      |  $$$$$$/  |  $$$$/| $$| $$| $$  |  $$$$/|  $$$$$$$
 |_______/  \______/  \______/  \_______/|__/ \_______/|_______/        \______/    \___/  |__/|__/|__/   \___/   \____  $$
                                                                                                                 /$$  | $$
                                                                                                                |  $$$$$$/
                                                                                                                 \______/ 
*/                                                                                                                


pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DoodlesUtility is ERC721A, Ownable {
    uint256 WalletMax = 10;
    uint256 Max_Mint = 7777;
    uint256 public mintPrice = 0.003 ether;
    bool public paused = true;
    string public baseURI = "ipfs://bafybeibp7ebmmtsi7mwufh7x2afajwdwtfzoyp3p3vvqswcxwveywfcucq/";
    using Strings for uint256;

    constructor() ERC721A("DoodlesUtility", "DDLESUTLTY") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "Contract is paused");
        require(quantity + _numberMinted(msg.sender) <= WalletMax, "Oh oh Limit");
        require(totalSupply() + quantity <= Max_Mint, "No more peepo");
        require(msg.value >= (mintPrice * quantity), "Dont be greedy");
        _safeMint(msg.sender, quantity);
    }



    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  
   function TeamMint(uint256 _numberMinted, address _receiver) public onlyOwner {
        require(
            totalSupply() + _numberMinted <= Max_Mint,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _numberMinted);
    }

    function setmintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;

    }  

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    


}
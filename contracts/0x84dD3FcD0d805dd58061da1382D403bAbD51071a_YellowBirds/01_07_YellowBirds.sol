// SPDX-License-Identifier: MIT

/**

  ___    ___ _______   ___       ___       ________  ___       __           ________  ___  ________  ________  ________      
 |\  \  /  /|\  ___ \ |\  \     |\  \     |\   __  \|\  \     |\  \        |\   __  \|\  \|\   __  \|\   ___ \|\   ____\     
 \ \  \/  / | \   __/|\ \  \    \ \  \    \ \  \|\  \ \  \    \ \  \       \ \  \|\ /\ \  \ \  \|\  \ \  \_|\ \ \  \___|_    
  \ \    / / \ \  \_|/_\ \  \    \ \  \    \ \  \\\  \ \  \  __\ \  \       \ \   __  \ \  \ \   _  _\ \  \ \\ \ \_____  \   
   \/  /  /   \ \  \_|\ \ \  \____\ \  \____\ \  \\\  \ \  \|\__\_\  \       \ \  \|\  \ \  \ \  \\  \\ \  \_\\ \|____|\  \  
 __/  / /      \ \_______\ \_______\ \_______\ \_______\ \____________\       \ \_______\ \__\ \__\\ _\\ \_______\____\_\  \ 
|\___/ /        \|_______|\|_______|\|_______|\|_______|\|____________|        \|_______|\|__|\|__|\|__|\|_______|\_________\
\|___|/                                                                                                          \|_________|
                                                                                                                             
                                                                                                                            

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YellowBirds is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("Yellow Birds", "YELLOWBIRDS") {}
    
    uint256 public collectionSize = 5555;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 10;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}
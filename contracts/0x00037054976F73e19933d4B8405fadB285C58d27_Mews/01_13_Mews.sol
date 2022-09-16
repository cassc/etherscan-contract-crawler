// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Mews is ERC721, Ownable, ERC2981 {
    /**
    ==============
    Introducing...
             ____    __      __           
     /'\_/`\/\  _`\ /\ \  __/\ \          
    /\      \ \ \L\_\ \ \/\ \ \ \   ____  
    \ \ \__\ \ \  _\L\ \ \ \ \ \ \ /',__\ 
     \ \ \_/\ \ \ \L\ \ \ \_/ \_\ /\__, `\
      \ \_\\ \_\ \____/\ `\___x___\/\____/
       \/_/ \/_/\/___/  '\/__//__/ \/___/ 
                                          
    MEWs or Meta Exo Whips are a 3D digital collectible fashion art item designed and developed by Metadrip. 

    Contract written by 0xhanvalen via Raidguild for Metadrip.
    ==============
    */

    using Strings for uint256;

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 private currentIndex;
    string private baseURI;
    string private unrevealedURI;
    bool private isRevealed;
    mapping(address => uint16) public amountMinted;
    uint16 private maxMintedPerUser = 10;

    constructor() ERC721("Metadrip Mews", "MEWS") {
        mintPrice = 0.33 ether;
        totalSupply = 200;
        currentIndex = 0;
        isRevealed = false;
        _setDefaultRoyalty(0x8ceb7C0eF432213C10451087A47ec1FC6E7e616c, 690);
    }

    function teamMint() public onlyOwner {
        for (uint256 i = 0; i < 20; i++) {
            require(currentIndex + 1 <= totalSupply, "Sold Out");
            currentIndex++;
            _mint(0x8ceb7C0eF432213C10451087A47ec1FC6E7e616c, currentIndex);
        }
    }

    function updateMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "No Negative Prices");
        mintPrice = newPrice;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealedURI(string memory newURI) public onlyOwner {
        unrevealedURI = newURI;
    }

    function toggleReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function mint(uint16 amount) public payable {
        require(
            amountMinted[msg.sender] + amount <= maxMintedPerUser,
            "Too Many"
        );
        require(msg.value >= mintPrice, "Not Enough Money");
        require(currentIndex + 1 <= totalSupply, "Sold Out");
        for (uint256 i = 0; i < amount; i++) {
            currentIndex++;
            amountMinted[msg.sender]++;
            _mint(msg.sender, currentIndex);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId <= totalSupply, "Unreal Token");
        require(tokenId > 0, "Unreal Token");
        if (isRevealed) {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        } else {
            return string(abi.encodePacked(unrevealedURI));
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
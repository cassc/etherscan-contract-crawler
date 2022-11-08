// ███╗   ██╗ ██████╗ ██████╗ ███████╗██╗███████╗██╗   ██╗    ██╗  ██╗     █████╗ ██╗   ██╗██████╗ ██████╗ ███████╗██╗   ██╗    ██╗███╗   ██╗     ██████╗ ██████╗ ██╗      ██████╗ ██╗   ██╗██████╗
// ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██║██╔════╝╚██╗ ██╔╝    ╚██╗██╔╝    ██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝╚██╗ ██╔╝    ██║████╗  ██║    ██╔════╝██╔═══██╗██║     ██╔═══██╗██║   ██║██╔══██╗
// ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██║█████╗   ╚████╔╝      ╚███╔╝     ███████║██║   ██║██║  ██║██████╔╝█████╗   ╚████╔╝     ██║██╔██╗ ██║    ██║     ██║   ██║██║     ██║   ██║██║   ██║██████╔╝
// ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██║██╔══╝    ╚██╔╝       ██╔██╗     ██╔══██║██║   ██║██║  ██║██╔══██╗██╔══╝    ╚██╔╝      ██║██║╚██╗██║    ██║     ██║   ██║██║     ██║   ██║██║   ██║██╔══██╗
// ██║ ╚████║╚██████╔╝██████╔╝███████╗██║██║        ██║       ██╔╝ ██╗    ██║  ██║╚██████╔╝██████╔╝██║  ██║███████╗   ██║       ██║██║ ╚████║    ╚██████╗╚██████╔╝███████╗╚██████╔╝╚██████╔╝██║  ██║
// ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═╝        ╚═╝       ╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝     ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/extensions/ERC721ABurnable.sol";

contract KillerCupcakes is ERC721A, Ownable, ERC721ABurnable {
    
    string public baseURI = "ipfs://bafybeif4tlo7qzeyfyaqkzjvu7rjxifarqpdy54th4d2eqazpqkkgrg7ei/"; // need to change
    
    uint256 public maxDevMint = 100;
    uint256 public maxSupply = 600;
    uint256 public maxSeekerMintAmount = 10; // max mint amount for NFT
    uint256 public pricePublic = 0.15 ether;
    
    bool public paused = true; // deploy paused on launch

    constructor() ERC721A("KillerCupcakes", "CUPCAKES") {}

    function mintDev(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();

        require(paused, "You can't mint dev when unpaused");
        require(_mintAmount > 0, "Can't mint ZERO");
        require(_mintAmount <= maxDevMint, "Can't mint more than 100");
        
        require(supply + _mintAmount <= maxSupply, "Can't mint more than supply");

        _mint(_to, _mintAmount);
    }

    function setmaxSeekerMintAmount(uint256 _maxSeekerMintAmount) public onlyOwner {
        maxSeekerMintAmount = _maxSeekerMintAmount;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

   function _mintCheck(uint256 _mintAmount) private {
        require(_mintAmount > 0, "You can't mint ZERO tokens");
        require(_mintAmount <= (maxSeekerMintAmount - balanceOf(msg.sender)), "You can only allocated amount of Cupcakes");
        require(msg.value == (pricePublic * _mintAmount), "Minting is not free");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Can't mint more than supply");
    }

    function mint(uint256 _mintAmount) external payable {
        require(paused == false, "Minting is paused");
        require(_mintAmount <= maxSeekerMintAmount, "Can't mint more than allocated amount");
        _mintCheck(_mintAmount);

        _mint(msg.sender, _mintAmount);
    }

    function withdraw() public payable onlyOwner {
       (bool os, ) = payable(owner()).call{value: address(this).balance}("");
         require(os);
     }

}
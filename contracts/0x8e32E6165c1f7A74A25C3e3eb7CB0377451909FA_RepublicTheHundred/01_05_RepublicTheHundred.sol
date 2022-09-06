// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RepublicTheHundred is ERC721A, Ownable {
    string public baseURI = "ipfs://QmWB7EcNsSp2WDNaenAMtJcmaCcPY6qsWmLLaxMizuboE2/";
    
    uint256 public maxDevMint = 11;
    uint256 public maxSupply = 101;
    uint256 public maxSeekerMintAmount = 1;
    uint256 public pricePublic = 0.0 ether;
    
    bool public paused = true; // deploy paused on launch

    constructor() ERC721A("Republic - The Hundred", "S100") {}

    function mintDev(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();

        require(paused, "You can't mint dev when unpaused");
        require(_mintAmount > 0, "Can't mint ZERO");
        require(_mintAmount <= maxDevMint, "Can't mint more than 11");
        
        require(supply + _mintAmount <= maxSupply, "Can't mint more than supply");

        _mint(_to, _mintAmount);
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
        require(balanceOf(msg.sender) == 0, "You have already minted");

        uint256 supply = totalSupply();
        require(msg.value == 0, "Minting is free");
        
        require(supply + _mintAmount <= maxSupply, "Can't mint more than supply");
    }

    function mint(uint256 _mintAmount) external payable {
        require(paused == false, "Minting is paused");
        require(_mintAmount <= maxSeekerMintAmount, "Can't mint more than 1");
        _mintCheck(_mintAmount);

        _mint(msg.sender, _mintAmount);
    }

}
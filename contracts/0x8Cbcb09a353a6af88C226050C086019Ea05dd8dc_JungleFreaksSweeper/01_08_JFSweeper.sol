//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;  

import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract JungleFreaksSweeper is ERC721A, Ownable, Pausable, ReentrancyGuard {  
    using Strings for uint256;

    string  public baseUrl;
    uint256 public maxSweepers = 3333;
    uint256 public maxPerTransaction = 10; 
    uint256 public mintPrice = 0.05 ether;
    address private treasuryWallet = address(0xEE29CdCEB1bbde84a8685FC2D21F59E36a739905);
    address private wnWallet = address(0x48B80A96E3c14fF24a2732970444Ae6166918190);
    address private bbWallet = address(0x3e2f194cc9EE48EF50C0E82a3c693524f7122D30);

	constructor() ERC721A("Jungle Freaks Sweeper", "JFFS") {
        _pause();
        setBaseUri("https://ipfs.io/ipfs/Qmaj4MkSH8hyyoMKPGGKqpzA4nYkhJAEoiFKU7a3PESMAc");
    }

    function unpauseMint() external onlyOwner {
        _unpause();
    }

    function pauseMint() external onlyOwner {
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    // ===== View =====
    function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "Token does not exist!");
        return string(abi.encodePacked(baseUrl, "?0.json"));
    }

    function mint(uint256 _quantity) public payable nonReentrant {
  	    uint256 currentSupply = totalSupply();
        require(_quantity > 0 && _quantity <= maxPerTransaction, "Invalid mint amount!");
        require(currentSupply + _quantity <= maxSweepers, "Sold Out!");
        require(msg.value == _quantity * mintPrice, "Wrong mint price!");
        _safeMint(msg.sender, _quantity);
    }

    function setBaseUri(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    function withdrawFunds() public onlyOwner {
        uint256 fundsBalance = address(this).balance;
        (bool wns, ) = wnWallet.call{ value: fundsBalance * 10 / 100 } ('');
        require(wns, "Unable to withdraw");
        (bool bbs, ) = bbWallet.call{ value: fundsBalance * 10 / 100 } ('');
        require(bbs, "Unable to withdraw");
	    (bool tws, ) = treasuryWallet.call{value: address(this).balance}("");
		require(tws, "Unable to withdraw");
	}
}
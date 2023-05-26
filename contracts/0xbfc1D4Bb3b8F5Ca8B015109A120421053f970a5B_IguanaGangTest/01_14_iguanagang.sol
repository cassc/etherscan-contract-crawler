//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721a.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract IguanaGangTest is ERC721A, Ownable, ReentrancyGuard {  
    using Address for address;
    using SafeMath for uint256;

    // Sale Details
    uint public presalePrice = 0.04 ether; 
    uint public publicPrice = 0.06 ether;
    uint public MAX_PRESALE_PLUS_ONE = 4001; 
    uint public MAX_SUPPLY_PLUS_ONE = 5556; 
    uint public MAX_PER_TX_PLUS_ONE = 4; 
    uint public MAX_PER_ADMIN_MINT_PLUS_ONE = 501; 
    uint adminMinted;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmWSrgPDVfCB6ixKCd1XVY6xEKhR9eW5fx6ymp7ofWC7Yh/";
    string public contractURI;

    // Sale Controls
    bool public saleActive = false;

    // Contract Creation
	constructor() ERC721A("Iguana Gang", "IGU") {}
   
    // ------------------------- MINTING FUNCTIONS ------------------------- //

    // Main Sale Minting 
    function mintIguanas(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require(saleActive, "Sale Not Active");
        require(supply + _amount < MAX_SUPPLY_PLUS_ONE, "Not Enough Supply");
        require(_amount > 0 && _amount < MAX_PER_TX_PLUS_ONE, "Max per TX is 3");

        if (supply < MAX_PRESALE_PLUS_ONE) {
            require(msg.value == presalePrice * _amount, "0.04 to mint an Iguana");
        }
        else {
            require(msg.value == publicPrice * _amount, "Incorrect Amount Of ETH Sent");
        }
        
        _safeMint(msg.sender, _amount);
    }

    function adminMint(uint256 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _amount < MAX_SUPPLY_PLUS_ONE, "Not Enough Supply");
        adminMinted += _amount; 
        require(_amount > 0 && adminMinted< MAX_PER_ADMIN_MINT_PLUS_ONE, "Max admin mint is 500");
        _safeMint(msg.sender, _amount);
    }

    // Main Sale Flipstate
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // ------------------------- Additional Functions ------------------------- //

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    // Change Presale Price
    function setPresalePrice(uint256 _newPrice) public onlyOwner{ 
        presalePrice = _newPrice;
    }

    // Change Public Price
    function setPublicPrice(uint256 _newPrice) public onlyOwner{ 
        publicPrice = _newPrice;
    }

    // ------------------------- a Metadata Related Functions ------------------------- //
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function setBaseURI(string calldata _uri) external onlyOwner {
		baseURI = _uri;
	}

    function getContractURI() public view returns (string memory) {
		return contractURI;
	}

    function setContractURI(string calldata _uri) external onlyOwner {
		contractURI = _uri;
	}
}
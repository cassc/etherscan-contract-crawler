// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract theDutchies is ERC721A, Ownable {  
    using Strings for uint256;
    string public _kenmerkenURI = "ipfs://bafybeibe74dtq2xkrx4rnqoggqmbmavzjh7w4rsxvjm3rz7gr3gvmnq2ne/";
    bool public whitelistActief = false;
    bool public veilingActief = false;
    uint256 constant public dutchies = 4200;
    uint256 public maxMint = 2; 
    mapping (address => uint256) public hoeveelWhitelistDutchies;
    mapping (address => uint256) public hoeveelDutchies;
    bytes32 public whitelistMerkle;

    constructor() ERC721A("The Dutchies", "DUTCH") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _kenmerkenURI;
    }
    /// @dev See {ERC721A-_startTokenId}.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function whitelistVeiling(uint256 quantity, bytes32[] calldata proof) external {
        require(msg.sender == tx.origin);
        require(whitelistActief, "De veiling is nog gesloten");
        require(MerkleProof.verify(proof, whitelistMerkle, keccak256(abi.encodePacked(msg.sender))), "Address not on Whitelist");
        require(totalSupply() + quantity <= dutchies, "Alle Dutchies zijn weg");
        require(hoeveelWhitelistDutchies[msg.sender] + quantity <= maxMint, "2 max per wallet");
        _safeMint( msg.sender, quantity);
        hoeveelWhitelistDutchies[msg.sender] += quantity;
    } 

    function deVeiling(uint256 quantity) external {
        require(msg.sender == tx.origin);
        require(veilingActief, "De veiling is nog gesloten");
        require(totalSupply() + quantity <= dutchies, "Alle Dutchies zijn weg");
        require(hoeveelDutchies[msg.sender] + quantity <= maxMint, "1 max per wallet");
        _safeMint( msg.sender, quantity);
        hoeveelDutchies[msg.sender] += quantity;
    } 

 	function verdeelDutchies(address meester, uint256 _dutchies) public onlyOwner {
	    require(totalSupply() + _dutchies <= dutchies);
        _safeMint(meester, _dutchies);
    }    

    function setKenmerken(string memory kenmerken) external onlyOwner {
        _kenmerkenURI = kenmerken;
    }

    function setWhitelistActief(bool val) external onlyOwner {
        whitelistActief = val;
    }

    function setVeilingActief(bool val) external onlyOwner {
        veilingActief = val;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }    

    function setWhitelistMerkle(bytes32 whitelistRoot) public onlyOwner {
		whitelistMerkle = whitelistRoot;
	}

    function collectCoins() public payable onlyOwner {
	      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success);
	  }   
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './base/Ownable.sol';
import './base/ERC721A.sol';
import './base/MerkleProof.sol';

/*========================================================================\
 ________  ________  ________  _____ ______   _______   ________  ________      
|\   ___ \|\   __  \|\   __  \|\   _ \  _   \|\  ___ \ |\   __  \|\   ____\     
\ \  \_|\ \ \  \|\  \ \  \|\  \ \  \\\__\ \  \ \   __/|\ \  \|\  \ \  \___|_    
 \ \  \ \\ \ \  \\\  \ \  \\\  \ \  \\|__| \  \ \  \_|/_\ \   _  _\ \_____  \   
  \ \  \_\\ \ \  \\\  \ \  \\\  \ \  \    \ \  \ \  \_|\ \ \  \\  \\|____|\  \  
   \ \_______\ \_______\ \_______\ \__\    \ \__\ \_______\ \__\\ _\ ____\_\  \ 
    \|_______|\|_______|\|_______|\|__|     \|__|\|_______|\|__|\|__|\_________\
                                                                    \|_________| 
     \============================ By Degen Den ===============================*/


contract Doomers is ERC721A, Ownable {

    //Global variables
    uint256 public maxSupply = 6969;
    uint256 public maxFree = 1;
    uint256 public maxPerTxn = 20;
    uint256 public cost = 0.0069 ether;
    
    bool public presale = false;
    bool public publicSale = false;
    bool public revealed = false;

    address public capitulation;

    bytes32 public root = 0xd8bdd8393b8c4f7f4e91c15efc5701aabc0cbdcb86be8292e36196e80544a8be;

    string public unrevealedURI = "ipfs/QmQ42mnX5PdupsXvRQjgHo5wftnLMPqwd17fmk2LpvREsm";
    string public revealedURI;

    //Maps the address of a user to its number of claims
    mapping(address => uint256) public validBlobs;

    //Maps address to its free mint calimed status
    mapping(address => bool) public freeClaimed;

    //Maps address to its doomlist calimed status
    mapping(address => bool) public doomlistClaimed;

    constructor() ERC721A("Doomers", "DOOM") {}

    //Check if the whitelist is enabled and the address is part of the whitelist
    modifier isDoomlisted(address _address, bytes32[] calldata proof) {
        require(
            doomlistClaimed[_address] == false && _verify(_leaf(_address), proof),
            "This address is not whitelisted or has reached maximum mints"
        );
        _;
    }
            /*----------------------//
            //  INTERNAL FUNCTIONS  //
            //----------------------*/
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
            
    function _baseURI() internal view virtual override returns (string memory) {
		return revealedURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(revealed == false) {
            return unrevealedURI;
        }
        else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
        }
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
            /*----------------------//
            //    MINT FUNCTIONS    //
            //----------------------*/
    function claimWithBlobs() public {
        uint256 amt = validBlobs[msg.sender];
        require(presale == true, "Blob claiming is not active");
        require(totalSupply() + amt <= maxSupply, "Exceeds max supply");

        validBlobs[msg.sender] = 0;
        _safeMint(msg.sender, amt);
    }

    function doomlistMint(bytes32[] calldata _proof) public isDoomlisted(msg.sender, _proof) {
        require(presale == true, "Doomlist mint is not active");
        require(totalSupply() + 1 <= maxSupply, "Exceeds max supply");

        doomlistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintFree() public {
        require(publicSale == true, "Public sale is not active");
        require(totalSupply() + 1 <= maxSupply, "Exceeds max supply");
        require(freeClaimed[msg.sender] == false, "Exceeds max free amount");

        freeClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintPaid(uint256 _mintAmount) public payable {
        require(publicSale == true, "Public sale is not active");
        require(totalSupply() + _mintAmount <= maxSupply, "Exceeds max supply");
        require(_mintAmount <= maxPerTxn, "Exceeds max transaction amount");
        require(msg.value >= _mintAmount * cost, "Not enough ether sent");

        _safeMint(msg.sender, _mintAmount);
    }
            /*---------------------//
            //   OWNER FUNCTIONS   //
            //---------------------*/
    function devMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");

        _safeMint(_to, _amount);
    }

    function snapshot(address[] calldata _owners, uint256[] calldata _numBlobs) public onlyOwner {
        for (uint256 i = 0; i < _owners.length; i++) {
            validBlobs[_owners[i]] = _numBlobs[i];
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxTxn(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function setUnrevealedURI(string memory _newURI) public onlyOwner {
		unrevealedURI = _newURI;
	}

    function setRevealedURI(string memory _newURI) public onlyOwner {
		revealedURI = _newURI;
	}

    function setCapitulation(address _address) public onlyOwner {
		capitulation = _address;
	}

    function reveal(string memory _newURI) public onlyOwner {
        revealed = !revealed;
        revealedURI = _newURI;
    }

    function flipPresale() public onlyOwner {
		presale = !presale;
	}

    function flipPublicSale() public onlyOwner {
		publicSale = !publicSale;
	}
            /*------------------//
            //    CAPITULATE    //
            //------------------*/
    function capitulate(uint256 _tokenId) external {
        require(msg.sender == capitulation, "Not authorized");

        _burn(_tokenId);
    }
}
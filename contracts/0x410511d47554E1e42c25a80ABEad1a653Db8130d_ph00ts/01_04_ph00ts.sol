// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './imports/ERC721A.sol';
import './imports/Ownable.sol';
                                                                        
/*                                                                       
            ,---,        ,----..       ,----..       ___                
,-.----.  ,--.' |       /   /   \     /   /   \    ,--.'|_              
\    /  \ |  |  :      /   .     :   /   .     :   |  | :,'             
|   :    |:  :  :     .   /   ;.  \ .   /   ;.  \  :  : ' :  .--.--.    
|   | .\ ::  |  |,--..   ;   /  ` ;.   ;   /  ` ;.;__,'  /  /  /    '   
.   : |: ||  :  '   |;   |  ; \ ; |;   |  ; \ ; ||  |   |  |  :  /`./   
|   |  \ :|  |   /' :|   :  | ; | '|   :  | ; | ':__,'| :  |  :  ;_     
|   : .  |'  :  | | |.   |  ' ' ' :.   |  ' ' ' :  '  : |__ \  \    `.  
:     |`-'|  |  ' | :'   ;  \; /  |'   ;  \; /  |  |  | '.'| `----.   \ 
:   : :   |  :  :_:,' \   \  ',  /  \   \  ',  /   ;  :    ;/  /`--'  / 
|   | :   |  | ,'      ;   :    /    ;   :    /    |  ,   /'--'.     /  
`---'.|   `--''         \   \ .'      \   \ .'      ---`-'   `--'---'   
  `---`                  `---`         `---`                            
*/                                                                    
                                            
contract ph00ts is ERC721A, Ownable {

    uint256 public maxSupply = 15000;
    uint256 public maxFree = 3;
    uint256 public maxPerTxn = 30;
    uint256 public cost = 0.0001 ether;

    bool public mintLive = false;
    bool public revealed = false;

    string public revealedURI;
    string public unrevealedURI = "ipfs/QmXaCZyfy9fnt79RG9M5fpnbQmotz9jZvVXsc2YMqaSCbU";

    mapping(address => bool) public freeMinted;

    constructor() ERC721A("ph00ts", "PH00T") {}

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

    function mintFree() public {
        require(mintLive == true, "Minting is not active");
        require(totalSupply() + 3 <= maxSupply, "Exceeds max supply");
        require(freeMinted[msg.sender] == false, "Exceeds max free amount");

        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 3);
    }

    function mintPaid(uint256 _mintAmount) public payable {
        require(mintLive == true, "Minting is not active");
        require(totalSupply() + _mintAmount <= maxSupply, "Exceeds max supply");
        require(_mintAmount <= maxPerTxn, "Exceeds max transaction amount");
        require(msg.value >= _mintAmount * cost, "Not enough ether sent");

        _safeMint(msg.sender, _mintAmount);
    }

    function devMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");

        _safeMint(_to, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setRevealedURI(string memory _newURI) public onlyOwner {
		revealedURI = _newURI;
        revealed = !revealed;
	}

    function flipMinting() public onlyOwner {
		mintLive = !mintLive;
	}
}
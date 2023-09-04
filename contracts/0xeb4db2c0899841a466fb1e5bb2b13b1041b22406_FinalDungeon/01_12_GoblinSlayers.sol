// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FinalDungeon is IERC721A, Ownable, ERC721A {
    uint256 public maxSupply = 5000;
    bool public paused = true;
    string public baseURI;

    IERC721A public chainknightsToken;
    // Chain Knight Token Address
    address constant public chainKnightAddress = 0xD0E45144CaaCc11CC304FF05B044C00De53FD790;


    // For checking minted per wallet
    mapping(address => uint) internal hasMinted;

    constructor() ERC721A('Final Dungeon', 'FINAL') {
        // Mint some here
        chainknightsToken = IERC721A(chainKnightAddress);
        _safeMint(msg.sender, 50);
    }

    /** MINTING FUNCTIONS */

    /**
     * @dev Checks if you own a chainknight token.
     * @param _wallet The wallet to check.
     * @param tokenId The token id of the chainknight.
     */
    function ownsChainKnight(address _wallet, uint tokenId) public view returns (bool) {
        if(_wallet == chainknightsToken.ownerOf(tokenId)) return true;
        return false;
    }

    /**
     * @dev Allows you to mint 1 token, unless you pass in an owned chainknight token then you mint 2.
     * @param chainKnightTokenId The token id of the chainknight the sender owns.
     */
    function mint(uint256 chainKnightTokenId) public payable {
        // Pass in a chain knight token, if you own it, get an extra mint

        // Pass in 0 if you do not own a chain knight
        uint _mintAmount = 1;
        if(ownsChainKnight(msg.sender, chainKnightTokenId)) {
            _mintAmount = 2;
        }
        
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Contract paused");
        require(totalSupply() + _mintAmount <= maxSupply, "No enought mints left.");

        // ADD CHECK FOR 5 PER WALLET
        require(hasMinted[msg.sender] == 0, "You have already minted!");
        
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /** TOKEN URI AND METADATA ON CHAIN FUNCTIONS */
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
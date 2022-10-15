// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/IERC721A.sol';
import 'contracts/ERC721A.sol';


contract DefinitelyARug is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxSupply = 3000;
    uint256 public maxMint = 20;
    uint256 public mintPrice = 0.003 ether; // 

    string private baseURI;

    bool public revealed = false;
    bool public publicMintEnabled = false;

    mapping(address => uint256) totalPublicMint;
    mapping(address => uint256) public totalFreeMints;

    
    constructor (
        ) ERC721A("Definitely A Rug", "DRUG") {
    }

    // only allows msg.sender to be external tx origin 
    modifier userOnly {
        require(tx.origin == msg.sender,"Error: Function cannot be called by another contract");
        require(publicMintEnabled, "Public mint is currently paused");

        _;
    }

    function mint(uint256 _quantity) external payable  userOnly nonReentrant {

        if (totalFreeMints[msg.sender] < 2) {
            
            require((totalPublicMint[msg.sender] + _quantity) <= maxMint, "Error: Cannot mint more than 1");
            totalFreeMints[msg.sender] += _quantity;
            totalPublicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
            require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");

        } else {
            
            require((totalPublicMint[msg.sender] + _quantity) <= maxMint, "Error: Cannot mint more than 20");
            require(msg.value >= (_quantity * mintPrice), "Not enough ether sent");
            totalPublicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
            require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");

        }
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    return baseURI;
        
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // withdraw to owner(), i.e only if msg.sender is owner
    function withdrawTransfer() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }


}
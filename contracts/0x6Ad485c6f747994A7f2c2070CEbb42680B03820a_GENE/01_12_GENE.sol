//SPDX-License-Identifier: MIT
/*
 _______  _______  _        _______ 
(  ____ \(  ____ \( (    /|(  ____ \
| (    \/| (    \/|  \  ( || (    \/
| |      | (__    |   \ | || (__    
| | ____ |  __)   | (\ \) ||  __)   
| | \_  )| (      | | \   || (      
| (___) || (____/\| )  \  || (____/\
(_______)(_______/|/    )_)(_______/
By
 _______  _______  _______  _          _______  _______  _______  _______ _________
(  ____ )(  ___  )(  ____ \| \    /\  (  ____ \(  ___  )(       )(  ____ \\__   __/
| (    )|| (   ) || (    \/|  \  / /  | (    \/| (   ) || () () || (    \/   ) (   
| (____)|| |   | || |      |  (_/ /   | |      | |   | || || || || (__       | |   
|     __)| |   | || |      |   _ (    | |      | |   | || |(_)| ||  __)      | |   
| (\ (   | |   | || |      |  ( \ \   | |      | |   | || |   | || (         | |   
| ) \ \__| (___) || (____/\|  /  \ \  | (____/\| (___) || )   ( || (____/\   | |   
|/   \__/(_______)(_______/|_/    \/  (_______/(_______)|/     \|(_______/   )_(                       
*/
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";


contract GENE is ERC721A, Ownable {


    using Strings for uint256;

    // Supply and Price
    uint256 public constant maxSupply = 666;
    uint256 public WLcost = 0.08 ether;
    uint256 public publicCost = 0.09 ether;

    // WL
    bytes32 private merkleRoot;

    // Memory
    bool public wlActive;
    bool public pubActive;
    string private baseURI;
    bool public appendedID;

    // Claim tracker
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicClaimed;

    constructor() ERC721A("GENE by KISS", "GENE") {
    }

    function mintWL(uint256 _quantity) public payable {
        require(_quantity > 0);
        require(wlActive, "WLSALE_INACTIVE");
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(whitelistClaimed[msg.sender] + _quantity <= 2, "WLPAID_MAXED");
        unchecked {
            whitelistClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function mintPublic(uint256 _quantity) external payable {
        require(_quantity > 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(publicClaimed[msg.sender] + _quantity <= 2, "PUBLICPAID_MAXED");
        unchecked {
            publicClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function promoMint(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Over Supply");
        require(_quantity > 0, "QUANTITY_INVALID");
        _safeMint(_account, _quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWLCost(uint256 _newCost) public onlyOwner {
        WLcost = _newCost;
    }

    function setpublicCost(uint256 _newCost) public onlyOwner {
        publicCost = _newCost;
    }

    function activateWLSale() external onlyOwner {
        !wlActive ? wlActive = true : wlActive = false;
    }

    function activatePublicSale() external onlyOwner {
        !pubActive ? pubActive = true : pubActive = false;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _baseURI, bool appendID) external onlyOwner {
        if (!appendedID && appendID) appendedID = appendID; 
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (appendedID) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }
}
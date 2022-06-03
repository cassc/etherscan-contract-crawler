// SPDX-License-Identifier: UNLICENSED
// Creator: Luca Di Domenico - @luca_dd7
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Cornicelli is ERC721A, Ownable {

    uint32 private _max_supply = 14000;
    uint256 public presale_cost = 0.02 ether;
    uint256 public public_sale_cost = 0.04 ether;
    bytes32 private _merkleRootWhitelisted = 0x85a0955281e4d894d3a76439eb360857584a0fade0d1278651948fa25366b466;
    string private _myBaseURI = "ipfs://QmWBygenXB5LMx8ZCJQWBJwCKCL1svUeVDN8ZhrgXqKWYB/"; // json folder CID
    mapping(address => bool) public whitelistClaimed;
    bool public paused = true;
    bool public preSale = false;
    bool public publicSale = false;

    event NewCornicelliNFTMinted(uint256 firstTokenId, uint8 quantity, uint256 totalMinted);

    constructor() ERC721A("Cornicelli", "CORNO") {}

    function whitelistPresaleMint(bytes32[] calldata _merkleProof, uint8 _quantity) public payable {
        require(!paused, "Oops contract is paused");
        require(preSale, "Presale Hasn't started yet");
        require(_quantity > 0 && _quantity <= 10, "Need to mint at least 1 NFT and no more than 10.");
        require(msg.value >= presale_cost * _quantity, "Insufficient amount of ethers sent.");
        require(!whitelistClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _merkleRootWhitelisted, leaf), "You are not Whitelisted.");
        whitelistClaimed[msg.sender] = true;
        if(_quantity >= 5 && _quantity < 10) {
            _quantity = _quantity + 1;
        } else if (_quantity == 10) {
            _quantity = 12;
        }
        require(totalSupply() + _quantity <= _max_supply, "The total supply limit has been reached.");
        _safeMint(msg.sender, _quantity);
        emit NewCornicelliNFTMinted(_currentIndex - _quantity, _quantity, _totalMinted());
        if(msg.value > presale_cost * _quantity){
            payable(msg.sender).transfer(msg.value - (presale_cost * _quantity));
        }
    }

    function publicSaleMint(uint8 _quantity) public payable {
        require(!paused, "Oops contract is paused");
        require(publicSale, "Public Sale Hasn't started yet");
        require(_quantity > 0 && _quantity <= 6, "Need to mint at least 1 NFT and no more than 6.");
        require(balanceOf(msg.sender) == 0, "You have already minted NFTs. Don't be a whale!");
        require(msg.value >= public_sale_cost * _quantity, "Insufficient amount of ethers sent.");
        if(_quantity >= 3 && _quantity < 6) {
            _quantity = _quantity + 1;
        } else if (_quantity == 6) {
            _quantity = 8;
        }
        require(totalSupply() + _quantity <= _max_supply, "The total supply limit has been reached.");
        _safeMint(msg.sender, _quantity);
        emit NewCornicelliNFTMinted(_currentIndex - _quantity, _quantity, _totalMinted());
        if(msg.value > presale_cost * _quantity) {
            payable(msg.sender).transfer(msg.value - (presale_cost * _quantity));
        }
    }

    function freeMint(address[] calldata _to, uint256[] calldata _quantity) public onlyOwner {
        for(uint256 i = 0; i < _quantity.length; i++){
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(_myBaseURI).length != 0 ? string(abi.encodePacked(super.tokenURI(tokenId), ".json")) : '';
    }

    // getters functions

    function _baseURI() internal view virtual override returns (string memory) {
        return _myBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getTotalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    // Only Owner functions

    function whitdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setPresaleCost(uint256 _newCost) external onlyOwner {
        presale_cost = _newCost;
    }

    function setPublicSaleCost(uint256 _newCost) external onlyOwner {
        public_sale_cost = _newCost;
    }

    function setMerkleRootWhitelisted(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRootWhitelisted = _newMerkleRoot;
    }

    function setPaused(bool _newPaused) external onlyOwner {
        paused = _newPaused;
    }

    function setPresale(bool _newPresale) external onlyOwner {
        preSale = _newPresale;
    }

    function setPublicSale(bool _newPublicsale) external onlyOwner {
        publicSale = _newPublicsale;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _myBaseURI = uri;
    }
}
//  _____                     
// |  __ \                    
// | |__) |__ _ __   ___      
// |  ___/ _ \ '_ \ / _ \     
// | |  |  __/ |_) |  __/     
// |_|   \___| .__/ \___|     
//     /\  | | |              
//    /  \ | |_|              
//   / /\ \| __|              
//  / ____ \ |_               
// /_/    \_\__|_        _    
// \ \        / /       | |   
//  \ \  /\  / /__  _ __| | __
//   \ \/  \/ / _ \| '__| |/ /
//    \  /\  / (_) | |  |   < 
//     \/  \/ \___/|_|  |_|\_\                          
                            
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract pepeatwork is ERC721A, Ownable {
    bool public saleEnabled = false;
    bytes32 private merkleRoot;

    mapping(address => uint256) public _mintedCount;
    
    string public baseURI = '';
    
    uint256 constant public maxMintPerWallet = 2;
    uint256 constant public wlPrice = 0.01 ether;
    uint256 constant public publicPrice = 0.015 ether;
    uint256 constant public maxSupply = 999;

    constructor() ERC721A("Pepe At Work", "PAW") {}

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function devMint(address to, uint256 _mintAmount) external onlyOwner {
		require(_totalMinted() + _mintAmount <= maxSupply, "Sold out!");
		_safeMint(to, _mintAmount);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(saleEnabled, 'Paused!');
        require(_totalMinted() + _mintAmount <= maxSupply, "Sold out!");
        require(_mintedCount[msg.sender] + _mintAmount <= maxMintPerWallet, "Max 2 per wallet!");
        require(_mintAmount > 0 && _mintAmount <= maxMintPerWallet, "Invalid mint amount!");
        _;
    }

    function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {   
        require(msg.value >= (publicPrice * _mintAmount), "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
        _mintedCount[msg.sender] += _mintAmount;
    }

    function wlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) {
        require(_mintedCount[msg.sender] <= 0, "You have already minted, please check secondary or public.");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(msg.value >= (wlPrice * _mintAmount), "Insufficient funds!");
        _safeMint(_msgSender(), _mintAmount);
        _mintedCount[msg.sender] += _mintAmount;
    }

    function setSaleEnabled(bool _state) external onlyOwner {
        saleEnabled = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
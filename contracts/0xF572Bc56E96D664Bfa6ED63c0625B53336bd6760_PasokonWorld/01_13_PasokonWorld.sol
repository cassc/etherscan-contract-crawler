// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//  ________  ________  ________  ________  ___  __    ________  ________      
// |\   __  \|\   __  \|\   ____\|\   __  \|\  \|\  \ |\   __  \|\   ___  \    
// \ \  \|\  \ \  \|\  \ \  \___|\ \  \|\  \ \  \/  /|\ \  \|\  \ \  \\ \  \   
//  \ \   ____\ \   __  \ \_____  \ \  \\\  \ \   ___  \ \  \\\  \ \  \\ \  \  
//   \ \  \___|\ \  \ \  \|____|\  \ \  \\\  \ \  \\ \  \ \  \\\  \ \  \\ \  \ 
//    \ \__\    \ \__\ \__\____\_\  \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
//     \|__|     \|__|\|__|\_________\|_______|\|__| \|__|\|_______|\|__| \|__|
//                        \|_________|                                         


import "./ERC721A.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PasokonWorld is ERC721A, Ownable {
    string  public baseURI;

    uint256 public immutable publicMintPrice = 0.035 ether;
    uint256 public immutable wlMintPrice = 0.02 ether;
    uint32 public immutable maxSupply = 6666;
    uint32 public immutable maxPerTx = 3;

    bool public activeWl = false;
    bool public activePublic = false;

    mapping(address => bool) public wlMinted;

    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("PasokonWorld  Official", "PW") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(activePublic,"not started");

        require(amount <= maxPerTx,"max 3 per tx");
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(msg.value >= amount * publicMintPrice,"insufficient value");

        _safeMint(msg.sender, amount);
    }

    function whiteListMint(uint32 amount, bytes32[] calldata proof) public payable callerIsUser {
        require(activeWl,"not started");
        require(canMint(msg.sender,root, proof), "verification failed");

        require(amount <= maxPerTx,"max 3 per tx");
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(msg.value >= amount * wlMintPrice,"insufficient value");

        require(!wlMinted[msg.sender], "already minted");
        wlMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }

    function devMint(uint32 amount) public onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function getWlMinted(address addr) public view returns (bool){
        return wlMinted[addr];
    }

    function canMint(address account, bytes32 merkleRoot, bytes32[] calldata proof) public pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        root = merkleRoot;
    }

    function setActiveWl(bool flag) public onlyOwner {
        activeWl = flag;
    }

    function setActivePublic(bool flag) public onlyOwner {
        activePublic = flag;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}
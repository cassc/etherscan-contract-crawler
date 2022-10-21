// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Kiddoy00ts is ReentrancyGuard,ERC721A("Kiddoy00ts", "Ky00ts"), ERC721ABurnable, Ownable {
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxMint;

    bytes32 public merkleRoot;
    
    enum Phase{
        NONE,        
        KIDDO,
        FREE,
        PUBLIC
    }

    Phase public currentPhase = Phase.NONE;

    string internal kiddo;
    string internal y00ts;

    function setMaxSupply(uint256 value) public onlyOwner { 
        require(value > 0 && value <= 10000 && _totalMinted() <= value,  "Invalid max supply");
        maxSupply = value;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner { 
        mintPrice = _mintPrice;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner { 
        maxMint = _maxMint;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function cyclePhases(bytes32 _newMerkleRoot, uint256 _newSupply, uint256 _newMintPrice,uint256 _newMaxMint) external onlyOwner { 
        setMintPrice(_newMintPrice);
        setMerkleRoot(_newMerkleRoot);
        setMaxSupply(_newSupply);
        setMaxMint(_newMaxMint);
        currentPhase = Phase((uint8(currentPhase) + 1) % 4);
    }

    function stopAllPhases() external onlyOwner { 
        currentPhase = Phase.NONE;
    }

    function setSpecificPhase(Phase _phase) external onlyOwner { 
        currentPhase = _phase;
    }

    function setKiddo(string calldata _kiddo) external onlyOwner { 
        kiddo = _kiddo;
    }

    function setY00ts(string calldata _y00ts) external onlyOwner { 
        y00ts= _y00ts;
    }

    function _baseURI() internal view override returns (string memory) {
        if (((block.timestamp + 7200) % 86400) < 36000) {
            return kiddo; 
        } else {
            return y00ts;
        }
    }

    function getMintbyAddress() public view returns (uint64)
    {
        return _getAux(msg.sender);
    }

    function verifySingleMint(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);       
    }

    function verifyMultiMint(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function freeMint(bytes32[] calldata _merkleProof) external {
        require(currentPhase == Phase.FREE, "Free mint not started");        
        require(verifySingleMint(_merkleProof), "Incorrect merkle tree proof");
        require(_totalMinted() < maxSupply, "Max supply exceeded");
        uint64 auxData = _getAux(msg.sender);
        require(auxData & 1 == 0, "Max mint for this phase exceeded");
        _setAux(msg.sender, auxData | 1);
        _mint(msg.sender, 1);
    }

    function kiddoList(uint256 amount, bytes32[] calldata _merkleProof) external payable{
        require(currentPhase == Phase.KIDDO, "Kiddolist not started");  
        require(msg.value >= (mintPrice * amount), "Insufficient funds");       
        require(verifyMultiMint(_merkleProof), "Incorrect merkle tree proof");
        require(_totalMinted() + amount <= maxSupply, "Max supply exceeded");
        uint64 auxData = _getAux(msg.sender);
        require( (auxData + amount) <= maxMint, "Max mint for this phase exceeded");
        _setAux(msg.sender, auxData + uint64(amount));
        _mint(msg.sender, amount);
    }
    
    function publicMint(uint256 amount) external payable {
        require(currentPhase == Phase.PUBLIC, "Public sale not started");
        require(tx.origin == msg.sender, "Caller is not origin");
        require(msg.value >= (mintPrice * amount), "Insufficient funds");
        require(_totalMinted()+ amount <= maxSupply, "Max supply exceeded");
        require(amount <= maxMint, "Max mint for this phase exceeded");
        _mint(msg.sender, amount);
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        require(_totalMinted() + amount <= maxSupply, "Max supply exceeded");
        require(amount <= 100, "Mint amount too large for one transaction");
        _mint(to, amount);        
    }

    function withdrawFunds(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
    }
}
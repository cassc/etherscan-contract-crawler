// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract YinYangGangNFT is ERC721A("Yin Yang Gang", "YYG"), ERC721ABurnable, Ownable {
    uint256 public maxSupply;
    uint256 public mintPrice;

    bytes32 public merkleRoot;
    
    enum Phase{
        NONE,
        RAFFLE,
        WHITELIST,
        PUBLIC
    }

    Phase public currentPhase = Phase.NONE;

    string internal yin;
    string internal yang;

    function setMaxSupply(uint256 value) public onlyOwner { 
        require(value > 0 && value <= 10000 && _totalMinted() <= value,  "Invalid max supply");
        maxSupply = value;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner { 
        mintPrice = _mintPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function cyclePhases(bytes32 _newMerkleRoot, uint256 _newSupply, uint256 _newMintPrice) external onlyOwner { 
        setMintPrice(_newMintPrice);
        setMerkleRoot(_newMerkleRoot);
        setMaxSupply(_newSupply);
        currentPhase = Phase((uint8(currentPhase) + 1) % 4);
    }

    function stopAllPhases() external onlyOwner { 
        currentPhase = Phase.NONE;
    }

    function setSpecificPhase(Phase _phase) external onlyOwner { 
        currentPhase = _phase;
    }

    function setYin(string calldata _yin) external onlyOwner { 
        yin = _yin;
    }

    function setYang(string calldata _yang) external onlyOwner { 
        yang = _yang;
    }

    function _baseURI() internal view override returns (string memory) {
        if (((block.timestamp + 7200) % 86400) < 36000) {
            return yin; 
        } else {
            return yang;
        }
    }

    function verifySingleMint(address wallet, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);       
    }

    function verifyMultiMint(bytes memory data, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(data));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function raffleMint(bytes32[] calldata _merkleProof) external payable {
        require(currentPhase == Phase.RAFFLE, "Raffle sale not started"); 
        require(msg.value >= mintPrice, "Insufficient funds");
        require(verifySingleMint(msg.sender, _merkleProof), "Incorrect merkle tree proof");
        require(_totalMinted() < maxSupply, "Max supply exceeded");
        uint64 auxData = _getAux(msg.sender);
        require(auxData & 1 == 0, "Max mint for this phase exceeded");
        _setAux(msg.sender, auxData | 1);
        _mint(msg.sender, 1);
    }

    function whitelistMint(uint256 amount, bytes32[] calldata _merkleProof) external {
        require(currentPhase == Phase.WHITELIST, "Whitelist sale not started"); 
        bytes memory data = abi.encode(msg.sender, amount);
        require(verifyMultiMint(data, _merkleProof), "Incorrect merkle tree proof");
        require(_totalMinted() + amount <= maxSupply, "Max supply exceeded");
        uint64 auxData = _getAux(msg.sender);
        require(auxData & (1 << 1) == 0, "Max mint for this phase exceeded");
        _setAux(msg.sender, auxData | (1 << 1));
        _mint(msg.sender, amount);
    }

    function publicMint() external payable {
        require(currentPhase == Phase.PUBLIC, "Public sale not started");
        require(tx.origin == msg.sender, "Caller is not origin");
        require(msg.value >= mintPrice, "Insufficient funds");
        require(_totalMinted() < maxSupply, "Max supply exceeded");
        _mint(msg.sender, 1);
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        require(_totalMinted() + amount <= maxSupply, "Max supply exceeded");
        require(amount <= 30, "Mint amount too large for one transaction");
        _mint(to, amount);        
    }

    function withdrawFunds(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
    }
}
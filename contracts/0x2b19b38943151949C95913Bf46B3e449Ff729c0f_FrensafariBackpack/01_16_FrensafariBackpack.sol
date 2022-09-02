// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FrensafariBackpack is 
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable, 
    ERC1155Supply
    {   
    using SafeMath for uint256;
    uint256 public maxSupply;
    uint256 public totalSupply;    
    uint256 public minimumAmount;
    uint256 public mintWlCost;
    uint256 public mintPublicCost;

    mapping(Type => uint16) public maxSupplies;
    mapping(Type => uint16) public totalSupplies;

    bytes32 public merkleRoot;
    bytes32 public freeMintMerkleRoot;

    address public elefrenContractAddress;
    
    enum Phase {         
        PhaseT,
        PhaseOO,
        PhaseTT,
        PhaseOOT
    }

    enum Type {         
        RED,
        BLUE,
        MUDDY,
        MAGIC,
        OPENED
    }

    Phase public currentPhase;
    uint256 seed;
    uint256 constant INVERSE_BASIS_POINT = 10000;

    event MintFSB(
        address indexed receiver,
        Type indexed tokenType,
        uint256 indexed phase,
        uint256 timestamp
    ); 

    constructor() ERC1155("https://elefren-fsb.s3.amazonaws.com/{id}"){ 
        maxSupply = 7777;      
        maxSupplies[Type.RED] = 2500;
        maxSupplies[Type.BLUE] = 2500;
        maxSupplies[Type.MUDDY] = 2000;
        maxSupplies[Type.MAGIC] = 777;
        maxSupplies[Type.OPENED] = 7777;

        currentPhase = Phase.PhaseT;        
    }

    function name() external pure returns (string memory) {
        return "Frensafari Starter Backpack";
    }

    function symbol() external pure returns (string memory) {
        return "FSB";
    } 

    function mintWl(uint256 _mintAmount, bytes32[] calldata _merkleProof) external whenNotPaused payable {
        require(totalSupply < maxSupply, "Sold Out");
        if (currentPhase <= Phase.PhaseOO){
            require(totalSupply < 4444, "Sold Out Borneo Section");
        }
        
        require(msg.value >= (_mintAmount * mintWlCost), "Not enought ETH");
        
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not allowed to mint"
        );
        totalSupply += _mintAmount;
        _mintFSB(msg.sender, _mintAmount);
    }

    function mintPublic(uint256 _mintAmount) external whenNotPaused payable {        
        require(totalSupply < maxSupply, "Sold Out");
        if (currentPhase <= Phase.PhaseOO){
            require(totalSupply < 4444, "Sold Out Borneo Section");
        }
      
        require(msg.value >= (_mintAmount * mintPublicCost), "Not enought ETH");
       
        totalSupply += _mintAmount;
        _mintFSB(msg.sender, _mintAmount);
    }

    function mintAirdrop(address _minter, uint256 _mintAmount) external whenNotPaused 
        _validElefren(msg.sender) {
        require(totalSupply < maxSupply, "Sold Out");
        
        totalSupply += _mintAmount;
        _mintFSB(_minter, _mintAmount);
    }


    function mintFree(uint256 _mintAmount, bytes32[] calldata _merkleProof) external whenNotPaused payable {        
        require(currentPhase >= Phase.PhaseTT, "Maximus section not live ");        
        require(totalSupply < maxSupply, "Sold Out");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf),
            "Not allowed to mint"
        );
        
        totalSupply += _mintAmount;
        _mintFSB(msg.sender, _mintAmount);
    }

    function _mintFSB(address _minter, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            Type mintType = _pickRandomType();
            totalSupplies[mintType]++;
            _mint(_minter, uint256(mintType), 1, "0x0");
            emit MintFSB(_minter, mintType, uint256(currentPhase), block.timestamp);       
        }
    }

    function _pickRandomType() internal returns (Type) {        
        uint16 value = uint16(_random().mod(INVERSE_BASIS_POINT));
        while(true){
            if (totalSupplies[Type(value)] < maxSupplies[Type(value)]) {                
                return Type(value);                
            }
            value = uint16(_random().mod(INVERSE_BASIS_POINT));
        }
    }


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFreeMintMerkleRoot(bytes32 _freeMintMerkleRoot) internal onlyOwner {
        freeMintMerkleRoot = _freeMintMerkleRoot;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }  

    function setMintWlCost(uint256 _mintWlCost) external onlyOwner {
        mintWlCost = _mintWlCost;
    }

    function setMintPublicCost(uint256 _mintPublicCost) external onlyOwner {
        mintPublicCost = _mintPublicCost;
    }

    function setCurrentPhase(Phase phase) external onlyOwner {
        require(uint8(phase) <= 4, 'invalid phase');
        currentPhase = phase;        
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    )
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed))) % 4;
        seed++;
        return randomNumber;
    }

    function setSeed(uint256 _newSeed) public onlyOwner {
        seed = _newSeed;
    }

    function setElefrenContractAddress(address _elefrenContractAddress) public onlyOwner {
        elefrenContractAddress = _elefrenContractAddress;
    }    

     modifier _validElefren(address caller){
        assert(caller == elefrenContractAddress);
        _;
    }

    /* ADMIN ESSENTIALS */
    function adminMint(address _target, uint256[] memory tokenIds, uint256[] memory totals) external onlyOwner {
        uint256 quantity = tokenIds.length;
        require(maxSupply >= totalSupply + quantity, "Sold out");
        totalSupply += quantity;
        _mintBatch(_target, tokenIds, totals, "0x0");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _setURI(baseURI);
    }


    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
       
        require(success, "Transfer failed.");
    }
    
}
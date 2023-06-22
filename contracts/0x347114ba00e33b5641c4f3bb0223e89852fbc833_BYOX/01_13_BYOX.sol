// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BYOX is ERC1155, ERC1155Supply, Ownable {
 
    using Counters for Counters.Counter;

    struct BYOExclusive {
        bool isCollectingOpen;                                                       
        string uri;                               
        bytes32 merkle;
        mapping (address => uint256) claimed;                  
    }

    string public m_Name;
    string public m_Symbol;  
    mapping(uint256 => BYOExclusive) public BYOExclusiveData;
    Counters.Counter private itemCounter; 
    
    constructor(string memory _name,
        string memory _symbol) ERC1155("") {
        m_Name = _name;
        m_Symbol = _symbol;
    }

    // Owner only

    function createBYOExclusive(
        string memory _uri,
        bytes32 _merkle
    ) external onlyOwner {
        BYOExclusive storage byoX = BYOExclusiveData[itemCounter.current()];
        byoX.uri = _uri;
        byoX.merkle = _merkle;
        itemCounter.increment();
    }

    function editBYOExclusive(
        string memory _uri,
        bytes32 _merkle,
        uint256 _itemIdx
    ) external onlyOwner {
        BYOExclusiveData[_itemIdx].uri = _uri;    
        BYOExclusiveData[_itemIdx].merkle = _merkle;
    }   

    function ownerClaimFor (uint256 _numClaims, uint256 _itemIdx, address _receiver) external onlyOwner {
        _mint(_receiver, _itemIdx, _numClaims, "");
    }

    function toggleCollecting (uint256 _itemIdx) external onlyOwner {
        BYOExclusiveData[_itemIdx].isCollectingOpen = !BYOExclusiveData[_itemIdx].isCollectingOpen;
    }
    
    // External

    function whitelistCollect (uint256 _itemIdx, uint256 _numItems, uint256 _merkleIdx, uint256 _maxAmount, bytes32[] calldata merkleProof) external {
        require (BYOExclusiveData[_itemIdx].isCollectingOpen, "Collecting not open yet for this BYOExclusives.");             
        bytes32 nHash = keccak256(abi.encodePacked(_merkleIdx, msg.sender, _maxAmount));
        require(
            MerkleProof.verify(merkleProof, BYOExclusiveData[_itemIdx].merkle, nHash),
            "Invalid merkle proof !"
        );
        require (BYOExclusiveData[_itemIdx].claimed[msg.sender] + _numItems <= _maxAmount, "Minting more than available mints.");
        BYOExclusiveData[_itemIdx].claimed[msg.sender] = BYOExclusiveData[_itemIdx].claimed[msg.sender] + _numItems;
        _mint(msg.sender, _itemIdx, _numItems, "");
    }  

    // View

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }      

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "No token supply yet.");    
        return BYOExclusiveData[_id].uri;
    }

    function isCollectingOpen (uint256 _itemIdx) public view returns (bool) {
        return BYOExclusiveData[_itemIdx].isCollectingOpen;
    }  

    // Override

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KaijuKingzERC721.sol";

interface IRWaste {
    function burn(address _from, uint256 _amount) external;
    function updateReward(address _from, address _to) external;
} 

contract KaijuKingz is KaijuKingzERC721 {
    
    struct KaijuData {
        string name;
        string bio;
    }

    modifier kaijuOwner(uint256 kaijuId) {
        require(ownerOf(kaijuId) == msg.sender, "Cannot interact with a KaijuKingz you do not own");
        _;
    }

    IRWaste public RWaste;
    
    uint256 constant public FUSION_PRICE = 750 ether;
    uint256 constant public NAME_CHANGE_PRICE = 150 ether;
    uint256 constant public BIO_CHANGE_PRICE = 150 ether;

    /**
     * @dev Keeps track of the state of babyKaiju
     * 0 - Unminted
     * 1 - Egg
     * 2 - Revealed
     */
    mapping(uint256 => uint256) public babyKaiju;
    mapping(uint256 => KaijuData) public kaijuData;

    event KaijuFusion(uint256 kaijuId, uint256 parent1, uint256 parent2);
    event KaijuRevealed(uint256 kaijuId);
    event NameChanged(uint256 kaijuId, string kaijuName);
    event BioChanged(uint256 kaijuId, string kaijuBio);

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount) KaijuKingzERC721(name, symbol, supply, genCount) {}

    function fusion(uint256 parent1, uint256 parent2) external kaijuOwner(parent1) kaijuOwner(parent2) {
        uint256 supply = totalSupply();
        require(supply < maxSupply,                               "Cannot fuse any more baby Kaijus");
        require(parent1 < maxGenCount && parent2 < maxGenCount,   "Cannot fuse with baby Kaijus");
        require(parent1 != parent2,                               "Must select two unique parents");

        RWaste.burn(msg.sender, FUSION_PRICE);
        uint256 kaijuId = maxGenCount + babyCount;
        babyKaiju[kaijuId] = 1;
        babyCount++;
        _safeMint(msg.sender, kaijuId);
        emit KaijuFusion(kaijuId, parent1, parent2);
    }

    function reveal(uint256 kaijuId) external kaijuOwner(kaijuId) {
        babyKaiju[kaijuId] = 2;
        emit KaijuRevealed(kaijuId);
    }

    function changeName(uint256 kaijuId, string memory newName) external kaijuOwner(kaijuId) {
        bytes memory n = bytes(newName);
        require(n.length > 0 && n.length < 25,                          "Invalid name length");
        require(sha256(n) != sha256(bytes(kaijuData[kaijuId].name)),    "New name is same as current name");
        
        RWaste.burn(msg.sender, NAME_CHANGE_PRICE);
        kaijuData[kaijuId].name = newName;
        emit NameChanged(kaijuId, newName);
    }

    function changeBio(uint256 kaijuId, string memory newBio) external kaijuOwner(kaijuId) {
        RWaste.burn(msg.sender, BIO_CHANGE_PRICE);
        kaijuData[kaijuId].bio = newBio;
        emit BioChanged(kaijuId, newBio);
    }

    function setRadioactiveWaste(address rWasteAddress) external onlyOwner {
        RWaste = IRWaste(rWasteAddress);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxGenCount) {
            RWaste.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxGenCount) {
            RWaste.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < maxGenCount) {
            RWaste.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}
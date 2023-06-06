// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Sidekicks is ERC721, Ownable {
    bool public saleActive = false;
    bool public metaFlag = false;
    
    string internal baseTokenURI;

    bytes32 public merkleRoot;

    uint public totalSupply = 12500;

    uint public t2Price = 0.06 ether;
    uint public t3Price = 0.1 ether;

    uint public thNonce = 0;
    uint public t2Nonce = 0;
    uint public t3Nonce = 0;

    uint public thMax = 10000;
    uint public t2Max = 2000;
    uint public t3Max = 500;

    uint public maxTx = 20;

    mapping(address => bool) public claimed;

    constructor() ERC721("Metaguardians: Sidekicks", "SIDEK") {}


    modifier checkSupply(uint qty) {
        require(qty + (thNonce + t2Nonce + t3Nonce) <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        _;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    function setT2Price(uint newPrice) external onlyOwner {
        t2Price = newPrice;
    }

    function setT3Price(uint newPrice) external onlyOwner {
        t3Price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function toggleSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function toggleMetaFlag() public onlyOwner {
        metaFlag = !metaFlag;
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }
    
    function getTierHAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < thNonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getTier2AssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = thMax; i < (thMax + t2Nonce); i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getTier3AssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = (thMax + t2Max); i < (thMax + t2Max + t3Nonce); i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function giveawayTH(address to, uint qty) external onlyOwner {
        require(qty + thNonce <= thMax, "SUPPLY: Value exceeds Tier H Supply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = thNonce;
            _safeMint(to, tokenId);
            thNonce++;
        }
    }

    function giveawayT2(address to, uint qty) external onlyOwner {
        require(qty + t2Nonce <= t2Max, "SUPPLY: Value exceeds Tier 2 Supply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = thMax + t2Nonce;
            _safeMint(to, tokenId);
            t2Nonce++;
        }
    }

    function giveawayT3(address to, uint qty) external onlyOwner {
        require(qty + t3Nonce <= t3Max, "SUPPLY: Value exceeds Tier 3 Supply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = (thMax + t2Max) + t3Nonce;
            _safeMint(to, tokenId);
            t3Nonce++;
        }
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function mintTierH(uint qty, bytes32[] memory proof) external checkSupply(qty) {
        if(metaFlag) {
            require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
            require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        } else {
            require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, qty))), "Invalid proof");
            require(!claimed[msg.sender], "TRANSACTION: You already claimed!");
        }
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty + thNonce <= thMax, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = thNonce;
            _safeMint(msg.sender, tokenId);
            thNonce++;
        }
        claimed[msg.sender] = true;
    }

    function mintTier2(uint qty) external payable checkSupply(qty) {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + t2Nonce <= t2Max, "SUPPLY: Value exceeds Tier 2 Supply");
        require(msg.value >= t2Price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = thMax + t2Nonce;
            _safeMint(msg.sender, tokenId);
            t2Nonce++;
        }
    }

    function mintTier3(uint qty) external payable checkSupply(qty) {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + t3Nonce <= t3Max, "SUPPLY: Value exceeds Tier 3 Supply");
        require(msg.value >= t3Price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = (thMax + t2Max) + t3Nonce;
            _safeMint(msg.sender, tokenId);
            t3Nonce++;
        }
    }
    
    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
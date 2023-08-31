// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./PaymentSplitter.sol";

contract Expandables is ERC721Enumerable, ERC721Burnable, VRFConsumerBase, PaymentSplitter, Pausable, Ownable  {    
    using Strings for uint256;

    uint256 constant MAX_TOTAL_SUPPLY = 8888;

    uint256 mintPrice = 69000000000000000;
    uint256 whiteListPrice = 69000000000000000;
    bool mintingClosed;

    string private baseTokenURI;

    bytes32 merkleRoot = 0xec335a6860f7922e56c4ae0fd1d003f87bc1796ad87f4fa765cc19858ef73ad4;
    bytes32 merkleRootFree = 0x571b61c9e522a857abaa09ed96cde4fca59f4c3dc28a6baebf4164de2dcf060c;

    uint256 whitelistOpen = 1638823200;
    uint256 whitelistClose = 1638910800;
    uint256 publicOpen = 1638912600;

    Reveal[] reveals;

    mapping(uint256 => uint8) oneOnes;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public claimedFreeTokens;

    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;

    string constant public IPFS_HASH = "QmVtXCe4WY2mXHKmLcSNzskyWSLA68aAQwNiwdD6TkoXUA";
    string constant public ARWEAVE_HASH = "KpjNYjqWwQfuyxd19xT2MFY1bjibqpFunSvbMDOKOZk";

    struct Expandable {
        uint8 background;
        uint8 fur;
        uint8 mouth;
        uint8 eyes;
        uint8 clothes;
        uint8 hat;
        uint8 power;
        uint8 speed;
        uint8 cuteness;
        uint8 intelligence;
    }

    struct Reveal {
        uint256 randomness;
        uint256 untilTokenId;
    }

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _baseTokenURI,
        address[] memory payees,
        uint256[] memory shares_,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee        
    ) ERC721(_name, _symbol) PaymentSplitter(payees, shares_) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        baseTokenURI = _baseTokenURI;

        keyHash = _keyHash;
        fee = _fee;
    }    

    function mint(uint256 amount) external payable whenNotPaused {
        require (block.timestamp > publicOpen, "public sale not started");
        require(msg.value == amount * mintPrice, "payment incorrect");
        require(amount <= 10, "max tx amount exceeded");

        _mintPandas(msg.sender, amount);
    }      

    function whiteListMintFree(        
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(claimedFreeTokens[msg.sender] + amount <= maxAmount, "amount too high");
        require(block.timestamp > whitelistOpen, "whitelist sale closed");

        claimedFreeTokens[msg.sender] = claimedFreeTokens[msg.sender] + amount;

        _whitelistMint(amount, index, maxAmount, merkleProof, merkleRootFree);     
    }      

    function whitelistMint(
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(block.timestamp > whitelistOpen && block.timestamp < whitelistClose, "whitelist sale closed");
        require(msg.value == amount * whiteListPrice, "payment incorrect");
        require(claimedTokens[msg.sender] + amount <= maxAmount, "amount too high");

        claimedTokens[msg.sender] = claimedTokens[msg.sender] + amount;

        _whitelistMint(amount, index, maxAmount, merkleProof, merkleRoot);        
    }

    function _whitelistMint(
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof,
        bytes32 _merkleRoot
    ) internal {

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, _merkleRoot, node),
            "invalid merkle proof"
        );
        
        _mintPandas(msg.sender, amount);            
    }    

    function ownerMint(address to, uint256 amount) external onlyOwner {
        _mintPandas(to, amount);
    }  

    function setSaleWindows(
        uint256 _whitelistOpen, 
        uint256 _whitelistClose,
        uint256 _publicOpen
    ) external onlyOwner {
        whitelistOpen = _whitelistOpen;
        whitelistClose = _whitelistClose;
        publicOpen = _publicOpen;
    }   

    function closeMintingForever() external onlyOwner {
        mintingClosed = true;
    }   

    function setMerkleRoot(bytes32 _merkleRoot, bytes32 _merkleRootFree) external onlyOwner {
        merkleRoot = _merkleRoot;
        merkleRootFree = _merkleRootFree;
    }      

    function setPrice(uint256 _mintPrice, uint256 _whiteListPrice) external onlyOwner {
        whiteListPrice = _whiteListPrice;
        mintPrice = _mintPrice;
    }       

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }        

    function reveal() external onlyOwner returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }    

    function sendShares(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "not allowed");

        super.sendShares(account);
    } 

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }      

    function getTraits(uint256 tokenId) external view returns (Expandable memory) {
        require(reveals.length > 0 && reveals[reveals.length-1].untilTokenId >= tokenId, "not revealed yet");

        return Expandable({
            background: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getBackground(tokenId),
            fur: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getFur(tokenId),
            mouth: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getMouth(tokenId),
            eyes: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getEyes(tokenId),
            clothes: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getClothes(tokenId),
            hat: oneOnes[tokenId] != 0 ? oneOnes[tokenId] : getHat(tokenId),
            power: uint8(expandRandom(tokenId, 6) % 101),
            speed: uint8(expandRandom(tokenId, 7) % 101),
            cuteness: uint8(expandRandom(tokenId, 8) % 101),
            intelligence: uint8(expandRandom(tokenId, 9) % 101)
        });            
    }  

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId), 
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(baseTokenURI).length > 0 ? 
            string(abi.encodePacked(baseTokenURI, tokenId.toString())) : 
            "";
    }        

    function _mintPandas(address to, uint256 amount) private {
        require(totalSupply() + amount <= MAX_TOTAL_SUPPLY, "max supply exceeded");
        require(!mintingClosed, "mint closed");        

        for(uint256 i; i < amount; i++) {         
            _mint(to, totalSupply() + 1);        
        }       
    }         

    function fulfillRandomness(bytes32, uint256 _randomness) internal override {
        if(reveals.length == 0) {
            for(uint8 i=1; i <= 16; i++) {
                bool found;
                uint256 j;
                while(!found) {
                    uint256 ran = (uint256(keccak256(abi.encodePacked(i, j, _randomness))) % totalSupply()) + 1;
                    if(oneOnes[ran] == 0) {
                        found = true;
                        oneOnes[ran] = i;
                    } else {
                        j++;
                    }
                }
            }            
        }
        reveals.push(Reveal(_randomness, totalSupply()));
    }     

    function expandRandom(uint256 tokenId, uint256 nonce2) private view returns (uint256) {

        for(uint256 i; i < reveals.length; i++) {
            if(reveals[i].untilTokenId >= tokenId) {
                return uint(keccak256(abi.encodePacked(tokenId, nonce2, reveals[i].randomness)));
            }
        }
        return 0;
    } 

    function getBackground(uint256 tokenId) private view returns (uint8) {
        uint256 ran = (expandRandom(tokenId, 0) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 293) {
            return 17;
        } else if(ran <= 491) {
            return 18;            
        } else if(ran <= 815) {
            return 19;            
        } else if(ran <= 911) {
            return 20;            
        } else if(ran <= 1814) {
            return 21;            
        } else if(ran <= 3534) {
            return 22;            
        } else if(ran <= 5013) {
            return 23;            
        } else if(ran <= 5326) {
            return 24;            
        } else if(ran <= 5590) {
            return 25;            
        } else if(ran <= 5876) {
            return 26;            
        } else if(ran <= 6062) {
            return 27;            
        } else if(ran <= 6248) {
            return 28;            
        } else if(ran <= 7210) {
            return 29;            
        } else if(ran <= 7424) {
            return 30;            
        } else if(ran <= 8682) {
            return 31;            
        } else {
            return 32;            
        }                   
    }     

    function getFur(uint256 tokenId) private view returns (uint8) {
        uint256 ran = (expandRandom(tokenId, 1) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 480) {
            return 33;
        } else if(ran <= 1231) {
            return 34;            
        } else if(ran <= 2492) {
            return 35;            
        } else if(ran <= 2765) {
            return 36;            
        } else if(ran <= 3008) {
            return 37;            
        } else if(ran <= 3275) {
            return 38;            
        } else if(ran <= 3413) {
            return 39;            
        } else if(ran <= 3789) {
            return 40;            
        } else if(ran <= 4129) {
            return 41;            
        } else if(ran <= 6561) {
            return 42;            
        } else if(ran <= 7233) {
            return 43;            
        } else if(ran <= 7902) {
            return 44;            
        } else if(ran <= 8140) {
            return 45;            
        } else {
            return 46;            
        }                    
    }  

    function getMouth(uint256 tokenId) private view returns (uint8) {

        uint256 ran = (expandRandom(tokenId, 2) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 1247) {
            return 47;
        } else if(ran <= 1525) {
            return 48;
        } else if(ran <= 2162) {
            return 49;
        } else if(ran <= 2476) {
            return 50;
        } else if(ran <= 2797) {
            return 51;
        } else if(ran <= 3165) {
            return 52;
        } else if(ran <= 3313) {
            return 53;
        } else if(ran <= 3547) {
            return 54;
        } else if(ran <= 3820) {
            return 55;
        } else if(ran <= 4007) {
            return 56;
        } else if(ran <= 4255) {
            return 57;
        } else if(ran <= 4586) {
            return 58;
        } else if(ran <= 4913) {
            return 59;
        } else if(ran <= 5150) {
            return 60;
        } else if(ran <= 5386) {
            return 61;
        } else if(ran <= 5764) {
            return 62;            
        } else if(ran <= 5971) {
            return 63;            
        } else if(ran <= 6088) {
            return 64;            
        } else if(ran <= 6471) {
            return 65;            
        } else if(ran <= 6817) {
            return 66;             
        } else if(ran <= 7560) {
            return 67;             
        } else if(ran <= 7949) {
            return 68;             
        } else if(ran <= 8113) {
            return 69;             
        } else if(ran <= 8332) {
            return 70;             
        } else if(ran <= 8658) {
            return 71;
        } else {
            return 72;
        }                        
    }  

    function getEyes(uint256 tokenId) private view returns (uint8) {
        uint256 ran = (expandRandom(tokenId, 3) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 893) {
            return 73;
        } else if(ran <= 1027) {
            return 74;
        } else if(ran <= 1148) {
            return 75;
        } else if(ran <= 1464) {
            return 76;
        } else if(ran <= 1851) {
            return 77;
        } else if(ran <= 2044) {
            return 78;
        } else if(ran <= 2240) {
            return 79;
        } else if(ran <= 2336) {
            return 80;
        } else if(ran <= 2475) {
            return 81;
        } else if(ran <= 2613) {
            return 82;
        } else if(ran <= 2660) {
            return 83;
        } else if(ran <= 2853) {
            return 84;
        } else if(ran <= 3132) {
            return 85;
        } else if(ran <= 3513) {
            return 86;
        } else if(ran <= 3941) {
            return 87;
        } else if(ran <= 4836) {
            return 88;
        } else if(ran <= 5079) {
            return 89;
        } else if(ran <= 5419) {
            return 90;
        } else if(ran <= 5586) {
            return 91;
        } else if(ran <= 6009) {
            return 92;
        } else if(ran <= 6188) {
            return 93;
        } else if(ran <= 6483) {
            return 94;
        } else if(ran <= 7373) {
            return 95;
        } else if(ran <= 7634) {
            return 96;
        } else if(ran <= 7712) {
            return 97;
        } else if(ran <= 8039) {
            return 98;
        } else if(ran <= 8253) {
            return 99;
        } else if(ran <= 8675) {
            return 100;
        } else if(ran <= 8804) {
            return 101;                  
        } else {
            return 102;
        }
    }  

    function getClothes(uint256 tokenId) private view returns (uint8) {
        uint256 ran = (expandRandom(tokenId, 4) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 72) {
            return 103;
        } else if(ran <= 275) {
            return 104;
        } else if(ran <= 546) {
            return 105;
        } else if(ran <= 783) {
            return 106;
        } else if(ran <= 1276) {
            return 107;
        } else if(ran <= 1618) {
            return 108;
        } else if(ran <= 1690) {
            return 109;
        } else if(ran <= 2058) {
            return 110;
        } else if(ran <= 2205) {
            return 111;
        } else if(ran <= 2518) {
            return 112;
        } else if(ran <= 2656) {
            return 113;
        } else if(ran <= 2882) {
            return 114;
        } else if(ran <= 3426) {
            return 115;
        } else if(ran <= 3914) {
            return 116;
        } else if(ran <= 4073) {
            return 117;
        } else if(ran <= 4159) {
            return 118;
        } else if(ran <= 4437) {
            return 119;
        } else if(ran <= 4780) {
            return 120;
        } else if(ran <= 5004) {
            return 121;
        } else if(ran <= 5336) {
            return 122;
        } else if(ran <= 5664) {
            return 123;
        } else if(ran <= 5913) {
            return 124;
        } else if(ran <= 6401) {
            return 125;
        } else if(ran <= 6752) {
            return 126;
        } else if(ran <= 6909) {
            return 127;
        } else if(ran <= 6972) {
            return 128;
        } else if(ran <= 7116) {
            return 129;
        } else if(ran <= 7354) {
            return 130;
        } else if(ran <= 7597) {
            return 131;
        } else if(ran <= 7836) {
            return 132;
        } else if(ran <= 7977) {
            return 133;
        } else if(ran <= 8324) {
            return 134;
        } else {
            return 135;
        }   
    }
    
    function getHat(uint256 tokenId) private view returns (uint8) {
        uint256 ran = (expandRandom(tokenId, 5) % MAX_TOTAL_SUPPLY) + 1;

        if(ran <= 371) {
            return 136;
        } else if(ran <= 1199) {
            return 137;
        } else if(ran <= 1445) {
            return 138;
        } else if(ran <= 1954) {
            return 139;
        } else if(ran <= 2101) {
            return 140;
        } else if(ran <= 2225) {
            return 141;
        } else if(ran <= 3086) {
            return 142;
        } else if(ran <= 3247) {
            return 143;
        } else if(ran <= 3386) {
            return 144;
        } else if(ran <= 3532) {
            return 145;
        } else if(ran <= 3663) {
            return 146;
        } else if(ran <= 4061) {
            return 147;
        } else if(ran <= 4356) {
            return 148;
        } else if(ran <= 4463) {
            return 149;
        } else if(ran <= 4802) {
            return 150;
        } else if(ran <= 5243) {
            return 151;
        } else if(ran <= 5764) {
            return 152;
        } else if(ran <= 6101) {
            return 153;
        } else if(ran <= 6246) {
            return 154;
        } else if(ran <= 6371) {
            return 155;
        } else if(ran <= 6623) {
            return 156;
        } else if(ran <= 6772) {
            return 157;
        } else if(ran <= 6935) {
            return 158;
        } else if(ran <= 7446) {
            return 159;
        } else if(ran <= 7493) {
            return 160;
        } else if(ran <= 7564) {
            return 161;
        } else if(ran <= 7777) {
            return 162;
        } else if(ran <= 7940) {
            return 163;
        } else if(ran <= 8236) {
            return 164;
        } else if(ran <= 8433) {
            return 165;
        } else {
            return 166;
        }                  
    }            

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }        
}
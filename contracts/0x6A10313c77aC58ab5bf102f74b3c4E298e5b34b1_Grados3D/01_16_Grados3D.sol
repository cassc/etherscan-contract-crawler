// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Grados3D is ERC721, ERC721Enumerable, ERC2981, Ownable {
    using Strings for uint256;
    using Strings for uint8;
    bytes32 private root = 0xdc5cd25a44c36e69e9ca3896e833de1e3b9662279222692b7c97594a67dcdec5;
    //Weights of each Grados property
    uint8[] private VALUE1 = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
    uint8[] private VALUE2 = [7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 7, 7, 1, 1, 1, 7, 7];
    uint8[] private VALUE3 = [5, 15, 15, 15, 15, 15, 15];
    uint8[] private VALUE4 = [100, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 25, 25, 25, 25, 25, 25];
    uint8[] private VALUE5 = [8, 8, 6, 6, 6, 6, 5, 4, 4, 4, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1];
    uint8[] private VALUE6 = [175, 130, 130, 130, 130, 130, 130, 5, 30, 10];
    uint8[] private VALUE7 = [68, 15, 10, 7];


    // uint8[] private VALUE1 = [30, 25, 22, 18, 15, 10, 5, 1];
    // uint8[] private VALUE2 = [30, 25, 22, 18, 15, 10, 5, 1];
    // uint8[] private VALUE3 = [30, 25, 22, 18, 15, 10, 5, 1];
    // uint8[] private VALUE4 = [30, 25, 22, 18, 15, 10, 5, 1];
    // uint8[] private VALUE5 = [30, 29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1];
    // uint8[] private VALUE6 = [30, 25, 22, 18, 15, 10, 5, 1];
    // uint8[] private VALUE7 = [30, 25, 22, 18, 15, 10, 5, 1];

    string private gradosBaseURI;
    uint256 private gradosPrice = 0; // 0 ETH
    uint8 private gradosPerTx = 1;
    bool private saleIsActive = false;
    uint256 private maxGradosSupply = 0;
    uint256 private totalToBeClaim = 0;
    bool private claimIsActive = false;
    bool private allowListIsActive = false;
    bool private skip = false;
    uint8 private maxGradosAllow = 2;


    mapping(address => uint) public rewards;
    mapping(address => uint) public mintByWallet;

    struct Rewards{
        address wallet;
        uint8 quantity;
    }

    constructor() ERC721("Grados", "GRDS3D") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    event Minted(address wallet, uint256 tokenId);
    event Claimed(address wallet, uint256 amount);
    event ElToken(uint256 tokenId);
    /**
     * @dev function to convert a string to uint256.
     * https://ethereum.stackexchange.com/questions/62371/convert-a-string-to-a-uint256-with-error-handling
     */
    function strToUint(string memory _str) internal pure returns (uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return 0;
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10**(bytes(_str).length - i - 1);
        }

        return res;
    }
    
    function onAllowList(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, root, leafToCheck); 
    }
    
    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }

    function setOGHolder(Rewards[] memory rewardsByWallet) public onlyOwner  {
        for(uint8 i = 0; i < rewardsByWallet.length; i++) {
          rewards[rewardsByWallet[i].wallet] += rewardsByWallet[i].quantity;
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        gradosBaseURI = baseURI;
    }

    function setGradosPrice(uint256 price) public onlyOwner {
        gradosPrice = price;
    }

    function setGradosPerTx(uint8 perTx) public onlyOwner {
        gradosPerTx = perTx;
    }

    function setSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setClaimStatus() public onlyOwner {
        claimIsActive = !claimIsActive;
    }
    
    function setAllowListStatus() public onlyOwner {
         allowListIsActive = !allowListIsActive;
    }
    
    function setMaxGradosSupply(uint256 maxSupply) public onlyOwner {
        maxGradosSupply = maxSupply;
    }

    function setTotalToBeClaim(uint256 quantity) public onlyOwner {
        totalToBeClaim = quantity;
    }

    function setSkip() public onlyOwner {
        skip = !skip;
    }

    function setMaxGradosAllow(uint8 maxQuantity) public onlyOwner {
      maxGradosAllow = maxQuantity;
    }

    function getRandomWeightedIndex(uint seed, uint8[] memory arrayOfWeights, bool return2Characters) public view returns (string memory) {
        uint16 totalWeight = 0;
        for(uint8 i = 0; i < arrayOfWeights.length; i++) {
          totalWeight += arrayOfWeights[i];
        }
        
        uint randomWeight = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % totalWeight;
        uint16 currentWeight = 0;
        
        for(uint8 i = 0; i < arrayOfWeights.length; i++) {
            currentWeight += arrayOfWeights[i]; 
            if(randomWeight < currentWeight && i < 10) {
               if(return2Characters){
                 return string(bytes.concat(bytes("0"), bytes(i.toString())));
               } else {
                 return i.toString();
                }
             } else if (randomWeight < currentWeight && i > 9) {
               return i.toString();
             }
        }
        
        if(return2Characters) {
          return "00";
        } else {
          return "0";
        }
    }

    // function getValue2(uint seed) public view returns (string memory) {
    //   return getRandomWeightedIndex(seed, VALUE11, true);
    // }

    function getOGHoldersRewards(address wallet) public view returns(uint) {
        return rewards[wallet];
    }

    function getTotalMinted(address wallet) public view returns(uint) {
        if(skip) {
          return 0;
        }
        if (mintByWallet[wallet] >= 0) {
            return mintByWallet[wallet];
        } 
        return 0;
      }

    function getTotalToBeClaim() public view returns(uint) {
        return totalToBeClaim;
    }

    function getClaimStatus() public view returns(bool) {
        return claimIsActive;
    }

    function getAllowListStatus() public view returns(bool) {
        return allowListIsActive;
    }
    
    function getSaleStatus() public view returns(bool) {
        return saleIsActive;
    }
    
    function getPrice() public view returns(uint256) {
        return gradosPrice;
    }
    
    function getMaxGradosAllowPerWallet() public view returns(uint256) {
        return maxGradosAllow;
    }
    
    function getMaxGradosSupply() public view returns(uint256) {
        return maxGradosSupply;
    }

    function getMaxPerTx() public view returns(uint256) {
        return gradosPerTx;
    }


    function validateSeeds(uint256[][] memory seeds) public pure returns (bool) {
        bool isValid = false;
        for(uint8 i = 0; i< seeds.length; i++) {
            if (seeds[i].length == 13){
              isValid = true;
            }
        }

        return isValid;
    }
  
    function generateTokenId(uint256[] memory tokenSeeds) public view returns (uint256) {
       string memory firstPartToken = string(bytes.concat(bytes("2"),bytes(getRandomWeightedIndex(tokenSeeds[0], VALUE1, true)),bytes(getRandomWeightedIndex(tokenSeeds[1], VALUE2, true)),bytes(getRandomWeightedIndex(tokenSeeds[2], VALUE3, false)),bytes(getRandomWeightedIndex(tokenSeeds[3], VALUE4, true)),bytes(getRandomWeightedIndex(tokenSeeds[4], VALUE4, true))));
       string memory secondPartToken = string(bytes.concat(bytes(getRandomWeightedIndex(tokenSeeds[5], VALUE5, true)),bytes(getRandomWeightedIndex(tokenSeeds[6], VALUE5, true)),bytes(getRandomWeightedIndex(tokenSeeds[7], VALUE3, false)),bytes(getRandomWeightedIndex(tokenSeeds[8], VALUE4, true)),bytes(getRandomWeightedIndex(tokenSeeds[9], VALUE4, true))));
       string memory thirdPartToken = string(bytes.concat(bytes(getRandomWeightedIndex(tokenSeeds[10], VALUE6, true)),bytes(getRandomWeightedIndex(tokenSeeds[11], VALUE7, false)),bytes(getRandomWeightedIndex(tokenSeeds[12], VALUE7, false))));
       return strToUint(string(bytes.concat(bytes(firstPartToken), bytes(secondPartToken), bytes(thirdPartToken))));
    }

    function totalSupplyWithTotalToClaim() public view returns (uint256) {
      if(!claimIsActive) {
          return totalSupply(); 
      }

      return totalSupply() + totalToBeClaim;
    }

    function mint(uint256[][] memory quantity) external payable{
        require(getSaleStatus(), "Mint: Sale is not active");
        require(validateSeeds(quantity), "Mint: provided seeds no valid");
        require(quantity.length <= gradosPerTx,"Mint: grados to mint exceeds max per transations");
        require(msg.value >= gradosPrice * quantity.length, "Mint: Ether amount incorrect");
        require(getTotalMinted(msg.sender) + quantity.length <= getMaxGradosAllowPerWallet(), "Mint: this wallet already owns some Grados");
        require(totalSupply() + quantity.length <= maxGradosSupply,"Mint: Purchase would exceed max supply");
        for(uint8 i = 0; i < quantity.length; i++) {

            uint256 generatedToken = generateTokenId(quantity[i]);

            if(super._exists(generatedToken)) {
                uint256[] memory reverseSeeds;
                for (uint j = quantity.length; j > 0; j--) {
                  reverseSeeds[12 - i] = quantity[i][j];
                }
                generatedToken = generateTokenId(reverseSeeds);
                emit ElToken(generatedToken);
            } else {
              emit ElToken(generatedToken);
              _safeMint(msg.sender, generatedToken);
              mintByWallet[msg.sender] += 1; 
              emit Minted(msg.sender, generatedToken);
            }
        }
    }

    function claimReward(uint256[][] memory seeds) public{
        require(claimIsActive, "Claim Reward: is not active");
        require(validateSeeds(seeds), "Claim Reward: provided seeds no valid");
        require(seeds.length <= getOGHoldersRewards(msg.sender), "Claim Reward: Claim amount is not correct");
        require(totalSupply() + seeds.length <= maxGradosSupply,"Claim Reward: Purchase would exceed max supply");
        for(uint8 i = 0; i < seeds.length; i++) {
          uint256 generatedToken = generateTokenId(seeds[i]);
         
          if(super._exists(generatedToken)) {
            uint256[] memory reverseSeeds;
            for (uint j = seeds.length; j > 0; j--) {
               reverseSeeds[12 - i] = seeds[i][j];
             }
             generatedToken = generateTokenId(reverseSeeds);
             emit ElToken(generatedToken);
          }else {
            _safeMint(msg.sender, generatedToken);
            totalToBeClaim -= 1;
            emit ElToken(generatedToken);
            emit Minted(msg.sender, generatedToken);
          }
        }
        rewards[msg.sender] = rewards[msg.sender] - seeds.length;
        emit Claimed(msg.sender, seeds.length);
    }
    
    function allowList(uint256[][] memory seeds, bytes32[] calldata _merkleProof) external payable {
        require(_merkleProof.length > 0, "AllowList: you should provide a _merkleProof");
        require(getAllowListStatus(), "AllowList: is not active");
        require(onAllowList(_merkleProof), "AllowList: you are not allowed to mint yet");
        require(validateSeeds(seeds), "AllowList: provided seeds no valid");
        require(seeds.length <= gradosPerTx, "AllowList: seeds amount is not correct");
        require(msg.value >= gradosPrice * seeds.length, "AllowList: Ether amount incorrect");
        require(getTotalMinted(msg.sender) + seeds.length <= getMaxGradosAllowPerWallet(), "AllowList: You can not mint this quantity of Grados");
        require(totalSupply() + seeds.length <= maxGradosSupply,"AllowList: Purchase would exceed max supply");
        for(uint8 i = 0; i < seeds.length; i++) {
            uint256 generatedToken = generateTokenId(seeds[i]);

            if(super._exists(generatedToken)) {
                uint256[] memory reverseSeeds;
                for (uint j = seeds.length; j > 0; j--) {
                  reverseSeeds[12 - i] = seeds[i][j];
                }
                generatedToken = generateTokenId(reverseSeeds);
                emit ElToken(generatedToken);
            } else {
              _safeMint(msg.sender, generatedToken);
              emit ElToken(generatedToken);
              mintByWallet[msg.sender] += 1; 
              emit Minted(msg.sender, generatedToken);
            }
        }
    }

    function safeMint(address to, uint256[][] memory seeds)
        public
        onlyOwner
    {
        require(validateSeeds(seeds), "SafeMint: provided seeds no valid");
        require(totalSupply() + seeds.length <= maxGradosSupply,"SafeMint: Purchase would exceed max supply");
        for(uint8 i = 0; i < seeds.length; i++) {
          uint256 generatedToken = generateTokenId(seeds[i]);
          _safeMint(to, generatedToken);
          emit ElToken(generatedToken);
          emit Minted(to, generatedToken);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return bytes(gradosBaseURI).length > 0 ? string(abi.encodePacked(gradosBaseURI, tokenId.toString())) : "";

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
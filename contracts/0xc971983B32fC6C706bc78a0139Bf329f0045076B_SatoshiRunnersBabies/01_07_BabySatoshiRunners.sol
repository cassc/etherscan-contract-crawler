// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

//
//  __________       ___.             _________       __               .__    .__  __________                                         
//  \______   \_____ \_ |__ ___.__.  /   _____/____ _/  |_  ____  _____|  |__ |__| \______   \__ __  ____   ____   ___________  ______
//   |    |  _/\__  \ | __ <   |  |  \_____  \\__  \\   __\/  _ \/  ___/  |  \|  |  |       _/  |  \/    \ /    \_/ __ \_  __ \/  ___/
//   |    |   \ / __ \| \_\ \___  |  /        \/ __ \|  | (  <_> )___ \|   Y  \  |  |    |   \  |  /   |  \   |  \  ___/|  | \/\___ \ 
//   |______  /(____  /___  / ____| /_______  (____  /__|  \____/____  >___|  /__|  |____|_  /____/|___|  /___|  /\___  >__|  /____  >
//          \/      \/    \/\/              \/     \/                \/     \/             \/           \/     \/     \/           \/ 
//

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface SatoshiToken {
    function burnFrom(address account, uint256 amount) external;
    function getStaker(uint256 tokenId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
}

interface SatoshiRunnersNFT {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

contract SatoshiRunnersBabies is ERC721A, Ownable, ReentrancyGuard
{

    uint16 public constant MAX_TOKENS = 7000;   //Total supply
    uint16 public PRESALE_LIMIT = 3112;         //Private and Public sale limit
    uint16 public BREEDING_LIMIT = 3888;        //Breeding limit
    uint16 public presaleTokensSold = 0;
    uint16 public breedingTokenSold = 0;

    uint256 public PRICE = 37000000000000000; //0.037 eth
    uint256 public breedingFeeInSatoshi = 600000000000000000000;//600 $Satoshi to breed the babies
    uint16 public perAddressLimitPrivate = 2;
    uint16 public perAddressLimitPublic = 10;

    SatoshiToken public satoshiTokenAddress;
    SatoshiRunnersNFT public satoshiRunnersNFTAddress;
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    bool public breedingIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 root;
    mapping(address => uint16) public addressMintedBalancePrivate;
    mapping(address => uint16) public addressMintedBalancePublic;
    mapping(uint256 => bool) public hasBeenBreededBefore;

    constructor() ERC721A("Baby Satoshi Runners", "BSR") ReentrancyGuard() {
    }

    function mintToken(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");
        require(presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max private/public supply");
        require(totalSupply() + amount <= MAX_TOKENS, "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(!preSaleIsActive || addressMintedBalancePrivate[msg.sender] + amount <= perAddressLimitPrivate, "Max NFT per address exceeded for private sale");
        require(!saleIsActive || addressMintedBalancePublic[msg.sender] + amount <= perAddressLimitPublic, "Max NFT per address exceeded for public sale");
        require(amount > 0 && amount <= 10, "Max 100 NFTs per transaction");
        require(!whitelist || verify(proof), "Address not whitelisted");
                
        if(preSaleIsActive) {
            addressMintedBalancePrivate[msg.sender] += amount;
        } else if(saleIsActive) {
            addressMintedBalancePublic[msg.sender] += amount;
        }

        presaleTokensSold += amount;
        _safeMint(msg.sender, amount);
    }

    /** @dev Breeding logic between two original Satoshi Runners nfts
    *   @param fatherID   The father
    *   @param motherID   The mother
    */
    function breed(uint256 fatherID, uint256 motherID, address owner) internal {
        require(!hasBeenBreededBefore[fatherID],                                                                            "father has been breeded before");
        require(!hasBeenBreededBefore[motherID],                                                                            "mother has been breeded before");
        require(fatherID != motherID,                                                                                       "Must select two unique parents");
        require(satoshiRunnersNFTAddress.ownerOf(fatherID) == owner || satoshiTokenAddress.getStaker(fatherID) == owner,    "Father is not owned or staked by address");
        require(satoshiRunnersNFTAddress.ownerOf(motherID) == owner || satoshiTokenAddress.getStaker(motherID) == owner,    "Mother is not owned or staked by address");
        require(breedingTokenSold + 1 <= BREEDING_LIMIT,                                                                    "Breeding would exceed max supply");

        satoshiTokenAddress.burnFrom(owner, breedingFeeInSatoshi);
        hasBeenBreededBefore[fatherID] = true;
        hasBeenBreededBefore[motherID] = true;
        breedingTokenSold++;
        _safeMint(owner, 1);
    }

    function breedMultiple(uint256[] memory tokenIds) external {
        require(breedingIsActive,                                                                                           "It's not the breeding season yet!");
        require(tokenIds.length % 2 == 0,                                                                                   "The number of nfts must be an even number");
        require(msg.sender == tx.origin,                                                                                    "No transaction from smart contracts!");
        require(satoshiTokenAddress.balanceOf(msg.sender) >= breedingFeeInSatoshi * (tokenIds.length / 2),                  "Not enough $Satoshi for the breeding fee");
        require(satoshiTokenAddress.allowance(msg.sender, address(this)) >= breedingFeeInSatoshi * (tokenIds.length / 2),   "Allowed amount is less then the breeding fee");

        for (uint256 i = 0; i < tokenIds.length; i+=2) {
            breed(tokenIds[i], tokenIds[i+1], msg.sender);
        }
    }

    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setSatoshiTokenAddress(address _satoshiTokenAddress) external onlyOwner {
		satoshiTokenAddress = SatoshiToken(_satoshiTokenAddress);
	}

    function setSatoshiRunnersNFTAddress(address _satoshiRunnersNFTAddress) external onlyOwner {
        satoshiRunnersNFTAddress = SatoshiRunnersNFT(_satoshiRunnersNFTAddress);
    }

    function setPerAddressLimitPrivate(uint16 newLimit) external onlyOwner 
    {
        perAddressLimitPrivate = newLimit;
    }

    function setPerAddressLimitPublic(uint16 newLimit) external onlyOwner 
    {
        perAddressLimitPublic = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipReveal() external onlyOwner {
        revealed = !revealed;
    }

    function flipBreedingState() external onlyOwner {
        breedingIsActive = !breedingIsActive;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner 
    {
        whitelist = !whitelist;
    }
    
    function withdraw() external onlyOwner nonReentrant
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    ////
    //URI management part
    ////
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
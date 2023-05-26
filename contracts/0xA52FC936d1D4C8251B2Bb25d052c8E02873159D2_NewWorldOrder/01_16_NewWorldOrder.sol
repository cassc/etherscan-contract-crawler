//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ClaimerContract {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}




contract NewWorldOrder is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using SafeMath for uint256;

  ClaimerContract public mories;
  ClaimerContract public lossamos;


    /* Contract param */
    uint256 public MAX_TOKEN=10626; //from 0 to 9999 for mories and from 10001 to 10625 for losSamos + the 10000th
    
       
    /* Fairness param */
    string public PROVENANCE = "";//IPFS adress to provenance file
    uint256 public startingIndexBlock;//block number at the sold out time or after REVEAL_TIMESTAMP time
    uint256 public startingIndex;//derived from startingIndexBlock
    uint256 public REVEAL_TIMESTAMP;//it is the maximun time after presale before reveal 
    
    bool public claimIsActive = false;//required to be true to old SSF Owners to claim

    bool private lockClaim;//to avoid reentrant on claimToken

    /* SSF Link with    */

    uint256 public moriesRatio=1; //for 1 CryptoMories , you can claim 1 NWO
    uint256 public moriesFirstTokenId=0;
    uint256 public moriesStartIndex = 0 ;
    uint256 public moriesMaxSupply = 10000 ;

    uint256 public lossamosRatio=5; //for 1 Los Samos , you can claim 5 NWO
    uint256 public lossamosFirstTokenId=1;
    uint256 public lossamosStartIndex = 10000 ;
    uint256 public lossamosMaxSupply = 125 ;

    
    struct TriBalance {
        uint nwoBal;
        uint moriesBal;
        uint lossamosBal;
        uint moriesClaimable;
        uint lossamosClaimable;
    }



    struct NWOToken {
        uint nwoTokenId;
        uint wasClaimed;
    }

    mapping(uint => NWOToken) public nwoTokens;

    /* ************************************************************
    *       CONSTRUCTOR
    **************************************************************/
    constructor(address moriesAddress,address lossamosAddress) public ERC721("New World Order", "NWO") {
        mories=ClaimerContract(moriesAddress);
        lossamos=ClaimerContract(lossamosAddress);
    }


    /*
    * return 5 values - the canClaim returns the number of claimerContract token that can claim
    */
    function triBalanceOf(address addr) view public returns (uint nwoBal,uint moriesBal,uint lossamosBal,uint moriesCanClaim,uint lossamosCanClaim){
        uint moriesBal = mories.balanceOf(addr);
        uint lossamosBal=lossamos.balanceOf(addr);


        uint tokenId;
        uint moriesCanClaim = 0;
        
        for(uint i = 0; i < moriesBal; i++) {
            tokenId = mories.tokenOfOwnerByIndex(addr, i);
            if (!_exists(tokenId)) {moriesCanClaim++;}
        }

         
        uint lossamosCanClaim = 0;
        
        for(uint i = 0; i < lossamosBal; i++) {
            tokenId = lossamos.tokenOfOwnerByIndex(addr, i);
            if (canLosSamosClaim(tokenId)>0) {lossamosCanClaim++;}
        }

        return (balanceOf(addr),moriesBal,lossamosBal,moriesCanClaim,lossamosCanClaim);
    }

    /*
    *  Return the number of claimable nwo ie 0 or 1
    */
    function canMorieClaim(uint morieTokenId ) view public returns (uint nwoClaimable){
        uint nwoClaimable = 0;
            if (!_exists(morieTokenId)) nwoClaimable=1;
        return nwoClaimable;
    }


    /*
    *  Return the number of claimable nwo ie between 0 and 5  - Normally should be 0 or 5
    */
    function canLosSamosClaim(uint lossamosTokenId ) view public returns (uint nwoClaimable){
        uint nwoClaimable = 0;
            for(uint i=0;i<lossamosRatio;i++){
            if (!_exists(lossamosStartIndex+ lossamosTokenId + i*lossamosMaxSupply )) nwoClaimable++;
            }
        return nwoClaimable;
    }



    /**
     * RevealTime set manually by the owner at he begining of the presale .
     * Ovverdies if the collection is sold out
     */
    function setRevealTimestamp(uint256 revealTimeStampInSec) public onlyOwner {
        REVEAL_TIMESTAMP = block.timestamp + revealTimeStampInSec;
    } 

    /*     
    * Set provenance. It is calculated and saved before the presale.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /* 
    * To manage the reveal -The baseUri will be modified after
    * the startingIndex has been calculated.
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause presale if active, make active if paused - 
    * Presale for  only
    */
    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

  function trySetStartingIndexBlock() private {

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_TOKEN || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }   
  }

    /**
    * Claim token for owners of mories
    */
    function moriesOwnerClaimNTokens(uint[] memory tokenIds) public {
            claimNTokens(tokenIds,mories,moriesRatio,moriesStartIndex,moriesMaxSupply,moriesFirstTokenId);
    }

    /**
    * Claim token for owners of los Samos
    */
    function lossamosOwnerClaimNTokens(uint[] memory tokenIds) public {
            claimNTokens(tokenIds,lossamos,lossamosRatio,lossamosStartIndex,lossamosMaxSupply,lossamosFirstTokenId);
    }


    /**
    * Claim token for los samos owners 
    */
    function claimNTokens(uint[] memory tokenIds,ClaimerContract claimerContract, uint claimRatio,uint startIndex,uint maxSupply,uint firtsTokenId) public {
        
        require(claimIsActive, "Claim must be active");
        require(tokenIds.length>0, "Must claim at least one token.");
        require(totalSupply().add(tokenIds.length*claimRatio) <= MAX_TOKEN, "Purchase would exceed max supply.");
        
        for(uint i = 0; i < tokenIds.length; i++) {
                require(tokenIds[i]>=firtsTokenId,"Requested TokenId is above lower bound");
                require(tokenIds[i] <firtsTokenId+ maxSupply,"Requested TokenId is below upper bound"); 
                require(claimerContract.ownerOf(tokenIds[i]) == msg.sender, "Must own the requested tokenId to claim a NWO");
                uint _claimedTokendId = startIndex + tokenIds[i];    
                require(!_exists(_claimedTokendId), "One of the NWO has already been claimed");
        }
       

        for(uint i = 0; i < tokenIds.length; i++) {
                for(uint j = 0; j <claimRatio;j++) {
                    uint claimedTokendId = startIndex + tokenIds[i]  + j*maxSupply;
                    if (!_exists(claimedTokendId)) {
                        _safeMint(msg.sender, claimedTokendId);
                    }    
                }
        }
      
        trySetStartingIndexBlock();
    }

/**
    * Mints token - Emergency
    */
    function mintToken(uint tokenId) onlyOwner public  {
        require(tokenId >= 0, "Requested TokenId is below lower bound");
        require(tokenId <= MAX_TOKEN,"Requested TokenId is above upper bound"); 
        require(!_exists(tokenId) ,"tokenId already minted");
        
        
         _safeMint(msg.sender, tokenId);
        


    }




    /**
     * Set the starting index once the startingBlox index is known
     */
    function setStartingIndex() onlyOwner public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKEN;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKEN;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }


    /**
    * Set mories contract - Emergency only
    */
    function emergencySetMoriesContractAdress(address moriesAddress) public onlyOwner {
        mories=ClaimerContract(moriesAddress);
    }

    /**
    * Set losamos contract - Emergency only
    */
    function emergencySetLosSamosContractAdress(address losSamosAddress) public onlyOwner {
        lossamos=ClaimerContract(losSamosAddress);
    }


}
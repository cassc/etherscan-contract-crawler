// * ————————————————————————————————————————————————————————————————————————————————— *
// |                                                                                   |
// |    SSSSS K    K EEEEEE L      EEEEEE PPPPP  H    H U    U N     N K    K  SSSSS   |
// |   S      K   K  E      L      E      P    P H    H U    U N N   N K   K  S        |
// |    SSSS  KKKK   EEE    L      EEE    PPPPP  HHHHHH U    U N  N  N KKKK    SSSS    |
// |        S K   K  E      L      E      P      H    H U    U N   N N K   K       S   |
// |   SSSSS  K    K EEEEEE LLLLLL EEEEEE P      H    H  UUUU  N     N K    K SSSSS    |
// |                                                                                   |
// | * AN ETHEREUM-BASED INDENTITY PLATFORM BROUGHT TO YOU BY NEUROMANTIC INDUSTRIES * |
// |                                                                                   |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                          @@@,,,,,,,,,,,,,,,,,,,,@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@,,,,,,,,,,,,,,,,@@@@,,,@@@                        |
// |                                 @@@@@@@@@@@@@@@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                              @@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                                                                   |
// |                                                                                   |
// |   for more information visit skelephunks.com  |  follow @skelephunks on twitter   |
// |                                                                                   |
// * ————————————————————————————————————————————————————————————————————————————————— *
   
   
////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                           |                                                        //
//  The SkeleDrop Contract                   |  SkeleDrop is a way to manually airdrop crypt mints    //
//  By Autopsyop,for Neuromantic Industries  |  The tokens will be randomly selected from whats left  //
//  Part of the Skelephunks Platform         |  Only the owner of this contract can airdrop tokens    //
//                                           |                                                        //  
//////////////////////////////////////////////////////////////////////////////////////////////////////// 
// CHANGELOG
// V2: Fixes an issue where remaining claims for a wallet could be calculated incorrectly 


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleProof.sol";

interface ISkelephunks is IERC721{
    function mintedAt(uint256 tokenId) external view returns (uint256);
    function minterOf(uint256 tokenId) external view returns (address);
    function getGenderAndDirection(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex( address owner, uint256 index) external view returns (uint256);
    function numMintedReserve() external view returns (uint256);
    function maxReserveSupply() external view returns (uint256);
    function mintReserve(address to, uint256 quantity, uint256 genderDirection) external;
    function mintPrice () external view returns (uint256);
}

contract SkeleDropV2 is Ownable {   
    constructor () {
        transferOwnership( msg.sender );
        setSkelephunksContract(0x7db8cD89308A295bb2D7F809B05DB6389e9a6d88);// MAINNET
    }
    /** 
        Math
    **/
    function max(
        uint256 a,
        uint256 b
    ) private pure returns (uint256){
        if(a > b)return a;
        return b;
    }
    function min(
        uint256 a,
        uint256 b
    ) private pure returns (uint256){
        if(a < b)return a;
        return b;
    }
    /**
        The skele contract
    **/    
    ISkelephunks public skelephunksContract;

    function setSkelephunksContract( 
        address addr 
    ) public onlyOwner {
        skelephunksContract = ISkelephunks( addr );
    }
 
    /**
        function requires the skele contract
    **/    
    modifier requiresSkelephunks {
        require( ISkelephunks(address(0)) != skelephunksContract, "No Skelephunks contract linked" );
        _;
    }
    /**
        SkeleDrop requires the crypt to have supply
    **/
    function maxCryptMints(
    ) private view returns (uint256){
        return  skelephunksContract.maxReserveSupply() - skelephunksContract.numMintedReserve() - 666;
    }
    function cryptHasMints(
    ) private view returns (bool){
        return 0 < maxCryptMints() ;
    }
// ALL DROPS
    uint256 public maxDrops = 666;
    uint256 public totalDrops;//number of explicit walletDrops (per-address) allocated
    function setMaxDrops( 
        uint256 maximum 
    ) public onlyOwner {
        require(totalDrops < maximum , "Already dropped more than that" );
        require(maximum - totalDrops < maxCryptMints() , "Not enough mints in crypt" );//new max cant be supported by crypt
        maxDrops = maximum;
    }
    function remainingDrops(
    ) public view returns (uint256) {
        if (!cryptHasMints() ){
            return 0;
        }
        return maxDrops - totalDrops;
    }
    function unclaimedListDrops(
    ) public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < lists.length; i++){
                count+=lists[i].remain;
        }
        return count;
    }
    function unclaimedDrops(
    )public view returns (uint256){
        return totalDrops - totalClaims;
    }
    modifier needsRemainingDrops{
        require(0 < remainingDrops());
        _;
    }
// WALLET DROPS
    mapping( address=>uint256) walletDrops;
    function dropsForWallet(
        address wallet
    ) public view returns (uint256){
        return walletDrops[wallet];
    }
    function listDropsForWallet(
        address wallet, 
        bytes32[][] calldata proofs
    ) private view returns (uint256){
        uint256 count = 0;
        bool[] memory used = new bool[](lists.length);
        for(uint256 p = 0; p < proofs.length; p++){
            for(uint256 l = 0; l < lists.length; l++){
                if(!used[l] && lists[l].remain > count && isMember(wallet,lists[l].root,proofs[p])){
                    used[l] = true;
                    count+=remainingDropsFromListForWallet(l,wallet);
                }
            }
        }
        return count;
    }
    function remainingDropsFromListForWallet(
        uint256 index,
        address wallet
    )private view returns(uint256){
        return min(lists[index].maxPer - claimedFromList[wallet][index],lists[index].remain);
    }
    function isMember(
        address wallet, 
        bytes32 root,
        bytes32[] calldata proof
    )private pure returns (bool){
        return MerkleProof.verifyCalldata(proof,root,keccak256(abi.encodePacked(wallet)));
    }
    function totalDropsForWallet(
        address wallet,
        bytes32[][] calldata proofs
    )public view returns (uint256){
        return listDropsForWallet(wallet,proofs) + walletDrops[wallet];
    }    
    function unclaimedDropsForWallet(
        address wallet,
        bytes32[][] calldata proofs
    )public view returns (uint256){
        return claimsPaused ? 0 : totalDropsForWallet(wallet,proofs) - claimsForWallet(wallet);
    }
// ALL CLAIMS
    uint256 public totalClaims;//number of walletDrops that have been claimed (from any source)

// WALLET CLAIMS
    mapping( address=>uint256 ) claims;
    mapping( address=>mapping( uint256=>uint256 ) ) claimedFromList;
    function listClaimsForWallet(
        address wallet
    ) private view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < lists.length; i++){
            count+= claimedFromList[wallet][i];
        }
        return count;
    }
    function claimsForWallet(
        address wallet
    ) public view returns (uint256){
        return claims[wallet];
    }
// CONTROLS

    // sets the maximum to whats been allocated already to prevent future allocations 
    function freezeDrops(
    ) public onlyOwner {
        setMaxDrops(totalDrops);
    }
    /**
       claims can be paused
    **/  
    bool claimsPaused;
    function pauseClaims() public onlyOwner{ require(!claimsPaused,"claims already paused");claimsPaused = true;}
    function unpauseClaims() public onlyOwner{ require(claimsPaused,"claims not paused");claimsPaused = false;}
    modifier pauseable { require (!claimsPaused,"claimes are paused");_;}
    /**
       skeledrop enables an operator to allocate a free new mint claim to somebody from the crypt
    **/  
  
// LISTS

    struct List {
        bytes32 root;
        uint256 remain;
        uint256 maxPer;
    }
    List[] lists;
    /**
       skeledrop enables an operator to allocate create a list with access to an allocatoin of mints
    **/  
    function addList(
        bytes32 root,
        uint256 amount,
        uint256 maxPer
    )public onlyOwner{
        require(amount <= remainingDrops(),"cannot supply this many drops, please lower the amount");
        totalDrops+=amount;
        lists.push(List(root,amount,maxPer));
    }

    function quickAddList(
        bytes32 root,
        uint256 amount
    )public onlyOwner{
        addList(root,amount,1);
    }
    function remainingDropsForRoot(
        bytes32 root
    )public view returns (uint256){
        uint256 remaining;
        for(uint256 i = 0; i < lists.length; i++){//loop through all lists
            if (lists[i].root == root){
                remaining += lists[i].remain;
            }
        }
        return remaining;
    }
    function disableList(
        uint256 index
    )private onlyOwner{
        totalDrops -= lists[index].remain;
        lists[index].remain = 0;
    }
    function disableAllLists(
    ) public onlyOwner{
        require(lists.length > 0, "no lists to disable");
        for(uint256 i = 0; i < lists.length; i++){//loop through all lists
            disableList(i);
        }
    }
    function disableAllListsForRoot(// it is possible to add a root more than once. disable all matches
        bytes32 root
    ) public onlyOwner {
        uint256 found;
        for(uint256 i = 0; i < lists.length; i++){//loop through all lists
            if (lists[i].root == root && lists[i].remain > 0){
                found++;
                totalDrops -= lists[i].remain;
                lists[i].remain = 0;
            }
        }
        require(found > 0, "no active lists with that root can be found");
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

    function bulkDrop(
        address[] calldata tos,
        uint256 amount
    ) public onlyOwner needsRemainingDrops {
        require(remainingDrops() >= tos.length ,"not enuff walletDrops for all that");
        for( uint256 i = 0; i < tos.length; i++){
            drop(tos[i],amount);
        }
    }
    function quickDrop(
        address to
    ) public onlyOwner needsRemainingDrops {
        drop(to,1);
    }
    function drop(
        address to,
        uint256 amount
    ) public onlyOwner needsRemainingDrops {
        require(to != owner(), "WTF scammer");
        walletDrops[to]+=amount;
        totalDrops+=amount;
    }


    function mintFromCrypt(
        address to, 
        uint256 num, 
        uint256 gad
    ) private requiresSkelephunks {
        skelephunksContract.mintReserve(to, num, gad);
    }

    function claimDrops (
        uint256 gad
    ) public requiresSkelephunks pauseable {
        require(gad >= 0 && gad < 4, "invalid gender and direction");
        uint numDrops = walletDrops[msg.sender];
        uint numClaims = claims[msg.sender];
        uint256 dropsLeft = numDrops-numClaims ;// walletDrops left for wallet
        uint256 claimsRequested = dropsLeft;
        mintFromCrypt(msg.sender,claimsRequested,gad);// do the mint
        claims[msg.sender] += claimsRequested;//register the claims for wallet
        totalClaims += claimsRequested;//register claims to total
    }

    function claim (
        uint256 quantity,
        uint256 gad,
        bytes32[][] calldata proofs
    ) public requiresSkelephunks pauseable {
        require(gad >= 0 && gad < 4, "invalid gender and direction");
        uint256 unclaimed = unclaimedDropsForWallet(msg.sender,proofs);// all drops left for wallet
        require(quantity <= unclaimed, "not enough drops for this wallet to claim this quantity");
        uint256 requested = quantity == 0 ? unclaimed : quantity; //amount claiming - 0  = claim all
        uint requests = requested;

        // claim from lists first, then walletDrops 
        for(uint256 i = 0; i < lists.length; i++){//loop through all lists
            if( lists[i].remain > 0 && requests > 0 && claimedFromList[msg.sender][i] < lists[i].maxPer ){//claims remain, was list i max claimed by wallet?
                uint256 listRemains = remainingDropsFromListForWallet(i,msg.sender);//dont claim more than max ever
                uint256 listClaims = min(requests,listRemains);//we will claim no more than we're requesting from what remains
                lists[i].remain-=listClaims;//list remains minus claiming amount
                claimedFromList[msg.sender][i] += listClaims;// account for wallet claims from list
                require(claimedFromList[msg.sender][i]<=lists[i].maxPer,"attempted to claim more than maxPer from list");//this shouln't be possible
                requests-=listClaims;// requests less claiming amount
            }
        }
        claims[msg.sender] += requested;//register the claims for wallet
        totalClaims += requested;//register claims to total
        mintFromCrypt(msg.sender,requested,gad);// do the mint
    }

}
// SPDX-License-Identifier: MIT

/*
*
* Dev by @bitcoinski, @ultra_dao
* Thanks to @PixelVault_ for their thought leadership in the space and the mint pass approach to gas wars
* There are various mechanics in this contract heavily inspired from these trailblazers among others <3
*
* Thanks to all 111 @Ultra_DAO team members, and for this project especially:
* Project Lead: @chriswallace
* Project Mgr: @healingvisions
* Legal: @vinlysneverdie
* Artists: @grelysian | @Jae838 | @DesLucrece | @sadcop
* Story By: @crystaladalyn
* Community & Marketing: @rpowazynski | @OmarIbisa
* Discord Mods: @HeyHawX | @OmarIbisa | @ResetNft
* Meme-Daddy: @ryan_goldberg_
* Website & Web3: @calvinhoenes | @bitcoinski | @ximecediazArt
* Smart Contracts: @bitcoinski
* Art Generation: @bitcoinski
*
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './AbstractMintPassportFactory.sol';

import "hardhat/console.sol";

/*
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;::cclooddxxxkkkOOOOO0000000OOOOOkkkxxxddoolcc::;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;:clodxkkO0KKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK00Okxxdolc:;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;:oxOKXXNNNNNNNNNNNNNNNNXOxlco0NNNNNKOxolllloddkKNNNNNNNNNNNNNNNXXK0Okdl:;;;;;;;;;;;;;;
;;;;;;;;;;;;:oOXNNNNNNNNNNNNNNNNNX0xl:,'''';odkko;,'',,''''''oXNNNNNNNNNNNNNNNNNNNNNXOo:;;;;;;;;;;;;
;;;;;;;;;;;:xXNNNNNNNNNNNNNNNNKkoc;'',,,,,,....'',,,,;;,,,,,.'coxKNNNNNNNNNNNNNNNNNNNNKd:;;;;;;;;;;;
;;;;;;;;;;:xXNNNNNNNNNNNNNXOOOc'',;;;;;;;;,,..',,,;;,,;;,,,,..','c0XxoodkKNNNNNNNNNNNNNKo;;;;;;;;;;;
;;;;;;;;;;l0NNNNNNNNNNNNNXx,',..,,,,,,,,,;;;,....',,;,,;;,,'..;;'';:'.''';lkXNNNNNNNNNNNOc;;;;;;;;;;
;;;;;;;;;;dXNNNNNNNNNNNNXd,''...,,,,,,,,,,,,;;''..'',;,,;;,,,;;,,,..',,,,,''dXNNNNNNNNNNXd:;;;;;;;;;
;;;;;;;;;ckNNNNNNNNNNNN0l,,,,,.',,,,,,,,,,,,,;;,'.'',,;,,;;,,;;,,,'',,,,,;''dXNNNNNNNNNNN0l;;;;;;;;;
;;;;;;;;;l0NNNNNNNNNNNO;';;,,,,,,,,,,,;;,,,,,,;,,,,,,,;;,,;;;,,,,,,,,,,;,,,,kNNNNNNNNNNNNXd;;;;;;;;;
;;;;;;;;;dXNNNNNNNNNNNO;.;:;,,,,,,,,,,,,,,,,,,;;,,,,,,,,,,,,,,,,,,,,,,;;,;,;ONNNNNNNNNNNNNOc;;;;;;;;
;;;;;;;;:kNNNNNNNNNNNNO;.,;;,,,;,,;,,,,,,,,,,,;;,,,,,,,,,,,,,,,,,,,,,,;;;:';ONNNNNNNNNNNNNKo;;;;;;;;
;;;;;;;;cONNNNNNNNNNXk;.',;;;,,,;;;;;,,,,,,,,,;,,,,,,,,,,,,,,,,,,,,,,,,;;;..cKNNNNNNNNNNNNXx;;;;;;;;
;;;;;;;;l0NNNNNNNNNXx,',,,,;;;,,,;;,;;,,,,,,,,;;,,,,,,,,,,,,,,,,;;,,,,,,,'..:0NNNNNNNNNNNNNk:;;;;;;;
;;;;;;;;oKNNNNNNNNNk,.,,,,,,,;;,,,,,,,,,,,,,,,,;,,,,,,,,,,,,,,,,,;;,,,,,,,''lXNNNNNNNNNNNNNOc;;;;;;;
;;;;;;;;dXNNNNNNNNNKo'.',,,,,,,;,,,,,,,,,,,,,,,,,''''''',,,,,,,,,,;,,,,,,,',kNNNNNNNNNNNNNN0l;;;;;;;
;;;;;;;:xXNNNNNNNNNNNOc..,,,,,,,,,,,,,,,,;;,,,'.,;;;;;;;;,',,,,,'',,,,,,,,';ONNNNNNNNNNNNNNKo;;;;;;;
;;;;;;;:xXNNNNNNNNNNNNXk;',,,;,,,,,,,,,,,,,,;,..;:::;;;;;,',,,,,'.;:::::;'.:0NNNNNNNNNNNNNNKo;;;;;;;
;;;;;;;:kNNNNNNNNNNNNNNN0c.',;,,,,,,,,,,,,,,,;'...''...''',,,,,,''','',,,,'cKNNNNNNNNNNNNNNKo;;;;;;;
;;;;;;;:kNNNNNNNNNNNNNNNN0:.''....'',,,,,,,,,,,;,,,'.  .',,,,,,,,,,'...',,,dXNNNNNNNNNNNNNN0l;;;;;;;
;;;;;;;:kNNNNNNNNNNNNNNNNXl...........',,,,,,,,,;;;'    .,,,,,,,,,,.  .','lKNNNNNNNNNNNNNNN0c;;;;;;;
;;;;;;;:kNNNNNNNNNNNNNNXk:..',,,,,,,'..',,,,,,,,,,,.    .,,,,,,,,,.    .':ONNNNNNKxocdKNNNNkc;;;;;;;
;;;;;;;:xXNNNNNNNNNNNNNKc.',,,'...,,;,,,,,,,,,,,,,'.    .,,,,,,,,,.    .:ONNNNNXkc,,'cKNNNXx:;;;;;;;
;;;;;;;;dXNNNNNNNNNNNNNNd'',,,...''.',,,,,,,,,,,,,'.   .',,,;,'',,.   .;kNNNNNNOcldo:l0NNNKo;;;;;;;;
;;;;;;;;oKNNNNNNNNNNNNNNK:.,,,........',,,,,,,,,,,'.   .,;,,;,'.''.  ..:0NNNNNNOccdolxXNNN0l;;;;;;;;
;;;;;;;;l0NNNNNNNNNNNNNNNk;.,,,'...'..',,,,,,,,,,,,'...,;;,,,'',,,''.'.,cdxkOOxl;:xkOXNNNNkc;;;;;;;;
;;;;;;;;:kNNNNNNNNNNNNNNNXx;'',,,...'','''',,,,,,,,,,,,,;,,,'''...'',,,,,''';;,;dKNNNNNNNXx:;;;;;;;;
;;;;;;;;;dXNNNNNNNNNNNNNNNNKxoc;,''''',col,...''',;,,,,;;,,,,,;,,'''.';;,..,:;cONNNNNNNNNKo;;;;;;;;;
;;;;;;;;;l0NNNNNNNNNNNNNNNNNNNXKOxoclx0XNNd..........'',;,,,,,,;;,,:ok00kocclxKNNNNNNNNNNOc;;;;;;;;;
;;;;;;;;;:xXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd,,,,'........,,,'''';cokKNNNNNNNXXNNNNNNNNNNNXx:;;;;;;;;;
;;;;;;;;;;l0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNXl',,,,,,,,,,.cO0Okxxk0XNNNNNNNNNNNNNNNNNNNNNNNKo;;;;;;;;;;
;;;;;;;;;;;dKNNNNNNNNNNNNNNNNKOkkO0XX0kxkd;',,,,,,,,,''dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOc;;;;;;;;;;
;;;;;;;;;;;:kXNNNNNNNNNNNNN0o::cc::cc;:cl;.',,,,,,,,,'.lk0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd;;;;;;;;;;;
;;;;;;;;;;;;cONNNNNNNNNNKOd:;oxxxdoolcoxxd;',,,,,,,,'';clccoxddkKNNNNNNNNNNNNNNNNNNNNNN0l;;;;;;;;;;;
;;;;;;;;;;;;;lONNNNNNNXkc:;,lxxxdooxo:ldxo,.,,,,,,,',lxxxo:lddoc:xKXNNNNNNNNNNNNNNNNNNXx:;;;;;;;;;;;
;;;;;;;;;;;;;;lOXNNNNXxcoxl,:odo:;oxo;':c;..,,,,,'.':oddl:lxxxxoclodx0NNNNNNNNNNNNNNNXkc;;;;;;;;;;;;
;;;;;;;;;;;;;;;ckKNNNx:ldoc'',;::lxkxc,,;,.';;;;;,.,:clc;:dOOOkdxOkkolONNNNNNNNNNNXKOo:;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;:ldkx;':::c:,,d0XXNNXXKK000000OOOO00KKKKXXNNNNNXXNNNXKXNNNXXKK0Okxoc:;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;,,,,,:ccdKNNWWWWWWWWNWWWWWWNWWWWWNWWWWNNWWNNWWWWWN0xdolc::;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;:dXWNWWWWWWWWNXKNWWNNX0KNWNNWWWNNWWNNWWWWNXx:;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;:xNWWNWWWWWWW.ARDEN.WAS.HERE.kOXNWWWWWWWWNXx:;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;:dXWWWWWWWWWN.WOODIESNFT.COM.xkKNNWWWWWWWNKd;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;oKWWWWWWWWNWNNNXXXNXK0KXXKKXXXNWNWWWWWWNXkc;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;l0NWWWWWNNWWWWWWWWNWWWWWWWNWWWWWNNWWWWWNKo;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:xKNNNNNNNWWWWWNNNNNXXXXKK0000KKKKKKKXK0d:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:clooodddxxxdddooollllccc::::::cccccccc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;@ultra_dao
*/


contract WoodiesMintPassportFactory is AbstractMintPassportFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter; 

    // Roles
    bytes32 public constant WOODIE_OPERATOR_ROLE = keccak256("WOODIE_OPERATOR_ROLE");
  
    mapping(uint256 => MintPass) public mintPasses;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct MintPass {
        bytes32 merkleRoot;
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        string ipfsMetadataHash;
        address redeemableContract; // contract of the redeemable NFT
        mapping(address => uint256) claimedMPs;
    }
   
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://ipfs/") {
        name_ = _name;
        symbol_ = _symbol;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); //bitcoinski
        _setupRole(DEFAULT_ADMIN_ROLE, 0x8367A713bc14212Ab1bB8c55A778e43e50B8b927); //chriswallace
        grantRole(WOODIE_OPERATOR_ROLE, msg.sender);
    }

    function addMintPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _ipfsMetadataHash,
        address _redeemableContract,
        uint256 _maxPerWallet
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "addMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "addMintPass: window cannot be 0");


        MintPass storage mp = mintPasses[mpCounter.current()];
        mp.saleIsOpen = false;
        mp.merkleRoot = _merkleRoot;
        mp.windowOpens = _windowOpens;
        mp.windowCloses = _windowCloses;
        mp.mintPrice = _mintPrice;
        mp.maxSupply = _maxSupply;
        mp.maxMintPerTxn = _maxMintPerTxn;
        mp.maxPerWallet = _maxPerWallet;
        mp.ipfsMetadataHash = _ipfsMetadataHash;
        mp.redeemableContract = _redeemableContract;
        mpCounter.increment();

    }

    function editMintPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _ipfsMetadataHash,        
        address _redeemableContract, 
        uint256 _mpIndex,
        bool _saleIsOpen,
        uint256 _maxPerWallet
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "editMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "editMintPass: window cannot be 0");

        
        mintPasses[_mpIndex].merkleRoot = _merkleRoot;
        mintPasses[_mpIndex].windowOpens = _windowOpens;
        mintPasses[_mpIndex].windowCloses = _windowCloses;
        mintPasses[_mpIndex].mintPrice = _mintPrice;  
        mintPasses[_mpIndex].maxSupply = _maxSupply;    
        mintPasses[_mpIndex].maxMintPerTxn = _maxMintPerTxn; 
        mintPasses[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;    
        mintPasses[_mpIndex].redeemableContract = _redeemableContract;
        mintPasses[_mpIndex].saleIsOpen = _saleIsOpen; 
        mintPasses[_mpIndex].maxPerWallet = _maxPerWallet; 
    }       

    function burnFromRedeem(
        address account, 
        uint256 mpIndex, 
        uint256 amount
    ) external {
        require(mintPasses[mpIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");

        _burn(account, mpIndex, amount);
    }  

    function claim(
        uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable {
        // verify call is valid
        
        require(isValidClaim(numPasses,amount,mpIndex,merkleProof));
        
        //return any excess funds to sender if overpaid
        uint256 excessPayment = msg.value.sub(numPasses.mul(mintPasses[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        mintPasses[mpIndex].claimedMPs[msg.sender] = mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses);
        
        _mint(msg.sender, mpIndex, numPasses, "");

        emit Claimed(mpIndex, msg.sender, numPasses);
    }

    function claimMultiple(
        uint256[] calldata numPasses,
        uint256[] calldata amounts,
        uint256[] calldata mpIndexs,
        bytes32[][] calldata merkleProofs
    ) external payable {

         // verify contract is not paused
        require(!paused(), "Claim: claiming is paused");

        //validate all tokens being claimed and aggregate a total cost due
       
        for (uint i=0; i< mpIndexs.length; i++) {
           require(isValidClaim(numPasses[i],amounts[i],mpIndexs[i],merkleProofs[i]), "One or more claims are invalid");
        }

        for (uint i=0; i< mpIndexs.length; i++) {
            mintPasses[mpIndexs[i]].claimedMPs[msg.sender] = mintPasses[mpIndexs[i]].claimedMPs[msg.sender].add(numPasses[i]);
        }

        _mintBatch(msg.sender, mpIndexs, numPasses, "");

        emit ClaimedMultiple(mpIndexs, msg.sender, numPasses);

    
    }

    function mint(
        address to,
        uint256 numPasses,
        uint256 mpIndex) public onlyOwner
    {
        _mint(to, mpIndex, numPasses, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numPasses,
        uint256[] calldata mpIndexs) public onlyOwner
    {
        _mintBatch(to, mpIndexs, numPasses, "");
    }

    function isValidClaim( uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof) internal view returns (bool) {
         // verify contract is not paused
        require(mintPasses[mpIndex].saleIsOpen, "Sale is paused");
        require(!paused(), "Claim: claiming is paused");
        // verify mint pass for given index exists
        require(mintPasses[mpIndex].windowOpens != 0, "Claim: Mint pass does not exist");
        // Verify within window
        require (block.timestamp > mintPasses[mpIndex].windowOpens && block.timestamp < mintPasses[mpIndex].windowCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= numPasses.mul(mintPasses[mpIndex].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= amount, "Claim: Not allowed to claim given amount");
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= mintPasses[mpIndex].maxPerWallet, "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= mintPasses[mpIndex].maxMintPerTxn, "Max quantity per transaction exceeded");

        console.log('total supply left', totalSupply(mpIndex));
        require(totalSupply(mpIndex) + numPasses <= mintPasses[mpIndex].maxSupply, "Purchase would exceed max supply");
        
        console.log('isValidClaim leaf sender', msg.sender);
        bool isValid = verifyMerkleProof(merkleProof, mpIndex, amount);
        console.log('ISVALIDMERKLEPROOF', isValid);
       require(
            isValid,
            "MerkleDistributor: Invalid proof." 
        );  
       return isValid;
         

    }



    function isSaleOpen(uint256 mpIndex) public view returns (bool) {
        return mintPasses[mpIndex].saleIsOpen;
    }

    function turnSaleOn(uint256 mpIndex) external{
        require(isWoodiesTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mpIndex) external{
        require(isWoodiesTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = false;
    }
    
    function promoteTeamMember(address _addr) public{
        console.log('promoteTeamMember', _addr);
         grantRole(WOODIE_OPERATOR_ROLE, _addr);
    }

    function demoteTeamMember(address _addr) public {
         revokeRole(WOODIE_OPERATOR_ROLE, _addr);
    }

    function isWoodiesTeamMember(address _addr) internal view returns (bool){
        return hasRole(WOODIE_OPERATOR_ROLE, _addr) || hasRole(DEFAULT_ADMIN_ROLE, _addr);
    }

    function makeLeaf(address _addr, uint amount) public view returns (string memory) {
        return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex, uint amount) public view returns (bool) {
        if(mintPasses[mpIndex].merkleRoot == 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45){
            return true;
        }
        string memory leaf = makeLeaf(msg.sender, amount);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, mintPasses[mpIndex].merkleRoot, node);
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    function getClaimedMps(uint256 poolId, address userAdress) public view returns (uint256) {
        return mintPasses[poolId].claimedMPs[userAdress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), mintPasses[_id].ipfsMetadataHash));
    } 
}
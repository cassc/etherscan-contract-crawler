// SPDX-License-Identifier: MIT

/*

.....................................................          .....                                                              
................................................................................                                                  
........................................................................................                                          
.............................................................................................                                     
....................................................................................................                              
...........................................................................................................                       
................................................................................................................                  
.....................................................................................................................             
.......................................................................'''''...........................................           
........................................................',,,',,;;;,,,,;;;;;;;,'..........................................         
.....................................................';clclooolc::::;,;clcc:;,',,,''''....................................        
...................................................,coxxddxkkxoc;,,''':ll:;;;,',,,,''......................................       
..................................................,cddooooddol::;,,'';cc;'''''''',,''.......................................   .  
.................................................';:::::::::cool:;;:::c;,,;;,,'.................................................. 
................................................,;:cccccclcclool:',;;';:c:;,,'......      .....................................   
...............................................cxkxdddoc:ll::lllc,,;c;,''.........          ...................................   
..............................................'lOOOkkxxollollool;'.';:,...                  ......................................
...............................................ck00OOOOxdxxddxd:...';:;'.                 ........................................
..............................................'lkOOOOOOkOOkxxkdc,',,;:;'.               ..........................................
 .............................................;dOOOkkkOOkxxkkxdl:;;,;;;'.               ..........................................
 .............................................;xOkkkkkkkkkkxxdolcc::::;'.               ..........................................
    ..........................................:xkkxxkkxxxkkkxxxdddoollc,.               ..........................................
      ........................................:do:;:odkkxkkOOkxxxxxkkxl;..              ..........................................
       .......................................;c,'...'lkkOOOOkddxkkkdc'.                 .........................................
         .....................................,;::..'cx0OOOOOkxdolc,.                    .........................................
          ....................................';c;..':dO00000Okd:,.                     ..........................................
             ..................................';col,,ok000OOOkdc,.                   ............................................
               ..................................;ol;,oOOkkkkkxo;'.                   ............................................
                ..................................;dxodOOkkxxxoc,..                   ............................................
                 .................................'o000Okxxxdol:,'..          .'..    ............................................
                   ...............................'l00kxdxxddl:,'''..         ...    .............................................
                     ..............................lOOkdddddol:,'''....             ..............................................
                        ......................... .o0Oxdoolllc:,''''''.            ...............................................
                        ......................  ..'xOkdllcc:::;''''..              ...............................................
                         .....................  ...ckxl:;,;,,,'....              .................................................
                            ..................   ...'::;'.......                 .................................................
                               ................       ....                      ..................................................
                                 .............                                 ...................................................
                                           .                                       ...............................................
                                                                                        ..........................................
                                                                                                ..................................
                                                                                                  ................................
                                                                                                   ...............................
                                                                                                   ...............................
                                                                                                    ..............................
                                                                                                     ...................  ........
                                                                                                      ............................
                                                                                                      ...............  ...........
                                                                                                      ...............  ...........
                                                                                                       .........   .  ............
                                                                                                       ..               ..........
                                                                                                                        ..........
                                                                                                                       ........   
                                                                                                                      .......     
                                                                                                                      .....       
                                                                                                                       ...        
                                                                                                                                  
                                                                                                                                  
Dev by @bitcoinski
*/


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './AbstractMintPassFactory.sol';

import "hardhat/console.sol";




contract Presessence is AbstractMintPassFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter; 

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  
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

    string public _contractURI;
   
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
        _setupRole(DEFAULT_ADMIN_ROLE, 0xbf46D2161045251cB97D0B41929bc1D36044E1a0); 
        _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
        grantRole(OPERATOR_ROLE, msg.sender);
        grantRole(OPERATOR_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3);
        grantRole(OPERATOR_ROLE, 0xbf46D2161045251cB97D0B41929bc1D36044E1a0);
        grantRole(OPERATOR_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
        _contractURI = "ipfs://QmY8mJ7ZGsL3jbdUTy1o2GybrZmt2fb8pavGHUwBFikAax";
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function editMintPassWhiteListMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].merkleRoot = _merkleRoot;
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

        require(totalSupply(mpIndex) + numPasses <= mintPasses[mpIndex].maxSupply, "Purchase would exceed max supply");
        
        bool isValid = verifyMerkleProof(merkleProof, mpIndex, amount);
       
       require(
            isValid,
            "MerkleDistributor: Invalid proof." 
        );  
       return isValid;
         

    }



    function isSaleOpen(uint256 mpIndex) public view returns (bool) {
        if(paused()){
            return false;
        }
        return mintPasses[mpIndex].saleIsOpen;
    }

    function getTokenSupply(uint256 mpIndex) public view returns (uint256) {
        return totalSupply(mpIndex);
    }

    function turnSaleOn(uint256 mpIndex) external{
        require(isTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mpIndex) external{
        require(isTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = false;
    }
    
    function promoteTeamMember(address _addr) public{
         grantRole(OPERATOR_ROLE, _addr);
    }

    function demoteTeamMember(address _addr) public {
         revokeRole(OPERATOR_ROLE, _addr);
    }

    function isTeamMember(address _addr) internal view returns (bool){
        return hasRole(OPERATOR_ROLE, _addr) || hasRole(DEFAULT_ADMIN_ROLE, _addr);
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

     function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    //TODO: SET ROYALTIES HERE and in MetaData
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
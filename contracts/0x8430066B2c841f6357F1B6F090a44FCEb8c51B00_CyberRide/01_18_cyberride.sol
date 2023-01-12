// SPDX-License-Identifier: MIT

// File: contracts/CyberRide.sol


pragma solidity ^0.8.0;



//.------..------..------..------..------..------..------..------..------.
//|C.--. ||Y.--. ||B.--. ||E.--. ||R.--. ||R.--. ||I.--. ||D.--. ||E.--. |
//| :/\: || (\/) || :(): || (\/) || :(): || :(): || (\/) || :/\: || (\/) |
//| :\/: || :\/: || ()() || :\/: || ()() || ()() || :\/: || (__) || :\/: |
//| '--'C|| '--'Y|| '--'B|| '--'E|| '--'R|| '--'R|| '--'I|| '--'D|| '--'E|
//`------'`------'`------'`------'`------'`------'`------'`------'`------'
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddddddooooooddddddddddddddddddddddddddddddddddddddddddddddddd
//dddddddddddddddddddddoc:;,,'..'cdddddooodddddolododddddddddddddddddddddddddddddd
//dddddddddddddddoc;;;;,'.....   .;oddollooollcccllllooddddddddddddddddddddddddddd
//dddddddddddddo;'......'.....    ..;loooc::,,'',;:c::cloddddddddddddddddddddddddd
//ddddddddddddl;;cloddl,''''...     ..,::'........,;:;;;:coddddddddddddddddddddddd
//dddddddddddo;',''',lo:,,''''..     ..','..........'''',,;clddddddddddddddddddddd
//dddddddddddl,........,oxkl,''..    ....''''''............',,;coddddddddddddddddd
//dddddddddddo:........';;,,'''..    .........'''''.............,loddddddddddddddd
//ddddddddddddl,.......;lc,'.....     ............'''''..';;..  ..,ldddddddddddddd
//dddddddddddddl;,,,,;cdkOxc,.......     .............'..,cdxo,.   .cddddddddddddd
//ddddddddddddddoc:;,:coKNNO:'........      ..............',:xk:.   .ldddddddddddd
//dddddddddododdol:,....cxko,'...........   ................';xO:.  .;oddddddddddd
//ddddddddddddol:;;,,'.......................................'c0o.   ,oddddddddddd
//ddddddddddddoc:cclllc;'......................,;cc:;,'.......lOl.  .;oddddddddddd
//ddddddddddddc:;;;;:coo:,'......              .';:ccll;,''.'ckx,   'ldddddddddddd
//dddddddddddoc;;,,,,,:looo:,'...........       .....,clc:;,:lc'  .,lddddddddddddd
//dddddddddddoc;;,,,,,;cdxxo:,,,,,,'''''..............';:;'....  .cddddddddddddddd
//ddddddddddddl:;;;;,,,;lool:;,,,,,,,,,,,,,,,,''''''''',;:c::;'''';ldddddddddddddd
//ddddddddddddol:;;;;;;;clc:;;,,,,,,,,,,''',,,,,,''''',;:ccclol;,'';codddddddddddd
//dddddddddddddolc:::;;:looc;;;;,,,,,,;;,,''',,,,,,,,,,,,,,,;cdl;''';ldddddddddddd
//ddddddddddddddoollc:;:looc;;;;,,,,,;cc:,,'',,,,,,,,,,,,,,,,;loc,'',cdddddddddddd
//ddddddddddddddddoolc::ccc:;;;,,,;;:cllc;,,,,,,,,,,,,,,,,,,;;cdl,',,cdddddddddddd
//ddddddddddddddddddoolccc::;;;,;;cllcc:;;,,,,,,,,,,,,,,,;;;;:loc,,,;ldddddddddddd
//ddddddddddddddddddddoollcc::;;:clol:;;;;;;,;;;;;;;;;,,;;;:clol:,;:codddddddddddd
//ddddddddddddddddddddddooollcccloodoc:;;;;;;;;;;;;;;;;;;;:cclcc::cloddddddddddddd
//ddddddddddddddddddddddddooooooooddolcc:::;;;;;;;;;;;;;;;::cccllooodddddddddddddd
//dddddddddddddddddddddddddddddddddddollccc:::::::::::::::cclloooddddddddddddddddd
//ddddddddddddddddddddddddddddddddddddoollllcccccccccccccllooddddddddddddddddddddd
//dddddddddddddddddddddddddddddddddddddooolllllllllllllloooodddddddddddddddddddddd
//
// The CyberRide Gen-1: 
// Your first unique 3D voxel rides designed for any Metaverse.
// Each CyberRide Gen-1 NFT in your wallet will grant one free CyberRide on every future release. You will only have to pay the gas fee.
// Visit https://cyberride.io for details. 
//



import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import {MerkleProof} from "MerkleProof.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";


/**
 * @title CyberRide Gen-1 contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract CyberRide is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer{


    //provenance hash calculated before sale open to ensure fairness, see https://cyberride.io/provenance for more details
    string public cyberRideProvenance = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public publicSalePrice = 0.03 ether; //0.03 ETH

    uint256 public allowListPrice = 0.03 ether; //0.03 ETH

    uint public constant maxRidePurchase = 5; // 5 max ride per transaction during public sale

    uint256 public constant totalRides = 6666; // total 6,666 rides for the metaverse

    bool public saleIsActive = false;

    bool public isAllowListActive = false;

    string private _baseTokenURI;

    mapping(address => bool) public claimed;

    bytes32 public merkleRoot;// using merkleProof for efficient allowlist structure 

    constructor() ERC721A("CyberRide Gen-1", "RIDE") {}

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    

     //
     // Reserve rides for future development and collabs
     //
    function reserveRides(uint256 numberOfTokens) external onlyOwner {   
        require(totalSupply() + numberOfTokens <= totalRides, "Reserve amount would exceed max supply of CyberRide Gen-1");
    
         _safeMint(msg.sender,  numberOfTokens);
    }

   
  

    // @notice Set baseURI
    /// @param baseURI URI of the ipfs folder
    function setBaseURI(string memory baseURI) external onlyOwner {
            _baseTokenURI = baseURI;
    }


     // @notice Set merkle root for allowlist
    /// @param newRoot for the merkle tree
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
            merkleRoot = newRoot;
    }


    function alreadyClaimed(address addr) external view returns (bool) {
        return claimed[addr];
    }


    /// @notice Get uri of tokens
    /// @return string Uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    //  Set CyberRide provenance
    function setProvenance(string  memory newProvenance) external onlyOwner {
        cyberRideProvenance = newProvenance;
    }

    //
    //  Set Public Sale State
    //
    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    //
    // Set if allow list is active  
    //
    function setIsAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }


    // just in case if eth price goes crazy
    function setPublicSalePrice(uint256 newSalePrice) external onlyOwner {
        publicSalePrice = newSalePrice;
    }

    // just in case if eth price goes crazy
    function setAllowlistSalePrice(uint256 newSalePrice) external onlyOwner {
        allowListPrice = newSalePrice;
    }



    //
    // Mints CyberRide based on the number of tokens. This is allowlist only
    //
    function mintAllowList(bytes32[] calldata merkleProof) external payable nonReentrant{
        uint256 supply = totalSupply();
        require(isAllowListActive, "Allowlist is not yet active");
        require(claimed[msg.sender] == false, "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf) == true, "Invalid merkle proof");
        require(supply + 1 <= totalRides, "Purchase would exceed max supply of CyberRide Gen-1");
        require(allowListPrice <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");
    
        claimed[msg.sender] = true;
        // set starting index block starting index block is not set. Meaning the first allowlist mint
        if (startingIndexBlock==0) {
            startingIndexBlock = block.number;
        } 
        _safeMint(msg.sender, 1);
    }


    //
    // Mints CyberRide based on the number of tokens, public sale only
    //
    function mintRide(uint numberOfTokens) external payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint a CyberRide");
        require(numberOfTokens <= maxRidePurchase, "Can only mint 5 rides at a time");
        require(numberOfTokens > 0, "Can only mint a positive amount");
        require(totalSupply() + numberOfTokens <= totalRides, "Purchase would exceed max supply of CyberRide Gen-1");
        require(publicSalePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Only real users minting are supported");

        _safeMint(msg.sender, numberOfTokens);
        
    }
    
    //
    // Set the starting index for the collection
    //
    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % totalRides;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number-startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % totalRides;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex+1;
        }
    }

    //
    // Set the starting index block for the collection, essentially unblocking
    // setting starting index
    //
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}
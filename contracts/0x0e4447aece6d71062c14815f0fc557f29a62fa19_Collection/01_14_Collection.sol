// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/MerkleProof.sol";
import "./CollectionDescriptor.sol";

/*
Daisychains: Life In Every Breath.
A collection from the Logged Univere Story: MS-OS by Andy Tudhope.
https://www.untitledfrontier.studio/blog/logged-universe-5-ms-os

Scattered across that empty street, a ceramic shard came to rest in the storm water drain. 
“Give your time without fear or grief,” it said. “This is grace.”

ooolc:,.                ..........',,..,:;'.      ..';:::::::;;,.                               .;od
''...                   ..,,,,,;;::coxdoddo:.    ..';::::::clodd:::,.           ..               'ld
                         .';::::::lxKNXkddddl,.  .,;:cc::cdOKNNKxddo;.        ....               .;o
                         ..,:::::cxXWMWXOxdddl' .,;:coolokXWMMWKxdddc.     ...,,'..               .,
                          .,;cccclOWMMMWN0xddo;..;:coxxdOWMMMMWKxdddl'   ..',;;;;'..                
                ..'...    .';clood0WMMMMMWKkdo;.':loxOOkXMMMMMWXkdddc. ..,;:::::::;'..              
            ....;looolc;.. .,:ldkxkNMMMMMMWXOd:':dxx0K0XWMMMMMWXkddc'..,;:clc:::::::;,.             
          ..';:lxkxdddddoc'..;ldk0OKMMMMMMWNKxlclxkOK0KWMMMMMMWXkdc'.';clodollodxxxdo:.             
        ..';::ckNNK0Okxdddl,.'cdOK0KWMMMWWNOdllcoxOOkOXNWWWMWWNKkl;,:ldxkkxxOKXWWWWXOoc:'           
  ......',::::lOWMMWWNX0Oxdo;':dk000XNNXKOxocclldxdlloxOOOOOkxdoolcoxO000O0NMMMMMWNOxddo;.          
   ...,,;:::::cxXWMMMMMWWNKOxllldOkdxkkxddoc,;cldolc:cloddolc:cllldk00KKXNMMMMMMWNOxdddl'           
      .',;::ccclkNMMMMMMMMWNOolloxdccclool;..'coxdlcccllc:,.';clodddxOXWMMMMMMMWNOxdddl,            
       ..';:cloddk0NMMMMMMMXdccllldoc:clc;'. .cdkdlccc:;'...,codolccokKNWWMMMMWXOxddoc'      .......
         ..,;:loxOO0XWMMMWXkoo:,:coxdccc:,. .:k0Oxoc:;'.  .;ldxoc:ccldxkOKXNWNXOdoc;'.....'''',,,,..
           ..';coxOKKKNWNKOddl,..,ldkxlc:,..,OWWNOoc;'..'oOOkkdcccccllllooldxkxo:,'.',;;::::::::;'..
   ..',;;;;,...';oxOK0Okkdoooc,. .;x00Oo:,..:XMMMKxl'..lKWMWKdc::;,,'..';:clllllllllooooolcc:::::,..
  'cooddddddol:,';lodOxocccclc;'. .kWWWXkc..oXWWWXKo.,dXMMMNk:;,...  ..,:clodddkO000OOkxdolccc:::;'.
 .,oxxxxxxxxxxxxdooccoddolcccc:;...cKWMMN0l;kNNNNNXkoKNNNWNk;...,;:lccldddoooodk0KKKKK0KKXKK0Oxl::;.
,;cxKXXXXXXNNNNNNKxlclclodxdolc:;'..cKNNNNXOKWMWWNNXNMMWNN0l:cokKNWWKkxxolcc:coOXNWMMMMMMMMMMWNKxl,.
;::oKWMMMMMMMMMMMW0llc;,;cldkOOkdl;..oXNWWWNKKK0OOOO0KKXNNKKXXNWMMWXkolccccclldOXWMMMMMMMMMMWXKOko;.
:::coOXWMMMMMMMMMWKxdo,....;xXWWWNX0xd0WMWKkxxookkkxodxxkKWMWNNWNKxc;;;,;;:ccodxkKWMMMMMWWNKOxdddoc'
:::::cok0XNWWMMMMNKkdoc;'.  'oKWMMWNNNNN0OddkkddkxddxkxddxOKNWXOd:..........',:ood0NWWNX0Oxdddddo:'.
::::cclodxO0KXXNNX0xoolc:;'...':xKXNWWWKxxxddxxdddldxddxkkkx0WNK0Okxdddc;....',:cclxOOkxdddoolc;..  
,;;::ccloxkO00000kdlcccccc:;,,'..:d0NWNkddxxxddollcloddxxxxdkNMWNNWMMMMWKxolllccllccll;,,,''...     
....',,;;:cloxkkOkdolllloooodxxxkOO0XW0xxxddddoc;'';coodxxkkx0WWNNNNXXK0kxxdddooodddodl:;,''.....   
      .....',:lllodoooddxxk0NWWMMWNNWMXxdxxxdddl:;;:loddddddxKWN0dc:;:ccccccccccloxO00Okxolcc::;,,'.
    .';::cccclddlclc:;;,,,:x0XNNNNXNWMWOdxxxxdddoodoodddxkxdOWMWN0d;...',;:cclllok0KKKK0Okxdolcc:::;
 .':loddddxkOKXX0dclc,... ...,;,;:ldOXWXkxxdddxxddkxdxkxodxkXWWNNNNNOl,. .';:lodx0NWWWNXK0Okdl::::::
.:lddddxk0XNWMMMWNOxdoc:,,''.'''';oOXNWWNKkdxkxddkkkddkxdkKNNK0XNWMMMW0l.  .':odxKWMMMMMMMWWXOdc::::
'codxkOKNWMMMMMMMWN0xdoolc::::cokKNWWNNWWWX0OOkxxxxxxkOOKNWWW0l;cxOKXXKkl;'..,looKWMMMMMMMMMMWXkl::;
.,lkKNWMMMMMMMMMMMWXOdlcccclodkKWMMMNKOkdONWWWWNKKKXNWWXXNNNNXk, .;clodxxdoc::cclkNWWWWWWWWWWWWXxc:;
.;cok0XNWWMWWNNXNXK0kocclloxxxxOK0kd:'.'oXWNNWW00NNNWWWOoONWWWWk'..,:ccclodoooolldO0000000OOOOOOd:'.
.,::ccodxxkkkOO00000Oxddooolc;'.......,oKWMWN0d;dNWWNNXd.,dKWMMNd. .,:ccc:cloxxlll::loddddddddddl,. 
..,::::::codxxxxxxxxollllc:,......',;:lOWMMWk;..oXWWMWXc..;lkXXXk' ..;clllloox0Oxd:'.',:lloollc:,.  
..';::::ccccccc:;;;:loollccc:::::::cclk0XWKo'..,l0WWMMK;..,:cdkkd:. .,codxkKK00K0kdc;'.........     
..';;;;;;;,,'....,:ldOK00kxxxdoolccclxkxdl'...,:ck0KXXd. .,:ccoxxo:,.,odx0XWWWNK00Oxlc;,..          
..''......   .':lodxKNWMMWWXKOxoc:cldxo:.  .';:ccdOkxo' ..;ccccldolc:clo0WWMMMMWKOkxdoc:;,..        
..          .:odddkKWMMMMMMMWXOdllodol:,..';:ccccdkkdc. .,:llc::ldollclkNMMMMMMMWN0xolcc::,'.       
           .:odddkKWMMMMMMMWNK0Okxdolc:::cloolc:coxdlc,.,coddoollxkoclokXNWMMMMMMMW0oc:::::;,..     
           ,ldddkKWMMMMMMNK0K00Oxollllloxxxxdolccdxoll::ldxkOKK0kO0xoc:lxk0XNWWMMMMNkl:::::;,''...  
          .,lodkKWMMMMWN0kkOOkdoc:ldk0KXXNXXX0xdxkxdlllldOXNWWWNK0Kkd:.'codxkO0KNWMWOl:::;'.....    
           ..,lk0KKK0Oxdoxxdol;'.;okXWMMMMMMWX000xolcldOXWMMMMMWK00Odc,..:oddddxxOKKxc:;'..         
             .;:cclccc:clocc;'..;odkXWMMMMMMNKKKkxdl;cx0NWMMMMMMXkOkdl:'..':loddddol;,'..           
             ..';::::::cc:;,...;oddkXWMMMMMN0O0kdl:,.;ox0NWMMMMMWOdxdl:;.   .',;::;'                
               ..',;:::;;'..  .ldddkKWMMMMMKxkkdl:,..;odxOXWMMMMW0olllc:,.                          
.                ..,;;,'..    'ldddxKWMMMWXxoddl:,'..,odddkKNWMWNkl::c::,.                          
c'                .',..       .:oddx0WWWXOoccllc;'.. .:odddx0NWN0oc:::::;'.                         
oc.               ...          'coodO0Oxoc:::cc:,..   .;ldddx0Kklc::::;;;,.                       ..
dl,.              ..            ...':c:::::::::,..     .':llc:::;;,,'...''..                 ..,;;:c
do;.    .                          .';;;;::::;;'.        .','..''...........                .:lodddd
*/

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner; // = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03
    address payable public recipient; // in this instance, it will be a 0xSplit on mainnet

    CollectionDescriptor public descriptor;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    uint256 public deluxeBuyableSupply;
    mapping(uint256 => bool) public deluxeIDs;

    // for loyal mints
    mapping (address => bool) public claimed;
    bytes32 public loyaltyRoot;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address payable recipient_, uint256 startDate_, uint256 endDate_, bytes32 root_) ERC721(name_, symbol_) {
        owner = msg.sender;
        descriptor = new CollectionDescriptor();
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        loyaltyRoot = root_;

        // mint #1 to UF to kickstart it. this is from the loyal mint so also set claim to true.
        _createNFT(owner, block.timestamp, true);
        claimed[owner] = true;
    }

    // change descriptor (in case there's issues)
    // only allowed by admin/owner until 1 December 2023.
    // this is to fix potential issues or upgrade.
    // After Dec 01 2023, it's not possible anymore.
    function changeDescriptor(address _newDescriptor) public {
        require(msg.sender == owner, 'not owner');
        require(block.timestamp < 1701406800, 'cant change descriptor anymore'); //Fri Dec 01 2023 05:00:00 GMT+0000
        descriptor = CollectionDescriptor(_newDescriptor);
    }

    /*
    ERC721 code
    */
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateURI(tokenId, deluxe);
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateBase64Image(tokenId, deluxe);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateImage(tokenId, deluxe);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        bool deluxe = deluxeIDs[tokenId];
        return descriptor.generateTraits(tokenId, deluxe);
    }

    /*FOR STATS*/
    function generateFullTraitsFromVM(uint256 _seed, address _minter, bool deluxe) public view returns (string memory) {
        uint256 customTokenId = uint(keccak256(abi.encodePacked(_seed, _minter))); // seed = timestamp
        return descriptor.generateTraits(customTokenId, deluxe);
    }

    /*
    VM Viewers:
    These drawing functions are used inside the browser vm to display the NFT without having to call a live network.
    */

    // Generally used inside the browser VM
    function generateFullImageFromVM(uint256 _seed, address _owner, bool deluxe) public view returns (string memory) {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        return descriptor.generateImage(tokenId, deluxe);
    }

    function generateImageFromTokenIDAndDeluxe(uint256 tokenId, bool deluxe) public view returns (string memory) {
        return descriptor.generateImage(tokenId, deluxe);
    }

    /* PUBLIC MINT OPTIONS */
    function mintDeluxe() public payable {
        deluxeBuyableSupply+=1;
        require(deluxeBuyableSupply <= 96, "ALL DELUXE HAS BEEN SOLD");
        require(msg.value >= 0.055 ether, "MORE ETH NEEDED"); // ~$100 (~1900/ETH)
        _mint(msg.sender, block.timestamp, true);
    }

    function mint() public payable {
        require(msg.value >= 0.016 ether, "MORE ETH NEEDED"); // ~$30 (~1900/ETH)
        _mint(msg.sender, block.timestamp, false);
    }

    function loyalMint(bytes32[] calldata proof) public {
        loyalMintLeaf(proof, msg.sender);
    }

    // anyone can mint for someone in the merkle tree
    // you just need the correct proof
    function loyalMintLeaf(bytes32[] calldata proof, address leaf) public {
        // if one of addresses in the overlap set
        require(claimed[leaf] == false, "Already claimed");
        claimed[leaf] = true;

        bytes32 hashedLeaf = keccak256(abi.encodePacked(leaf));
        require(MerkleProof.verify(proof, loyaltyRoot, hashedLeaf), "Invalid Proof");
        _mint(leaf, block.timestamp, true); // mint a deluxe mint for loyal collector
    }

    /* INTERNAL MINT FUNCTIONS */
    function _mint(address _owner, uint256 _seed, bool _deluxe) internal {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        _createNFT(_owner, _seed, _deluxe);
    }

    function _createNFT(address _owner, uint256 _seed, bool _deluxe) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        if(_deluxe == true) { deluxeIDs[tokenId] = _deluxe; }
        super._mint(_owner, tokenId);
    }

    // WITHDRAWING ETH
    function withdrawETH() public {
        recipient.call{value: address(this).balance}(""); // this *should* be safe because the recipient is known
    }

    /*
    If for some reason, the split/recipient is not allowing one to withdraw, this emergency admin withdraw
    can be used to send any other address.
    If set up correctly, this will do nothing.
    */  
    function emergencyWithdraw(address _newRecipient) public {
        require(msg.sender == owner, "NOT_OWNER");
        (bool success, bytes memory returnData)  = recipient.call{value: address(this).balance}("");
        if(success == false) {
            _newRecipient.call{value: address(this).balance}("");
        } else { revert('emergency not needed'); } // this can't be used if normal withdraw works
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                                                         ...::^^: ^????JJJ?7~.  :^:::.              
//    :?7~^:                                   ...:. :!77???JJJJJY? 75YYYYYYYYYY!..~~~~~^.            
//    !5555Y!  ^!~^^^.  ........       :^^~~~~!!!!7! !YYYYYJYYYYYY? 75YYYYY5YYYY5J.:~~~~~~.  .^~^:..  
//    ?YYYYY~ ~Y5555J^ ~~~~~~~~~~^:   :777!!!!!!!!7! ~YJJJJJJJJ???^ !5YYYY7~JYYYY57 ^~~~~~^ .~~~~~~~^ 
//   .YYYYY? !YYYYY!  .~~~~~~~~~~~~^. :!!!!!!!!!~~~: !YJJJY!..      !5YYYY: :YYYYYY. ^~~~~~^~~~~~~~^. 
//   ^YYYYY7!YYYYY!   :~~~~~^^~~~~~~^ ^7!!!!~.       !YJJJJ?!!!.    !5YYYY~.7YYYYYJ.  ^~~~~~~~~~~~^   
//   75YYYYYYYYYYJ.   :~~~~~. :~~~~~^ ^7!!!!!~~~.    7YJJJJYYYY!    !5YYYYYYYYYY5Y^    ^~~~~~~~~~:    
//   JYYYYYYYYYYY?    ^~~~~~..^~~~~~. ~!!!!!!777^    7YJJJJJJJ?:    !5YYYYYY555Y7:     .~~~~~~~~:     
//  :YYYYYYYYYYYYJ    ^~~~~~~~~~~~~.  ~!!!!!!!~~.    ?YJJJJ^ .      75YYYYY?7!^.        ^~~~~~~^      
//  ~5YYYYY5YYYYYY^  .~~~~~~~~~~~~.   !!!!!!.   ...  ?YJJJJ?7?????~ 75YYY57             :~~~~~~:      
//  ?YYYYYY7JYYYY57  :~~~~~~~~~~~~:  .!!!!!!~~!!!!!:.JJJJJJYYYYYYY! J5YYY57             ^~~~~~~:      
// .YYYYYY~ !5YYYYJ. ^~~~~~:^~~~~~~  :7!!!!!!!!!!!7.:YYYYYYYJJJJJJ^ JYYJJJ~             ^~~~~~~^      
// ~5YYYY?  ~5YYYYY: ~~~~~~..~~~~~~: ~7777!!!!!!!!^ .!!~^^^:::.... .....:::::...        .:::^^~:      
// 7555557  :55YY55~.~~~~~~. ~~~~~~^ :^^::::...     ::::::    :^^~~~~: ~!!!!!!!!!~:.                  
// .~!!!!:   ~???77^.^^:::.  ...  . .^^~!!~        ^~~~~~~.   ^~~~~~~^ ~!!!!!!!!!!7!:                 
//                     .^~7????!^. .J55555J.      .~~~~~~~.   ^~~~~~~^ ~!!!!7:^7!!!7!                 
//                   :!JYYYYYYYYYJ^.YYYYY5!       :~~~~~~~    ^~~~~~~: ~!!!!!~!!!!!!:                 
//                 .7JYJJYYYYYYYJ7::YYYYY5~       ^~~~~~~^    ~~~~~~~. ~!!!!!!!!!!!:                  
//                ~JYJJJY?~~7?7^.  ^YYYYYY^       ^~~~~~~^   .~~~~~~~  ~!!!!!7!!!!!~.                 
//               !YJJJYJ^          ~5YYYYY:       ^~~~~~~^   :~~~~~~:  !!!!!!^!!!!!!!                 
//              ~YJJJJJ:           75YYYYJ.       ^~~~~~~~..:~~~~~~~  .!!!!!~ :7!!!!7:                
//             :JJJJJY~            ?YYYY5?        :~~~~~~~~~~~~~~~~.  ^7!!!7^ ~!!!!!!.                
//             7YJJJJJ:           :YYYYY57..::^^~: ~~~~~~~~~~~~~~~.   !!!!!!!!!!!!!7~                 
//            :YJJJJJY~   :7?7!~: ~5YYYYYYYYYYY55? .~~~~~~~~~~~~:    :7!!!!!!!!!!!!~                  
//            ^YJJJJJJJ?7?JYYYYY~ JYYYYYYYYYYYYY5~  .:^~~~~~^^:.     ^!!!!!!77!!!~:                   
//            .JYJJJJJJYYYJYYJ7^ ~5555555YYYYJJJ7.     .....          ....:::::..                     
//             ^?YYYYYYYYYJ?!:   7?77!~~^^::..                                                        
//              .^!77?7!~^.                                                                           

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract KreepyClub is ERC721A, Ownable {

    bytes32 public ogRoot; // Merkle Root for OGs
    bytes32 public kreeplistRoot;  // Merkle Root for Kreeplist 

    string public kreepyKey = ""; // Provenance Hash 

    uint256 public kreepyPrice = 69000000000000000; // 0.069 ETH

    uint public constant maxOGPurchase = 6;
    uint public constant maxKreeplistPurchase = 3;
    uint public constant maxKreepPurchase = 3;

    uint256 public availableKreeps = 9999;

    bool public saleIsActive = false;
    bool public kreeplistIsActive = false;
    bool public ogSaleIsActive = false;

    // Withdraw addresses
    address t1 = 0xf0050336d1B33fc14738f4108152c78Fd7457889; // KREEP
    address t2 = 0x49FFBd039464d1EB28fFc285165D8E13549EbA86; // TOMO
    address t3 = 0xb20E0A0a0310403CA03952aa4de26091a40f9000; // JUNK
    address t4 = 0x8323cc95c6fc88C832086e38869cFe1d834A4980; // DEVS (PVNKS.COM)
    address t5 = 0x42BE36f54a5054Bb7cfc768e5fB35C8Ca7c17707; // SKOLLEE
    address t6 = 0x644F86B5a22d0f14733612506c9d61Ae3E3a0bd8; // KREEPY CLUB
    
    // Reserve up to 300 Kreepies for founders (100 per artist) for marketing, giveaways etc.
    uint public foundersReserve = 300;

    string private _baseTokenURI;

    constructor() ERC721A("KREEPY CLUB", "KREEPS") { }

    modifier kreepyCapture() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(((_total)/100)*19)); // KREEP
        require(payable(t2).send(((_total)/100)*19)); // TOMO
        require(payable(t3).send(((_total)/100)*19)); // JUNK
        require(payable(t4).send(((_total)/100)*30)); // DEVS (PVNKS)
        require(payable(t5).send(((_total)/100)*8));  // SKOLLEE
        require(payable(t6).send(((_total)/100)*5));  // KREEPY COLD
    }
    
    function reserveKreeps(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= foundersReserve, "unable to mint any further for founders");
        _safeMint(_to, _reserveAmount);
        foundersReserve = foundersReserve - _reserveAmount;
    }

    function setTheKreepyPrice(uint256 newPrice) public onlyOwner {
        kreepyPrice = newPrice;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        kreepyKey = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipKreeplistSale() public onlyOwner {
        kreeplistIsActive = !kreeplistIsActive;
    }

    function flipOGSale() public onlyOwner {
        ogSaleIsActive = !ogSaleIsActive;
    }

    function setOGRoot(bytes32 root) external onlyOwner {
        ogRoot = root;
    }

    function setKreeplistRoot(bytes32 root) external onlyOwner {
        kreeplistRoot = root;
    }

    // Utility 

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Minting

    function ogMint(uint kreepAmount, bytes32[] calldata proof) public payable kreepyCapture {
        require(ogSaleIsActive, "Kreep List Sale is not active");
        require(numberMinted(msg.sender) + kreepAmount <= maxOGPurchase,"you cannot mint this many");
        require(totalSupply() + kreepAmount <= availableKreeps, "Supply would be exceeded");
        require(MerkleProof.verify(proof, ogRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");
        require(msg.value >= kreepyPrice * kreepAmount, "Ether value sent is incorrect");

            _safeMint(msg.sender, kreepAmount);
    } 

    function kreeplistMint(uint kreepAmount, bytes32[] calldata proof) public payable kreepyCapture {
        require(kreeplistIsActive, "Kreep List Sale is not active");
        require(numberMinted(msg.sender) + kreepAmount <= maxKreeplistPurchase,"you cannot mint this many"); 
        require(totalSupply() + kreepAmount <= availableKreeps, "Supply would be exceeded");
        require(MerkleProof.verify(proof, kreeplistRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");
        require(msg.value >= kreepyPrice * kreepAmount, "Ether value sent is incorrect");

            _safeMint(msg.sender, kreepAmount);
    } 

    function publicMint(uint kreepAmount) public payable kreepyCapture {
        require(saleIsActive, "Public Sale is not active");
        require(kreepAmount > 0 && kreepAmount <= maxKreepPurchase, "This is not possible");
        require(totalSupply() + kreepAmount <= availableKreeps, "Supply would be exceeded");
        require(msg.value >= kreepyPrice * kreepAmount, "Ether value sent is incorrect");

            _safeMint(msg.sender, kreepAmount);
    } 

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
       .';:cc:;,.                                           
   ..,;cloooooolc;'.                          .......       
  .;ldoooooooooooooc'                     .';:cllllllc;,'.  
 .;odoooooooooooooool,                  .;coooooooooooool;. 
 .:ddddddooooooooooool'    ..   ..     'coooooooooooooooodc.
 'dxdddddddddooooooooo;..':c,,;::.    'looooooooooooooooodo'
 ;xxxxxdddddddddddooool:loooooooc:::;;cooooooooooooooddddddc
 ,xxxxxxxxxddddddddddddddoooooooooooooooooooooddddddddddddxl
 .lkxxxxxxxxxxxdddddddddddddddddddddddddddddddddddddddxxxxxl
  .okkxkxxxxxxxxxxxxxxxddddddddddddddddddddddddxxxxxxxxxxxd;
   .:dkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;.
     .,lxkkkkxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxdc'  
      'okkkkkkkxkkkkkkxxkkxkxoodxxxxxkxc,cxkxxkkxxkd:;'.    
    .;dkkkkkkkkkxkdldxxxkkko,..'okxkkx:. .okxkkkxkko.       
  .,oxkkkkkkkkkxkx, .lkxxkd,..  ;xkkx:....lkxkkkkkxxl.      
 .:xkkkkkkkkkkkkko.  .okkx; ,c;..okxc..c'.ckkkkkkkxxkl.     
.cxkkkkkkkkkkkkkko....,dkc..oxd; ;xl..lx, ;kkxkkkkkkxkl.    
,ooxkkkkkkkkkkkkko..l,.;l'.ckkkl..c'.:xk; ,xkxkkkkkkkx:.    
,.,dkkkkkkkkkkkkkl..od'.. ,xkkkx, ..,xkkc 'xkkkkkkkkkx;     
  ,xkkkkkkkkkkkkkl..oko,.'okkkxkl. ,dkkkl..dkkkkkkkkkko.    
  'xkkkkkkkkkkkkkl..okkdodkkkkkkxdoxkkkko..okkkkkkkkkkd'    
  .dkkkkkkkkkkkkkl..okkkkkkkkkkkkkkkkkkko..lkkkkkkkkkkx,    
  .lkkkkkkkkkkkkkl..oxxxxxxxdddddddddoool..lkkkkkkkkkkx,    
   ,xkkkkkkkkkkkkl. ..............'.......,dkkkkkkkkkkd.    
   .:xkkkkkkkkkkkxlllllllllooooooodddddddxxkkkkkkkkkkkc     
    .:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko.     
      ,dkkkkkkkkkkkkkkkkkkkkxkkkxxxxxkkkkkkkkkkkkkkxl.      
       .:dkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkd:.       
         .cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.         
           .:oxxxxxxxxdddddddddddddddddddddxxdc,.           
             .'codddddddddddddddddddddddddoc,.              
                .,coddddddddddddddddddddl;.                 
                   .,:lddooooddddoooodc,.                   
                      ..,:looooooool:'.                     
                          ..,;;;;,'.

Project licensed to DISTRITO FASHION L.L.C.                          
 */

contract NohowSquad is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    mapping (address => uint256) public numberOfWLMintsOnAddress;
    mapping (address => uint256) public numberOfPublicMintsOnAddress;

    //Sale flags
    bool public OGSaleActive = false;
    bool public WLSaleActive = false;
    bool public communitySale = false;
    bool public saleActive = false;

    //Front-end UI Flags
    bool public PreWL = false;
    bool public PreCommunity = false;
    bool public PrePublic = false;

    //Mint limits
    uint public immutable ADDRESS_WL_MAX_MINTS = 2;
    uint public immutable ADDRESS_OG_MAX_MINTS = 3;
    uint public ADDRESS_PUBLIC_MAX_MINTS = 2;
    uint public ADDRESS_MAX_MINTS = 5; 

    //Supply
    uint256 public maxSupply = 4444;

    //Pricing
    uint256 public OGPrice = 0.06 ether;
    uint256 public MLPrice = 0.079 ether;
    uint256 public Price = 0.099 ether;

    //Pre-reveal IPFS link
    string private _baseTokenURI = "";

    //Merkle roots
    bytes32 public OGMerkleRoot;
    bytes32 public WLMerkleRoot;
    bytes32 public CommunityMerkleRoot;

    //Payable addresses

    constructor() ERC721A("Nohow Squad", "NohowSquad") {
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * OG mint
     */
    function mintOGSale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {

        require(OGSaleActive, "Presale must be active to mint");    

        require(MerkleProof.verify(_merkleProof, OGMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");

        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfWLMintsOnAddress[msg.sender] + numberOfMints <=  ADDRESS_OG_MAX_MINTS, "Sender is trying to mint more than their whitelist amount");
        require(totalSupply() + numberOfMints <= maxSupply, "This would exceed the max number of mints");
        require(msg.value >= numberOfMints * OGPrice, "Not enough ether to mint");

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Whitelist mint
     */
    function mintWLSale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {
        
        require(WLSaleActive, "Sale must be active to mint"); 

        require(MerkleProof.verify(_merkleProof, WLMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");

        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfWLMintsOnAddress[msg.sender] + numberOfMints <= ADDRESS_WL_MAX_MINTS, "Sender is trying to mint more than their whitelist amount");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * MLPrice, "Not enough ether to mint");

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Community mint
     */
    function mintCommunitySale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {
        
        require(communitySale, "Sale must be active to mint"); 

        require(MerkleProof.verify(_merkleProof, CommunityMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");

        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfWLMintsOnAddress[msg.sender] + numberOfMints <= ADDRESS_WL_MAX_MINTS, "Sender is trying to mint more than their whitelist amount");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * Price, "Not enough ether to mint");

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Public mint
     */
    function mintPublic(uint256 numberOfMints) external payable callerIsUser {

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfPublicMintsOnAddress[msg.sender] + numberOfMints <= ADDRESS_PUBLIC_MAX_MINTS, "Sender is trying to mint more than their public amount");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * Price, "Amount of ether is not enough");

        numberOfPublicMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Reserve mint for founders
     */
    function reserveMint(uint256 quantity, address recipient) external onlyOwner {

        require(totalSupply() + quantity <= maxSupply, "Too many minted to perform dev mint");
        
        _safeMint(recipient, quantity);  
    }

    function toggleOGSale() external onlyOwner {
        OGSaleActive = !OGSaleActive;
    }

    function PreWLFlags() external onlyOwner {
        OGSaleActive = false;
        PreWL = true;
        PreCommunity = false;
        PrePublic = false;
    }

    function toggleWLSale() external onlyOwner {
        WLSaleActive = !WLSaleActive;
    }

    function PreCommunitySaleFlags() external onlyOwner {
        WLSaleActive = false;
        PreWL = false;
        PreCommunity = true;
        PrePublic = false;
    }

    function toggleCommunitySale() external onlyOwner {
        communitySale = !communitySale;
    }

    function PrePublicFlags() external onlyOwner {
        communitySale = false;
        PreWL = false;
        PreCommunity = false;
        PrePublic = true;
    }

    function togglePublicSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function currentSaleState() public view returns (string memory) {
        if(OGSaleActive){
            return "OG";
        } else if(WLSaleActive){
            return "WL";
        } else if(PreWL){
            return "preWL";
        } else if(communitySale){
            return "Community";
        } else if(PreCommunity){
            return "preCommunity";
        } else if(saleActive){
            return "Public";
        } else if(PrePublic){
            return "prePublic";
        } else {
            return "Closed";
        }
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        Price = newPrice;
    }

    function setOGMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        OGMerkleRoot = newMerkleRoot;
    }

     function setWLMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        WLMerkleRoot = newMerkleRoot;
    }

    function setCommunityMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        CommunityMerkleRoot = newMerkleRoot;
    }

    function setPublicMaxMints(uint256 newPublicMaxMints) external onlyOwner {
        ADDRESS_PUBLIC_MAX_MINTS = newPublicMaxMints;
    }

    function setAddressMaxMints(uint256 newAddressMaxMints) external onlyOwner {
        ADDRESS_MAX_MINTS = newAddressMaxMints;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < maxSupply, "Cannot increase supply of tokens");
        maxSupply = newSupply;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(payable(msg.sender), contractBalance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
     }
     
    // Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner)); 
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;    
        }
    }   

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
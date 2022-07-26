// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
..                                                                                                  
,c.             .                                                                                  .
,Ox'      .     co.                            .ll;..                                            .lc
.oNXkoclx00x:...dNx:,                     .''.:0Wd'.,c'              ..              .,;.    ..;dKk.
 .xWMMMMMMMMWX00NMKodx:..           .';clxkc'lKMWo. 'OXko:'.  ...   .xOdc,..cl;,,;::. cXX0kkOKNWNx. 
  .xWMMMWMMMWMMMMWWxlXWX0xl;'.....,o0NWWMNo:kNMMW0o,.kWMMWNKOO0Xd.  ,KMMMK; 'OWWWWWk. ,KMMMMMMW0:.  
   lNMMMMW0OKWMMMWMOcOMMMMWWNXXK0KNWMMMMNx;kWMMWMWW0c:OWMMMMMMMMO.  oNMMMW0:.:XMMMM0, .kMMMWMWk.    
  .OMMMMMO' 'kNMWMM0cxWMMWMMMMMMMMMMMMMWd.,OMMMMMMMM0,'xXWMMMWMMO'.dXWMMWXOo,;KMMMM0' .xWMMMWO.     
  cNMWMMMX:  .oNMMMNxckWMN0OXWMMMWKxOXWXc;OWMWMMMMWM0,  'dNMWMMNo.lNMMWKl.  .oWMMMWd. ,0MMMMK;      
 'OWMWWWMMO.  ,0MMMMWx;kKc. cNMMM0,  'ld:.cXMWWXXWMMK,   'OMMMMW0ONMMWXc    :KMMMMNl .kWMMWXc       
 .'lKMMMMMO'  ;KMMMMMXl,'   oNMMWd.       .kWMWx;xXNWd.  cNMMMWMWWWMWKo.   .dWMMMWO'.kWMWMXc        
    :KWMMK:   ,0MMMMMMk.   ;KMMMWk''cxOko:lKWMX: ,d0MWk' '0WMMWWO:ckNWNOc.  cNMMMX: :XMMMMK,        
     ,0WMXc    'dXMWMWd.   ;KMMMMXl .,kWMWWMMMXl.lKNMMNl  ;KMMMK;  .dWMMWK;.xWMMNo. ,KMMMW0;        
      lNMMNx.   ;KMMMK,    cNMMMMXc   .cdkNMMMMNKXWWMMK,  '0MMMO'   cNMMMX:.:KMWk.  .kMMM0,         
      ;XMMMX: .lXWMMMX;    lWMMWMK,     .lXMMWK0XWMMMMNc .oNMMMNk' .xWWMMWK:.oWMXo..cXMMMO'         
      ;XMWM0, lNMMWKdl'   .xWMMWMWx.  .lONMMMWx.,kNWMMMO,;0NWMMMWK:.;:xNMMWo.oWMMWK0NMMMMX;         
      lNMMWx.'0MMMNl     'xNMWMMMWd.  cNMMMWMM0' .;dNMMWOc,,:kNMMMO.  'OWMW0:,o0NWMMMMMMWk.         
     .oXNMM0,:XMMWO,   .lKWMMMMWMWx.  cNMWMMMM0'   .oNMWWN0d:,l0NWNx.  'd0XWXkc',oKWWWMM0,          
      ..:OWWXKWMMX:  .;ONXOkxkkxxxxc.,OWMMMMMWd.    :XMMMMMMW0o;,:okx:'. .':d0Xx. 'kNMMNl           
         .oKWMMWKc..'coo:.       .':ldxddoolloc.   .:lllodONMMW0d;......     .:dd, .lkO0:           
           .;dko. ...           ..''.                     .:xocc:;.             .,'.   ..           
              .                                                                    .                
 */

contract Otaku is ERC721A, Ownable, ReentrancyGuard {
    //The
    using Strings for uint256;

    //Sale flags
    bool public WLsaleActive = false;
    bool public saleActive = false;

    //Mint limits
    uint public LEVEL_1_ADDRESS_MAX_MINTS = 1;
    uint public LEVEL_2_ADDRESS_MAX_MINTS = 2;
    uint public PUBLIC_MAX_MINTS = 3;

    mapping(address => uint256) WLMintsOnAddress;
    mapping(address => uint256) publicMintsOnAddress;

    //Supply
    uint256 public maxSupply = 2000;
    uint256 public reservedSupply = 50;

    //Pricing
    uint256 public price = 0.05 ether;

    //Pre-reveal IPFS link
    string private _baseTokenURI = "";

    //Merkle roots
    bytes32 public WLLevel1MerkleRoot;
    bytes32 public WLLevel2MerkleRoot;

    //Curse
    constructor() ERC721A("Otaku Club", "Otaku") {
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * Whitelist Level 1 mint
     Of
     */
    function mintWLLevel1Sale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {
        
        require(WLsaleActive, "Sale must be active to mint"); 
        require(MerkleProof.verify(_merkleProof, WLLevel1MerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");
        require(numberOfMints > 0, "Sender is trying to mint none");
        require(WLMintsOnAddress[msg.sender] + numberOfMints <= LEVEL_1_ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * price, "Amount of ether is not enough");

        WLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);

    }

    /**
     * Whitelist Level 2 mint
     The
     */
    function mintWLLevel2Sale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {
        
        require(WLsaleActive, "Sale must be active to mint"); 
        require(MerkleProof.verify(_merkleProof, WLLevel2MerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");
        require(numberOfMints > 0, "Sender is trying to mint none");
        require(WLMintsOnAddress[msg.sender] + numberOfMints <= LEVEL_2_ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * price, "Amount of ether is not enough");

        WLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);

    }

    /**
     * Public mint
     Blood
     */
    function mint(uint256 numberOfMints) external payable callerIsUser {

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints > 0, "Sender is trying to mint none");
        require(publicMintsOnAddress[msg.sender] + numberOfMints <= PUBLIC_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * price, "Amount of ether is not enough");

        publicMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Reserve mint for founders
     Moon
     */
    function reserveMint(uint256 quantity) external onlyOwner {

        require(totalSupply() + quantity <= reservedSupply, "Too many minted to public to perform dev mint");

        _safeMint(msg.sender, quantity);
    }

    function toggleWLSale() external onlyOwner {
        WLsaleActive = !WLsaleActive;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setLevel1MaxMints(uint256 newAddressMaxMints) external onlyOwner {
        LEVEL_1_ADDRESS_MAX_MINTS = newAddressMaxMints;
    }

    function setLevel2MaxMints(uint256 newAddressMaxMints) external onlyOwner {
        LEVEL_2_ADDRESS_MAX_MINTS = newAddressMaxMints;
    }
    
    function setPublicMaxMints(uint256 newAddressMaxMints) external onlyOwner {
        PUBLIC_MAX_MINTS = newAddressMaxMints;
    }

    function setWLLevel1MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        WLLevel1MerkleRoot = newMerkleRoot;
    }

    function setWLLevel2MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        WLLevel2MerkleRoot = newMerkleRoot;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < maxSupply, "Cannot increase supply of tokens");
        maxSupply = newSupply;
    }

    function setReservedSupply(uint256 newReservedSupply) external onlyOwner {
        reservedSupply = newReservedSupply;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(address(0x4E3005d1A604409483b96Eef987CfB44881aA77B), contractBalance * 40/100);
        _withdraw(address(0x670d69434691683Fe9b7e62B85586659771DbAA1), contractBalance * 20/100);
        _withdraw(address(0xC44BE13D3b12d1b2A243B1bE4EEaAb0c8399b938), contractBalance * 20/100);
        _withdraw(address(0x3798d9c91e21cb6062B934ECfa6FAFF5c5526c5C), contractBalance * 10/100);
        _withdraw(address(0x5bE300580348267a6B094760F16B29328a9842fD), contractBalance * 10/100);
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

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
    //If you can discover the location of the curse you will be rewarded
}
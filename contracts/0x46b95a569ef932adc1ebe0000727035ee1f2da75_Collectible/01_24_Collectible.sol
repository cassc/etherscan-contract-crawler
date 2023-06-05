// SPDX-License-Identifier: MIT

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWWMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMM
MMMMMMMMMMMMMMMWX0XWWNMMMWWMMMMMMMMMMMMMMMMMMMMMWWNNNXXXKKXNWMMMMWWMMMWMWMMMMMMMMMMMMMMMMMMNKK00OkOXMMWOllcc::oXWWWWWWWWWWWWWWWWWWMMMMMMMMMM
MMMMMMMMMMMMMMXo,,,;;dNMO:,;;::ccllooddxkOXWWk:;,,''.......':dXMMNOxxkkkkOO0000klcc::;:OMM0;...    cNMK,      '0WNK0OkkOO0XWWWWWWWWMMMMMMMMM
MMMMMMMMMMMMMMO..:. ;OWMo                 .cOc                ;0MO'         ...        cNMx.       'OMO.      ,ko,.      ..,cxKWWWWWMMMMMMMM
MMMMMMMMMMMMMMXdlcc::kWWc     ...  ..       ..       .l:       lWk.                    '0Md         oWk.       .              .dNWWWWMMMMMMM
MMMMMMMMMMMMMMMMMMMOcOMWd,,':xKKxook0c               :KO,      ;Xx.       .:lcc:'      .dWl         ;Xx.             .lO:      '0WWWWMMMMMMM
MMMMMMMMMMMMMMOlloolc0MXc...;dOOxxx0Xl.              .cc.      cNd        ;XMMMM0,      cXc         .Od              .OWd.     .OWWWWWMMMMMM
MMMMMMMMMMMMMM0d: .cdKM0'       .:co:       'c.              .c0Wo        ,OKKXWWl      'Oc          oo               'dkkxddolkNWWWWWMMMMMM
MMMMMMMMMMMMMNx:' .lkNMk.                .'lKK;              .l0Nc         ....xWO'     .l;          ,;       cc.       .;dKWWWWWWWWWWWMMMMM
MMMMMMMMMMMMMXocddddONMx.                cKMMN:        .       .kc             oWNc      .     .;.           .kWOl.        .cONWWWWWWWWMMMMM
MMMMMMMMMMMMMO.'dkkOXMMo                  'xNWl       :Ko.      c;        ,olloKMMk.           :0:           .dXXNKx:.       .oNWWWWWWWMMMMM
MMMMMMMMMMMMMx..::::kWWx'..'cxxxdc;c:.      lNo       :N0,      ..       .xMWMMMMMN:           cNx.           ...',;d0o.      .kWWWWWWWMMMMM
MMMMMMMMMMMMMOckMMNXWMNd'',:xKNWXOkKXo.     '0x.      ,KX;               .kMWMMMMMMx.          oWX:                 :XWl      .dWWWWWWWMMMMM
MMMMMMMMMMMMMo'oodo,kMK;     .''',;,'.      ;Xk.      '0Nc                ';:::xNMMX;         .xMWk.                :XK;      .kWWWWWWWMMMMM
MMMMMMMMMMMMWo......kM0'                   ;0M0'      ,0Wx'.''',.              ;KMMWd.      ..;0MMNx;;::ccllol'      ..       :XWWWWWWWMMMMM
MMMMMMMMMMMMMN00OOk0NMNxlcc::;;,'''.....'cxNMMW0xxkOOOKWMWNXNNWW0c;,,'''''.....lNMMMNkxxkkO00KXWMMMMMMMMMMMMMWXx:..        .'lKWWWWWWWWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXKXWMMMMMMMMMMMMMMMMWMMMMMMWWWWWWWNNNNXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWN0kxdooodx0XWWWWWWWWWWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM
Dev by @bitcoinski
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import "./ICollectible.sol";

import "hardhat/console.sol";


/*
* @title ERC721 token for Collectible, redeemable through burning  MintPass tokens
*/

contract Collectible is ICollectible, AccessControl, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private generalCounter; 

  
    mapping(uint256 => TokenData) public tokenData;

    mapping(uint256 => RedemptionWindow) public redemptionWindows;

    struct TokenData {
        string tokenURI;
        bool exists;
    }

    struct RedemptionWindow {
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 maxRedeemPerTxn;
    }

    struct SaleConfig {
        bool isSaleOpen;
        bool isPresaleOpen;
        bytes32 presaleMerkleRoot;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 maxMintsPerTxn;
        uint256 mintPrice;
        uint256 maxSupply;
    }

    SaleConfig public saleConfiguration;
    
    string private baseTokenURI;

    string public _contractURI;
    

    MintPassFactory public mintPassFactory;

    event Redeemed(address indexed account, string tokens);
    event Minted(address indexed account, string tokens);

    /**
    * @notice Constructor to create Collectible
    * 
    * @param _symbol the token symbol
    * @param _mpIndexes the mintpass indexes to accommodate
    * @param _redemptionWindowsOpen the mintpass redemption window open unix timestamp by index
    * @param _redemptionWindowsClose the mintpass redemption window close unix timestamp by index
    * @param _maxRedeemPerTxn the max mint per redemption by index
    * @param _baseTokenURI the respective base URI
    * @param _contractMetaDataURI the respective contract meta data URI
    * @param _mintPassToken contract address of MintPass token to be burned
    */
    constructor (
        string memory _name, 
        string memory _symbol,
        uint256[] memory _mpIndexes,
        uint256[] memory _redemptionWindowsOpen,
        uint256[] memory _redemptionWindowsClose, 
        uint256[] memory _maxRedeemPerTxn,
        string memory _baseTokenURI,
        string memory _contractMetaDataURI,
        address _mintPassToken
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
        _contractURI = _contractMetaDataURI;
        mintPassFactory = MintPassFactory(_mintPassToken);
        generalCounter.increment();

        for(uint256 i = 0; i < _mpIndexes.length; i++) {
            uint passID = _mpIndexes[i];
            redemptionWindows[passID].windowOpens = _redemptionWindowsOpen[i];
            redemptionWindows[passID].windowCloses = _redemptionWindowsClose[i];
            redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn[i];
        }

          _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
          _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
          _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
          _setupRole(DEFAULT_ADMIN_ROLE, 0x7F379e2ca3c7e626aaF5B76A9507a5e909f72Db5);
        
    }


    /**
    * @notice Set the mintpass contract address
    * 
    * @param _mintPassToken the respective Mint Pass contract address 
    */
    function setMintPassToken(address _mintPassToken) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPassFactory = MintPassFactory(_mintPassToken); 
    }    

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;    
    }    

    /**
    * @notice Pause redeems until unpause is called
    */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called
    */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
     

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowOpen UNIX timestamp for redeem start
    */
    function setRedeemStart(uint256 passID, uint256 _windowOpen) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].windowOpens = _windowOpen;
    }        

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowClose UNIX timestamp for redeem close
    */
    function setRedeemClose(uint256 passID, uint256 _windowClose) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].windowCloses = _windowClose;
    }  

    /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param _maxRedeemPerTxn number of passes that can be redeemed
    */
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn;
    }        

    /**
    * @notice Check if redemption window is open
    * 
    * @param passID the pass index to check
    */
    function isRedemptionOpen(uint256 passID) public view override returns (bool) { 
        if(paused()){
            return false;
        }
        return block.timestamp > redemptionWindows[passID].windowOpens && block.timestamp < redemptionWindows[passID].windowCloses;
    }


    /**
    * @notice Redeem specified amount of MintPass tokens
    * 
    * @param mpIndexes the tokenIDs of MintPasses to redeem
    * @param amounts the amount of MintPasses to redeem
    */
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts) external override{
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        
        //check to make sure all are valid then re-loop for redemption 
        for(uint256 i = 0; i < mpIndexes.length; i++) {
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(amounts[i] <= redemptionWindows[mpIndexes[i]].maxRedeemPerTxn, "Redeem: max redeem per transaction reached");
            require(mintPassFactory.balanceOf(msg.sender, mpIndexes[i]) >= amounts[i], "Redeem: insufficient amount of Mint Passes");
            require(block.timestamp > redemptionWindows[mpIndexes[i]].windowOpens, "Redeem: redeption window not open for this Mint Pass");
            require(block.timestamp < redemptionWindows[mpIndexes[i]].windowCloses, "Redeem: redeption window is closed for this Mint Pass");
        }

        string memory tokens = "";
    
        for(uint256 i = 0; i < mpIndexes.length; i++) {

            mintPassFactory.burnFromRedeem(msg.sender, mpIndexes[i], amounts[i]);
            for(uint256 j = 0; j < amounts[i]; j++) {
                _safeMint(msg.sender, generalCounter.current());
                tokens = string(abi.encodePacked(tokens, generalCounter.current().toString(), ","));
                generalCounter.increment();
            }
            
        }

        emit Redeemed(msg.sender, tokens);
    }  

    
    function toggleSaleOn(bool isOn) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleConfiguration.isSaleOpen = isOn;
    }  

    function editSale(
        bool isSaleOpen,
         uint256 windowOpens,
        uint256 windowCloses,
        uint256 maxMintsPerTxn,
        uint256 mintPrice,
        uint256 maxSupply
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleConfiguration.isSaleOpen = isSaleOpen;
        saleConfiguration.windowOpens = windowOpens;
        saleConfiguration.windowCloses = windowCloses;
        saleConfiguration.maxMintsPerTxn = maxMintsPerTxn;
        saleConfiguration.mintPrice = mintPrice;
        saleConfiguration.maxSupply = maxSupply;
    } 

     function togglePresale(
        bool isPresaleOpen
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleConfiguration.isPresaleOpen = isPresaleOpen;
    }     

    function editPresaleMerkleRoot(
        bytes32 presaleMerkleRoot
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleConfiguration.presaleMerkleRoot = presaleMerkleRoot;
    }     

    function directMint(
        uint256 quantity,
        uint256 amount, 
        bytes32[] calldata merkleProof
    ) external payable {

        require(!paused(), "Mint: minting is paused");
        require(quantity > 0, "Sale: Must send quantity");
        require(saleConfiguration.isSaleOpen, "Sale: Not started");
        if(saleConfiguration.isPresaleOpen){
            console.log("PRESALE IS OPEN");
            require(quantity <= amount, "Claim amount not allowed");
            require(
                verifyMerkleProof(merkleProof, amount),
                "MerkleDistributor: Invalid proof." 
            );  
        }
        require(quantity <= saleConfiguration.maxMintsPerTxn, "Sale: Max quantity per transaction exceeded");
        require(block.timestamp >= saleConfiguration.windowOpens, "Sale: redeption window not open for this Mint Pass");
        require(block.timestamp <= saleConfiguration.windowCloses, "Sale: redeption window is closed for this Mint Pass");
        require(msg.value >= quantity.mul(saleConfiguration.mintPrice), "Sale: Ether value incorrect");
        require(totalSupply() + quantity <= saleConfiguration.maxSupply, "Purchase would exceed max supply");
        
        string memory tokens = "";

        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, generalCounter.current());
            tokens = string(abi.encodePacked(tokens, generalCounter.current().toString(), ","));
            generalCounter.increment();
        }

        emit Minted(msg.sender, tokens);

    }


    

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     


   /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param id of token
    * @param uri to point the token to
    */
    function setIndividualTokenURI(uint256 id, string memory uri) external override onlyRole(DEFAULT_ADMIN_ROLE){
        require(_exists(id), "ERC721Metadata: Token does not exist");
        tokenData[id].tokenURI = uri;
        tokenData[id].exists = true;
    }   
   
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         if(tokenData[tokenId].exists){
            return tokenData[tokenId].tokenURI;
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), '.json'));
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

     function makeLeaf(address _addr, uint amount) public view returns (string memory) {
        return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint amount) public view returns (bool) {

        if(saleConfiguration.presaleMerkleRoot == 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45){
            console.log("OPEN MINT");
            return true;
        }
        string memory leaf = makeLeaf(msg.sender, amount);
        console.log("LEAFLEAF", leaf);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, saleConfiguration.presaleMerkleRoot, node);
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


}

   

interface MintPassFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }
// SPDX-License-Identifier: MIT

/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,'...',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,.,,,;'',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,'..,;,..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,'...'...',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,..;:;::..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,'.',,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,'..,..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,l;.',,,,,,,,,,,,,,,,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,.'c,.,,,,,,,,,,,,,,,,,,,,'',,,,,,,,,'.:00l'.',,,,,,,,,,,,,,.;;.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,.':'.,,,,,,,,,,,,,,,,,,,,...',,,,,,,'.cKXXOo;'.'',,,,,,,,,,.ck:.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,..;'.,,,,,,,,,,,,,,,,,,,,'.;,',,,,,,'.;0XXXXKko:,'...'',,,,.'xOc'',,,,,,,,,,,,,,,,'.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,'.,'.,,,,,,,,,,,,,,,,,,,,''ok:'.',,,,.'kXXXXXXXXKOdlc:;;,,'..;OKkl;'',,,,,,,,,,,,'...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,'...',,,,,,,,,'..',,,,,,,,'lKKxc'..',..:0XXXXXXXXXXXXXKK00OkdloOXX0xl;,..',,,,,,,.,'.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,''',,,,,,,,,,':c'',,,,,,,.;OXXXOdc;'...:k0KXXXXXXXXXXXXXXXXXX00XXXXXKkdlcc:,,'''.ld'.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,'.oKx:'',,,,,''oXXXXXXKOdoccox0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kd:..c0x;.',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,..dXX0d;''',,'.,kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKo.;OXOl'.',,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,..dXXXXKkol:,'. ;OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxcxXXXk:..,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,..oXXXXXXXXK0kdlclxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOOXXXXKo..,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,'.cKXXXXXXXXXXXXXK0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl..,''',,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,.;OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk,.'..',,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,..oKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO;.,'.,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,'',,,.,xKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0ooc',,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,'..''''.,d0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXkx0XXXXXXXXXXXXXXXXKKx,.',,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,'.;olc;,.':oxOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx,:x0XXXKKXXXXXXXXXKK0xoc;'',,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,.,x000OOkxddOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0ccddOXKxdKXXXXXXXXKKK0Okdc,'',,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,.:k00000KKKKKXXXXXXXXXXXXXXXXXXXXXXXK0KXXXXXXXXXXXXXXXXXXXXXKooOxdOO:;xKKKKKXXKKKKx;,,,,',,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,'.ck000000KKKKKKKKKKXXXXXKXXXXXXXXXX0ldKXXXXXXXXXXXX00XXXXXXKodOOdolloox0KKKKKKKK00d,',,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,'.;dO0000KKKKKKKKKKKKKKKKKKKKKXXXXXKll0XXXXXXXXXXXXkkKXXXXX0od00kodO0kdox0KKKKOO000l'',,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,'.':dO000KKKKKKKKKKKKKKKKKKKKKXXKXKllKXXXXXXXXXXXKxdKXXXXKxlk00OOO0OOOkdddk0OlcO00x,',,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,'.';:clooox0KKKKKKKKKKKKKKKKKKKKkcxKKKKKXXKKKKXOcoKXXXKk:lO0OO0000OO00Ododx:,d00x;.,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,'.....:x00000KKKKKKKKKKKKKKOo,l0KKKKKKKKKKK0c;xKKK0xc'cOOO0000000O0O0Oxlll;oOd,',,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,'..:lxO0000000KKKKKKKKKK0ko;.;kKKKKKKKK00koc,c0KOxooxlckkxO00Okdl::clxkkk:.'oc'',,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,..:x000000000KKKKKK0Oxdooo:ckKKK00Okkxdl;;ccoxxxxO00kol;;xOdc:::cclllloc'.'..',,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,'.':cldkO000OOOkxdlcoxxoclxkkxxdxxdoolllc:ldxO000000xo:;lolok000OO00Od:..,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''..,lxxddol::c:;o0Odoxxl:clloooodkO0OO000000000000kllk000OxdddldO0Oc.',,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'cO0000Okxdddk000000OxxxxkO000000000000000000000000000OkO0KklxKXk,.,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,',d0000000000000000000000000000000000000000KKKKKKKKKKKKKKKOdoOXXO,.,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,';x00000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXKdclk0XXXx..,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.:OKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0ll0XXX0:.',,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,kKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOk0XKol0XXKc..,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXXX0xoddd0XXOc..,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.lKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0d:,:x0kddod0Xkc'.',,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.;0XXXXXXXXXXXXXXXXXXXXXXXXX0OOOOK0KXXXXKOl,.......lkl;:c'..,,,',,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.:OXXXXXXXKKXXXXXXXXX0k0XXXKOxlodldddxo;''..',,'.,do,...',,,'..',,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.,o0XXXXX0xxkO0KK0OxdkKXXXXXXKK0OOo;'',;,..,,,,,:oc'',,,,'.  .,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..,cdOKXXKOkxxxxxxkKXXXXXXXXX0xl;,;cllo:..,,,,''''',,,,.. ..,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..';coxO0KKXXXXXXXXXXXKOxc,..,ldxk00l.',,,,,''....'....',,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...',,;;:lloollllc;,'...'okOO00k, .......   ..'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''....'........... ..'''''.     ....   .....,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.          ................   . ...'.',,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .................................',,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .................... ...... ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. ................. .... ....',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'. ............... .''....',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'. .............. .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. ............... .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..  ................ .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.   ................. ..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.. .................... .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'. ..................... .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,. ...................... .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Dev by @bitcoinski
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private earlyIDCounter; 
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
    
    string private baseTokenURI;

    string public _contractURI;
    

    MintPassFactory public mintPassFactory;

    event Redeemed(address indexed account, string tokens);

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
        address _mintPassToken,
        uint earlyIDMax
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
        _contractURI = _contractMetaDataURI;
        mintPassFactory = MintPassFactory(_mintPassToken);
        earlyIDCounter.increment();
        for(uint256 i = 0; i <= earlyIDMax; i++) {
            generalCounter.increment();
        }

        for(uint256 i = 0; i < _mpIndexes.length; i++) {
            uint passID = _mpIndexes[i];
            redemptionWindows[passID].windowOpens = _redemptionWindowsOpen[i];
            redemptionWindows[passID].windowCloses = _redemptionWindowsClose[i];
            redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn[i];
        }

          _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
          _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
          _setupRole(DEFAULT_ADMIN_ROLE, 0x41e2E9aefc57f7760807897125F6DD5C18168F85); 
          _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
        
    }


    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toH1 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
          (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
          (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
          (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
          (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
          (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
           uint256 (result) +
           (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
           0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
        }

        function toH (bytes32 data) public pure returns (string memory) {
            return string (abi.encodePacked ("0x", toH1 (bytes16 (data)), toH1 (bytes16 (data << 128))));
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
                _safeMint(msg.sender, mpIndexes[i] == 0 ? earlyIDCounter.current() : generalCounter.current());
                tokens = string(abi.encodePacked(tokens, mpIndexes[i] == 0 ? earlyIDCounter.current().toString() : generalCounter.current().toString(), ","));
                if(mpIndexes[i] == 0){
                    earlyIDCounter.increment();
                }
                else{
                    generalCounter.increment();
                }
            
            }
            
        }

        emit Redeemed(msg.sender, tokens);
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
   

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         if(tokenData[tokenId].exists){
            return tokenData[tokenId].tokenURI;
        }
        return string(abi.encodePacked(baseTokenURI, toH(keccak256(toBytes(tokenId))), '.json'));
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


    function h(uint256 t) public view returns (string memory) {
        return string(abi.encodePacked(toH(keccak256(toBytes(t)))));
    } 

   

}

   

interface MintPassFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }
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
* Discord Mods: @OmarIbisa | @ResetNft
* Meme-Daddy: @ryan_goldberg_
* Website & Web3: @calvinhoenes | @bitcoinski | @ximecediazArt
* Smart Contracts: @bitcoinski
* Art Generation: @bitcoinski
*
*/

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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import "./IWoodie.sol";

import "hardhat/console.sol";


/*
* @title ERC721 token for Woodie, redeemable through burning Woodies MintPassport tokens
*
* @author original logic by Niftydude, extended by @bitcoinski
*/

contract Woodie is IWoodie, AccessControl, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private ultraDAOCounter; 
    Counters.Counter private generalCounter; 

    // Roles
    bytes32 public constant WOODIE_OPERATOR_ROLE = keccak256("WOODIE_OPERATOR_ROLE");
    bytes32 public constant WOODIE_URI_UPDATER_ROLE = keccak256("WOODIE_URI_UPDATER_ROLE");
  
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
    string private ipfsURI;

    string public _contractURI;

    uint256 private ipfsAt;

    MintPassportFactory public woodiesMintPassportFactory;

    event Redeemed(address indexed account, string tokens);

    /**
    * @notice Constructor to create Woodie
    * 
    * @param _symbol the token symbol
    * @param _mpIndexes the mintpass indexes to accommodate
    * @param _redemptionWindowsOpen the mintpass redemption window open unix timestamp by index
    * @param _redemptionWindowsClose the mintpass redemption window close unix timestamp by index
    * @param _maxRedeemPerTxn the max mint per redemption by index
    * @param _baseTokenURI the respective base URI
    * @param _contractMetaDataURI the respective contract meta data URI
    * @param _mintPassToken contract address of MintPassport token to be burned
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
        woodiesMintPassportFactory = MintPassportFactory(_mintPassToken);
        for(uint256 i = 0; i < 111; i++) {
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
            _setupRole(DEFAULT_ADMIN_ROLE, 0x8367A713bc14212Ab1bB8c55A778e43e50B8b927); 
            grantRole(WOODIE_OPERATOR_ROLE, msg.sender);
    }

    /**
    * @notice Set the mintpassport contract address
    * 
    * @param _mintPassToken the respective Mint Passport contract address 
    */
    function setMintPassportToken(address _mintPassToken) external override onlyOwner {
        woodiesMintPassportFactory = MintPassportFactory(_mintPassToken); 
    }    

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }    


    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _ipfsURI the respective ipfs base URI
    */
    function setIpfsURI(string memory _ipfsURI) external override onlyOwner {
        ipfsURI = _ipfsURI;    
    }    

    /**
    * @notice Change last ipfs token index
    * 
    * @param at the token index 
    */
    function endIpfsUriAt(uint256 at) external onlyOwner {
        ipfsAt = at;    
    }    

    /**
    * @notice Pause redeems until unpause is called
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called
    */
    function unpause() external override onlyOwner {
        _unpause();
    }
     

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowOpen UNIX timestamp for redeem start
    */
    function setRedeemStart(uint256 passID, uint256 _windowOpen) external override onlyOwner {
        redemptionWindows[passID].windowOpens = _windowOpen;
    }        

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowClose UNIX timestamp for redeem close
    */
    function setRedeemClose(uint256 passID, uint256 _windowClose) external override onlyOwner {
        redemptionWindows[passID].windowCloses = _windowClose;
    }  

    /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param _maxRedeemPerTxn number of passes that can be redeemed
    */
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn) external override onlyOwner {
        redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn;
    }        

    /**
    * @notice Check if redemption window is open
    * 
    * @param passID the pass index to check
    */
    function isRedemptionOpen(uint256 passID) public view override returns (bool) { 
        return block.timestamp > redemptionWindows[passID].windowOpens && block.timestamp < redemptionWindows[passID].windowCloses;
    }


    /**
    * @notice Redeem specified amount of MintPass tokens for MetaHero
    * 
    * @param mpIndexes the tokenIDs of MintPasses to redeem
    * @param amounts the amount of MintPasses to redeem
    */
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts) external override{
        console.log('redeeming...');
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        
        //check to make sure all are valid then re-loop for redemption 
        for(uint256 i = 0; i < mpIndexes.length; i++) {
            console.log('checking token ', mpIndexes[i]);
            console.log('quantity ', amounts[i]);
            //console.log(woodiesMintPassportFactory.mintPasses(mpIndexs[i]));
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(amounts[i] <= redemptionWindows[mpIndexes[i]].maxRedeemPerTxn, "Redeem: max redeem per transaction reached");
            require(woodiesMintPassportFactory.balanceOf(msg.sender, mpIndexes[i]) >= amounts[i], "Redeem: insufficient amount of Mint Passports");
            require(block.timestamp > redemptionWindows[mpIndexes[i]].windowOpens, "Redeem: redeption window not open for this Mint Passport");
            require(block.timestamp < redemptionWindows[mpIndexes[i]].windowCloses, "Redeem: redeption window is closed for this Mint Passport");
        }

        string memory tokens = "";
    
        for(uint256 i = 0; i < mpIndexes.length; i++) {

            woodiesMintPassportFactory.burnFromRedeem(msg.sender, mpIndexes[i], amounts[i]);
            for(uint256 j = 0; j < amounts[i]; j++) {
                _safeMint(msg.sender, mpIndexes[i] == 0 ? ultraDAOCounter.current() : generalCounter.current());
                tokens = string(abi.encodePacked(tokens, mpIndexes[i] == 0 ? ultraDAOCounter.current().toString() : generalCounter.current().toString(), ","));
                if(mpIndexes[i] == 0){
                    ultraDAOCounter.increment();
                }
                else{
                    generalCounter.increment();
                }
            
            }
            
            console.log('new token IDs redeemed:', tokens);
        }

        emit Redeemed(msg.sender, tokens);
    }  

    

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function promoteTeamMember(address _addr, uint role) public{
        if(role == 0){
            grantRole(WOODIE_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
            grantRole(WOODIE_URI_UPDATER_ROLE, _addr);
        }
         
    }

    function demoteTeamMember(address _addr, uint role) public {
         if(role == 0){
            revokeRole(WOODIE_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
           revokeRole(WOODIE_URI_UPDATER_ROLE, _addr);
        }
         
    }

    function hasWoodiesRole(address _addr, uint role) public view returns (bool){
        if(role == 0){
            return hasRole(WOODIE_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
            return hasRole(WOODIE_URI_UPDATER_ROLE, _addr);
        }
        return false;
    }

   /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param id of token
    * @param uri to point the token to
    */
    function setIndividualTokenURI(uint256 id, string memory uri) external override {
        require(hasRole(WOODIE_URI_UPDATER_ROLE, msg.sender), "Access: sender does not have access");
        require(_exists(id), "ERC721Metadata: Token does not exist");
        tokenData[id].tokenURI = uri;
        tokenData[id].exists = true;
    }   
   
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
       
        if(tokenId > ipfsAt) {
            return baseTokenURI;
        } else {
            return ipfsURI;
        }
    }     

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(tokenData[tokenId].exists){
            return tokenData[tokenId].tokenURI;
        }

        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function setContractURI(string memory uri) external {
        require(hasRole(WOODIE_URI_UPDATER_ROLE, msg.sender) );
        _contractURI = uri;
    }

    //TODO: SET ROYALTIES HERE and in MetaData
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

}

   

interface MintPassportFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }
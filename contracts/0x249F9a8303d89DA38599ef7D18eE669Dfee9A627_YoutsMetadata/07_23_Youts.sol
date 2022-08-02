//SPDX-License-Identifier: CC0-1.0

/*                                                                      

`YMM'   `MM' .g8""8q. `7MMF'   `7MF'MMP""MM""YMM  .M"""bgd                                                                 
  VMA   ,V .dP'    `YM. MM       M  P'   MM   `7 ,MI    "Y                                                                 
   VMA ,V  dM'      `MM MM       M       MM      `MMb.         gp                                                          
    VMMP   MM        MM MM       M       MM        `YMMNq.     ""                                                          
     MM    MM.      ,MP MM       M       MM      .     `MM                                                                 
     MM    `Mb.    ,dP' YM.     ,M       MM      Mb     dM     ,,                                                          
   .JMML.    `"bmmd"'    `bmmmmd"'     .JMML.    P"Ybmmd"      db                                                          
                                                                                                                        
                                                                                                                           
 ..|'''.|  '||''''|  '|.   '|' '||''''|  '||''|.       |     |''||''| '||'  ..|''||   '|.   '|'  .|'''.|  
.|'     '   ||  .     |'|   |   ||  .     ||   ||     |||       ||     ||  .|'    ||   |'|   |   ||..  '  
||    ....  ||''|     | '|. |   ||''|     ||''|'     |  ||      ||     ||  ||      ||  | '|. |    ''|||.  
'|.    ||   ||        |   |||   ||        ||   |.   .''''|.     ||     ||  '|.     ||  |   |||  .     '|| 
 ''|...'|  .||.....| .|.   '|  .||.....| .||.  '|' .|.  .||.   .||.   .||.  ''|...|'  .|.   '|  |'....|'  


    On-chain art by ok_0S (weatherlight.eth). 2022.

    // 6,969 Youts
    // Fully on-chain SVG artwork
    // Most (non-Special) Youts can toggleDarkMode()
    // Special Themes inspired by legendary NFT collections

    gm.

    "A fully on-chain gang of misfits and weirdos for everyone. CC0."
    
    That's the description set for Youts, and it really means what
    it says. Youts are for everyone, and they're CC0, so they're for
    everyone to do with them what they want. I hope you take your 
    Youts and run with them. Go wild.

    Youts: Generations tokens are fully on-chain, and the contract was
    developed to allow full visibility into all components from within
    the Etherscan interface. Youts are SVG images and therefore may
    not be displayable in certain wallets or implementations that
    don't support SVGs.

    Youts: Generations is a love letter to the NFT scene of 2021-2022.
    This collection would not be possible without the community, and
    especially the following collections and the people who created
    them. Noted with each of these legendary collections is a brief
    note on how that inspiration has manifested in Youts: Generations.


    - Manny's Game
        * "Gamer" Theme
        * Special thanks to all Mannys for the last year of learning
          and bagel rinsing. Best community in web3.

    - OKPC
        * Light / Dark mode rendering toggle.
        * Special thanks to the OKPC team for the inspo for making
          dynamic on-chain NFTs 
    
    - Shields
        * Base Theme Color Scheme Inspiration
        * "Heraldry" Theme
        * Special thanks to the Shields team for the inspo for using
          separate contracts for component pieces
    
    - LOOT
        * "Inventory" Theme
        * Divine Robes and Divine Orders
        * Special thanks to Dom for making on-chain SVG understandable
        * Special thanks to DivineDAO for the Divine Order glyphs
    
    - Corruption(s*)
        * "Ion" Theme 
        * Special thanks to Dom for showing how to shed responsibility
        * Special thanks to the Corruption(s*) community for showing
          how communities can prop themselves up. 
    
    - BLOOT
        * "Deriv" Theme
        * Thanks to the BLOOT team for all the memes.

    - Shinsei Galverse
        * "Gal" Theme
        * Special thanks to the Galverse team for being in it for the
          right reasons.

    - Nouns
        * "Nounish" Theme
        * "Nounish" Face
        * Special thanks to NounsDAO for doing it iconic.
    
    - CryptoPunks
        * "2017" Theme
        * Special thanks to CryptoPunks. Acknowledge your elders.
    
    
    Countless other collections and individuals inspired elements of 
    Youts: Generations; my gratitude is real.

    May all who inspire vibe eternally. 

    | ~~~
    |  ACKNOWLEDGE:
    |  Youts are experimental art.
    |  This contract is unaudited.
    |  There is no roadmap.
    |  Absolutely no promises have been made.
    | ~~~

    Sound good? Mint directly from the contract.

    Follow @YoutsNFT on twitter.

*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "./YoutsMetadata.sol";

interface IYouts {
    function getDarkMode(uint256 tokenId) external view returns (bool);
}

/** @title Youts - Main contract 
  * @author @ok_0S / weatherlight.eth
  * The main contract for Youts. ERC721 with upgradeable metadata contracts.
  */
contract Youts is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    mapping(uint256 => bool) public darkTokens;
	address public metadataAddress;
	bool public mintIsActive;
    uint256 public mintPrice = 50000000000000000;
    uint256 public togglePrice = 10000000000000000;


    /** @dev Initialize the Youts Metadata contract. Mint the first 69 Youts to the contract owner.
        * @param _metadataAddress Address of Youts Metadata Contract 
        */
    constructor(address _metadataAddress) 
        ERC721("Youts", "YOUTS") 
        Ownable() 
    {
		metadataAddress = _metadataAddress;
	}


    /** @dev Start or pause the mint.
        * @param status "true" will enable minting; "false" will disable 
        */
    function setMintState(bool status)
        external
        onlyOwner
    {
      mintIsActive = status;
    }


	/** @dev Sets the price for mints.  
      * @notice Only callable by the contract owner.
	  * @param price Value expressed in wei 
	  */
    function setMintPrice(uint256 price)
        external
        onlyOwner
    {
      mintPrice = price;
    }


	/** @dev Sets the price for toggling Dark Mode.  
      * @notice Only callable by the contract owner.
	  * @param price Value expressed in wei 
	  */
    function setTogglePrice(uint256 price)
        external
        onlyOwner
    {
      togglePrice = price;
    }


	/** @dev Sets the address for the Metadata contract. Allows for upgrading contract.  
      * @notice Only callable by the contract owner.
	  * @param addr Address of Metadata Contract 
	  */
	function setMetadataAddress(address addr)
        public
        onlyOwner
    {
        metadataAddress = addr;
    }


    /** @dev Renders a JSON object containing the token's metadata and image. 
	  * @param tokenId A token's numeric ID. 
	  */
	function tokenURI(uint256 tokenId)
        override
        public
        view
        returns (string memory) 
    {
        if (!_exists(tokenId)) revert YoutNotFound();
        return 
            IYoutsMetadata(metadataAddress).tokenURI(tokenId, address(this));
    }
    

    /** @dev Mint a Yout for 0.05 ETH.
	  */
	function mint()
        public
        payable
        nonReentrant
    {   
        require(mintIsActive, "Youts: Minting is not available right now");
        require(msg.value == mintPrice, "Youts: 0.05 ETH to mint");
        require(totalSupply() < 6970, "Youts: All Youts claimed");
    	_doMint();
    }


    /** @dev Mint up to 10 Youts at once.
      * @param quantity A number of Youts to mint. 
	  */
    function mintQuantity(uint256 quantity) 
        public 
        payable
        nonReentrant 
    {
        require(mintIsActive, "Youts: Minting is not available right now");
        require(msg.value == mintPrice * quantity, "Youts: Transaction value must equal (mintPrice * quantity)");
        require(quantity < 11, "Youts: Try minting less than 10 Youts at once");
        require(quantity > 0, "Youts: You can't mint 0 Youts, ya goof");
        require(totalSupply() < 6970 - quantity, "Youts: All Youts claimed");
        uint256 i = 0;
        while (i < quantity) {
            _doMint();
            i++;
        }
    }


    /** @dev Mint a number of Youts at no cost, regardless of sale status.
      * @notice Only callable by the contract owner.
      * @param quantity A number of Youts to mint. 
	  */
    function ownerMint(uint256 quantity) 
        public 
        nonReentrant 
        onlyOwner 
    {
        require(totalSupply() < 6970 - quantity, "Youts: All Youts claimed");
        uint256 i = 0;
        while (i < quantity) {
            _doMint();
            i++;
        }
    }


    /** @dev Mints a token, increments the token counter, and sets Dark Mode "on" for a few tokens.
      * @notice All of these steps must be performed when minting a token to maintain correct state.
	  */
    function _doMint() 
        internal
    {   
        _mint(msg.sender, totalSupply());
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        initializeDarkMode(tokenId);
    }


    /** @dev Toggles Dark Mode "on" for ~10% of tokens
      * @param tokenId A token's numeric ID. 
	  */
    function initializeDarkMode(uint256 tokenId)
        internal
    {           
        if (IYoutsMetadata(metadataAddress).isToggleable(tokenId, address(this)) == true && uint256(keccak256(abi.encodePacked("DARKMODE", tokenId))) % 10 == 0) {
            _toggleDarkMode(tokenId);
        }
    }


    /** @dev 
      * @param tokenId A number of Youts to mint. 
	  */
    function toggleDarkMode(uint256 tokenId) 
        external
        payable 
        onlyOwnerOf(tokenId) 
    {
        require(msg.value == togglePrice, "Youts: Payment doesn't match togglePrice");
        require(IYoutsMetadata(metadataAddress).isToggleable(tokenId, address(this)) == true, "Youts: Youts with special themes can't be toggled");
        _toggleDarkMode(tokenId);
    }


    /** @dev 
      * @param tokenId A token's numeric ID.  
	  */
    function _toggleDarkMode(uint256 tokenId) 
        internal 
    {
        darkTokens[tokenId] = !darkTokens[tokenId];
    }


    /** @dev 
      * @param tokenId A token's numeric ID. 
	  */
    function getDarkMode(uint256 tokenId) 
        external
        view
        returns (bool)
    {   
        return
            darkTokens[tokenId];
    }


    /** @dev Transfer the contract's balance to the contract owner.
      * @notice Only callable by the contract owner.
	  */
	function withdrawAvailableBalance() 
        public  
        onlyOwner 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    

    /** @dev Requires the caller to be the owner of the specified tokenId.
	  * @param tokenId A token's numeric ID. 
    */
    modifier onlyOwnerOf(uint256 tokenId)
    {
        if (msg.sender != ownerOf(tokenId)) revert NotYoutOwner();
        _;
    }

    error NotYoutOwner();
    error YoutNotFound();

}
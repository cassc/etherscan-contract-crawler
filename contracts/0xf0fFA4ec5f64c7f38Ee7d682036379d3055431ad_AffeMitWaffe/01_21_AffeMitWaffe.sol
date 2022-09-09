// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./URIManager.sol";
import "./ERC2981GlobalRoyalties.sol";
import "./ERC721Lending.sol";

//                                       .,*.                                   
//                                      *(//*                                   
//                              .      .//&/                                    
//                  .*.       (*/// , *(/,*  ,,,                                
//               ./&#*,(*.,   ,/((%./#(//#.//((#(###/**///#%#%(%(**             
//               //*/%&*#&/*/,.*/,*%##/*,(/*(/*#,,,*(#&(//                      
//                        (*#/(#/(*,        */%(/*/.#,,                         
//                      /#(.&(* //(/,/        ,,./**                            
//                    ./(%//,         .,*(/(((*/%%*.,                           
//                    */,.(/.   ,#%%,.      */.(*/*.                            
//                     *&%(%&%#&%(##%&(#   %*,(#&@/                             
//                      *#(/%*%(/*(%,*#%%(%%/##(%*.                             
//                        *.*/%,/,/*(,//%(#/#%,#*,                              
//                         . %/(%(#*##%#%(*,/(**                                
//                         ,(@##*&**##**/#/(/,                                  
//                          (,%#((/%((//(%/%.                                   
//                          , **,(/**/*/**((,                                   
//                           / (,..  ../*.*#,                                   
//                            ,(*##((%((#(/@,                                   
//                             (.%*( * .*(.&,                                   
//                              (/#%#/%#%(*%,                                   
//                             */,###(%%(*%#/                                   
//                           ,//#%**(//,,(((*.                                  
//                          ((*..**((#%/*(*//*,                                 
//                         ..%#,*((#.  ,.(,(/**                                 
//                          /...**,     .,/((/,                                 
//                          /. %*/(,     /.((%.*                                
//                            *#/,%./     ( #/,                                 
//                             */**       /.//#,                                
//                         (*#**,*#.      (**#&,                                
//                                     *,,/##,       

/**
 * @title Affe mit Waffe NFT smart contract.
 * @notice Implementation of ERC-721 standard for the genesis NFT of the Monkeyverse DAO.
 *   "Affe mit Waffe" is a symbiosis of artificial intelligence and the human mind. The
 *   artwork is a stencil inspired by graffiti culture and lays the foundation for creative
 *   development. The colors were decided by our AI – the Real Vision Bot. It determines
 *   the colors based on emotions obtained via natural language processing from the Real
 *   Vision interviews. Human creativity completes the piece for the finishing touch. Each
 *   Affe wants to connect, contrast, and stand out. Like the different colors and emotions
 *   of the day, the Affen are born to connect people, minds and ideas, countries, racesand
 *   genders through comparison and contrast.Despite their bossy appearance they are a
 *   happy hungry bunch at heart. They may look tough on the outside but are soft on the
 *   inside – and are easy to win over with a few bananas. The raised gun symbolizes our
 *   own strength and talents; it shall motivate us to use them wisely to overcome our
 *   differences for tolerance and resolve our conflicts peacefully.
 */

contract AffeMitWaffe is ERC721, ERC721Enumerable, Pausable, AccessControl,
                   ERC721Burnable, ERC2981GlobalRoyalties, URIManager, ERC721Lending {
    // Create the hashes that identify various roles. Note that the naming below diverges
    // from the naming of the DEFAULT_ADMIN_ROLE, whereby OpenZeppelin chose to put
    // the 'ROLE' part of the variable name at the end. Here, instead, all other roles are  named
    // with 'ROLE' at the beginning of the name, because this makes them much easier to
    // find and identify (they naturally get grouped together) in graphical tools like Remix
    // or Etherscan.
    bytes32 public constant ROLE_PAUSER = keccak256("ROLE_PAUSER");
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");
    bytes32 public constant ROLE_ROYALTY_SETTING = keccak256("ROLE_ROYALTY_SETTING");
    bytes32 public constant ROLE_METADATA_UPDATER = keccak256("ROLE_METADATA_UPDATER");
    bytes32 public constant ROLE_METADATA_FREEZER = keccak256("ROLE_METADATA_FREEZER");

    /**
     * @notice The owner variable below is 'honorary' in the sense that it serves no purpose
     *   as far as the smart contract itself is concerned. The only reason for implementing
     *   this variable, is that OpenSea queries owner() (according to an article in their Help
     *   Center) in order to decide who can login to the OpenSea interface and change
     *   collection-wide settings, such as the collection banner, or more importantly, royalty
     *   amount and destination (as of this writing, OpenSea implements their own royalty
     *   settings, rather than EIP-2981.)
     *   Semantically, for our purposes (because this contract uses AccessControl rather than
     *   Ownable) it would be more accurate to call this variable something like
     *   'openSeaCollectionAdmin' (but sadly OpenSea is looking for 'owner' specifically.)
     */
    address public owner;

    uint8 constant MAX_SUPPLY = 250;
    /**
     * @dev The variable below keeps track of the number of Affen that have been minted.
     *   HOWEVER, note that the variable is never decreased. Therefore, if an Affe is burned
     *   this does not allow for a new Affe to be minted. There will ever only be 250 MINTED.
     */
    uint8 public numTokensMinted;
    
    /**
     * @dev From our testing, it seems OpenSea will only honor a new collection-level administrator
     *   (the person who can login to the interface and, for example, change royalty
     *   amount/destination), if an event is emmitted (as coded in the OpenZeppelin Ownable contract)
     *   announcing the ownership transfer. Therefore, in order to ensure the OpenSea collection
     *   admin can be updated if ever needed, the following event has been included in this smart
     *   contract.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Constructor of the Affe mit Waffe ERC-721 NFT smart contract.
     * @param name is the name of the ERC-721 smart contract and NFT collection.
     * @param symbol is the symbol for the collection.
     * @param initialBaseURI is the base URI string that will concatenated with the tokenId to create
     *   the URI where each token's metadata can be found.
     * @param initialContractURI is the location where metadata about the collection as a whole
     *   can be found. For the most part it is an OpenSea-specific requirement (they will try
     *   to find metadata about the collection at this URI when the collecitons is initially
     *   imported into OpenSea.)
     */
    constructor(string memory name, string memory symbol, string memory initialBaseURI, string memory initialContractURI)
    ERC721(name, symbol)
    URIManager(initialBaseURI, initialContractURI) {
        // To start with we will only grant the DEFAULT_ADMIN_ROLE role to the msg.sender
        // The DEFAULT_ADMIN_ROLE is not granted any rights initially. The only privileges
        // the DEFAULT_ADMIN_ROLE has at contract deployment time are: the ability to grant other
        // roles, and the ability to set the 'honorary' contract owner (see comments above.)
        // For any functionality to be enabled, the DEFAULT_ADMIN_ROLE must explicitly grant those roles to
        // other accounts or to itself.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setHonoraryOwner(msg.sender);
    }

    /**
     * @notice The 'honorary' portion of this function's name refers to the fact that the 'owner' variable
     *   serves no purpose in this smart contract itself. 'Ownership' is mostly meaningless in the context
     *   of a smart contract that implements security with RBAC (Role Based Access Control); so 'owndership'
     *   is only implemented here to allow for certain collection-wide admin functionality within the
     *   OpenSea web interface.
     * @param honoraryOwner is the address that one would like to designate as the 'owner' of this contract
     *   (most likely with the sole purpose of being able to login to OpenSea as an administrator of the
     *   collection.)
     */
    function setHonoraryOwner(address honoraryOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(honoraryOwner != address(0), "New owner cannot be the zero address.");
        address priorOwner = owner;
        owner = honoraryOwner;
        emit OwnershipTransferred(priorOwner, honoraryOwner);
    }


    // Capabilities of ROLE_PAUSER

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of (in the case of an emergency) pausing all transfers
     *   of tokens in the contract (which includes minting/burning/transferring.)
     * @dev This function calls the internal _pause() function from
     *   OpenZeppelin's Pausable contract.
     */
    function pause() external onlyRole(ROLE_PAUSER) {
        _pause();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of UNpausing all transfers
     *   of tokens in the contract (which includes minting/burning/transferring.)
     * @dev This function calls the internal _unpause() function from
     *   OpenZeppelin's Pausable contract.
     */
    function unpause() external onlyRole(ROLE_PAUSER) {
        _unpause();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of pausing all token lending. When loans
     *   are paused, new loans cannot be made, but existing loans can be recalled.
     * @dev This function calls the internal _pauseLending() function of the
     *   ERC721Lending contract.
     */
    function pauseLending() external onlyRole(ROLE_PAUSER) {
        _pauseLending();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of UNpausing all token lending.
     * @dev This function calls the internal _unpauseLending() function of the
     *   ERC721Lending contract.
     */
    function unpauseLending() external onlyRole(ROLE_PAUSER) {
        _unpauseLending();
    }


    // Capabilities of ROLE_MINTER

    // the main minting function
    function safeMint(address to, uint256 tokenId) external onlyRole(ROLE_MINTER) {
        require(numTokensMinted < MAX_SUPPLY, "The maximum number of tokens that can ever be minted has been reached.");
        numTokensMinted += 1;
        _safeMint(to, tokenId);
    }


    // Capabilities of ROLE_ROYALTY_SETTING
    
    function setRoyaltyAmountInBips(uint16 newRoyaltyInBips) external onlyRole(ROLE_ROYALTY_SETTING) {
        _setRoyaltyAmountInBips(newRoyaltyInBips);
    }

    function setRoyaltyDestination(address newRoyaltyDestination) external onlyRole(ROLE_ROYALTY_SETTING) {
        _setRoyaltyDestination(newRoyaltyDestination);
    }


    // Capabilities of ROLE_METADATA_UPDATER

    function setBaseURI(string calldata newURI) external onlyRole(ROLE_METADATA_UPDATER) allowIfNotFrozen {
        _setBaseURI(newURI);
    }

    function setContractURI(string calldata newContractURI) external onlyRole(ROLE_METADATA_UPDATER) allowIfNotFrozen {
        _setContractURI(newContractURI);
    }

    
    // Capabilities of ROLE_METADATA_FREEZER

    function freezeURIsForever() external onlyRole(ROLE_METADATA_FREEZER) allowIfNotFrozen {
        _freezeURIsForever();
    }


    // Information fetching - external/public

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _buildTokenURI(tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        require(_exists(tokenId), "Royalty requested for non-existing token");
        return _globalRoyaltyInfo(salePrice);
    }

    /**
     * @notice Returns all the token IDs owned by a given address. NOTE that 'owner',
     *   in this context, is the meaning as stipulated in EIP-721, which is the address
     *   returned by the ownerOf function. Therefore this function will enumerate the
     *   borrower as the current owner of a token on loan, rather than the original owner.
     * @param tokenOwner is the address to request ownership information about.
     * @return an array that has all the tokenIds owned by an address.
     */
    function ownedTokensByAddress(address tokenOwner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(tokenOwner);
        uint256[] memory allTokenIdsOfOwner = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIdsOfOwner[i] = (tokenOfOwnerByIndex(tokenOwner, i));
        }
        return allTokenIdsOfOwner;
    }

    /**
     * @notice Function retrieves the specific token ids on loan by a given address.
     * @param rightfulOwner is the original/rightful owner for whom one wishes to find the
     *   tokenIds on loan.
     * @return an array with the tokenIds currently on loan by the origina/rightful owner.
     */
    function loanedTokensByAddress(address rightfulOwner) external view returns (uint256[] memory) {
        require(rightfulOwner != address(0), "ERC721Lending: Balance query for the zero address");
        uint256 numTokensLoanedByRightfulOwner = loanedBalanceOf(rightfulOwner);
        uint256 numGlobalTotalTokens = totalSupply();
        uint256 nextTokenIdToQuery;

        uint256[] memory theTokenIDsOfRightfulOwner = new uint256[](numTokensLoanedByRightfulOwner);
        // If the address in question hasn't lent any tokens, there is no reason to enter the loop.
        if (numTokensLoanedByRightfulOwner > 0) {
            uint256 numMatchingTokensFound = 0;
            // Continue searching in the loop until either all tokens in the collection have been examined
            // or the number of tokens being searched for (the number owned originally by the rightful
            // owner) have been found.
            for (uint256 i = 0; numMatchingTokensFound < numTokensLoanedByRightfulOwner && i < numGlobalTotalTokens; i++) {
                // TokenIds may not be sequential or even within a specific range, so we get the next tokenId (to 
                // lookup in the mapping) from the global array holding all tokens.
                nextTokenIdToQuery = tokenByIndex(i);
                if (mapFromTokenIdToRightfulOwner[nextTokenIdToQuery] == rightfulOwner) {
                    theTokenIDsOfRightfulOwner[numMatchingTokensFound] = nextTokenIdToQuery;
                    numMatchingTokensFound++;
                }
            }
        }
        return theTokenIDsOfRightfulOwner;
    }


    // Hook overrides

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable, ERC721Lending)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981GlobalRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
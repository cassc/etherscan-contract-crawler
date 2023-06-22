// SPDX-License-Identifier: MIT

/// @title: BurnNFT
/// @author: Humie Devs
//              ..                                              ./%@&(.            
//          *@@@@@@@#                                         (@@&*.,&@@(          
//         *@@@@@@@@@(                                       ,@@,     ,@@*         
//          @@@@@@@@@.             .(@@@@@@@@@@%*             &@&.   .&@&          
//            /#%#/(@@&,     ,%@@@@#/,,&@#   .,*#&@@@%/        .#@@@@@%,           
//                    &@@(*@@@/        ,@@#.,#@@@@@@@@@@@#                         
//                     [email protected]@@&,          #@@@@#/.        ,@@@&,                      
//                    %@&.,&@@(    ,&@@&/.&@@,       /@@@*/@@@,                    
//                  *@@,     #@@&@@@%.     *@@&.  [email protected]@@%    #@@@#                   
//                 /@@.       (@@@@#.        *@@@@@@*      (@&@@#                  
//                ,@@.      %@@%  #@@&*      .&@@@@&.      &@/ @@(                 
//                #@&/.   ,@@%      ,@@@#. (@@@*  /@@@%,  &@%  /@@.                
//                %@%#&@@@@@/          #@@@@%.       ,%@@@@&.  ,@@*                
//                %@#   %@@&@@@&.     /@@@@@@#         /@@&&@@@@@@,                
//                (@%  %@&    /&@@%*%@@%    #@@&*    .&@@,     (@@.                
//                 @@([email protected]@*       /@@@#        ,@@@# &@@*      *@@,                 
//                  &@&@&.    .&@@%.%@@%         &@@@#       ,@@*                  
//                   &@@@,  /@@@/     #@@/    *@@@#,&@@#.   (@@.                   
//                    *@@@@@@%.        [email protected]@@@@@@%      #@@&#@@(                     
//                      *@@@%(,.. .,*(&@@@@@/          ,&@@@(                      
//                         /@@@@@@@@%/.   (@@.      (@@@#  (@@&,                   
//          #@@@@@@@%.         /&@@@@&%%##(&@@&@@@@@/.       .&@@@@@@@#            
//         &@#     *@@*               .,*//*,,                *@@@@@@@@@/          
//         &@#     [email protected]@*                                       ,@@@@@@@@@*          
//         .%@@@&@@@&.                                          #@@@@@#                                                                                                                                                                            
//                                                     
// ............................................................................
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Adminable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// Everything required for construction.
/// @param burnableNFTContract The ERC721 contract that will be allowed for swaps.
/// @param burnPrice The price to burn/swap and mint the new edition.
/// @param name The ERC721 name.
/// @param symbol The ERC721 symbol.
/// @param baseURI The initial ERC721 baseURI (can be modified by admin).
/// @param admin The initial admin address (onchain administration).
/// @param owner The initial owner address (offchain administration).
struct BurnNFTConfig {
    address burnableNFTContract;
    uint96 burnPrice;
    string name;
    string symbol;
    string baseURI;
    address admin;
    address owner;
}

/// @title Burn Contract
/// @notice
///
contract BurnNFT is ERC721A, Ownable, Adminable {
    
    using Address for address payable;
    using SafeMath for uint256;

    /// @dev set by admin and read by BurnNFT.burnSingle and BurnNFT.burn
    uint96 public burnPrice;

    /// @dev the interfacing NFT contract - set during construction
    IERC721 public burnableNFT;

    /// @dev is burning active or paused
    bool public isPaused;

    /// @dev set by admin and read by ERC721A._baseURI
    string private baseURI;

    /// Emitted when contract is constructed.
    /// @param sender the `msg.sender` that deploys the contract.
    /// @param config All config used by the constructor.
    event Construct(address sender, BurnNFTConfig config);

    /// Emitted when the base URI is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the base URI.
    /// @param baseURI the new base URI.
    event BaseURI(address sender, string baseURI);

    /// Token constructor.
    /// Assigns owner and admin roles, mints all tokens for the admin and sets
    /// initial base URI.
    /// @param config_ All construction config.
    constructor(BurnNFTConfig memory config_)
        ERC721A(config_.name, config_.symbol)
    {
        // Setup roles
        _transferAdmin(config_.admin);
        _transferOwnership(config_.owner);

        // Set initial baseURI.
        baseURI = config_.baseURI;

        // Set burn price
        burnPrice = config_.burnPrice;

        // Set-up burnable NFT interface
        burnableNFT = IERC721(config_.burnableNFTContract);

        // Enable burning in construction
        isPaused = false;

        // Inform the world.
        emit Construct(msg.sender, config_);
    }

    /// Public burn/swap function
    /// @param tokenIds the tokenIds to swap for new editions
    function burnAndSwap(uint256[] calldata tokenIds) public payable {
        require(!isPaused, "Burning is currently paused");
        uint256 count = tokenIds.length;
        require(count > 0, "Cannot burn 0 tokens");
        // Check price
        require(uint256(burnPrice).mul(count) <= msg.value, "Not enough ETH sent");

        // Swap the MusicNFTs for the given tokenIds & mint the new Editions.
        for (uint256 i; i < count; i++) {
            uint256 id = tokenIds[i];
            address tokenOwner = burnableNFT.ownerOf(id);

            // Check whether we're allowed to swap this Music NFT
            if (
                tokenOwner != msg.sender &&
                (! burnableNFT.isApprovedForAll(tokenOwner, msg.sender)) &&
                burnableNFT.getApproved(id) != msg.sender
            ) { 
                revert NotAllowedToSwap(); 
            }

            // Transfer out tokens to the contract
            burnableNFT.transferFrom(msg.sender, address(this), id);
        }
        
        // Mint tokens
        _safeMint(msg.sender, count);
    }

    /// Admin MAY set a new base URI at any time.
    /// @param baseURI_ The new base URI that all token URIs are build from.
    function adminSetBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
        emit BaseURI(msg.sender, baseURI_);
    }

    /// Admin MAY set a new owner at any time.
    /// The owner has no onchain rights other than transferring ownership.
    /// @param owner_ The new owner address.
    function adminSetOwner(address owner_) external onlyAdmin {
        _transferOwnership(owner_);
    }

    /// Admin MAY set the state to `paused` at any time.
    /// @param paused_ The new state of the contract.
    function adminSetPaused(bool paused_) external onlyAdmin {
        isPaused = paused_;
    }

    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view override returns (string memory baseURI_) {
        baseURI_ = baseURI;
    }

    /// Admin WILL withdraw all ETH
    function adminWithdrawETH(address payable payee) public virtual onlyAdmin {
        payee.sendValue(address(this).balance);
    }

    /// Owners and Approved EOAs CAN burn their tokens
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    /// @dev error 
    error NotAllowedToSwap();
}
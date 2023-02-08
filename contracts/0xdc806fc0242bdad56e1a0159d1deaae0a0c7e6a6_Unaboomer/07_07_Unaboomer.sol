// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {Main} from "./Main.sol";

/** 
@title Unaboomer
@author lzamenace.eth
@notice This contract contains ERC-721 Unaboomer tokens (BOOMER) which are the profile 
picture and membership tokens for the Unaboomer NFT project and chain based game.
Each Unaboomer is a unique, dynamically generated pixel avatar in the likeness
of the real-life Unabomber, Theodore Kaczynski. Unaboomers can be "killed" by
other players by "sending" (burning) mailbombs. When Unaboomers are killed their
corresponding image is replaced with an explosion, rendering it worthless as any
rarity associated with it ceases to exist. The game stops when MAX_SURVIVOR_COUNT
threshold is breached. The surviving players (any address which holds an "alive"
Unaboomer) will advance to the next round of gameplay.
@dev All contract functions regarding token burning and minting are limited to 
the Main interface where the logic and validation resides.
*/
contract Unaboomer is ERC721, Owned {
    using LibString for uint256;

    /// Track mints per wallet to enforce maximum
    mapping(address => uint256) public tokensMintedByWallet;
    /// Maximum supply of BOOMER tokens
    uint256 public constant MAX_SUPPLY = 5000;
    /// Maximum amount of survivors remaining to advance to the next round
    uint256 public constant MAX_SURVIVOR_COUNT = 1000;
    /// Maximum amount of mints per wallet - cut down on botters
    uint256 public constant MAX_MINT_AMOUNT = 25;
    /// Amount of Unaboomers killed (tokens burned)
    uint256 public burned;
    /// Amount of Unaboomers radicalized (tokens minted)
    uint256 public minted;
    /// Base URI for Unaboomers - original pixelated avatars and pixelated explosions
    string public baseURI;
    /// Contract address of the deployed Main contract interface to the game
    Main public main;

    constructor() ERC721("Unaboomer", "BOOMER") Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Set metadata URI for Unaboomer PFPs and explosions
    /// @param _baseURI IPFS hash or URL to retrieve JSON metadata for living Unaboomer tokens
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// Set main contract address for executing functions
    /// @param _address Contract address of the deployed Main contract
    function setMainContract(address _address) external onlyOwner {
        main = Main(_address);
    }

    // =========================================================================
    //                              Modifiers
    // =========================================================================
    
    /// Limit function execution to deployed Main contract
    modifier onlyMain {
        require(msg.sender == address(main), "invalid msg sender");
        _;
    }

    // =========================================================================
    //                              Tokens
    // =========================================================================

    /// Helper function to get supply minted
    /// @return supply Number of Unaboomers radicalized in totality (minted)
    function totalSupply() public view returns (uint256) {
        return minted - burned;
    }

    /// Mint tokens from main contract
    /// @param _to Address to mint BOOMER tokens to
    /// @param _amount Amount of BOOMER tokens to mint
    function radicalize(address _to, uint256 _amount) external onlyMain {
        require(minted + _amount <= MAX_SUPPLY, "supply reached");
        require(tokensMintedByWallet[_to] + _amount <= MAX_MINT_AMOUNT, "cannot exceed maximum per wallet");
        for (uint256 i; i < _amount; i++) {
            minted++;
            _safeMint(_to, minted);
        }
        tokensMintedByWallet[_to] += _amount;
    }

    /// Toggle token state from living to dead
    /// @param _tokenId Token ID of BOOMER to toggle living -> dead and increment kill count
    function die(uint256 _tokenId) external onlyMain {
        require(_tokenId <= minted, "invalid token id");
        if (ownerOf(_tokenId) != address(0)) {
            burned++;
            _burn(_tokenId);
        }
    }

    /// Retrieve owner of given token ID
    /// @param _tokenId Token ID to check owner of
    /// @return owner Address of owner
    /// @dev Overridden from Solmate contract to allow zero address returns 
    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        return _ownerOf[_tokenId];
    }

    // Return URI to retrieve JSON metadata from - points to images and descriptions
    /// @param _tokenId Token ID of BOOMER to fetch URI for
    /// @return string IPFS or HTTP URI to retrieve JSON metadata from
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (ownerOf(_tokenId) == address(0)) {
            return string(abi.encodePacked(baseURI, "dead.json"));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }
    }

    /// Checks if contract supports a given interface
    /// @param interfaceId The interface ID to check if contract supports
    /// @return bool Boolean value if contract supports interface ID or not
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
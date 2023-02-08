// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Main} from "./Main.sol";

/** 
@title Mailbomb
@author lzamenace.eth
@notice This contract contains ERC-1155 Mailbomb tokens (BOMB) which are used as
utility tokens for the Unaboomer NFT project and chain based game.
Mailbombs can be delivered to other players to "kill" tokens they hold, which 
toggles the image to a dead / exploded image, and burns the underlying BOMB token. 
@dev All contract functions regarding token burning and minting are limited to 
the Main interface where the logic and validation resides.
*/
contract Mailbomb is ERC1155, Owned {

    /// Track the total number of bombs assembled (tokens minted)
    uint256 public bombsAssembled;
    /// Track the number of bombs that have exploded (been burned)
    uint256 public bombsExploded;
    /// Base URI for the bomb image - all bombs use the same image
    string public baseURI;
    /// Contract address of the deployed Main contract interface to the game
    Main public main;

    constructor() ERC1155() Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Set metadata URI for all BOMB (token 1)
    /// @param _baseURI IPFS hash or URL to retrieve JSON metadata
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

    /// Mint tokens from main contract
    /// @param _to Address to mint BOMB tokens to
    /// @param _amount Amount of BOMB tokens to mint
    function create(address _to, uint256 _amount) external onlyMain {
        bombsAssembled += _amount;
        super._mint(_to, 1, _amount, "");
    }

    /// Burn spent tokens from main contract
    /// @param _from Address to burn BOMB tokens from
    /// @param _amount Amount of BOMB tokens to burn
    function explode(address _from, uint256 _amount) external onlyMain {
        bombsExploded += _amount;
        super._burn(_from, 1, _amount);
    }

    /// Get the total amount of bombs that have been assembled (minted)
    /// @return supply Number of bombs assembled in totality (minted)
    function totalSupply() public view returns (uint256 supply) {
        return bombsAssembled;
    }

    /// Return URI to retrieve JSON metadata from - points to images and descriptions
    /// @param _tokenId Unused as all bombs point to same metadata URI
    /// @return string IPFS or HTTP URI to retrieve JSON metadata from
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return baseURI;
    }

    /// Checks if contract supports a given interface
    /// @param interfaceId The interface ID to check if contract supports
    /// @return bool Boolean value if contract supports interface ID or not
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
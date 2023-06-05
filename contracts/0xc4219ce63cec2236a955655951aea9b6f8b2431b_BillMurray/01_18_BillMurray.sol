// _______                                                   __            __     __                     __                                         
//       \                                                 /  |          /  |   /  |                   /  |                                        
//$$$$$$$  | ______    ______      __   ______    _______  _$$ |_         $$ |   $$ | ______   _______  $$ |   __  _____  ____    ______   _______  
//$$ |__$$ |/      \  /      \    /  | /      \  /       |/ $$   |        $$ |   $$ |/      \ /       \ $$ |  /  |/     \/    \  /      \ /       \ 
//$$    $$//$$$$$$  |/$$$$$$  |   $$/ /$$$$$$  |/$$$$$$$/ $$$$$$/         $$  \ /$$//$$$$$$  |$$$$$$$  |$$ |_/$$/ $$$$$$ $$$$  | $$$$$$  |$$$$$$$  |
//$$$$$$$/ $$ |  $$/ $$ |  $$ |   /  |$$    $$ |$$ |        $$ | __        $$  /$$/ $$    $$ |$$ |  $$ |$$   $$<  $$ | $$ | $$ | /    $$ |$$ |  $$ |
//$$ |     $$ |      $$ \__$$ |   $$ |$$$$$$$$/ $$ \_____   $$ |/  |        $$ $$/  $$$$$$$$/ $$ |  $$ |$$$$$$  \ $$ | $$ | $$ |/$$$$$$$ |$$ |  $$ |
//$$ |     $$ |      $$    $$/    $$ |$$       |$$       |  $$  $$/          $$$/   $$       |$$ |  $$ |$$ | $$  |$$ | $$ | $$ |$$    $$ |$$ |  $$ |
//$$/      $$/        $$$$$$/__   $$ | $$$$$$$/  $$$$$$$/    $$$$/            $/     $$$$$$$/ $$/   $$/ $$/   $$/ $$/  $$/  $$/  $$$$$$$/ $$/   $$/ 
//                        /  \__$$ |                                                                                                              
//                          $$    $$/                                                                                                               
//                           $$$$$$/    
    
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

//An ERC721 smart contract that is able to designate an individual minter and token setter role, and a royalty recipient.
contract BillMurray is AccessControl, ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981
{
    using Counters for Counters.Counter;
    Counters.Counter private _mintCount;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    //The max amount of tokens that can ever possibly be minted.
    // uint256 public maxMintAmount;

    //Initializes an event that is invoked when a token is minted.
    event Minted(uint256 tokenId);

    bytes32 public constant TOKEN_SETTER_ROLE = keccak256("TOKEN_SETTER_ROLE");
    //Initializes an event that is invoked when a token's tokenURI is set.
    event OnSetTokenURI(uint256, string);

    //Initializes the _basisPoints property. It determines the percentage rate of which royalties are paid out
    //Formula: 1000 / _basisPoints;
    uint256 private _basisPoints = 1000; //1000 = 10%
    //The address to which royalties will be paid out to.
    address private _royaltyRecipient;

    uint256 private maxMintAmount;

    //Passes along the addresses used for minting, token URI setting, and royalties to their respective contract constructors.
    constructor(address admin, address[] memory minterRoleAddresses, address[] memory tokenSetterRoleAddresses, address royaltiesAddress, uint256 basisPoints, uint256 _maxMintAmount)
    ERC721("Bill Murray 1000","BILL")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);         
        _setupRoles(MINTER_ROLE, minterRoleAddresses);
        _setupRoles(TOKEN_SETTER_ROLE, tokenSetterRoleAddresses);

        _basisPoints = basisPoints;
        _setRoyaltiesRecipient(royaltiesAddress);

        require(_maxMintAmount > 0, "The Max Mint Amount must not be zero!");
        maxMintAmount = _maxMintAmount;
    }

    function _setupRoles(bytes32 role, address[] memory addresses) private {
        for (uint i = 0; i < addresses.length; i++) {
            
            require(addresses[i] != address(0), "Cannot set 0x0 as role!");
            _setupRole(role, addresses[i]);
        }
    }

    //Public facing mint function to be called from Web3 technologies.
    function mint() public {

        require(hasRole(MINTER_ROLE, msg.sender), "Msg.sender is not permitted to mint tokens!");

        require(_mintCount.current() < maxMintAmount, "The max amount of NFTs have been minted! No more are able to be made.");
        
        //Assigns a local variable to the current value of the number of minted tokens.
        uint256 newTokenId = _mintCount.current();
        //Invokes ERC721's _safeMint function, passing the msg.sender address and the id that we want to set to the newly minted token's tokenID. 
        _safeMint(msg.sender, newTokenId);
        //Increases the tracked number of minted tokens by 1.
        _mintCount.increment();

        //Invokes the Minted event, passing along the newly minted token's tokenId.
        emit Minted(newTokenId);
    }

    //Helper function which returns the number of minted tokens.
    function getMintCount() public view returns(uint256) {
        return _mintCount.current();
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        //Requires that the address that signed the transaction is assigned a token setter role by the contract.
        require(hasRole(TOKEN_SETTER_ROLE, msg.sender), "Msg.sender is not permitted to set token URIs!");
        
        //Calls ERC721URIStorage's setTokenURI functionality
        super._setTokenURI(tokenId, _tokenURI);
        //Invokes the OnSetTokenURI event, passing along the tokenID that had its tokenURI changed, and its new tokenURI.
        emit OnSetTokenURI(tokenId, _tokenURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

     //Sets the calculated amount of royalty to be paid out based on the price of the sale    
    function royaltyInfo(uint256, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyRecipient, (_salePrice * _basisPoints) / 10000);
    }

    //Sets the royalty recipient.  
    function _setRoyaltiesRecipient(address newRecipient) internal {
        //Revert transaction if setting royalties to 0x0.
        require(newRecipient != address(0), "Royalties: new recipient is the zero address!");
        _royaltyRecipient = newRecipient;
    }
}
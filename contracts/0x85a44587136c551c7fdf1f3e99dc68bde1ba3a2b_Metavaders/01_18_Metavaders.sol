// SPDX-License-Identifier: MIT

/// @title: Metavaders - Mint
/// @author: PxGnome
/// @notice: Basic core Metavaders NFT Smart Contract
/// @dev: This is Version 1.0
//
// ███╗   ███╗███████╗████████╗ █████╗ ██╗   ██╗ █████╗ ██████╗ ███████╗██████╗ ███████╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
// ██╔████╔██║█████╗     ██║   ███████║██║   ██║███████║██║  ██║█████╗  ██████╔╝███████╗
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚██╗ ██╔╝██╔══██║██║  ██║██╔══╝  ██╔══██╗╚════██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║ ╚████╔╝ ██║  ██║██████╔╝███████╗██║  ██║███████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Metavaders is 
    Ownable,
    AccessControlEnumerable,
    ERC721Enumerable
{
    
    // SPECIAL ROLE DEFINE
    bytes32 public constant ACTIVATOR_ROLE = keccak256("ACTIVATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Strings for uint256;
    string public _baseTokenURI;
    mapping (uint256 => string) private _tokenURIs; // Optional mapping for token URIs


    uint256 public max_mint = 10101;
    uint256 public reserved = 200; // Reserved amount for special usage
    // uint256 public price = 0.07 ether;
    // uint256 private _max_gas = 0.01 ether;
    // uint256 public start_time = 0; // start time:  Monday, September 13, 2021 7:00:00 PM UTC

    // uint256 private _presale_max = 1000;


    bool private _reveal = false;

    // -- CONSTRUCTOR FUNCTIONS -- //
    // 10101 Metavaders in total
    constructor(string memory baseURI) ERC721("Metavaders", "MVADER")  {
        // Set up baseURI for when not yet revealed
        setBaseURI(baseURI);

        // Set Up Roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ACTIVATOR_ROLE, _msgSender());
        grantRole(ACTIVATOR_ROLE, address(this));

        _setupRole(MINTER_ROLE, _msgSender());
        grantRole(MINTER_ROLE, address(this));

        // Mint the first Metavader for owner
        _safeMint(_msgSender(), 0); 
    } 

    // // -- UTILITY FUNCTIONS -- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -- BASE FUNCTIONS -- //
    // Shows Base URI
    function getBaseURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    // Mint Function
    function mint(address to, uint256 num) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        uint256 supply = totalSupply();
        for(uint256 i; i < num; i++){
            _safeMint(to, supply + i );
        }
    }

    // Used to set up overrides
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    //     super._burn(tokenId);
    // }
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (!_reveal) {
            return _baseURI();
        }
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    // Used to update baseURI to make upgrades to metadata - Only done by owner
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // To allow token URI to reveal the actual collection
    function reveal(bool _revealed, string memory baseURI) public onlyOwner {
        _reveal = _revealed;
        setBaseURI(baseURI);
    }

    // // Minted the reserve
    function reserveMint(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reserved, "Exceeds reserved supply" );
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
        reserved -= _amount;
    }

    // Withdraw ETH to owner addresss
    function withdrawAll() public payable onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance)); 
        return balance;
    }

    // -- CUSTOM ADD ONS  --//
    // ACTIVATOR_ROLE
    function grantActivator(address _address) public {
        grantRole(ACTIVATOR_ROLE, _address);
    }
    function revokeActivator(address _address) public {
        revokeRole(ACTIVATOR_ROLE, _address);
    }

    // MINTER_ROLE
    function grantMinter(address _address) public {
        grantRole(MINTER_ROLE, _address);
    }
    function revokeMinter(address _address) public {
        revokeRole(MINTER_ROLE, _address);
    }

    // Changes the Metavaders' mode can be used by ACTIVATORS
    function changeMode(uint256 tokenId, string memory mode) public virtual {
        require(hasRole(ACTIVATOR_ROLE, _msgSender()), "Must have ACTIVATOR_ROLE to execute");
        _setTokenURI(tokenId, string(abi.encodePacked(tokenId.toString(), mode)));
    }

    // Helps check which Metavader this wallet owner owns
    function collectionInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Helps check how many Metavader this wallet owner owns
    // function tokenInWallet(address _owner) public view returns(uint256) {
    //     return balanceOf(_owner);
    // }

    function remainingSupply() public view returns(uint256) {
        return (max_mint - totalSupply() - reserved);
    }
}
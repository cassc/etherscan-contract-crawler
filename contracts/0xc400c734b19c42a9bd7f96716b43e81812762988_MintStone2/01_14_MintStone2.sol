// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintStone2 is Ownable, ReentrancyGuard, ERC721Enumerable {
    event PermanentURI(string _value, uint256 indexed _id);

    bool public baseURILocked;
    bool public contractPaused;

    string private _baseTokenURI;
    address private _mintAuthorizedContract;
    address private _burnAuthorizedContract;
    address private _admin;

    constructor(
        string memory baseTokenURI,
        address admin)
    ERC721("CF MintStone II", "MINTSTONE2") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        _safeMint(msg.sender, 0);
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        baseURILocked = true;
        for (uint256 i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual {
        // Avoid unnecessary approvals for the authorized contract
        require(
            msg.sender == _burnAuthorizedContract || _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == _mintAuthorizedContract, "This token can only be minted by the mint contract");
        _safeMint(to, tokenId);
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setBurnAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _burnAuthorizedContract = authorizedContract;
    }

    function setMintAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _mintAuthorizedContract = authorizedContract;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!contractPaused, "Contract is paused");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Marketplace blocklist functions
    mapping(address => bool) private _marketplaceBlocklist;

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        require(_marketplaceBlocklist[to] == false, "Marketplace is blocked");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        require(_marketplaceBlocklist[operator] == false, "Marketplace is blocked");
        super.setApprovalForAll(operator, approved);
    }

    function blockMarketplace(address addr, bool blocked) public onlyOwnerOrAdmin {
        _marketplaceBlocklist[addr] = blocked;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/mintstone2/marketplace-metadata";
    }
}
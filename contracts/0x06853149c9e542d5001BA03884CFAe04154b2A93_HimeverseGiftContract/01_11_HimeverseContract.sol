// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721A.sol";

contract HimeverseGiftContract is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public  MAX_SUPPLY = 2000;           // Max Supply
    string  private baseTokenURI;                // Base TokenURI  
    bool    public  isPaused;                    // Is it paused?
    mapping(address => bool) public admin_list;  //address allowed to mint.

    // We are only inheriting ERC721A straight.
    constructor() ERC721A("HimeVerse Smile", "HVSM"){}

    // Returns total number of tokens minted (different from totalSupply() inherited)
    function totalMinted() external view returns (uint256){
        return _totalMinted();
    }

    // This modifier make sure that it is not another contract calling this contract.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Airdrop is only allowed to those addresse that are in admin_list.
    function airdrop(address[] memory addresses) external callerIsUser{
        require(!isPaused, "Minting is paused currently.");
        require((_totalMinted() + addresses.length) <= MAX_SUPPLY, "You cannot exceed max supply.");
        require(admin_list[msg.sender], "Only mintable from admin addresses.");

        // Record the # minted.
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    // Set admin address.
    function setAdmin(address newadmin, bool isAdmin) external onlyOwner{
        admin_list[newadmin] = isAdmin;
    }

    // TokenURI Functoin to be called.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Else return the true address
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    // This _baseURI function is inherited from 721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Setter for base token URI.
    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenURI = _baseTokenUri;
    }

    // Toggle Pause status
    function togglePause() external onlyOwner{
        isPaused = !isPaused;
    }
}
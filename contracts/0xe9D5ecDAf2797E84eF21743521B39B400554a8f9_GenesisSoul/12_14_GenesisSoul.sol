// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*

 .M"""bgd `7MMF'`7MMF'  `7MMF'
,MI    "Y   MM    MM      MM  
`MMb.       MM    MM      MM  
  `YMMNq.   MM    MMmmmmmmMM  
.     `MM   MM    MM      MM  
Mb     dM   MM    MM      MM  
P"Ybmmd"  .JMML..JMML.  .JMML.

*/

/**
 * @title Genesis Soul Token
 * @author TRIBE
 * @notice This is a semi-soulbound contract, which unlocks transfers & approvals after a certain period of time.
*/

// Developed by @ASXLabs on Twitter
// https://www.asxlabs.com


contract GenesisSoul is Ownable, ERC721A, ERC721ABurnable, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    string private baseTokenUri;
    uint256 private devMinted = 0;

    bool public mintActive = false;
    bool public soulBoundEnabled = true;
    uint256 public mintPrice = 0.0088 ether;
    uint256 public maxSupply = 20000;


    constructor() ERC721A("Genesis Soul", "GS") {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    /** 
    @notice Mint function. The designated WL wallet can be minted to by any other wallet.
    This allows minters to use any hot wallet to mint to their designed cold wallet. 
    */
    function mint(address to) external payable callerIsUser {
        require(mintActive, "Minting is not active");
        require(_getAux(to) < 1, "You have already minted a token to this address");
        require(msg.value >= mintPrice, "Below mint price");
        require(_totalMinted() < maxSupply, "Max supply reached");
    
        _setAux(to, 1);
        _mint(to, 1);
    }

    // Mint function for dev wallets. Can only be called by the owner. Mints 200 tokens max.
    function mintDev(address to, uint256 amount) external onlyOwner {
        require(devMinted + amount <= 200, "You are trying to mint more than 200 tokens in total");
        require(totalSupply() + amount <= maxSupply, "Max supply reached");        
        unchecked {devMinted += amount;}

        _mint(to, amount);
    }


    // Revoke a token
    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId, false);
    }

    // Set base URI
    /* 
    * @dev Must include trailing slash 
    **/
    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    // Toggle minting status
    function setMintActive() external onlyOwner {
        mintActive = !mintActive;
    }
    
    // Toggle transfer status
    function setSoulBound() external onlyOwner {
        soulBoundEnabled = !soulBoundEnabled;
    }

    // Set mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    // Set max supply
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    
    // Returns the total amount of tokens minted
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }
    
    /**
    @notice Prevents the transfer of tokens if the tokens are in the "soulbound state" 
    */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (!(from == address(0)) && !(to == address(0))) {
            require(!soulBoundEnabled, "Token is currently in soulbound state");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
    @notice Blocks listing and approving of tokens if the tokens are in the "soulbound state"
    */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        require(!soulBoundEnabled, "Token is currently in soulbound state");
        super.setApprovalForAll(operator, approved);
    }

    /**
    @notice Blocks listing and approving of tokens if the tokens are in the "soulbound state"
    */
    function approve(
        address to, 
        uint256 tokenID
    ) public override payable {
        require(!soulBoundEnabled, "Token is currently in soulbound state");
        super.approve(to, tokenID);
    }

    // Returns the total amount of tokens burned
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    // Returns the amount of tokens burned by a specific address
    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    // Return uri for certain token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString())) : "";
    }

    // Withdraw funds
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/**
 *
 *  TradersClubDAO
 *
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721AWhitelist.sol";
contract TradersClubDAO is ERC2981, ERC721A, Ownable, ReentrancyGuard, ERC721AWhitelist{

    uint256 public immutable maxSupply;
    uint256 public immutable amountForDevs;
    address immutable teamAddress; 
    bool teamMintStatus;
    
    mapping(bytes => bool) public signatures;
    address whitelistSigningKey = address(0);

    constructor(uint256 _maxSupply, uint256 _amountForDev, address _teamAddress, uint96 royaltyFees) ERC721A("TradersClubDAO", "TCDAO"){
        require(_maxSupply > 0, "ERC721A: max batch size must be nonzero");
        _setDefaultRoyalty(_teamAddress, royaltyFees);

        maxSupply = _maxSupply;
        amountForDevs = _amountForDev;
        teamAddress = _teamAddress;
        teamMintStatus = false;
        
        signatures["0x0000000000000000000000000000000000000000"] = true;
    }

    /**
     * @dev Caller is User.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
    

    /**
     * @dev Mint for public.
     */
    function mint(bytes32 hash, bytes calldata whiteListSignature, bytes calldata signature) callerIsUser public {
        require(numberMinted(msg.sender) < maxSupply , "Reached maximum NFT mint for public member");
        require(recoverWhitelistSigner(hash, whiteListSignature) == owner(), "You are not on the list.");
        require(!signatures[signature], "You have already minted NFT.");
        _whitelistMint();
        signatures[signature] = true;
    }

    function _whitelistMint() private {
        require(numberMinted(msg.sender) < 1, "1 NFT max per address");
        require(_totalMinted() < maxSupply, "NFT Sold out");
        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Mint for internal team.
     */
   function teamMint() external payable callerIsUser{
        require( msg.sender == teamAddress, "This is only for team member.");
        _internalMint();
    }    
    
    function _internalMint() private {
        require(numberMinted(msg.sender) < amountForDevs , "Reached maximum NFT mint for team member");
        require(_totalMinted() < maxSupply, "NFT Sold out");
        _safeMint(msg.sender, 50);
    }

    /**
     * @dev BaseTokenURI for Traders Club DAO
     */
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Reset specific token royalty.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner nonReentrant {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Default Royalty
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Reset specific token royalty.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    /**
     * @dev Reset specific token royalty.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Get mint count of input address.
     */
    function numberMinted(address owner) public view returns(uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev Withdraw balnace to Team Address.
     */
    function withdraw() external onlyOwner {
        payable(teamAddress).transfer(address(this).balance);
    }

     /**
     * Override Royalty Interface
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

}
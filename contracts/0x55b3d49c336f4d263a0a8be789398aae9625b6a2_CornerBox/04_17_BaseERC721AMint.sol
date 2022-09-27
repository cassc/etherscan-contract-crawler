// SPDX-License-Identifier: MIT
// BaseERC721AMint Contract v1.0.1
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./library/TokenLib.sol";
import "./library/BasicRequires.sol";

/**
 * @title BaseERC721AMint
 * @author Heath C. Michaels, (@heathcmichaels @wanderingme @wanderingheath)    f
 * @dev Basic NFT contract extending Chiru Labs' ERC721A standard
 *
 * @notice Contract is just the nuts and bolts of a basic NFT mint with custom features
 *
 *
 */

 contract BaseERC721AMint is Ownable, ReentrancyGuard, IERC721A, ERC721A, ERC721AQueryable{
    using Strings for uint256;
    using TokenLib for TokenLib.TokenStorage;
    using BasicRequires for uint256;

    TokenLib.TokenStorage private TokenStorage;

    bool public isMintEnabled;
    bool public isPaused;
    bool public isLocked;
    bool public isBurnLive;

    uint256 public maxSupply;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxPerWallet = 20;
    uint256 public whitelistedMaxPerWallet = maxPerWallet;

    string private baseURI;
    string internal baseExt = "";
    string public provenanceHash = "";

    bytes32 private whitelistRoot;

    constructor(
            string memory _name, 
            string memory _symbol, 
            uint256 _maxSupply, 
            string memory _initBaseUri
    ) ERC721A(_name, _symbol) {
                baseURI = _initBaseUri;
                maxSupply = _maxSupply;
    }
    modifier mintConform(uint256 _numberOfTokensRequestedForMint) {
        require(_numberOfTokensRequestedForMint.RequiresCheckMint(isLocked, totalSupply(), maxSupply, balanceOf(msg.sender), (isMintEnabled ? maxPerWallet : whitelistedMaxPerWallet)));
         _;
    }
    modifier nonOwnerMintConform(uint256 _numberOfTokensRequestedForMint) {
        require(_numberOfTokensRequestedForMint.RequiresCheckNonOwnerMint(isPaused, mintPrice));
        _;
    }
  
    /**
     *
     *                           PUBLIC/EXTERNAL FUNCTIONS
     *
     */


    /**
     * Public Mint
     */
    function mint(uint256 _numberOfTokensRequestedForMint) public payable nonReentrant mintConform(_numberOfTokensRequestedForMint) nonOwnerMintConform(_numberOfTokensRequestedForMint) {
        require(isMintEnabled, "Minting unavailable");
         mintTokens(_numberOfTokensRequestedForMint, msg.sender);
    }
    function signedMint(uint256 _numberOfTokensRequestedForMint, bytes32[] memory proof) public payable nonReentrant mintConform(_numberOfTokensRequestedForMint) nonOwnerMintConform(_numberOfTokensRequestedForMint) {
        require(MerkleProof.verify(proof, whitelistRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle");
        mintTokens(_numberOfTokensRequestedForMint, msg.sender);
    }
    function tokenURI(uint256 tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory){
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), baseExt));
    }
    function burn(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "caller unapproved");
        maxSupply -= 1;
        _burn(tokenId);
        TokenStorage.burn(tokenId);
    }
    function getAddressFromBurnedTokenId(uint256 tokenId) view external returns (address){
        return TokenStorage.getAddressByBurnedTokenId(tokenId);
    }
    function getNumberBurned(address user) view external returns (uint256) {
        return _numberBurned(user);
    }

     /**
      *
      *                           PRIVATE/INTERNAL FUNCTIONS
      *
      */

    function mintTokens(uint256 _numberOfTokensRequestedForMint, address _addressToReceiveToken) internal {
        _mint(address(_addressToReceiveToken), _numberOfTokensRequestedForMint);
        TokenLib.emitEventForMint(totalSupply(), _numberOfTokensRequestedForMint, _addressToReceiveToken);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
     /** 
      *
      *                           OWNER ONLY FUNCTIONS
      *
      */

    function withdraw() external onlyOwner nonReentrant payable {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

     function mintForAddresses(uint256 _numberOfTokensRequestedForMint, address[] calldata _addressesToReceiveToken) public payable mintConform(_numberOfTokensRequestedForMint) onlyOwner{
           for (uint i = 0; i < _addressesToReceiveToken.length; i++) {
                mintTokens(_numberOfTokensRequestedForMint, _addressesToReceiveToken[i]);
           }
    }
    //Warning, locking tokens cannot be undone! 
    function lockRemainingTokensForever() external onlyOwner{
        isLocked = true;
        maxSupply = totalSupply();
    }

    function toggleMintIsEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }
    function setPause(bool val) external onlyOwner{
        isPaused = val;
    }
    function setBurnLive(bool val) external onlyOwner{
        isBurnLive = val;
    }
 
    function setProvenanceHash(string memory _provHash) external onlyOwner {
        provenanceHash = _provHash;
    }
    
    //   WL : optional update whitelist max per wallet for presale
    function setWhitelistedMaxPerWallet(uint256 _val) external onlyOwner{
        whitelistedMaxPerWallet = _val;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        //Be sure the uri ends in "/"
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        //i.e., ".json" or leave blank for custom http api calls
        baseExt = _newBaseExtension;
    }
    function addMerkleRoot(bytes32 _whitelistRoot) external onlyOwner{
        whitelistRoot = _whitelistRoot;
    }
    
 }
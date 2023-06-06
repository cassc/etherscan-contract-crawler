// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * @title Token contract for Savage Droids
 * @dev This contract allows the distribution of 
 * Savage Droids tokens in the form of a presale and main sale.
 * 
 * Users can mint from either Community or Theos in either sales. 
 *
 * SAVAGE DROIDS X BLOCK::BLOCK.
 * 
 * Smart contract work done by lenopix.eth
 */
contract SavageDroids is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Address for address;

    event Mint(address indexed to, uint256 indexed tokenId, uint256 indexed factionId, bytes32 mintHash);

    // Faction Ids
    uint256 public constant COMMUNITY_ID = 0;
    uint256 public constant THEOS_ID = 1;

    // Minting constants
    uint256 public maxMintPerTransaction;
    uint256 public COMMUNITY_MINT_SUPPLY;
    uint256 public THEOS_MINT_SUPPLY;

    uint256 public COMMUNITY_STAFF_SUPPLY;
    uint256 public THEOS_STAFF_SUPPLY;

    // 0.088 ETH
    uint256 public constant MINT_PRICE = 88000000000000000;

    // Keep track of supply
    uint256 public communityMintCount = 0;
    uint256 public theosMintCount = 0;
    
    // Sale toggles
    bool private _isPresaleActive;
    bool private _isSaleActive;

    // Tracks the faction for a token
    mapping (uint256 => uint256) factionForToken;

    // Presale
    mapping (address => bool) private presaleClaimed; // Everyone who got in on the presale can only claim once.
    address private signVerifier;

    // Module contract
    mapping(address => bool) private moduleContracts;

    // Base URI
    string private _uri;

    constructor(
        uint256 communityMintSupply,
        uint256 theosMintSupply,
        uint256 communityStaffSupply,
        uint256 theosStaffSupply,
        uint256 maxMint
    ) ERC721("Savage Droids", "SD888") {
        COMMUNITY_MINT_SUPPLY = communityMintSupply;
        THEOS_MINT_SUPPLY = theosMintSupply;
        COMMUNITY_STAFF_SUPPLY = communityStaffSupply;
        THEOS_STAFF_SUPPLY = theosStaffSupply;
        maxMintPerTransaction = maxMint;

        _isSaleActive = false;
        _isPresaleActive = false;
        signVerifier = 0xd974C841FF9ad100a992555F4587CA61c838E6Aa;
    }

    // @dev Returns the faction of the token id
    function getFaction(uint256 tokenId) 
    external view returns (uint256) {
        require(_exists(tokenId), "Query for nonexistent token");
        return factionForToken[tokenId];
    }

    // @dev Returns whether a user has claimed from presale
    function getPresaleClaimed(address user) 
    external view returns (bool) {
        return presaleClaimed[user];
    }

    // @dev Returns the enabled/disabled status for presale
    function getPreSaleState() 
    external view returns (bool) {
        return _isPresaleActive;
    }

    // @dev Returns the enabled/disabled status for minting
    function getSaleState() 
    external view returns (bool) {
        return _isSaleActive;
    }

    // @dev Allows to set the baseURI dynamically
    // @param uri The base uri for the metadata store
    function setBaseURI(string memory uri) 
    external onlyOwner {
        _uri = uri;
    }

    // @dev Sets a new signature verifier
    function setSignVerifier(address verifier)
    external onlyOwner {
        signVerifier = verifier;
    }

    // @dev Dynamically set the max mints a user can do in the main sale
    function setMaxMintPerTransaction(uint256 maxMint)
    external onlyOwner {
        maxMintPerTransaction = maxMint;
    }

    // @dev Presale Mint
    // @param tokenCount The tokens a user wants to purchase
    // @param presaleMaxMint The max tokens a user can mint from the presale
    // @param factionId Community: 0 and Theos: 1
    // @param sig Server side signature authorizing user to use the presale
    function mintPresale(
        uint256 tokenCount, 
        uint256 presaleMaxMint, 
        uint256 factionId,
        bytes memory sig
    ) external nonReentrant payable {
        require(factionId == 0 || factionId == 1, "Faction is not valid");
        require(_isPresaleActive, "Presale not active");
        require(!_isSaleActive, "Cannot mint while main sale is active");
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= presaleMaxMint, "Token count exceeds limit");
        require((MINT_PRICE * tokenCount) == msg.value, "ETH sent does not match required payment");
        require(presaleMaxMint <= 6, "The max that a random user can mint in the presale is 6");
        require(!presaleClaimed[msg.sender], "Already minted in the presale with this address");
        
        // Verify signature
        bytes32 message = getPresaleSigningHash(msg.sender, tokenCount, presaleMaxMint, factionId).toEthSignedMessageHash();
        require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");

        presaleClaimed[msg.sender] = true;

        // Mint
        _handleFactionMint(
            tokenCount, 
            factionId, 
            msg.sender, 
            COMMUNITY_MINT_SUPPLY,
            THEOS_MINT_SUPPLY
        );
    }

    // @dev Main sale mint
    // @param tokensCount The tokens a user wants to purchase
    // @param factionId Community: 0 and Theos: 1
    function mint(uint256 tokenCount, uint256 factionId) 
    external nonReentrant payable {
        require(factionId == 0 || factionId == 1, "Faction is not valid");
        require(_isSaleActive, "Sale not active");
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= maxMintPerTransaction, "Token count exceeds limit");
        require((MINT_PRICE * tokenCount) == msg.value, "ETH sent does not match required payment");

        _handleFactionMint(
            tokenCount, 
            factionId, 
            msg.sender, 
            COMMUNITY_MINT_SUPPLY,
            THEOS_MINT_SUPPLY
        );
    }

    // @dev Private mint function reserved for company.
    // 44 Community and 44 Theos are reserved.
    // @param recipient The user receiving the tokens
    // @param tokenCount The number of tokens to distribute
    // @param factionId Community: 0 and Theos: 1
    function mintToAddress(address recipient, uint256 tokenCount, uint256 factionId) 
    external onlyOwner {
        require(isSaleFinished(), "Sale has not concluded");
        require(factionId == 0 || factionId == 1, "Faction does not exist");
        require(tokenCount > 0, "You can only mint more than 0 tokens");

        _handleFactionMint(
            tokenCount, 
            factionId, 
            recipient, 
            COMMUNITY_MINT_SUPPLY + COMMUNITY_STAFF_SUPPLY,
            THEOS_MINT_SUPPLY + THEOS_STAFF_SUPPLY
        );
    }

    // @dev Allows to enable/disable minting of presale
    function flipPresaleState()
    external onlyOwner {
        _isPresaleActive = !_isPresaleActive;
    }

    // @dev Allows to enable/disable minting of main sale
    function flipSaleState() 
    external onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function withdraw() 
    external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // @dev Future proof the contract to allow for 
    // functionality like transfer and fusion of droids.
    function toggleModuleContract(address module, bool state) 
    external onlyOwner {
        moduleContracts[module] = state;
    }

    function mintToken(address recipient, uint256 tokenId, uint256 factionId) 
    external
    {
        require(moduleContracts[msg.sender]);
        factionForToken[tokenId] = factionId;
        _safeMint(recipient, tokenId);
    }

    function burnToken(uint256 tokenId) 
    external
    {
        require(moduleContracts[msg.sender]);
        _burn(tokenId);
    }

    function getPresaleSigningHash(
        address recipient,
        uint256 tokenCount,
        uint256 presaleMaxMint,
        uint256 factionId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            recipient,
            tokenCount, 
            presaleMaxMint, 
            factionId
        ));
    }

    function supportsInterface(bytes4 interfaceId) 
    public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() 
    internal view override returns (string memory) {
        return _uri;
    }

    // @dev Check if sale has been sold out
    function isSaleFinished()
    internal view returns (bool) {
        return communityMintCount >= COMMUNITY_MINT_SUPPLY && theosMintCount >= THEOS_MINT_SUPPLY;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) 
    internal override(ERC721) {
        super._burn(tokenId);
    }

    function _handleFactionMint(
        uint256 tokenCount,
        uint256 factionId,
        address recipient,
        uint256 communityTotalSupply,
        uint256 theosTotalSupply
    ) private {
        if (factionId == COMMUNITY_ID) {
            require(communityMintCount < communityTotalSupply, "Community has been fully minted");
            require((communityMintCount + tokenCount) <= communityTotalSupply, "Cannot purchase more than supply available");
            communityMintCount += tokenCount;

            _mint(recipient, tokenCount, COMMUNITY_ID);
        } else if (factionId == THEOS_ID) {
            require(theosMintCount < theosTotalSupply, "Theos has been fully minted");
            require((theosMintCount + tokenCount) <= theosTotalSupply, "Cannot purchase more than supply available");
            theosMintCount += tokenCount;

            _mint(recipient, tokenCount, THEOS_ID);
        }
    }

    function _mint(address recipient, uint256 tokenCount, uint256 factionId) 
    private {
        uint256 totalSupply = totalSupply();
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = totalSupply + i;
            factionForToken[tokenId] = factionId;
            emit Mint(recipient, tokenId, factionId, _getHash(tokenId));
            _safeMint(recipient, tokenId);
        }
    }

    // @dev The hash that is used to generate the droid.
    function _getHash(uint256 tokenId)
    private view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, blockhash(block.number - 1)));
    }
}
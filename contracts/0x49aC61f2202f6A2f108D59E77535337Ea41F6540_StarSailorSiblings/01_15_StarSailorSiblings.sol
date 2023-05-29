pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/*
    @title Star Sailor Siblings' ERC-721 contract
    @author Humza K.

    https://starsailorsiblings.com/
*/

// For readability purpose only. It could be replaced with ERC721
contract StardustContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {} 
}

contract StarSailorSiblings is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    // Type alias
    using Address for address;

    // Stardust contract
    StardustContract stardust;

    // Minting constants
    uint256 public constant MAX_MINT_PER_TRANSACTION = 5;
    uint256 public constant MAX_BURN_PER_TRANSACTION = 3;
    uint256 public constant MAX_SUPPLY = 10101;

    // 0.075 ETH
    uint256 public constant MINT_PRICE = 75000000000000000; 

    // 101 are reserved. 5 guaranteed mints for each 999 STARDUST minted.
    // 101 + (999 * 5) = 5,096 guaranteed mints during private sale
    // Any supply left will be carried over to the primary sale
    uint256 public constant MAX_PRIVATE_SALE_SUPPLY = 5096;
    uint256 public constant MAX_MINT_PER_STARDUST = 5;
    
    // Keeping track of avatars/animations indexes
    uint256 public constant indexAvatarsStart = 0;
    uint256 public constant indexAvatarsEnd = 10100;
    uint256 public constant indexAnimationsStart = 10101;
    uint256 public constant indexAnimationsEnd = indexAnimationsStart + MAX_SUPPLY;

    // No need to call the contract for factually immutable values
    uint256 public constant STARDUST_TOTAL_SUPPLY = 999;

    // Keep track of supply
    uint256 public avatarsBurnedCount = 0;
    uint256 public animationsMintedCount = 0;
    
    // Control primary sale and burn
    bool private _isSaleActive;
    bool private _isPrivateSaleActive;
    bool private _isBurnActive;
    bool private _reserveClaimed;

    // Reserve 100 tokens to the staff, minted in 4 iterations of 25 each
    uint256 private _staffReservePerIteration = 25;
    uint256 private _staffReserveIterationCount = 0;

    // baseURI
    string private _uri;

    // Keep track of mints by stardust holders
    mapping(uint256 => uint256) private _stardustAlreadyMintedCount;
    
    constructor() ERC721("Star Sailor Siblings", "SSS") {
        _reserveClaimed = false;
        _isSaleActive = false;
        _isBurnActive = false;
    }

    // @param uri The base uri for the metadata store
    // @dev Allows to set the baseURI dynamically
    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    // @dev Sets the StardustContract to be used
    function setStardustContract(address _t) public onlyOwner {
        stardust = StardustContract(_t);
    }

    // @dev Returns the number of SSS tokens burned
    function getAvatarsBurnedCount() public view returns (uint256) {
        return avatarsBurnedCount;
    }

    // @dev Returns the number of animations minted so far
    function getAnimationsMintedCount() public view returns (uint256) {
        return animationsMintedCount;
    }

    // @dev Allows to enable/disable minting
    function flipSaleState() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    // @dev Allows to enable/disable private sale
    function flipPrivateSaleState() public onlyOwner {
        _isPrivateSaleActive = !_isPrivateSaleActive;
    }

    // @dev Allows to enable/disable burn functionality
    // @dev Nice to have functionality, in case the burn has to be stopped for any unforeseeable reason
    function flipBurnState() public onlyOwner {
        _isBurnActive = !_isBurnActive;
    }

    // @dev Returns the number of SSS tokens a given STARDUST token id can redeem
    function getMintedCountForStardustTokenId(uint stardustTokenId) public view returns (uint256) {
        require(stardustTokenId < STARDUST_TOTAL_SUPPLY, "You have provided an invalid STARDUST token id");
        return _stardustAlreadyMintedCount[stardustTokenId];
    }

    // @dev Reserves the tokens for staff. 
    // @dev The reserve happens in 4 iterations of 25 each
    function reserveSss() public onlyOwner {
        require(_staffReserveIterationCount < 4, "Reserve has already been claimed");

        uint supply = totalSupply();
        uint i;

        for(i = 0; i < _staffReservePerIteration; i++) {
            _safeMint(msg.sender, supply + i);
        }

        _staffReserveIterationCount += 1;
    }

    // @dev Returns enabled/disabled status for burn mechanism
    function getBurnState() public view returns (bool) {
        return _isBurnActive;
    }

    // @dev Returns the enabled/disabled status for minting
    function getSaleState() public view returns (bool) {
        return _isSaleActive;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // @dev Allows minting X number of SSS tokens
    // @param tokensCount No. of SSS tokens to mint
    function mintPublicSale(uint tokensCount) public nonReentrant payable {
        uint256 supply = totalSupply();
        require(_isSaleActive, "Sale is not active at the moment");
        require(supply < MAX_SUPPLY, "All SSS tokens have been minted");
        require(tokensCount > 0, "You can only mint more than 0 tokens");
        require((supply + tokensCount) <= MAX_SUPPLY, "The purchase exceeds the total supply available");
        require(tokensCount <= MAX_MINT_PER_TRANSACTION, "Too much requested");
        require((MINT_PRICE * tokensCount) == msg.value, "The specified ETH value is incorrect");

        for (uint256 i = 0; i < tokensCount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    // @dev Allows mint for private sale by stardust holders
    // @dev This may introduce a bit redundancy around mint logic, but I'm choosing the safe path around conditional minting.
    function mintPrivateSale(uint stardustTokenId, uint tokensCount) public nonReentrant payable {
        uint256 supply = totalSupply();

        require(_isPrivateSaleActive, "Private Sale is not active at the moment");
        require(supply < MAX_PRIVATE_SALE_SUPPLY, "All SSS tokens available for private sale have been minted");
        require(tokensCount > 0, "You can only mint more than 0 tokens");
        require(stardust.ownerOf(stardustTokenId) == msg.sender, "You do not own the stardust token id");
        require(_stardustAlreadyMintedCount[stardustTokenId] + tokensCount <= MAX_MINT_PER_STARDUST, "The purchase exceeds the available number of SSS tokens you can redeem using this STARDUST");

        _stardustAlreadyMintedCount[stardustTokenId] += tokensCount;

        for (uint256 i = 0; i < tokensCount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    // @dev Allows burn of exactly 3 SSS tokens in exchange for an animated token
    // @param tokenIds Array of token ids to burn
    // @param tokenToAnimatedId Id of the token that should be animated
    function burnSss(uint256[] memory tokenIds, uint256 tokenToAnimateId) public {
        require(_isBurnActive, "Burn is not active yet");
        require(tokenToAnimateId != 0, "You cannot burn token id 0");
        require(tokenIds.length == MAX_BURN_PER_TRANSACTION, "You need to burn 3 SSS in order to receive an animated one");
        require(ownerOf(tokenToAnimateId) == msg.sender, "You do not own the requested animated token id");

        for(uint256 i = 0; i < 3; i++) {
            if (ownerOf(tokenIds[i]) != msg.sender)
                revert("You do not own one of the token ids specified");

            if (!_validTokenId(tokenIds[i]))
                revert("Invalid token id specified");

            burn(tokenIds[i]);
            avatarsBurnedCount += 1;
        }

        _mintAnimated(tokenToAnimateId, msg.sender);
    }

    // @dev Mint the token id for animations
    // @param tokenToAnimatedId The id of the SSS token whose animation is to be minted
    function _mintAnimated(uint256 tokenToAnimateId, address receiver) private {
        uint256 animatedTokenId = (tokenToAnimateId + indexAnimationsStart) - 1;
        _safeMint(receiver, animatedTokenId);
        animationsMintedCount += 1;
    }

    // @dev Validates a given token id
    // @param tokenId The token id to be verified
    function _validTokenId(uint256 tokenId) internal view returns (bool) {
        return tokenId >= 0 && tokenId < MAX_SUPPLY;
    }
}
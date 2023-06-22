// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./FineCoreInterface.sol";

/// @custom:security-contact [email protected]
contract Solids is ERC721Enumerable, ERC721Burnable, ERC721Royalty, AccessControl, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    FineCoreInterface coreContract;
    
    bool public paused = false;

    uint public TOKEN_LIMIT = 8888; // not including bonus
    uint256 public remaining;
    mapping(uint256 => uint256) public cache;

    address payable public artistAddress = payable(0x70F2D7fA5fAE142E1AF7A95B4d48A9C8e417813D);
    address payable public additionalPayee = payable(0x0000000000000000000000000000000000000000);
    uint256 public additionalPayeePercentage = 0;
    uint256 public additionalPayeeRoyaltyPercentage = 0;
    uint96 public royaltyPercent = 4500;

    string public _contractURI = "ipfs://QmPmtPqQff6nnyvv8LNEpSnLqeARVus8Q5SbUfWSLAw126";
    string public baseURI = "ipfs://QmSBiKg2u4YvEB8rQrJisAvBxCR4L9QYFvFdibkk1kBDby";
    string public artist = "FAR";
    string public description = "SOLIDS is a generative architecture NFT project created by FAR. There are 8,888 + 512 unique buildings generated algorithmically, enabling utility in the Metaverse.";
    string public website = "https://fine.digital";
    string public license = "MIT";

    event recievedFunds(address _from, uint _amount);
    
    constructor(address coreAddress, address shopAddress) ERC721("SOLIDS", "SOLID") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, shopAddress);
        coreContract = FineCoreInterface(coreAddress);
        // set deafault royalty
        _setDefaultRoyalty(address(this), royaltyPercent);
        remaining = TOKEN_LIMIT; // start with max tokens
    }

    /**
     * @dev receive direct ETH transfers
     * @notice for splitting royalties
     */
    receive() external payable {
        emit recievedFunds(msg.sender, msg.value);
    }

    /**
     * @dev split royalties sent to contract (ONLY ETH!)
     */
    function withdraw() onlyOwner external {
        _splitFunds(address(this).balance);
    }

    /**
     * @dev Split payments
     */
    function _splitFunds(uint256 amount) internal {
        if (amount > 0) {
            uint256 partA = amount * coreContract.platformRoyalty() / 10000;
            coreContract.FINE_TREASURY().transfer(partA);
            uint256 partB = amount * additionalPayeeRoyaltyPercentage / 10000;
            if (partB > 0) additionalPayee.transfer(partB);
            artistAddress.transfer((amount - partA) - partB);
        }
    }

    /**
     * @dev lookup the URI for a token
      * @param tokenId to retieve URI for
     */
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"));
    }

    // On-chain Data

    /**
     * @dev Update the base URI field
     * @param _uri base for all tokens 
     * @dev Only the admin can call this
     */
    function setContractURI(string calldata _uri) onlyOwner external {
        _contractURI = _uri;
    }

    /**
     * @dev Update the base URI field
     * @param _uri base for all tokens 
     * @dev Only the admin can call this
     */
    function setBaseURI(string calldata _uri) onlyOwner external {
        baseURI = _uri;
    }

    /**
     * @dev Update the royalty percentage
     * @param _percentage for royalties
     * @dev Only the admin can call this
     */
    function setRoyaltyPercent(uint96 _percentage) onlyOwner external {
        royaltyPercent = _percentage;
    }

    /**
     * @dev Update the additional payee sales percentage
     * @param _percentage for sales
     * @dev Only the admin can call this
     */
    function additionalPayeePercent(uint96 _percentage) onlyOwner external {
        additionalPayeePercentage = _percentage;
    }

    /**
     * @dev Update the additional payee royalty percentage
     * @param _percentage for royalty
     * @dev Only the admin can call this
     */
    function additionalPayeeRoyaltyPercent(uint96 _percentage) onlyOwner external {
        additionalPayeeRoyaltyPercentage = _percentage;
    }

    /**
     * @dev Update the description field
     * @param _desc description of the project
     * @dev Only the admin can call this
     */
    function setDescription(string calldata _desc) onlyOwner external {
        description = _desc;
    }

    /**
     * @dev Update the website field
     * @param _url base for all tokens 
     * @dev Only the admin can call this
     */
    function setWebsite(string calldata _url) onlyOwner external {
        website = _url;
    }

    /**
     * @dev pause minting
     * @dev Only the admin can call this
     */
    function pause() onlyOwner external {
        paused = true;
    }

    /**
     * @dev unpause minting
     * @dev Only the admin can call this
     */
    function unpause() onlyOwner external {
        paused = false;
    }

    /**
     * @dev checkPool -maintain interface compatibility
     */
    function checkPool() external view returns (uint256) {
        return remaining;
    }

    /**
     * @dev Draw a token from the remaining ids
     */
    function drawIndex() internal returns (uint256 index) {
        //RNG
        uint randomness = coreContract.getRandomness(remaining, block.timestamp);
        uint256 i = randomness % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = cache[i] == 0 ? i : cache[i];

        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;
    }

    /**
     * @dev Mint a token 
     * @param to address to mint the token to
     * @dev Only the minter role can call this
     */
    function mint(address to) external onlyRole(MINTER_ROLE) returns (uint) {
        require(!paused, "minting paused");
        require(remaining > 0, "all tokens minted");
        uint id = drawIndex();
        _safeMint(to, id);
        return id;
    }

    /**
     * @dev Mint a bonus token (for infinites AI holders)
     * @param to address to mint the token to
     * @dev Only the minter role can call this
     */
    function mintBonus(address to, uint infiniteId) external onlyRole(MINTER_ROLE) returns (uint bonusId) {
        require(!paused, "minting paused");
        bonusId = 10000 + infiniteId;
        require(!_exists(bonusId), "Token already minted");
        _safeMint(to, bonusId);
    }

    // getters for interface

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function getArtistAddress() external view returns (address payable) {
        return artistAddress;
    }

    function getAdditionalPayee() external view returns (address payable) {
        return additionalPayee;
    }

    function getAdditionalPayeePercentage() external view returns (uint256) {
        return additionalPayeePercentage;
    }

    function getTokenLimit() external view returns (uint256) {
        return TOKEN_LIMIT;
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev get baseURI for all tokens
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }
}
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Uniwoman is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    // URI
    // ------------------------------------------------------------------------
    string public baseTokenURI;

    // Constants
    // ------------------------------------------------------------------------
    uint256 public constant MAX_UNIWOMAN = 444;
    uint256 private constant PRICE = 0.025 ether;

    // State variables
    // ------------------------------------------------------------------------
    bool public isMetadataLocked = false;

    // Error messages
    // ------------------------------------------------------------------------
    string private constant ALL_TOKENS_MINTED = "All uniwoman minted";
    string private constant TOKEN_LIMIT_EXCEEDED =
        "Not enough uniwoman left to mint";

    string private constant METADATA_LOCKED = "Metadata is locked";
    string private constant INVALID_ETH_AMOUNT =
        "Invalid eth amount. Price is 0.025 per uniwoman.";

    constructor(string memory baseURI) ERC721("uniwoman", "uniwoman") {
        setBaseURI(baseURI);
    }

    // Withdraws eth from the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable to = payable(msg.sender);
        to.transfer(balance);
    }

    function _mintTokensToAddr(uint256 amount, address receiver) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(receiver, newTokenId);
        }
    }

    // Modifiers
    // ------------------------------------------------------------------------

    modifier notLockedMetadata() {
        require(!isMetadataLocked, METADATA_LOCKED);
        _;
    }

    // State toggling
    // ------------------------------------------------------------------------

    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }

    // Minting functions
    // ------------------------------------------------------------------------

    function mint(uint256 numberOfTokens) public payable {
        require(
            totalSupply() + numberOfTokens <= MAX_UNIWOMAN,
            TOKEN_LIMIT_EXCEEDED
        );

        require(numberOfTokens > 0, "Number of tokens must be positive");
        require(msg.value >= PRICE * numberOfTokens, INVALID_ETH_AMOUNT);

        _mintTokensToAddr(numberOfTokens, msg.sender);
    }

    // Mint an amount of tokens for free to an address `to`
    function mintTokensToAddress(uint256 numberOfTokens, address to)
        external
        onlyOwner
    {
        require(
            totalSupply() + numberOfTokens <= MAX_UNIWOMAN,
            TOKEN_LIMIT_EXCEEDED
        );
        _mintTokensToAddr(numberOfTokens, to);
    }

    // Mint one token for free to multiple addresses
    function mintTokenToAddresses(address[] memory addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + 1 <= MAX_UNIWOMAN, TOKEN_LIMIT_EXCEEDED);
            address to = addresses[i];
            _mintTokensToAddr(1, to);
        }
    }

    // URI functions
    // ------------------------------------------------------------------------
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Only callable when the metadata is still unlocked
    // Will be locked after reveal
    function setBaseURI(string memory baseURI)
        public
        onlyOwner
        notLockedMetadata
    {
        baseTokenURI = baseURI;
    }
}
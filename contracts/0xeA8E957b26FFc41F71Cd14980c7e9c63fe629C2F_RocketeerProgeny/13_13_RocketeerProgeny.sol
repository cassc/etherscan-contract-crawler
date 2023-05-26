// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // import OpenZeppelin ERC721 contract
import "@openzeppelin/contracts/utils/Counters.sol"; // import OpenZeppelin Counters library
import "@openzeppelin/contracts/access/Ownable.sol"; // import OpenZeppelin Ownable contract

contract RocketeerProgeny is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter; // private variable to keep track of token IDs
    string private _baseTokenURI; // private variable to store the base URI for token metadata
    uint256 private _maxSupply; // private variable to store the maximum supply of tokens
    string private _contractURI; // private variable to store the URI for the contract metadata
    bool private _mintingEnabled = false; // private variable to enable or disable minting of tokens

    constructor() ERC721("RocketeerProgeny", "RCTP") {
        // Set up default values
        _baseTokenURI = "https://progeny.rocketeer.fans/progeny/api?id="; // set the default base URI for token metadata
        _maxSupply = 3475; // set the maximum supply of tokens to the mean diameter of the moon in kilometers
        _contractURI = "https://progeny.rocketeer.fans/progeny/metadata/"; // set the URI for the contract metadata

        // On construct, mint the first token to the contract owner
        _tokenIdCounter.increment(); // Start IDs at 1
        _safeMint(msg.sender, _tokenIdCounter.current()); // Unsafe mint to deployer
    }

    /**
     * @dev Set the base URI for token metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Return the base URI for token metadata.
     * @return The current base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set the URI for the contract metadata.
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @dev Return the URI for the contract metadata.
     * @return The current contract URI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Toggle the ability to mint new tokens.
     */
    function toggleMinting() external onlyOwner {
        _mintingEnabled = !_mintingEnabled;
    }

    /**
     * @dev Return the current state of minting.
     * @return A boolean indicating whether minting is currently enabled or disabled.
     */
    function mintingEnabled() public view returns (bool) {
        return _mintingEnabled;
    }

    /**
     * @dev Return the total number of minted tokens.
     * @return The total supply of minted tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Mint a new token to the specified address.
     * @param to The address to receive the new token.
     */
    function mint(address to) external {
        // make sure minting is enabled
        require(_mintingEnabled, "Minting is currently disabled");

        // make sure maximum supply hasn't been reached
        require(_tokenIdCounter.current() <= _maxSupply, "Max supply reached");

        // increment the token ID counter
        _tokenIdCounter.increment();

        // Every 42nd unit becomes a special edition, gas fees paid for but not owned by the minter
        if (_tokenIdCounter.current() % 42 == 0) {
            // Mint special edition to the owner of the contract
            _safeMint(owner(), _tokenIdCounter.current());

            // increment the token ID counter
            _tokenIdCounter.increment();
        }

        // Mint the new token to the specified address and assign it the current token ID
        _safeMint(to, _tokenIdCounter.current());
    }
}
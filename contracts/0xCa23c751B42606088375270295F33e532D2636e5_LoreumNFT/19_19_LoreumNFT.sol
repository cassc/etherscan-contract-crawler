// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "lib/open-zeppelin/contracts/token/common/ERC2981.sol";
import "lib/open-zeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "lib/open-zeppelin/contracts/access/Ownable.sol";
import "lib/open-zeppelin/contracts/security/ReentrancyGuard.sol";
import "lib/open-zeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "lib/open-zeppelin/contracts/utils/Strings.sol";

/// @title The base NFT contract for the Loreum collection.
contract LoreumNFT is ERC165Storage, ERC2981, ERC721Enumerable, Ownable, ReentrancyGuard {

    // ---------------------
    //    State Variables
    // ---------------------   

    uint public mintCost;                       /// @dev The amount required per mint().
    
    uint96 public immutable royaltyFraction;    /// @dev The fee for royalties, in basis points (500 = 5%).
    uint16 public immutable MAX_SUPPLY;         /// @dev The maximum supply of NFTs mintable.
    uint8 public immutable MAX_MINT;            /// @dev The maximum amount mintable by a single address.
    
    string public tokenUri;                     /// @dev Uniform Resource Identifier for the collection.

    mapping(address => uint16) public totalMinted;      /// @dev Tracks number of NFTs minted per address.
    


    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the LoreumNFT.sol contract.
    /// @param  name_ The name of this NFT collection.
    /// @param  symbol_ The symbol of this NFT collection.
    /// @param  tokenUri_ The Uniform Resource Identifier for the collection.
    /// @param  mintCost_ The initial mintCost() value for this NFT collection.
    /// @param  royaltyFraction_ The fee for royalties, in basis points (500 = 5%).
    /// @param  maxSupply_ The maximum totalSupply() for this NFT collection.
    /// @param  maxMint_ The maximum amount a single address can mint.
    /// @param  admin The owner (multi-sig) which receives sales and is responible for managing the mint cost.
    constructor(
        string memory name_,
        string memory symbol_,
        string memory tokenUri_,
        uint mintCost_,
        uint96 royaltyFraction_,
        uint16 maxSupply_,
        uint8 maxMint_,
        address admin
    ) ERC721(name_, symbol_) {
        // Initial assignment of state variables.
        tokenUri = tokenUri_;
        mintCost = mintCost_;
        royaltyFraction = royaltyFraction_;
        MAX_SUPPLY = maxSupply_;
        MAX_MINT = maxMint_;

        // Transfer ownership to specified "admin" address.
        transferOwnership(admin);

        // Update royalty fees, per ERC2981 standard.
        _setDefaultRoyalty(admin, royaltyFraction);

        // Register supported interfaces, per ERC165Storage standard.
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
        _registerInterface(type(IERC2981).interfaceId);
    }


    // ------------
    //    Events
    // ------------

    /// @notice Emitted during publicMint().
    /// @param  mintedBy The address minting the NFT.
    /// @param  tokenId The tokenId of the NFT minted.
    /// @param  cost The cost to mint the NFT.
    event NFTMinted(address indexed mintedBy, uint16 indexed tokenId, uint cost);

    /// @notice Emitted during updateMintCost().
    /// @param  oldMintCost The old value of mintCost.
    /// @param  newMintCost The new value of mintCost.
    event MintCostUpdated(uint oldMintCost, uint newMintCost);

    

    // ---------------
    //    Functions
    // ---------------

    /// @notice Overrides the supportsInterface function in three base contracts.
    /// @dev    Explicitly points to ERC165Storage to reference _supportsInterfaces mapping.
    /// @param  interfaceId The interfaceId to check support for.
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC165Storage, ERC2981, ERC721Enumerable) 
        returns (bool) 
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }


    /// @notice Transfers ownership of the contract to a new account (`newOwner`) and updates defaultyRoyalty info.
    /// @dev    Can only be called by the current owner.
    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {
        require(newOwner != address(0), "LoreumNFT::transferOwnership() newOwner == address(0)");
        _transferOwnership(newOwner);
        _setDefaultRoyalty(newOwner, royaltyFraction);
    }

    /// @notice Implements the metadata standard by constructing a unique URI for each token.
    /// @param  tokenId_ The tokenID to view the URI for.
    function tokenURI(uint256 tokenId_) override view public returns (string memory) {
        return string(abi.encodePacked(tokenUri, Strings.toString(tokenId_)));
    }

    /// @notice Updates the mintCost value, relating to the cost to mint an NFT.
    /// @dev    Only the owner of this contract can access this function.
    /// @param  _mintCost The new mintCost value.
    function updateMintCost(uint _mintCost) onlyOwner external {
        emit MintCostUpdated(mintCost, _mintCost);
        mintCost = _mintCost;
    }

    /// @notice A public endpoint to mint an NFT, allows for batch minting.
    /// @param  amount The amount of NFTs to mint.
    function publicMint(uint8 amount) external payable nonReentrant {
        require(msg.value == amount * mintCost, "LoreumNFT::publicMint() msg.value != amount * mintCost");
        require(
            amount > 0 && amount + totalMinted[_msgSender()] <= MAX_MINT, 
            "LoreumNFT::publicMint() amount == 0 || amount + totalMinted[_msgSender()] > MAX_MINT"
        );
        require(
            totalSupply() < MAX_SUPPLY && totalSupply() + amount <= MAX_SUPPLY, 
            "LoreumNFT::publicMint() minted >= MAX_SUPPLY || minted + amount > MAX_SUPPLY"
        );
        
        // Increment amount of NFTs minted by _msgSender().
        totalMinted[_msgSender()] += amount;

        // Transfer ETH prior to _mint().
        payable(owner()).transfer(msg.value);
        
        // Mint NFT(s) from the contract, tokenId = totalSupply() + 1 due to sequential nature.
        for (uint8 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply() + 1, "");
            emit NFTMinted(_msgSender(), uint16(totalSupply()), mintCost);
        }
    }

    /// @notice Handles arbitrary call() executions to address(this), forwards any msg.value to owner().
    fallback() external payable {
        payable(owner()).transfer(msg.value);
    }

    /// @notice Handles arbitrary direct ETH transfers, forwards the amount to owner().
    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

}
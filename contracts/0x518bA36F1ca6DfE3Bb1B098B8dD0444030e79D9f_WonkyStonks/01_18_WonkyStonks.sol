// Solidity files have to start with this pragma.
// Version
pragma solidity 0.8.3;

// Import relevant libraries
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Main definition of Wonky Stonks (A Ledgart Project Production) smart contract
contract WonkyStonks is ERC721, ERC721Enumerable, ERC721URIStorage, IERC2981, Ownable {

    // Keep track of minted token. Each one corresponds to a randomly generated NFT
    // with characteristics of defined probability
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;

    // The fixed amount of tokens and royalty percent (5%) are stored in an unsigned integer type variables.
    // Royalty covers development fees, hosting fees, and production of future features
    // Reduce the barrier to entry by making the one token free (excluding mint gas fees)
    // Users interested in minting more than one NFT per transaction must pay a fee
    // The purpose is to incentivize widespread fragmentation rather than consolidation
    uint64 public maxSupply = 8736;
    uint64 public royalty = 500;
    uint64 public maxPerWallet = 12;
    uint64 public freeQuantity = 1;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() ERC721("Wonky Stonks", "WSTK") {}

    /**
    * Override for IERC2981 for optional royalty payment
    * @notice Called with the sale price to determine how much royalty
    *         is owed and to whom.
    * @param _tokenId - the NFT asset queried for royalty information
    * @param _salePrice - the sale price of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */
    function royaltyInfo (
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        // Royalty payment is 5% of the sale price
        uint256 royaltyPmt = _salePrice*royalty/10000;
        require(royaltyPmt > 0, "Royalty must be greater than 0");
        return (address(this), royaltyPmt);
    }
    
    /**
     * Override for ERC721 and ERC721URIStorage
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * Override for ERC721, ERC721Enumerable, and IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override for ERC721 and ERC271Enumerable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Override for ERC721URIStorage
     */
    function setBaseURI(string memory _newbaseTokenURI) public onlyOwner {
        _baseTokenURI = _newbaseTokenURI;
    }

    /**
     * Override for ERC721URIStorage
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Override for ERC721 and ERC721URIStorage
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory _uri = super.tokenURI(tokenId);

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_uri).length > 0) {
            return string(abi.encodePacked(_uri, ".json"));
        }

        return _uri;
    }

    /**
     * Read-only function to retrieve the number of NFTs that can be minted in one txn
     */
    function getCurrentMintLimit() public pure returns (uint64) {
        return 12;
    }

    /**
     * Read-only function to retrieve the current NFT price in eth (flat 0.07 ETH per NFT after the free one).
     * Price does not increase as quantity becomes scarce.
     */
    function getCurrentPrice() public pure returns (uint64) {
        return 70_000_000_000_000_000;
    }

    /**
     * Read-only function to retrieve the current NFT price in eth (flat 0.07 ETH per NFT after the free one).
     * Price does not increase as quantity becomes scarce.
     */
    function getCurrentPriceForQuantity(uint64 _quantityToMint) public view returns (uint64) {
        // The first NFT is free!
        if (balanceOf(msg.sender) > 0) {
            return getCurrentPrice() * _quantityToMint;
        } else {
            return getCurrentPrice() * (_quantityToMint - freeQuantity);
        }
    }
    
    /**
     * Read-only function to retrieve the total number of NFTs that have been minted thus far
     */
    function getTotalMinted() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * Read-only function to retrieve the total number of NFTs that remain to be minted
     */
    function getTotalRemainingCount() external view returns (uint256) {
        return (maxSupply - totalSupply());
    }
    
    /**
     * Mint quantity of NFTs for address initiating minting
     * The first mint per transaction is free to mint, however, others are 0.07 ETH per
     */
    function mintQuantity(uint64 _quantityToMint) public payable {
        require(_quantityToMint >= 1, "Minimum number to mint is 1");
        require(
            _quantityToMint <= getCurrentMintLimit(),
            "Exceeded the max number to mint of 12."
        );
        require(
            (_quantityToMint + totalSupply()) <= maxSupply,
            "Exceeds maximum supply"
        );
        require((_quantityToMint + balanceOf(msg.sender)) <= maxPerWallet, "One wallet can only mint 12 NFTs");
        require(
            (_quantityToMint + totalSupply()) <= maxSupply,
            "We've exceeded the total supply of NFTs"
        );
        require(
            msg.value == getCurrentPriceForQuantity(_quantityToMint),
            "Ether submitted does not match current price"
        );

        // Iterate through quantity to mint and mint each NFT
        for (uint64 i = 0; i < _quantityToMint; i++) {
            _tokenIds.increment();
            
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    /**
     * Mint quantity of NFTs for address initiating minting
     * These 50 promotional mints are used by the contract owner for promotions, contests, rewards, etc.
     */
    function mintPromotionalQuantity(uint64 _quantityToMint) public onlyOwner {
        require(_quantityToMint >= 1, "Minimum number to mint is 1");
        require(
            (_quantityToMint + totalSupply()) <= maxSupply,
            "Exceeds maximum supply"
        );

        // Iterate through quantity to mint and mint each NFT
        for (uint64 i = 0; i < _quantityToMint; i++) {
            _tokenIds.increment();
            
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    /**
     * Allow the owner of the smart contract to withdraw the ether
     * Fees are creator and development costs, hosting expenses, and production of future features
     */
    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "Balance must be >0");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "We failed to withdraw your ether");
    }
    
}
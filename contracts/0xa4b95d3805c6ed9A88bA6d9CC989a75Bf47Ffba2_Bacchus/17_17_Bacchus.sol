// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Bacchus is ERC721, ERC721Pausable, Ownable {
    using Strings for uint256;
    using Strings for address;

    //SUPPLY
    uint256 public constant MAX_SUPPLY = 1855;
    uint256 public currentSupply;

    //METADATA
    string public baseURI;
    string private collectionURI;

    //GENESIS COLLECTION
    address public genesisCollection;

    //PRICE
    uint256 public priceInDollar = 50;

    //PRICE ORACLE
    AggregatorV3Interface private usdByEthFeed;

    //SIGNER WALLET
    address public signer;

    //PAUSE/RESUME PUBLIC MINT
    bool public isPublicMint;

    /**
     * @dev Constructor function
     * @param _usdByEthFeedAddress USD By Dollar price oracle address
     * @param _signer Wallet address for signing the message that allows the free mint of unrevealed tokens
     * @param _genesisCollection Address of the Genesis NFT Collection
     */
    constructor(
        address _usdByEthFeedAddress,
        address _signer,
        address _genesisCollection
    ) ERC721("Bacchus", "BAC") {
        usdByEthFeed = AggregatorV3Interface(_usdByEthFeedAddress);
        signer = _signer;
        genesisCollection = _genesisCollection;
        isPublicMint = true;
    }

    /**
     * @dev Function to be called on public mint
     * @param to Address that will receive the NFTs
     * @param tokenIds List of token IDs to be minted
     */
    function safeMint(address to, uint256[] memory tokenIds) public payable {
        require(isPublicMint == true, "Public mint not enabled");
        require(
            currentSupply + tokenIds.length <= MAX_SUPPLY,
            "Max supply has been reached"
        );
        _checkPayment(tokenIds.length);
        for (uint256 index = 0; index < tokenIds.length; index++) {
            // It is mandatory that the wallet which is receiving the Bacchus NFTs is a holder
            // of the same IDs of the Genesis NFT Collection
            require(
                ERC721(genesisCollection).ownerOf(tokenIds[index]) == to,
                "Minter address is not the holder of the corresponding token id of Genesis collection"
            );
            _safeMint(to, tokenIds[index]);
        }
        currentSupply += tokenIds.length;
    }

    /**
     * @dev Function to be called from the WBC's Bacchus Mint page when a user wants to mint unrevealed NFTs
     * If every ID to be minted corresponds to a Genesis unrevealed NFT, the signer wallet will sign a message and 
       any user can call this function (passing the signature hash) to only pay the gas fees and receive 
       the corresponding unrevealed Bacchus NFTs without paying the pre-defined price per NFT.
     * @param to Address that will receive the NFTs
     * @param tokenIds List of token IDs to be minted
     * @param signature Signer's wallet signature hash of a specific message that allows Bacchus NFT minting without paying
     */
    function unrevealedMint(
        address to,
        uint256[] memory tokenIds,
        bytes calldata signature
    ) public {
        require(isPublicMint == true, "Public mint not enabled");
          require(
            currentSupply + tokenIds.length <= MAX_SUPPLY,
            "Max supply has been reached"
        );
        bytes32 hashMessageVar = hashMessage(to, tokenIds);
        // It is mandatory the pre-defined signer wallet has signed the same message hash of the
        // return of hashMessage() function
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(hashMessageVar),
                signature
            ) == signer,
            "Invalid signature"
        );
        for (uint256 index = 0; index < tokenIds.length; index++) {
            // It is mandatory that the wallet which is receiving the Bacchus NFTs is a holder
            // of the same IDs of the Genesis NFT Collection
            require(
                ERC721(genesisCollection).ownerOf(tokenIds[index]) == to,
                "Minter address is not the holder of the corresponding token id of Genesis collection"
            );
            _safeMint(to, tokenIds[index]);
        }
        currentSupply += tokenIds.length;
    }

    /**
     * @dev Function to that returns the hash of the message to be compared with the Signer's signature
     * in order to check signature validity and let wallets mint their unrevealed NFTs without paying
     * @param to Address that will receive the NFTs
     * @param tokenIds List of token IDs to be minted
     * @return hash The hash of the combination of the "to" address and the string concatenation of the "tokenIds" list elements
     */
    function hashMessage(address to, uint256[] memory tokenIds)
        internal
        pure
        returns (bytes32)
    {
        string memory stringTokenIds = "";
        for (uint256 index = 0; index < tokenIds.length; index++) {
            stringTokenIds = string(
                abi.encodePacked(stringTokenIds, tokenIds[index].toString())
            );
        }
        bytes memory message = (abi.encodePacked(to, stringTokenIds));
        return keccak256(message);
    }

    //PRICE CALCULATION FUNCTIONS
    function getUsdByEth() private view returns (uint256) {
        // Fetches the latest Usd/Eth price
        (, int256 price, , , ) = usdByEthFeed.latestRoundData();
        return uint256(price);
    }

    function getWeiPrice() public view returns (uint256) {
        // Calculates the amount of wei based on the price of each NFT (price in dollars)
        uint256 weiPrice = (priceInDollar *
            10**18 *
            10**usdByEthFeed.decimals()) / getUsdByEth();
        return weiPrice;
    }

    /**
     * @dev Internal function that allows a margin of 0.05% on minting payment
     */
    function _checkPayment(uint256 tokensNumber) private view {
        //Checks for the difference between the price to be paid for all the NFTs being minted and the amount of ether sent in the transaction
        uint256 priceInWei = getWeiPrice();
        uint256 minPrice = ((priceInWei * 995) / 1000) * tokensNumber;
        uint256 maxPrice = ((priceInWei * 1005) / 1000) * tokensNumber;
        require(msg.value >= minPrice, "Not enough ETH");
        require(msg.value <= maxPrice, "Too much ETH");
    }

    /**
     * @dev Function to be called by Paper XYZ Checkout to check minter eligibility for revealed items
     */
    function checkRevealedClaimEligibility(address to, uint256[] memory tokenIds)
        external
        view
        returns (string memory)
    {   
         bool isGenesisHolder = true;
         for (uint256 index = 0; index < tokenIds.length; index++) {
            // It is mandatory that the wallet which is receiving the Bacchus NFTs is a holder
            // of the same IDs of the Genesis NFT Collection
            if(!(ERC721(genesisCollection).ownerOf(tokenIds[index]) == to)){
                isGenesisHolder = false;
            }
        }
        if(!isGenesisHolder){
            return "Minter does not hold the corresponding NFTs of the Genesis Collection";
        } else if(currentSupply + tokenIds.length > MAX_SUPPLY){
            return "Max supply has been reached";
        } else if(!isPublicMint){
            return "Public mint not enabled";
        } 
        return "";
    }

    
    /**
     * @dev Function to be called by Paper XYZ Checkout to check minter eligibility for unrevealed items
     */
    function checkUnrevealedClaimEligibility(address to, uint256[] memory tokenIds, bytes calldata signature)
        external
        view
        returns (string memory)
    {   
         bool isGenesisHolder = true;
         for (uint256 index = 0; index < tokenIds.length; index++) {
            // It is mandatory that the wallet which is receiving the Bacchus NFTs is a holder
            // of the same IDs of the Genesis NFT Collection
            if(!(ERC721(genesisCollection).ownerOf(tokenIds[index]) == to)){
                isGenesisHolder = false;
            }
        }
        bytes32 hashMessageVar = hashMessage(to, tokenIds);

        if(!isGenesisHolder){
            return "Minter does not hold the corresponding NFTs of the Genesis Collection";
        } else if(currentSupply + tokenIds.length > MAX_SUPPLY){
            return "Max supply has been reached";
        } else if(ECDSA.recover(ECDSA.toEthSignedMessageHash(hashMessageVar),signature) != signer){
            return "Invalid signature";
        }else if(!isPublicMint){
            return "Public mint not enabled";
        } 
        return "";
    }

    //SETTERS

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        priceInDollar = _price;
    }

    function setGenesisCollection(address _genesisCollectionAddress)
        external
        onlyOwner
    {
        genesisCollection = _genesisCollectionAddress;
    }

    function setUsdByEthFeed(address usdByEthFeedAddress) external onlyOwner {
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }

    function setSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function resumePublicMint() external onlyOwner {
        isPublicMint = true;
    }

    function pausePublicMint() external onlyOwner {
        isPublicMint = false;
    }

    //GETTERS
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    /**
     * @dev Retrieve the funds of the sales to the contract owner
     */
    function retrieveFunds() external onlyOwner {
        // Only the owner can withraw the funds
        bool sent = payable(owner()).send(address(this).balance);
        require(sent, "Funds withdrawal not executed");
    }

    //OVERRIDES

    /**
     * @dev Funtion that is called every time before a token transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
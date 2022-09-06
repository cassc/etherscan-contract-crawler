// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/erc721a/contracts/ERC721A.sol";
import "../node_modules/@openzeppelin/contracts/token/common/ERC2981.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Sheepverse is ERC721A, ERC2981, Ownable, ReentrancyGuard {

    /**
     * @dev MintPhaseConfig is used to divide all tokens into multiple groups that can
     * have different prices and be revealed independently of one another
     */
    struct MintPhaseConfig {
        uint256 amount;
        uint256 tokenPrice;
        bool revealed;
        string baseTokenURI;
        bool locked;
    }

    /**
     * @dev The array of mint phases, a new mint phase will be added to this array and
     * build upon the previous mint phase (if any, see addMintPhase)
     */
    MintPhaseConfig[] public mintPhases;

    /**
     * @dev Lock the mint phases so none can be added anymore
     */
    bool private mintPhasesLocked = false;

    /**
     * @dev Reserved tokens, will be minted on contract creation
     */
    uint256 constant public RESERVED = 145;

    /**
     * @dev Fixed max per wallet
     */
    uint256 constant public MAX_PER_WALLET = 10;

    /**
     * @dev Fixed whitelist price
     */
    uint256 constant public WHITELIST_PRICE = 0.05 ether;

    /**
     * @dev Sale start, one can't mint before this date
     */
    uint256 immutable public SALE_START;

    /**
     * @dev Whitelist Sale start, whitelist addresses can't mint before this date
     */
    uint256 immutable public WHITELIST_SALE_START;

    /**
     * @dev The root hash of the whitelist merkle tree
     * Make sure to prepend 0x
     */
    bytes32 private whitelistMerkleRoot = 0x9d97282d96ff0057fec2757f09642f3c50d88b5572042d6f0843bd142029c4de;

    /**
     * @dev Free mint mapping for a simple free mint functionality
     */
    mapping(address => bool) freeMint;

    /**
     * @dev Points to the unreveal json file
     */
    string private unrevealedUri = 'ipfs://QmfJaSShLiFVRyQNUVawTwW5ZdcsBpfJ4ecUJrJWc5NfQe/reveal.json';

    // ================================================== //
    // Modifiers                                          //
    // ================================================== //

    /**
     * @dev Only resolves if the sale has started
     */
    modifier onlyIfSale() {
        require(block.timestamp > SALE_START, 'Sale has not started yet');
        _;
    }

    /**
     * @dev Only resolves if the whitelist sale has started
     */
    modifier onlyIfWhitelistSale() {
        require(block.timestamp > WHITELIST_SALE_START, 'Whitelist Sale has not started yet');
        require(block.timestamp < SALE_START, 'Public Sale has started');
        _;
    }

    // ================================================== //
    // Constructor                                        //
    // ================================================== //
    
    /**
     * @param name Contract name
     * @param symbol Contract symbol
     * @param saleStart Timestamp, sale start
     * @param whitelistSaleStart Timestamp, whitelist sale start
     * @param recipient The treasury, will receive the pre-mint NFTs and royalities
     */
    constructor(string memory name, string memory symbol, uint256 saleStart, uint256 whitelistSaleStart, address recipient) ERC721A(name, symbol) {
        SALE_START = saleStart;
        WHITELIST_SALE_START = whitelistSaleStart;

        // Mint reserved amount to treasury
        _safeMint(recipient, RESERVED);

        // Set the default royality fee to 2%
        _setDefaultRoyalty(recipient, 200);
    }

    // ================================================== //
    // External                                           //
    // ================================================== //

    /**
     * @param quantity The amount of tokens to be minted
     */
    function mint(uint256 quantity) external payable onlyIfSale {
        checkMintRequirements(0, quantity);
        _mint(msg.sender, quantity);
    }

    /**
     * @param quantity The amount of tokens to be minted
     * @param merkleProof The Merkle proof to be checked
     */
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable onlyIfWhitelistSale {
        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf),
            'Invalid proof!'
        );

        checkMintRequirements(WHITELIST_PRICE, quantity);
        _mint(msg.sender, quantity);
    }

    /**
     * @param merkleRoot The Merkle Root to be used for whitelist verification
     */
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /**
     * @dev Add wallet addresses to the free mint mapping
     * @param addresses Array of addresses to be added
     */
    function addFreeMintAddress(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            freeMint[addresses[i]] = true;
        }
    }

    /**
     * @dev Add a new mint phase, each mint phase will build upon the previous one, so no
     * need to add the token amounts together manually
     * @param amount Amount of tokens in this mint phase
     * @param tokenPrice Token price for the mint phase
     */
    function addMintPhase(uint256 amount, uint256 tokenPrice) external onlyOwner {
        require(!mintPhasesLocked, "Mint phases are locked");

        // If there is already a mint phase, get the amount and add it to the new one
        if (mintPhases.length != 0) {
            MintPhaseConfig memory lastEl = mintPhases[mintPhases.length - 1];
            amount = lastEl.amount + amount;
        }
        mintPhases.push(MintPhaseConfig(amount, tokenPrice, false, '', false));
    }

    /**
     * @dev Reveal a mint phase, can be used to show only part of the collection
     * @param mintPhaseIndex The index of the mintPhase in the mintPhases array
     * @param baseTokenURI Base URI to the folder of the mint phase token metadata
     */
    function revealMintPhase(uint256 mintPhaseIndex, string calldata baseTokenURI) external onlyOwner {
        require(mintPhases[mintPhaseIndex].amount > 0, 'No mint phases found');
        require(!mintPhases[mintPhaseIndex].locked, 'Mint phase is locked');
        mintPhases[mintPhaseIndex].baseTokenURI = baseTokenURI;
        mintPhases[mintPhaseIndex].revealed = true;
    }

    /**
     * @dev Lock the mint phases
     */
    function lockMintPhases() external onlyOwner {
        mintPhasesLocked = true;
    }

    /**
     * @dev Lock a mint phase so it can't be changed anymore
     * @param mintPhaseIndex The index of the mintPhase in the mintPhases array
     */
    function lockMintPhase(uint256 mintPhaseIndex) external onlyOwner {
        require(mintPhases[mintPhaseIndex].revealed, 'MintPhase is not revealed yet');
        mintPhases[mintPhaseIndex].locked = true;
    }

    /**
     * @dev Set the royalities, can't be set higher than 5%
     * @param recipient The royalities recipient
     * @param feeNumerator The feeNumerator ((_salePrice * feeNumerator / _feeDenominator())
     */
    function setRoyalities(address recipient, uint96 feeNumerator) external onlyOwner {
        require(feeNumerator < 501, 'Royalties too high');
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    /**
     * @dev Set the unrevealedUri in case it changes
     * @param _unrevealedUri The new unrevealdUri (full ipfs path to .json)
     */
    function setUnrevealedUri(string calldata _unrevealedUri) external onlyOwner {
        unrevealedUri = _unrevealedUri;
    }

    /**
     * @dev Withdraw the good stuff
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }('');
        require(success, 'Transfer failed.');
    }

    // ================================================== //
    // Public                                             //
    // ================================================== //

    /**
     * @param tokenId Token ID to get the URI for
     * @return tokenURI The Token URI (IPFS, json)
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // Get the mint phase for token ID
        MintPhaseConfig memory mintPhase = getMintPhase(tokenId);

        // If mint phase is revealed, use the mint phase base URI
        if (mintPhase.revealed) {
            return string(abi.encodePacked(mintPhase.baseTokenURI, _toString(tokenId), '.json'));
        }

        return unrevealedUri;
    }

    /**
     * @dev Return the mint phase for token ID, if the there is no mint phase for token ID
     * return the last one in the mintPhases array
     * @param tokenId Token ID
     * @return MintPhaseConfig MintPhaseConfig for tokenId
     */
    function getMintPhase(uint256 tokenId) public view returns(MintPhaseConfig memory) {
        // Fail if no mint phases where configured yet
        require(mintPhases.length > 0, 'No MintPhases defined');

        for (uint256 i = 0; i < mintPhases.length; i++) {
            // Add 1 to amount of mintPhase to prevent usage of <=
            if (tokenId < mintPhases[i].amount + 1) {
                return mintPhases[i];
            }
        }

        return mintPhases[mintPhases.length - 1];
    }

    /**
     * @dev Returns the remaining tokens of the current mint phase
     * @return amount Amount of tokens in current mintPhase
     */
    function getRemainingMintPhaseTokens() public view returns(uint256 amount) {
        // We need to add +1 to totalSuppy to get the next token Id
        MintPhaseConfig memory mintPhase = getMintPhase(totalSupply() + 1);
        return mintPhase.amount - totalSupply();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    // ================================================== //
    // Internal                                           //
    // ================================================== //

    /**
     * @dev Returns the starting token ID.
     * @return uint256 Start Token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ================================================== //
    // Private                                            //
    // ================================================== //

    /**
     * @dev Custom function to check mint requirements for mint, we use a custom
     * function to prevent code duplication.
     * @param tokenPrice The price for the requested tokens
     * @param quantity The requested quantity
     */
    function checkMintRequirements(uint256 tokenPrice, uint256 quantity) private {
        //Add 1 to totalSuppy to get the next token Id
        MintPhaseConfig memory mintPhase = getMintPhase(totalSupply() + 1);

        // If tokenPrice is 0, fallback to mintPhase tokenPrice
        if (tokenPrice == 0) {
            tokenPrice = mintPhase.tokenPrice;
        }

        // Check if sender has a free mint available
        if (freeMint[msg.sender]) {
            // deduct 1 from free mint
            require(msg.value >= tokenPrice * (quantity - 1), 'Not enough ether provided');
            freeMint[msg.sender] = false;
        } else {
            // To prevent use of >= (`msg.value >= (TOKEN_PRICE * quantity>`), subtract the smallest
            // possible value (1 wei) from the total price
            require(msg.value > ((tokenPrice * quantity) - 1 wei), 'Not enough ether provided');
        }

        // Add 1 to remaining token amount to use `<` istead of `<=`
        require(totalSupply() + quantity < mintPhase.amount + 1, 'Amount of tokens requested exceeds max supply of this phase');

        // Add 1 to MAX_PER_WALLET to use `<` instead of `<=`
        require(_numberMinted(msg.sender) + quantity < MAX_PER_WALLET + 1, "Amount of tokens exceeds allowed mints per wallet");
    }

}
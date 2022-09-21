// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/*
    ██▜█▟███████████████▜▛▙▛▛▛▟▜▟▞▛▛▛▛█▞▙▙█▜▜▜▙███████
    ████████▜█▛█▙██▟█▟█▟▜▝▖▞▖▌▞▄▗▐▗▚▐▗▖▞▖▖▖▘▚▜▛██▜█▛██
    █▛████▜▟████████▛█▟▜▗▚▛▙▛▛▙▜▜▚▛▙▛▙▜▜▟▜▚▚▜▜████████
    ████▙████████▛▙██▜▞▚▐▚▛▟▝▀▞▀▞▀▞▚▀▞▜▚▙▀▖▟▜█▙███████
    ███████████▜▟███▟▜▝▞▟▜▞▖▌▙▐▐▗▚▞▄▝▗▛▙▀▞▟▜█▙██▙█▙███
    ██▟█▜█████▜████▟▜▘▚▛▙▛▖▄▝▖▞▖▚▖▄▗▚▛▟▚▚▟▟▛▙█████████
    ██████▛██▟███▙█▞▚▐▜▟▙▜▜▟▛█▟▜▙▜▟▚▛▟▚▘▟▟▙████▛███▜▙█
    █▙██████████▙█▟▝▄▜▙▙▜▜▛▙█▙▛▙▜▙▜▜▜▚▚▟▙█▟███████▟███
    ████▜███▜█▜▟▙▙▘▞▟▙▚▌▚▘▜▜▟▙█▜▚▝▝▝▝▖▟▟▟▛███▜▟███████
    ██▜███▟█████▟▝▐▟▚▙▀▖▙▜▗▜▟▟▙▛▙▝▜▜▛▛▙█▜███▟████▟████
    ████████▛▙█▟▝▐▚▛▙▌▚▟▟▜▖▚▙▙▙█▟▐▐▜▟█████████████████
    █▛██▛█▛▙██▙▘▞▙▜▞▌▞▟▟▟▜▟▗▚▙▚▙▚▙▗▜▙█▙██▛▙█████▜█▛▙██
    █████████▙▚▘▞▗▘▚▘▟▟▟▙█▙▌▖▞▝▖▚▗▘▟▟▙██▙█████▜███████
    ███▛█████▟█▜▟▛█▙█▛█▙█▙▛█▜▟▛█▜▙█▙██████████████████

*/
contract OmegaComic is Ownable, ERC721, IERC2981 {
    /* -------------------------------------------------------------------------- */
    /*                                   Config                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string public baseTokenURI;

    /**
     * @notice Max supply of tokens
     */
    uint256 public immutable maxSupply;

    /**
     * @notice NFT royalties (ERC2981)
     * 10% = 1000 bps
     * (royaltyBps * _salePrice) / 10000
     */
    uint256 public royaltyBps;

    /**
     * @notice Royalty fee receiver address
     * this address will received royalty fee from second market sales
     */
    address public royaltyReceiver;

    /**
     * @notice Merkle root hash used for whitelist mint
     */
    bytes32 public merkleRoot;

    /**
     * @notice mapping between owner address -> flag if token is already claimed
     */
    mapping(address => uint256) public tokensClaimedPerUser;

    /**
     * @notice current token id - this ID will be used for next minted token
     */
    uint256 public currentTokenId = 1;

    /**
     * @notice Max tokens per user
     */
    uint256 public constant MAX_TOKENS_PER_USER = 4;

    /**
     * @notice Max royalty(bps) allowed = 10%
     */
    uint16 public constant MAX_ROYALTY_BPS_ALLOWED = 1000;

    /**
     * @notice Address that can execute claims up to the limit of the total supply
     */
    address public whitelistedClaimer;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when royalty BPS is updated
     */
    event RoyaltyBpsUpdated(uint256 royaltyBps);

    /**
     * @notice Emitted when new merkle root is set
     */
    event MerkleRootUpdated(bytes32 newMerkleRoot);

    /**
     * @notice Emitted when new base url is set
     */
    event BaseURIUpdated(string newBaseURI);

    /**
     * @notice Emitted royalty receiver is updated
     */
    event RoyaltyReceiverUpdated(address newRoyaltyReceiver);

    /**
     * @notice Emitted when whitelisted claimer is updated
     */
    event WhitelistedClaimerUpdated(address newWhitelistedClaimer);

    /* ---------------------------------------------------------------------------- */
    /*                                   ERRORS                                     */
    /* ---------------------------------------------------------------------------- */

    /**
     * @notice thrown if tokens claimed + tokens to claim exceeds quantity user is allowed to claim
     */
    error AlreadyClaimed();

    /**
     * @notice thrown if combination of user address / number of tokens is not in merkle tree root
     */
    error NotInWhitelist();

    /**
     * @notice caller of contract is another contract
     */
    error CallerIsContract();

    /**
     * @notice thrown if address is 0x
     */
    error AddressCannotBe0();

    /**
     * @notice Max supply of tokens reached
     */
    error MaxSupplyReached();

    /**
     * @notice Invalid number of tokens to claim
     */
    error InvalidNumberOfTokensToClaim();

    /**
     * @notice Invalid number of claimed tokens
     */
    error InvalidNumberOfClaimedTokens();

    /**
     * @notice Royalty exceeds limit allowed
     */
    error RoyaltyExceedsLimitAllowed();

    /**
     * @notice User is not a whitelisted account
     */
    error UserIsNotAWhitelistedAccount();

    /* -------------------------------------------------------------------------- */
    /*                                   CONSTRUCTOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Initializes the Omega contract by
     * @param setMaxSupply - Max supply of tokens
     * @param initialName - Initial name of the token
     * @param initialSymbol - Initial symbol of the token
     * @param initialBaseTokenURI - Initial base URI of the token
     * @param initialRoyaltyBps - Initial royalty BPS of the token
     * @param initialRoyaltyReceiverAddress - Initial royalty receiver address of the token
     * @param initialMerkleRoot - Initial merkle root of the token
     * @param initialWhitelistedClaimer - Initial whitelisted claimer address
     */
    constructor(
        uint256 setMaxSupply,
        string memory initialName,
        string memory initialSymbol,
        string memory initialBaseTokenURI,
        uint256 initialRoyaltyBps,
        address initialRoyaltyReceiverAddress,
        bytes32 initialMerkleRoot,
        address initialWhitelistedClaimer
    ) ERC721(initialName, initialSymbol) {
        if (
            initialRoyaltyReceiverAddress == address(0) ||
            initialWhitelistedClaimer == address(0)
        )
            revert AddressCannotBe0();
        if (initialRoyaltyBps > MAX_ROYALTY_BPS_ALLOWED)
            revert RoyaltyExceedsLimitAllowed();
        maxSupply = setMaxSupply;
        baseTokenURI = initialBaseTokenURI;
        royaltyBps = initialRoyaltyBps;
        royaltyReceiver = initialRoyaltyReceiverAddress;
        merkleRoot = initialMerkleRoot;
        whitelistedClaimer = initialWhitelistedClaimer;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   External functions                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Interface for the NFT Royalty Standard.
     *
     * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
     * support for royalty payments across all NFT marketplaces and ecosystem participants.
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     *
     * @param salePrice Sale price of the token
     * @return receiver receiver address for royalty fee
     * @return royaltyAmount Royalty amount
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    /**
     * @notice Set new royalty bps settings
     * @param newRoyaltyBps New BPS settings (10% = 1000 bps)
     */
    function setRoyaltyBps(uint256 newRoyaltyBps) external onlyOwner {
        if (newRoyaltyBps > MAX_ROYALTY_BPS_ALLOWED)
            revert RoyaltyExceedsLimitAllowed();
        royaltyBps = newRoyaltyBps;
        emit RoyaltyBpsUpdated(newRoyaltyBps);
    }

    /**
     * @notice Set new merkle tree root for whitelist mint
     * @param newMerkleRoot new merkle root tree
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
        emit MerkleRootUpdated(newMerkleRoot);
    }

    /**
     * @notice helper function for exposing _baseURI()
     * @return base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Set new bse URI
     * @param newBaseURI New base URI
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Set new royalty receiver address
     * @param newRoyaltyReceiver New royalty receiver address
     */
    function setRoyaltyReceiver(address newRoyaltyReceiver) external onlyOwner {
        if (newRoyaltyReceiver == address(0)) revert AddressCannotBe0();

        royaltyReceiver = newRoyaltyReceiver;

        emit RoyaltyReceiverUpdated(newRoyaltyReceiver);
    }

    /**
     * @notice Set new whitelisted claimer address
     * @param newWhitelistedClaimer New whitelisted claimer address
     */
    function setWhitelistedClaimer(address newWhitelistedClaimer) external onlyOwner {
        if (newWhitelistedClaimer == address(0)) revert AddressCannotBe0();

        whitelistedClaimer = newWhitelistedClaimer;

        emit WhitelistedClaimerUpdated(newWhitelistedClaimer);
    }

    /**
     * @notice Claim function
     * @param merkleProof - merkle proof
     * @param numberOfTokensAllowedToClaim - the total number of tokens a user is allowed to claim
     * @param numberOfTokensToClaim - number of tokens to be redeemed
     */
    function claim(
        bytes32[] calldata merkleProof,
        uint256 numberOfTokensAllowedToClaim,
        uint256 numberOfTokensToClaim
    ) external {
        if (
            numberOfTokensAllowedToClaim < 1 ||
            numberOfTokensAllowedToClaim > MAX_TOKENS_PER_USER
        ) revert InvalidNumberOfTokensToClaim();
        if (
            numberOfTokensToClaim < 1 ||
            numberOfTokensToClaim > MAX_TOKENS_PER_USER
        ) revert InvalidNumberOfClaimedTokens();
        if (currentTokenId + (numberOfTokensToClaim - 1) > maxSupply)
            revert MaxSupplyReached();

        _checkWhitelistRequirements(
            merkleProof,
            numberOfTokensAllowedToClaim,
            numberOfTokensToClaim
        );

        uint256 tokenId = currentTokenId;
        for (uint256 i = 0; i < numberOfTokensToClaim; i++) {
            _safeMint(msg.sender, tokenId);
            unchecked {
                tokenId += 1;
            }
        }

        currentTokenId = tokenId;
        tokensClaimedPerUser[msg.sender] += numberOfTokensToClaim;
    }

    /**
     * @notice Whitelisted claim function
     * @param quantity - number of tokens to be redeemed
     */
    function claimWithWhitelistedAddress(
        uint256 quantity
    ) external {
        if (msg.sender != whitelistedClaimer)
            revert UserIsNotAWhitelistedAccount();

        if (quantity < 1) revert InvalidNumberOfTokensToClaim();

        uint256 tokenId = currentTokenId;

        if (tokenId + (quantity - 1) > maxSupply) revert MaxSupplyReached();

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId);
            unchecked {
                tokenId += 1;
            }
        }

        currentTokenId = tokenId;
        tokensClaimedPerUser[msg.sender] += quantity;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId ID of token
     * @return uri for token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Public functions                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Internal functions                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Private functions                        */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check whitelist requirements
     * @param merkleProof - merkle proof
     * @param numberOfTokensAllowedToClaim - number of tokens a user is allowed to claim
     * @param numberOfTokensToClaim - number of tokens to redeem
     */
    function _checkWhitelistRequirements(
        bytes32[] calldata merkleProof,
        uint256 numberOfTokensAllowedToClaim,
        uint256 numberOfTokensToClaim
    ) private view {
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, numberOfTokensAllowedToClaim)
        );

        bool isValidLeaf = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!isValidLeaf) revert NotInWhitelist();

        if (
            tokensClaimedPerUser[msg.sender] + numberOfTokensToClaim >
            numberOfTokensAllowedToClaim
        ) revert AlreadyClaimed();
    }
}
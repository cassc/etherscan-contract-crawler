// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <[email protected]>
// Date: September 16th, 2022
// Purpose: ERC-721 contract for The Row

pragma solidity ^0.8.0;
pragma abicoder v2; // NOTE: Default as of 0.8.0 but explicitly typed to UniSwap (solc v:0.7.0) does so. LINK: https://docs.uniswap.org/protocol/guides/swaps/single-swaps#set-up-the-contract

// NFT Functionality Imports
import {ERC721Upgradeable as ERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable as ERC721Enumerable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC2981Upgradeable as IERC2981} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IERC165Upgradeable as IERC165} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
// Access Control Imports
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// Sale Imports
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {OracleLibrary} from "./libraries/OracleLibrary.sol";
// Utility Imports
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MerkleProofUpgradeable as MerkleProof} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/**
 * @title Architectural Design Token
 *
 * @author Kai Aldag <[email protected]>
 *
 * @notice The Row is a members-only, master-planned metaverse real estate development 
 * created by Everyrealm and the Alexander Team.
 *
 * @dev The Row Architectural Design Token is an upgradeable ERC-721 contract supporting
 * the metadata and enumerable extensions. It additionally implements ownable and access
 * control for adminitrative functionality.
 *
 * @custom:security-contact [email protected]
 */
contract RowArchitectureDesignToken is
    ERC721,
    ERC721Enumerable,
    IERC2981,
    Ownable,
    AccessControl,
    ReentrancyGuard
{
    // ────────────────────────────────────────────────────────────────────────────────
    // Events
    // ────────────────────────────────────────────────────────────────────────────────

    event NewMetaverseAdded(string indexed metaverseName, uint256 metaverseId);

    event SaleStateChanged(SaleState indexed saleState);


    // ────────────────────────────────────────────────────────────────────────────────
    // Fields
    // ────────────────────────────────────────────────────────────────────────────────

    enum SaleState {
        closed,
        whitelist,
        open
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // Fields
    // ────────────────────────────────────────────────────────────────────────────────


    //  ──────────────────────────────  Token Fields  ─────────────────────────────  \\

    /// @dev the limit the number of tokens
    uint8 public constant maxSupply = 30;

    /// @dev the number of artists involved
    uint8 public constant artistCount = 6;

    /// @dev corresponds token ID to metaverse IDs where a token's been built
    mapping(uint256 => uint8[]) private _builds;

    /// @dev list of metaverse build locations
    string[] private _metaverses;

    /// @dev baseURI for all tokens
    string private baseURI;

    /// @dev set of token URIs
    string[maxSupply] private tokenURIs;


    //  ─────────────────────────────  Payment Fields  ────────────────────────────  \\

    /// @dev merkle root for whitelist addresses
    bytes32 private whitelistMerkleRoot;

    /// @dev used to set public prices for initial mint
    uint256[maxSupply] private publicPrices;

    /// @dev used for royalty payments
    address payable[artistCount] private artistWallets;

    /// @dev royalty rate in basis points (0.01%)
    uint96 royaltyRateBips;

    /// @dev used to freeze public sales if needed
    SaleState private saleState;

    /// @dev used for converting ETH to USDC
    ISwapRouter internal swapRouter;

    /// @dev UniSwap pool for WETH9-USDC at 0.3% fee
    address internal pool; // Mainnet: 0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8 

    IWETH9 private WETH9;
    IERC20 private USDC;

    // Pool fee of 0.3%
    uint24 public constant poolFee = 3000;

    // ────────────────────────────────────────────────────────────────────────────────
    // Setup
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @param name_ the project's full display name. Will appear on Etherscan and other services
     * @param symbol_ the abbreviated symbol for the project. Will appear on Etherscan and other services
     * @param baseURI_ shared prefix of all tokens (ie. "ipfs://"). Note: Cannot be modified once set
     * @param uris_ list of 30 IPFS CIDs storing each token's metadata
     * @param royaltyRate_ initial royalty rate - in basis points (x/10,000). Can be modified by owner
     * @param artistWallets_ list of exactly 5 payable addresses to receive payments for initial and
                             recurring sales
     * @param _swapRouter UniSwap V3 address of the SwapRouter used to convert tokens. 
                          Should be "0xE592427A0AEce92De3Edee1F18E0157C05861564" on all networks.
     * @param _factory UniSwap V3 address of factory used to obtain the WETH-USDC (at 0.3%) pool.
                       Should be "0x1F98431c8aD98523631AE4a59f267346ea31F984" on all networks.
     * @param _wethAddress ERC-20 address of the WETH9 contract
     * @param _usdcAddress ERC-20 address of the USDC contract
     */
    function initialize(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        string[maxSupply] memory uris_,
        uint96 royaltyRate_,
        address payable [artistCount] memory artistWallets_,
        address _swapRouter,
        address _factory,
        address _wethAddress,
        address _usdcAddress
    ) initializer public {
        // 1. Initialize parent contracts
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        
        // 2. Variables setup
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        artistWallets = artistWallets_;
        royaltyRateBips = royaltyRate_;
        saleState = SaleState.closed;

        tokenURIs = uris_;
        baseURI = baseURI_;

        swapRouter = ISwapRouter(_swapRouter);
        WETH9 = IWETH9(payable(_wethAddress));
        USDC = IERC20(_usdcAddress);
        address _pool = IUniswapV3Factory(_factory).getPool(
            _wethAddress,
            _usdcAddress,
            poolFee
        );
        require(_pool != address(0), "RowADT: pool doesn't exist");
        pool = _pool;
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  Admin Functionality                                                           │
    //                                                                                │
    //  ──────────────────────────────────────────────────────────────────────────────┘

    //  ────────────────────────────────  Minting  ────────────────────────────────  \\
    
    /**
     * @dev used by admin privileged accounts to privately mint tokens.
     *
     * @param to address that will receive the newly minted token
     * @param tokenId tokenId to mint
     */
    function mintAdmin(
        address to, 
        uint256 tokenId
    ) external isValidToken(tokenId) onlyAdminRole nonReentrant {
        delete publicPrices[tokenId];
        _mint(to, tokenId);
    }

    /**
     * @dev used to update the whitelistMerkleRoot
     */
    function setWhitelistMerkleRoot(bytes32 newWhitelistMerkleRoot) external onlyAdminRole {
        whitelistMerkleRoot = newWhitelistMerkleRoot;
    }

    /**
     * @dev used by admin to set public sale price
     */
    function setSalePrice(uint256 tokenId, uint price) isValidToken(tokenId) external onlyAdminRole {
        require(!_exists(tokenId), "RowADT: Unable to set price for existing token.");
        publicPrices[tokenId] = price;
    }

    /**
     * @dev used by admin to set public sale state
     */
    function setSaleState(SaleState newState) external onlyAdminRole {
        saleState = newState;
        emit SaleStateChanged(newState);
    }

    //  ──────────────────────────────  Royalties  ────────────────────────────────  \\

    /**
     * @dev update the royalty rate on secondary sale.
     * 
     * @param newRate royalty rate in basis points
     */
    function updateRoyaltyRate(uint96 newRate) external onlyOwner {
        royaltyRateBips = newRate;
    }

    /**
     * @dev updates an the artist payment wallet
     * 
     * @param artistIndex index of arist account to override
     * @param newReceiver new wallet address to replace existing
     */
    function updateRoyaltyReceiver(uint256 artistIndex, address payable newReceiver) external onlyOwner {
        require(artistIndex < artistCount, "RowADT: artistIndex out of range.");
        artistWallets[artistIndex] = newReceiver;
    }

    /// @dev See {IERC2981}
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external view isValidToken(tokenId)
        returns (address receiver, uint256 royaltyAmount) {
        // 1. Figure out whose receiving the token
        receiver = artistOfToken(tokenId);
        // 2. Calculate royalty rate
        royaltyAmount = Math.mulDiv(salePrice, royaltyRateBips, 10_000);
    }

    //  ──────────────────────────────  Withdraws  ────────────────────────────────  \\

    /**
     * @dev used by owner to withdraw any Eth held by contract
     */
    function withdrawEth(address payable to) nonReentrant external onlyOwner {
        require(to != address(0x0), "RowADT: invalid withdraw address");
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "RowADT: unable to send value, recipient may have reverted");
    }

    /// @dev required so contract can receive ETH
    receive() payable external {}

    //  ───────────────────────────────  Metadata  ────────────────────────────────  \\

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) isValidToken(tokenId) external onlyAdminRole {
        tokenURIs[tokenId] = uri;
    }

    //  ──────────────────────  Metaverse Build Management  ───────────────────────  \\

    /**
     * @dev inserts a new named metaverse to list of supported environments
     */
    function addMetaverse(string calldata _metaverseName) external onlyOwner {
        _metaverses.push(_metaverseName);
        emit NewMetaverseAdded(_metaverseName, _metaverses.length - 1);
    }

    //  ──────────────────────  Ownable and Access Control  ───────────────────────  \\

    /**
     * @dev grantAdminRole allows the contract owner to create a new admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev revokeAdminRole allows the contract owner to remove an admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  User Functionality                                                            │
    //                                                                                │
    //  ──────────────────────────────────────────────────────────────────────────────┘


    //  ────────────────────────────────  Minting  ────────────────────────────────  \\

    /**
     * @notice mint token if public sale is active
     * 
     * Requirements:
     *     - Public minting must be active
     *     - Token must not exist
     *     - Token must not be reserved
     *     - Token must have a non-zero price
     *     - Token must id must be between 0 and 29
     *     - Payment amount must meet or exceed public price
     */
    function mint(address to, uint256 tokenId) 
        isValidToken(tokenId) external payable nonReentrant 
    {
        // 1. Require public sale to be live, token to not exist, the public price to be set
        require(saleState == SaleState.open,       "RowADT: Public minting not permitted at this time.");
        require(meetsPaymentRequirements(tokenId), "RowADT: Failed to meet payment requirements");
        
        // 2. Proceed to payment and mint
        mintWithPayment(to, tokenId);
    }

    /**
     * @notice mint token if caller on whitelist
     */
    function whitelistMint(address to, uint256 tokenId, bytes32[] calldata proof)
        isValidToken(tokenId) external payable nonReentrant 
    {
        // 1. Require whitelist sale to be live, token to not exist, the sale price to be set, and user to be on whitelist
        require(saleState == SaleState.whitelist,  "RowADT: Whitelist minting not permitted at this time.");
        require(meetsPaymentRequirements(tokenId), "RowADT: Failed to meet payment requirements");
        require(validateWhitelistProof(proof, to, tokenId), "RowADT: User not permitted to mint.");

        // 2. Proceed to payment and mint
        mintWithPayment(to, tokenId);
    }

    function meetsPaymentRequirements(uint256 tokenId) private returns(bool) {
        require(!_exists(tokenId), "RowADT: Unable to mint existing token.");
        require(publicPrices[tokenId] != 0, "RowADT: Public minting not permitted for given token.");
        require(
            // If msg has value, ensure it's 5% greater than estimated USDC value, or...
            (msg.value != 0 && 
                publicPrices[tokenId] <= estimateUSDCValue(msg.value)
            ) ||
            // Ensure the contract is authorized for enough USDC
            publicPrices[tokenId] <= USDC.allowance(msg.sender, address(this)),
            "RowADT: Insufficient payment."
        );

        return true;
    }

    function mintWithPayment(address to, uint256 tokenId) private {
        uint256 salePrice = publicPrices[tokenId];
        address paymentReceiver = artistOfToken(tokenId);

        // 2. Process payment
        if (msg.value > 0) { // If msg has value, estimate value in USDC. If 5% greater than sale price, convert to USDC
            uint256 valueInUSDC = estimateUSDCValue(msg.value);
            require(valueInUSDC >= Math.mulDiv(salePrice, 41, 40), "RowADT: Insufficient payment post conversion.");

            uint deadline = block.timestamp + 120;
            _convertEthToUSDC(salePrice, deadline, paymentReceiver);
        } else { // If no msg value, attempt to transfer USDC from caller to recipient
            require(USDC.allowance(msg.sender, address(this)) >= salePrice, "RowADT: Contract is not authorized to spend USDC.");
            require(USDC.transferFrom(msg.sender, paymentReceiver, salePrice), "RowADT: Payment failed.");
        }

        // 3. If this point is reached, payment was processed. Authorize Mint
        delete publicPrices[tokenId];
        _mint(to, tokenId);
    }

    /**
     * @dev extnernal function to convert Eth to USDC
     * 
     * Requirements:
     *     - msg.value must be non-zero
     */
    function convertEthToUSDC(uint256 usdcAmount, uint deadline, address recipient) payable nonReentrant external returns (uint256 ethConsumed) {
        ethConsumed = _convertEthToUSDC(usdcAmount, deadline, recipient);
    }

    /**
     * @dev converts Eth to USDC via UniSwap 0.3% fee pool
     * 
     * Requirements:
     *     - msg.value must be non-zero
     */
    function _convertEthToUSDC(uint256 usdcAmount, uint deadline, address recipient) private returns (uint256 ethConsumed) {
        require(msg.value > 0, "RowADT: Conversion requires Eth value.");

        uint256 ethValue = msg.value;
        WETH9.deposit{ value: msg.value }();

        require(
            WETH9.approve(address(swapRouter), ethValue), 
            "RowADT: Failed to give router swapping permissions for Weth."
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            address(WETH9),
            address(USDC),
            poolFee,
            recipient,
            deadline,
            usdcAmount,
            ethValue,
            0
        );

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        ethConsumed = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (ethConsumed) is less than the Eth value, approve the swapRouter to spend 0 WETH,
        // convert surplus Weth to Eth, then transfer funds back to caller.
        if (ethConsumed < ethValue) {
            require(
                WETH9.approve(address(swapRouter), 0),
                "RowADT: Failed to revoke router swapping permissions for Weth."
            );
            WETH9.withdraw(ethValue - ethConsumed);
            (bool success, ) = payable(msg.sender).call{value: ethValue - ethConsumed}("");
            require(success, "RowADT: eth send failed");
        }
    }

    /**
     * @dev Estimates the USDC conversion value of input Weth at 0.3% based on last 60 seconds of trades
     * Inspiration: https://github.com/t4sk/uniswap-v3-twap 
     *
     */
    function estimateUSDCValue(uint256 ethValue) public view returns(uint256) {
        uint32 secondsAgo = 60; // TODO: consider this assumption
        (int24 tick, ) = OracleLibrary.consult(pool, secondsAgo);

        return OracleLibrary.getQuoteAtTick(
            tick,
            uint128(ethValue),
            address(WETH9),
            address(USDC)
        );
    }

    /**
     * @notice gets the sale price of a token if for sale
     */
    function priceOf(uint256 tokenId) isValidToken(tokenId) view external returns(uint256 price) {
        price = publicPrices[tokenId];
    }

    //  ───────────────────────────────  Metadata  ────────────────────────────────  \\

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view isValidToken(tokenId) override(ERC721) returns (string memory) {
        string storage uri = tokenURIs[tokenId];
        return string(abi.encodePacked(baseURI, uri));
    }

    /**
     * @dev adds a metaverse to a token's list of deployed metaverses - and 
     * updates token's URI if non-empty value provided.
     */
    function tokenDeployedToMetaverse(
        uint256 tokenId, 
        uint8 metaverseId, 
        string calldata newURI
    ) external onlyAdminRole {
        // 1. Ensure token and metaverse exist
        require(_exists(tokenId), "RowADT: Token does not exist");
        require(_metaverses.length > metaverseId, "RowADT: Metaverse at id does not exist");

        // 2. Ensure not already deployed
        uint8[] storage buildsForToken = _builds[tokenId];
        uint256 numberOfBuilds = buildsForToken.length;
        for (uint256 i = 0; i > numberOfBuilds; i++) {
            uint8 buildMetaverseId = buildsForToken[i];
            require(buildMetaverseId != metaverseId, "RowADT: Token already deployed to given metaverse");
        }
        // 3. Insert new metaverse ID - and enforce one item was added
        _builds[tokenId].push(metaverseId);
        assert(_builds[tokenId].length == numberOfBuilds + 1);

        // 4. If a new URI is present, update token's URI
        if (bytes(newURI).length > 0) {
            tokenURIs[tokenId] = newURI;
        }
    }

    /// @notice returns name of metaverse
    function metaverseName(uint256 metaverseId) external view returns(string memory) {
        require(_metaverses.length > metaverseId, "RowADT: Metaverse at id does not exist");
        return _metaverses[metaverseId];
    }

    /// @notice returns a list of metaverse IDs a token's built in
    function tokenBuiltMetaverseIds(uint256 tokenId) external view returns(uint8[] memory) {
        require(_exists(tokenId), "RowADT: Token does not exist");
        return _builds[tokenId];
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  Internal Functionality                                                        │
    //                                                                                │
    //  ──────────────────────────────────────────────────────────────────────────────┘

    //  ──────────────────────  Ownable and Access Control  ───────────────────────  \\

    /**
     * @dev Checks if address has owner or Admin privileges.
     *
     * @param account address whose privileges will be checked.
     *
     * @return `true` if account is owner or Admin, `false` otherwise.
     */
    function hasAdminRole(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    //  ─────────────────────────────  Merkle Proofs  ─────────────────────────────  \\

    /**
     * @dev validates if a given address is permitted to mint a given token
     * 
     * @param proof merkle proof to validate
     * @param to address to check for eligibility
     * @param tokenId the token to check for eligibility
     */
    function validateWhitelistProof(bytes32[] calldata proof, address to, uint256 tokenId) private view returns(bool) {

        // TODO: This code's not the cleanest. Polish it up
        bytes32 proofForAllTokens = keccak256(abi.encodePacked(to, "all"));

        if (MerkleProof.verify(proof, whitelistMerkleRoot, proofForAllTokens)) {
            return true;
        }
        
        bytes32 proofForGivenToken = keccak256(abi.encodePacked(to, tokenId));

        return MerkleProof.verify(proof, whitelistMerkleRoot, proofForGivenToken);
    }

    //  ────────────────────────────────  Artists  ────────────────────────────────  \\

    /**
     * @notice returns the creator's wallet from a given token
     *
     * @param tokenId token to find creator
     *
     * @return artist the address of the artist
     */
    function artistOfToken(uint256 tokenId) public view isValidToken(tokenId) returns (address payable artist) {
        uint256 receiverIndex = tokenId / artistCount;
        artist = artistWallets[receiverIndex];
    }


    //  ──────────────────────────  Function Modifiers  ───────────────────────────  \\

    /**
     * @dev Throws if called by any account without admin or owner role.
     */
    modifier onlyAdminRole() {
        require(
            hasAdminRole(_msgSender()),
            "RowADT: caller requires Admin privileges."
        );
        _;
    }

    modifier isValidToken(uint256 tokenId) {
        require(0 <= tokenId && tokenId < maxSupply, "RowADT: No such token.");
        _;
    }

    //  ──────────────────────────────  Transfering  ──────────────────────────────  \\

    /**
     * @dev Required overwrite
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ──────────────────────  Supports Interface {ERC165}  ──────────────────────   \\

    /**
     * @dev Override required due to conflicting inheritance
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Reserved storage gap. LINK: https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}
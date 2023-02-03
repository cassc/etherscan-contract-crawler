// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "ReentrancyGuard.sol";

import "SafeERC20.sol";
import "IERC20.sol";

contract ChadsterNft is ERC721A, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Mint stages
    uint128 public constant STAGE_CLOSED = 0;
    uint128 public constant STAGE_LIVE = 1;

    uint128 public stage;

    // Private management variables
    string private _baseUri;

    // Token constants
    uint256 public constant TOTAL_SUPPLY = 500;

    address public constant DEAD = address(0xdead);

    uint256 public PUBLIC_MINT_PRICE = 100_000 * 10 ** 18; // 0.1% of $CHADSTER supply
    uint256 public PUBLIC_MAX_MINT = 8;

    uint256 public BREED_PRICE = 1_000 * 10 ** 18; // 0.001% of $CHADSTER supply

    // Token variables
    uint256 private _devMintQuantity;
    uint256 private _whitelistMintQuantity;
    
    IERC20 public TOKEN;

    // Events
    event Mint(address indexed to, uint256 amount);
    event StageChanged(uint128 indexed oldStage, uint128 indexed newStage);

    constructor(address chadsterToken) ERC721A("Chadster NFT", "CHADSTER") {
        stage = STAGE_CLOSED;
        TOKEN = IERC20(chadsterToken);
    }

    /**********************************************************
     * Breed functions
     ***********************************************************/
    /**
     * @dev Breed a new token.
     */
    function breed(uint256 source, uint256 target) public nonReentrant {
        address sender = msg.sender;
        require(stage == STAGE_LIVE, "Mint not open yet");
        require(ownerOf(source) == sender, "Not owned");
        require(ownerOf(target) == sender, "Not owned");
        require(TOKEN.balanceOf(sender) >= BREED_PRICE, "Insufficient balance");
        // Burn baby burn!
        TOKEN.safeTransferFrom(sender, DEAD, BREED_PRICE);

        _internalMint(sender, 1);
    }

    /**********************************************************
     * Mint functions
     ***********************************************************/

    /**
     * @dev Public mint of tokens.
     */
    function mint(uint256 quantity) public nonReentrant {
        address sender = msg.sender;
        require(stage == STAGE_LIVE, "Mint not open yet");
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Total supply exceeded"
        );
        require(quantity <= PUBLIC_MAX_MINT, "Mint quantity exceeded");
        require(TOKEN.balanceOf(sender) >= PUBLIC_MINT_PRICE, "Insufficient balance");

        // Burn the amount
        TOKEN.safeTransferFrom(sender, DEAD, PUBLIC_MINT_PRICE);

        _internalMint(sender, quantity);
    }

    /**********************************************************
     * Admin functions
     ***********************************************************/

    /**
     * @dev Set the base URI for the token.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    /**
     * @dev Withdraw ether from the contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Set the mint parameters for public.
     */
    function setMintParams(uint256 newPrice, uint256 newMaxMint)
        external
        onlyOwner
    {
        require(stage == STAGE_CLOSED, "Invalid stage");
        PUBLIC_MINT_PRICE = newPrice;
        PUBLIC_MAX_MINT = newMaxMint;
    }

    /**
     * @dev Set the minting stage for the token.
     */
    function setStage(uint128 newStage) external onlyOwner {
        require(newStage <= STAGE_LIVE, "Invalid stage");

        uint128 oldStage = stage;
        stage = newStage;

        emit StageChanged(oldStage, newStage);
    }

    /**********************************************************
     * Internal functions
     ***********************************************************/

    /**
     * @dev Mints the specified amount of tokens to the specified address.
     */
    function _internalMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
        emit Mint(to, quantity);
    }

    /**
     * @dev Returns the base URI for the token.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }
}
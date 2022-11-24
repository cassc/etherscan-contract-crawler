// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol"; // OZ: Pausable
import "@openzeppelin/contracts/access/Ownable.sol"; // OZ: Ownership
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // OZ: ERC165 interface
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // OZ: Reentrancy Guard
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleRoot
import "@openzeppelin/contracts/utils/Counters.sol"; // OZ: Counter

import "./interfaces/IERC721BridgableParent.sol"; // token contract for minting

/// @title StagedMintV1 - lets users mint in stages, currently only 2 stages (premint and public stage)
contract StagedMintV1 is Ownable, ReentrancyGuard, Pausable {
    // For counter
    using Counters for Counters.Counter;

    // Stages
    enum MintStage {
        DISABLED,
        PREMINT,
        ALLOWLIST,
        PUBLIC_SALE
    }

    /** IMMUTABLE STORAGE **/

    /// @notice Number of mints in PREMINT phase
    uint256 constant PREMINT_COUNT = 2;

    /// @notice Number of mints in ALLOWLIST phase
    uint256 constant ALLOWLIST_COUNT = 3;

    /// @notice Cost to mint each NFT (in wei)
    uint256 public immutable MINT_COST;
    /// @notice Cost to premint each NFT (in wei)
    uint256 public immutable PREMINT_COST;
    /// @notice Available NFT supply
    uint256 public immutable AVAILABLE_SUPPLY;
    /// @notice Maximum mints per address
    uint256 public immutable MAX_PER_ADDRESS;
    /// @notice Address of NFT Contract to mint to
    IERC721BridgableParent public immutable NFT_CONTRACT;

    /** MUTABLE STORAGE **/
    /// @notice Variable to keep track of which stage we are in
    MintStage public mintStage = MintStage.DISABLED;
    /// @notice Merkle root hash for the premint list
    bytes32 public merkleRootHash;
    /// @notice Address mapping to track number of completed premints
    mapping(address => uint256) public premintCounts;
    /// @notice Address mapping to track number of completed allowlist mints
    mapping(address => uint256) public allowlistCounts;
    /// @notice Address mapping to track number of completed public sale mints
    mapping(address => uint256) public mintCounts;
    /// @notice Counter for number of NFTs that have been claimed
    Counters.Counter public currentTokenId;

    /** EVENTS **/

    /**
     * @notice Emitted when the owner changes the current mint stage
     *
     * @param owner Address of owner enabling the premint
     * @param stage Stage that the contract is currently in
     */
    event StageChanged(address indexed owner, MintStage stage);

    /**
     * @notice Emitted when the owner withdraws proceeeds
     *
     * @param owner Address of owner withdrawing
     * @param amount  Amount that was withdrew
     */
    event WithdrewProceeds(address indexed owner, uint256 amount);

    /** SETUP **/

    /**
     * @notice Creates a new NFT distribution contract
     *
     * @param _PREMINT_COST in wei per NFT
     * @param _MINT_COST in wei per NFT
     * @param _AVAILABLE_SUPPLY total NFTs to sell
     * @param _MAX_PER_ADDRESS maximum mints allowed per address
     * @param _NFT_CONTRACT_ADDRESS contract address of NFT that will be minted
     */
    constructor(
        uint256 _PREMINT_COST,
        uint256 _MINT_COST,
        uint256 _AVAILABLE_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        address _NFT_CONTRACT_ADDRESS
    ) {
        PREMINT_COST = _PREMINT_COST;
        MINT_COST = _MINT_COST;
        AVAILABLE_SUPPLY = _AVAILABLE_SUPPLY;
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
        NFT_CONTRACT = IERC721BridgableParent(_NFT_CONTRACT_ADDRESS);

        // Check that NFT contract address is correctly set
        require(
            address(NFT_CONTRACT) != address(0),
            "NFT_CONTRACT_ERROR: NFT Address has not been set"
        );

        // Check that NFT contract address supports ERC165 Interface
        require(
            NFT_CONTRACT.supportsInterface(type(IERC165).interfaceId) == true,
            "NFT_CONTRACT_ERROR: NFT Contract doesn't support ERC165 Interface"
        );

        // Check that the contract has the functions we expect
        require(
            NFT_CONTRACT.supportsInterface(
                type(IERC721BridgableParent).interfaceId
            ) == true,
            "NFT_CONTRACT_NOT_BRIDGABLE: NFT Contract is not a IERC721BridgableParent"
        );

        _pause();
    }

    /** EXTERNAL - ENTER RAFFLE OR MINT **/

    /**
     * @notice Allows users on the premint list to premint
     *
     * @param amount        Number of premints
     * @param merkleProof   Proof that the user is on the list
     */
    function enterPremint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            amount != 0,
            "INCORRECT_AMOUNT: Amount must be greater than zero"
        );

        // Ensure premint is enabled
        require(
            mintStage == MintStage.PREMINT || mintStage == MintStage.ALLOWLIST,
            "PREMINT_NOT_ACTIVE: Premint has not begun"
        );

        // Ensure sufficient payment
        if (mintStage == MintStage.ALLOWLIST) {
            require(
                msg.value == (amount * MINT_COST),
                "INCORRECT_PAYMENT: Incorrect payment amount for mint"
            );

            // Track user allowlist count
            uint256 userPremintedCount = allowlistCounts[_msgSender()];

            // Ensure address is not attempting to premint more than allowed
            require(
                (userPremintedCount + amount) <= ALLOWLIST_COUNT,
                "PREMINT_MAX_REACHED: Attempting to premint more than allotment"
            );

            // Increase count of user premints redeemed
            allowlistCounts[_msgSender()] = (userPremintedCount + amount);
        } else {
            require(
                msg.value == (amount * PREMINT_COST),
                "INCORRECT_PAYMENT: Incorrect payment amount for mint"
            );

            // Track user premint count
            uint256 userPremintedCount = premintCounts[_msgSender()];

            // Ensure address is not attempting to premint more than allowed
            require(
                (userPremintedCount + amount) <= PREMINT_COUNT,
                "PREMINT_MAX_REACHED: Attempting to premint more than allotment"
            );

            // Increase count of user premints redeemed
            premintCounts[_msgSender()] = (userPremintedCount + amount);
        }

        // Ensure address is on premint/allowlist list by checking merkle root
        bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verifyCalldata(merkleProof, merkleRootHash, merkleLeaf),
            "PREMINT_ADDRESS_MISSING: Address not on premint list"
        );

        _directMintAndIncrementCurrentTokenId(amount);
    }

    /**
     * @notice Whether or not user is on premint list using merkle proof
     *
     * @param account Account to check is on premint list
     * @return TRUE if account is on list, FALSE otherwise
     */
    function isOnPremintList(address account, bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        bytes32 merkleLeaf = keccak256(abi.encodePacked(account));
        return
            MerkleProof.verifyCalldata(merkleProof, merkleRootHash, merkleLeaf);
    }

    /**
     * @notice Mint during public sale
     *
     * @param amount Number of tokens to mint
     */
    function mint(uint256 amount) external payable whenNotPaused nonReentrant {
        // Ensure public sale has begun
        require(
            mintStage == MintStage.PUBLIC_SALE,
            "PUBLIC_SALE_NOT_STARTED: Public sale has not begun"
        );

        require(
            amount != 0,
            "INCORRECT_AMOUNT: Amount must be greater than zero"
        );

        // Ensure sufficient mint payment
        require(
            msg.value == (amount * MINT_COST),
            "INCORRECT_PAYMENT: Incorrect payment amount for mint"
        );

        uint256 addressMintedCount = mintCounts[_msgSender()];
        // Ensure number of tokens to acquire <= max for this address
        require(
            (addressMintedCount + amount) <= MAX_PER_ADDRESS,
            "MINT_MAX_REACHED: This transaction exceeds your addresses limit of tokens"
        );

        // Increase count of user mints redeemed
        mintCounts[_msgSender()] = (addressMintedCount + amount);

        _directMintAndIncrementCurrentTokenId(amount);
    }

    /** EXTERNAL - ADMIN */

    /** @notice Allows contract owner to withdraw proceeds of mints */
    function withdrawProceeds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        // Ensure there are proceeds to claim
        require(balance > 0, "PAYOUT_EMPTY: No proceeds available to claim");

        // Pay owner proceeds
        (bool sent, ) = payable(_msgSender()).call{value: balance}("");
        require(
            sent == true,
            "WITHDRAW_UNSUCCESFUL: Was unable to withdraw proceeds"
        );

        emit WithdrewProceeds(_msgSender(), balance);
    }

    /**
     * @notice Update the merkleproof root hash for the premint list
     *
     * @param rootHash for the merkle tree root
     */
    function updateMerkleRoot(bytes32 rootHash) external onlyOwner {
        // Ensure premint is enabled
        require(
            mintStage == MintStage.DISABLED,
            "NOT_DISABLED: Can not add to premint list unless disabled"
        );

        merkleRootHash = rootHash;
    }

    /**
     * @notice Pause/Unpause this contract
     *
     * @param _paused Whether to pause or unpause the contract
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused == true) _pause();
        else _unpause();
    }

    /**
     * @notice Sets the mint stage
     *
     * @param _stage Stage to change to
     */
    function setMintStage(MintStage _stage) external onlyOwner {
        mintStage = _stage;

        emit StageChanged(_msgSender(), _stage);
    }

    /** INTERNAL **/

    /**
     * @notice Private function used by premint and mint to mint
     *
     * @param amount number of tokens to mint
     */
    function _directMintAndIncrementCurrentTokenId(uint256 amount) internal {
        // Ensure NFTs are still available
        require(
            (currentTokenId.current() + amount) <= AVAILABLE_SUPPLY,
            "NFT_MAX_REACHED: Not enough NFTs left to fulfill transaction"
        );

        // Mint NFTs for number requested
        for (uint256 i = 0; i < amount; ++i) {
            // Increment current token id to next id
            currentTokenId.increment();
            // Mint current token id as NFT
            _mintNFT(_msgSender(), currentTokenId.current());
        }
    }

    /**
     * @notice Function to mint from the NFT contract
     *
     * @param to address to mint NFT to
     * @param tokenId tokenId to mint
     */
    function _mintNFT(address to, uint256 tokenId) internal {
        // Call mint function on external NFT contract
        NFT_CONTRACT.mint(to, tokenId);
    }
}
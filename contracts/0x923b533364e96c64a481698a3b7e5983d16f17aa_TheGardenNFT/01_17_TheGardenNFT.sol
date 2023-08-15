// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊◊ ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊        ◊◊◊◊ ◊◊◊◊  ◊◊◊◊ ◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊   ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊

 */

import "solmate/tokens/ERC721.sol";
import "fount-contracts/auth/Auth.sol";
import "fount-contracts/extensions/BatchedReleaseOperatorExtension.sol";
import "fount-contracts/extensions/SwappableMetadata.sol";
import "fount-contracts/utils/Royalties.sol";
import "fount-contracts/utils/Withdraw.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "./interfaces/IOperatorCollectable.sol";
import "./interfaces/ITheGardenNFT.sol";
import "./interfaces/IMetadata.sol";

/**
 * @author Fount Gallery
 * @title  The Garden NFT
 * @notice The Garden is a digital and physical bouquet of floral portraits created by
 *         renowned graphic artist Christopher DeLorenzo.
 *
 *         Ninety-nine unique pieces, released in three arrangements of sale.
 *
 *         Hand-crafted by Christopher, the digital portraits are one-of-a-kind and
 *         exist as ERC-721 tokens on the Ethereum blockchain. For each arrangement,
 *         Chris will design and create a limited edition physical print, not included in the
 *         digital collection. When an arrangement sells out, holders can choose to claim and
 *         collect a physical artwork, signed by the artist.
 *
 *         Contract features:
 *           - Batched releases of NFTs
 *           - Separate contracts for each arrangement of sale
 *           - Swappable metadata contract
 *           - On-chain royalties standard (EIP-2981)
 */
contract TheGardenNFT is
    ITheGardenNFT,
    ERC721,
    IOperatorCollectable,
    BatchedReleaseOperatorExtension,
    SwappableMetadata,
    Royalties,
    Withdraw,
    Auth,
    ReentrancyGuard
{
    /* ------------------------------------------------------------------------
       S T O R A G E / C O N F I G
    ------------------------------------------------------------------------ */

    uint256 public constant MAX_PIECES = 99;
    uint256 public constant ARRANGEMENT_SIZE = 33;
    address public constant ARTIST = 0x9ECd87D919c78DaCF4Dd60EFE2ffF6a8457F2256;
    string public contractURI;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param royaltiesReceiver_ The receiver of royalty payments
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     */
    constructor(
        address owner_,
        address admin_,
        address royaltiesReceiver_,
        uint256 royaltiesAmount_,
        address metadata_
    )
        ERC721("The Garden", "GRDN")
        BatchedReleaseOperatorExtension(MAX_PIECES, ARRANGEMENT_SIZE)
        SwappableMetadata(metadata_)
        Royalties(royaltiesReceiver_, royaltiesAmount_)
        Auth(owner_, admin_)
    {}

    /* ------------------------------------------------------------------------
       C O L L E C T I N G
    ------------------------------------------------------------------------ */

    /**
     * @notice Collect a specific token from an operator contract
     * @dev Reverts if:
     *   - `id` has already been collected
     *   - `id` is not a token from the current `activeBatch`
     *   - caller is not approved for the current `activeBatch`
     * @param id The token id to collect
     * @param to The address to transfer the token to
     */
    function collect(uint256 id, address to)
        public
        override
        onlyWhenTokenIsInActiveBatch(id)
        onlyWhenOperatorForActiveBatch
        nonReentrant
    {
        // Transfer the token from the current owner to the new owner
        transferFrom(ownerOf(id), to, id);

        // Mark the token as collected
        _collectToken(id);
    }

    /**
     * @notice Mark a specific token id as collected by an operator contract
     * @dev Reverts if:
     *   - `id` has already been collected
     *   - `id` is not a token from the current `activeBatch`
     *   - caller is not approved for the current `activeBatch`
     * @param id The token id that was collected
     */
    function markAsCollected(uint256 id)
        public
        override
        onlyWhenTokenIsInActiveBatch(id)
        onlyWhenOperatorForActiveBatch
        nonReentrant
    {
        // Mark the token as collected
        _collectToken(id);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set an operator for a specific batch
     * @dev Allows the operator to run a sale for a specific batch.
     * Also sets {isApprovedForAll} for the minter so it can transfer tokens.
     * Reverts if the batch number is invalid
     * @param batch The batch to set the operator for
     * @param operator The operator contract that get's approval to all the minters tokens
     */
    function setBatchOperator(uint256 batch, address operator) public override onlyOwnerOrAdmin {
        // Remove approvals for the previous operator contract
        isApprovedForAll[ARTIST][_operatorForBatch[batch]] = false;

        // Automatically approve the new operator contract
        isApprovedForAll[ARTIST][operator] = true;

        // Set the new operator
        _setBatchOperator(batch, operator);
    }

    /**
     * @notice Admin function to advance the active batch based on the number of tokens sold
     * @dev Reverts if the current batch hasn't sold out yet, or if minting a batch fails
     */
    function goToNextBatch() public override onlyOwnerOrAdmin {
        _goToNextBatch();
        _mintArrangement(_activeBatch);
    }

    /**
     * @notice Internal function to mint all the tokens in a given arrangement
     * @dev Reverts if the `arrangement` is invlaid, or the tokens already exist
     * @param arrangement The arrangement number to mint
     */
    function _mintArrangement(uint256 arrangement) internal onlyOwnerOrAdmin {
        // Revert if arrangement is invalid (InvalidBatch from BatchedReleaseExtension)
        if (arrangement == 0 || arrangement > (_totalTokens / _batchSize)) revert InvalidBatch();

        // Calculate the offset for the token id based on the arrangement and arragenment size
        uint256 offset = (arrangement - 1) * ARRANGEMENT_SIZE;

        // Mint an arrangement to the artist
        for (uint256 i = 0; i < ARRANGEMENT_SIZE; i++) {
            _mint(ARTIST, i + 1 + offset);
        }
    }

    /**
     * @notice Admin function to set the metadata contract address
     * @param metadata_ The new metadata contract address
     */
    function setMetadataAddress(address metadata_) public override onlyOwnerOrAdmin {
        _setMetadataAddress(metadata_);
    }

    /**
     * @notice Admin function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwnerOrAdmin {
        _setRoyaltyInfo(receiver, amount);
    }

    /**
     * @notice Admin function to set the contract URI for marketplaces
     * @param uri The new contract URI
     */
    function setContractURI(string memory uri) external onlyOwnerOrAdmin {
        contractURI = uri;
    }

    /* ------------------------------------------------------------------------
       A R R A N G E M E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice Gets the currently active/latest arrangement number
     */
    function latestArrangement() external view returns (uint256) {
        return _activeBatch;
    }

    /**
     * @notice Gets the arrangement a particular token is in
     * @param id The token id to get the arrangement for
     */
    function arrangementForToken(uint256 id) public view returns (uint256) {
        return _getBatchFromId(id);
    }

    /**
     * @notice Checks if a token is in an arrangement that has been released
     * @param id The token id to check if it's been released
     */
    function hasTokenBeenReleased(uint256 id) external view returns (bool) {
        return !(_activeBatch == 0 || arrangementForToken(id) > _activeBatch);
    }

    /**
     * @notice Gets the current operator for a specific arrangement
     * @param arrangement The arrangement number to get the operator for
     */
    function operatorForArrangement(uint256 arrangement) external view returns (address) {
        return _operatorForBatch[arrangement];
    }

    /* ------------------------------------------------------------------------
       E R C - 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the token metadata
     * @return id The token id to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        return IMetadata(metadata).tokenURI(id);
    }

    /**
     * @notice Add on-chain royalty standard
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == ROYALTY_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Burn a token. You can only burn tokens you own.
     * @param id The token id to burn
     */
    function burn(uint256 id) external {
        require(ownerOf(id) == msg.sender, "NOT_OWNER");
        _burn(id);
    }

    // TODO: Add contractUri function for marketplaces

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw stuck ETH from this contract
     * @dev This contract doesn't use ETH directly, but this is a failsafe for cases
     * where ETH was accidentally sent to this contract and needs to be recovered.
     * @param to The address to withdraw ETH to
     */
    function withdrawStuckETH(address to) public onlyOwnerOrAdmin {
        _withdrawETH(to);
    }

    /**
     * @notice Admin function to withdraw stuck ERC-20 tokens from this contract
     * @dev Withdraws to the `to` address. This contract doesn't use ERC-20 tokens,
     * but this is a failsafe if tokens are sent to it by accident.
     * @param token The address of the ERC-20 token to withdraw
     * @param to The address to withdraw tokens to
     */
    function withdrawStuckToken(address token, address to) public onlyOwnerOrAdmin {
        _withdrawToken(token, to);
    }

    /**
     * @notice Admin function to withdraw stuck ERC-721 tokens from this contract
     * @dev Withdraws to the `to` address. This contract doesn't accept ERC-721 tokens,
     * but this is a failsafe if tokens are sent to it by accident.
     * @param token The address of the ERC-721 token to withdraw
     * @param id The token id to withdraw
     * @param to The address to withdraw tokens to
     */
    function withdrawStuckERC721Token(
        address token,
        uint256 id,
        address to
    ) public onlyOwnerOrAdmin {
        _withdrawERC721Token(token, id, to);
    }
}
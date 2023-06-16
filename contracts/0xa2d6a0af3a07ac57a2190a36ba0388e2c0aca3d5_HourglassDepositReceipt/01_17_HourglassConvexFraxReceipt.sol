// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/token/ERC1155/ERC1155.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@interfaces/IProxyVault.sol";
import "@interfaces/IRewardsDistributor.sol";
import "@interfaces/ICustodian.sol";

contract HourglassDepositReceipt is AccessControl, ERC1155 {

    /// @notice Setter role
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    /// @notice Minter role (the custodian)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Address of the rewards distributor
    address public immutable REWARD_DISTRIBUTOR;

    /// @notice Asset Metadata
    struct AssetMetadata {
        uint256 assetId;
        address custodian;
        address depositStrategy; // frax staking farm
        address matureHoldingsVault;
        uint256 rewardEpochDuration; 
    }

    /// @notice Token ID Metadata
    struct TokenIDMetadata {
        address depositVault; // convex vault
        uint256 nextCheckpoint;
        bool isMatured;
    }

    /// @notice Stores generic information about this asset receipt
    AssetMetadata public assetMetadata;

    /// @notice Stores maturity/token id specific data: tokenMetadata[tokenId] => TokenIDMetadata
    mapping(uint256 => TokenIDMetadata) public tokenMetadata;

    /// @notice Stored the amount of a given token ID
    mapping(uint256 => uint256) private _totalSupply;

    constructor(
        address _custodian, 
        address _setter, 
        address _admin, 
        address _rewardDistributor,
        string memory receiptName
    ) ERC1155(receiptName) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTER_ROLE, _setter);
        _setupRole(MINTER_ROLE, _custodian);
        
        REWARD_DISTRIBUTOR = _rewardDistributor;
    }


    ////////// MINTING, BURNING, & SUPPLY //////////

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        return (totalSupply(id) > 0);
    }

    /// @notice Allows the custodian to mint receipts when depositing into a vault
    /// @param account The account to mint to
    /// @param id The token id to mint
    /// @param amount The amount to mint
    /// @param data Any additional data to pass to the contract
    function mint(
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /// @notice Allows the custodian to mint receipts when depositing into a vault
    /// @param to The account to mint to
    /// @param ids The token ids to mint
    /// @param amounts The amounts to mint
    /// @param data Any additional data to pass to the contract
    function mintBatch(
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }

    /// @notice Allows burning of a user's receipt tokens by the custodian
    function burnFrom(address account, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(account, id, amount);
    }

    /// @notice Allows burning of a user's receipt tokens by the custodian
    function burnBatchFrom(
        address account, 
        uint256[] memory ids, 
        uint256[] memory amounts
    ) external onlyRole(MINTER_ROLE) {
        _burnBatch(account, ids, amounts);
    }

    /// @notice Allows checking on rewards earned by token ids
    /// @param tokenIds The token ids to check rewards for
    /// @return rewardTokens The reward tokens earned as an array of arrays
    /// @return amounts The amounts of reward tokens earned as an array of arrays
    function earned(uint256[] calldata tokenIds) external view returns (address[][] memory rewardTokens, uint256[][] memory amounts) {
        uint256 numIds = tokenIds.length;
        for (uint256 i; i < numIds; i++) {
            require(tokenMetadata[tokenIds[i]].depositVault != address(0), "tkn!init");
            (rewardTokens[i], amounts[i]) = IProxyVault(tokenMetadata[tokenIds[i]].depositVault).earned();
        }
    }


    ////////// RECEIPT DATA //////////

    /// @notice Called by the Custodian when adding a new asset id
    /// @param assetId The asset id to initialize
    /// @param custodian The custodian of the asset
    /// @param depositStrategy The deposit strategy for the asset
    /// @param rewardEpochDuration The duration of a reward epoch
    /// @dev bytes Any additional data to pass to the contract
    function initializeReceiptContract(
        uint256 assetId, 
        address custodian,
        address depositStrategy, 
        address matureHoldingsVault,
        uint256 rewardEpochDuration, 
        bytes calldata
    ) external onlyRole(MINTER_ROLE) {
        // sanity check - can only be initialized once
        if(assetMetadata.assetId != 0) revert AlreadyInitialized();

        // assign the asset metadata
        assetMetadata = AssetMetadata(assetId, custodian, depositStrategy, matureHoldingsVault, rewardEpochDuration);
    }

    /// @notice Called by the Custodian when adding a new token id (aka deploying a new maturity vault)
    /// @param assetId The asset id to initialize
    /// @param depositVault The deposit vault for the token id
    /// @param maturity The maturity of the token id
    /// @dev bytes Any additional data to pass to the contract
    function initializeTokenId(
        uint256 assetId, 
        address depositVault, 
        uint256 maturity, 
        bytes calldata
    ) external onlyRole(MINTER_ROLE) {
        // sanity checks - can only be initialized once per maturity
        if(assetId != assetMetadata.assetId) revert AssetIDMismatch(assetId, assetMetadata.assetId);
        // check that it hasn't initialized for this token id before
        if(tokenMetadata[maturity].depositVault != address(0)) revert TokenAlreadyInitialized(maturity);

        // assign the token id metadata
        tokenMetadata[maturity].depositVault = depositVault;

        /// @dev if the farm hasn't been sync'd yet, the first transfer will also have end up running the getRewards process
        tokenMetadata[maturity].nextCheckpoint = IFraxFarm(assetMetadata.depositStrategy).periodFinish();

        emit TokenInitialized(maturity, depositVault);
    }


    ////////// TRANSFER HOOKS //////////

    /// @notice Allows the setter to set the URI
    /// @param newuri The new URI
    function setURI(string memory newuri) external onlyRole(SETTER_ROLE) {
        _setURI(newuri);
    }

    /// @notice Before transfer hook to claim any rewards outstanding if it is time to do so
    /** @notice
    * For each token id:
    *    if the token hasn't matured yet,
    *      - check to see if it needs to be checkpointed & rewards claimed
    *      - if it's not time, do nothing here
    *    if the token is past maturity but hasn't been matured:
    *      - mature it by migrating to matured vault & setting `isMatured` to ensure future transfers don't claim
    *      - if the token is matured & migrated, do nothing at all.
    * Note: the most common case will be that the token hasn't matured & doesn't need to be checkpointed, so check that first to save gas
    */
    function _beforeTokenTransfer(
        address, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory
    ) internal override(ERC1155) {
        // save the length as a variable to save gas in loops
        uint256 numIds = ids.length;

        /// Total Supply tracking logic from OZ ERC1155Supply
        if (from == address(0)) {
            for (uint256 i; i < numIds; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i; i < numIds; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: !tknSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }

        /// Logic for automated rewards claiming & processing
        for (uint256 i; i < numIds; i++) {
            if(block.timestamp < ids[i]) {
                // if the token hasn't matured yet, checkpoint it
                if(tokenMetadata[ids[i]].nextCheckpoint < block.timestamp) {
                    // update next checkpoint period
                    tokenMetadata[ids[i]].nextCheckpoint = IFraxFarm(assetMetadata.depositStrategy).periodFinish();
                    
                    // claim rewards for the whole vault
                    IProxyVault(tokenMetadata[ids[i]].depositVault).claimRewards();
                    
                    // Emit an event so the signer that executed this can get reward allocation as gas compensation
                    emit RewardClaimedOnTransfer(ids[i]);
                }
            } else {
                // if the token has matured but is still staked, migrate it to the matured vault
                if(!tokenMetadata[ids[i]].isMatured) {
                    // set the token id to matured
                    tokenMetadata[ids[i]].isMatured = true;

                    // unstake & migrate to mature holding vault
                    ICustodian(assetMetadata.custodian).migrateToMaturedVault(
                        assetMetadata.assetId, 
                        tokenMetadata[ids[i]].depositVault,
                        ids[i]
                    );

                    emit MaturityMigratedOnTransfer(ids[i]);
                }
                // else the token has matured & been migrated, so do nothing
            }
        }
    }

    /// @notice Ping the reward distributor with the users & token amounts for rewards processing
    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override(ERC1155) {
        // do a single call up to the distributor with all token ids and amounts
        IRewardsDistributor(REWARD_DISTRIBUTOR).receiptCheckpoint(address(this), from, to, ids, amounts);
    }

    /// @notice ERC compliance
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /// ERRORS ///
    error AlreadyInitialized();
    error TokenAlreadyInitialized(uint256);
    error AssetIDMismatch(uint256, uint256);

    /// EVENTS ///
    event TokenInitialized(uint256 maturity, address depositVault);
    event RewardClaimedOnTransfer(uint256 maturity);
    event MaturityMigratedOnTransfer(uint256 maturity);
}
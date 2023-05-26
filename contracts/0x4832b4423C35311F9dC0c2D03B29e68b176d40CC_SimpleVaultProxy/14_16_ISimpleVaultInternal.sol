// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { IOwnableInternal } from '@solidstate/contracts/access/ownable/IOwnableInternal.sol';

interface ISimpleVaultInternal is IOwnableInternal {
    /**
     * @notice indicates which lending adaptor is to be interacted with
     */
    enum LendingAdaptor {
        DEFAULT, //allows for passing an 'empty' adaptor argument in functions
        JPEGD
    }

    /**
     * @notice indicates which staking adaptor is to be interacted with
     */
    enum StakingAdaptor {
        DEFAULT, //allows for passing an 'empty' adaptor argument in functions
        JPEGD
    }

    /**
     * @notice encapsulates an amount of fees of a particular token
     */
    struct TokenFee {
        address token;
        uint256 fees;
    }

    /**
     * @notice encapsulates an amount of yield of a particular token
     */
    struct TokenYield {
        address token;
        uint256 yield;
    }

    /**
     * @notice encapsulates the cumulative amount of yield accrued of a paritcular token per shard
     */
    struct TokensPerShard {
        address token;
        uint256 cumulativeAmount;
    }

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error SimpleVault__NotProtocolOwner();

    /**
     * @notice thrown when function called by account which is  non-authorized and non-protocol owner
     */
    error SimpleVault__NotAuthorized();

    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error SimpleVault__InvalidDepositAmount();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error SimpleVault__DepositForbidden();

    /**
     * @notice thrown when attempting to call a disabled function
     */
    error SimpleVault__NotEnabled();

    /**
     * @notice thrown when user is attempting to deposit after owning (minting) max shards
     */
    error SimpleVault__MaxMintBalance();

    /**
     * @notice thrown when attempting to act without being whitelisted
     */
    error SimpleVault__NotWhitelisted();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error SimpleVault__WithdrawalForbidden();

    /**
     * @notice thrown when setting a basis point fee value larger than 10000
     */
    error SimpleVault__BasisExceeded();

    /**
     * @notice thrown when attempting to claim yield before yield claiming is initialized
     */
    error SimpleVault__YieldClaimingForbidden();

    /**
     * @notice thrown when attempting to set a reserved supply larger than max supply
     */
    error SimpleVault__ExceededMaxSupply();

    /**
     * @notice thrown when setting a max supply which is smaller than total supply
     */
    error SimpleVault__MaxSupplyTooSmall();

    /**
     * @notice thrown when the vault does not have enough ETH to account for an ETH transfer + respective fee
     */
    error SimpleVault__InsufficientETH();

    /**
     * @notice thrown when attempting to interact on a collection which is not part of the vault collections
     */
    error SimpleVault__NotCollectionOfVault();

    /**
     * @notice thrown when marking a token for sale which is not in ownedTokenIds
     */
    error SimpleVault__NotOwnedToken();

    /**
     * @notice thrown when attempting to sell a token  not marked for sale
     */
    error SimpleVault__TokenNotForSale();

    /**
     * @notice thrown when an incorrect ETH amount is received during token sale
     */
    error SimpleVault__IncorrectETHReceived();

    /**
     * @notice thrown when attempted to mark a token for sale whilst it is collateralized
     */
    error SimpleVault__TokenCollateralized();

    /**
     * @notice thrown when attempting to discount yield fee with a DAWN_OF_INSRT token not
     * belonging to account yield fee is being discounted for
     */
    error SimpleVault__NotDawnOfInsrtTokenOwner();

    /**
     * @notice thrown when attempting to add a token to collectionOwnedTokens without vault being the token owner
     */
    error SimpleVault__NotTokenOwner();

    /**
     * @notice thrown when attempting to remove a token from collectionOwnedTokens with vault being the token owner
     */
    error SimpleVault__TokenStillOwned();

    /**
     * @notice emitted when an ERC721 is transferred from the treasury to the vault in exchange for ETH
     * @param tokenId id of ERC721 asset
     */
    event ERC721AssetTransfered(uint256 tokenId);

    /**
     * @notice emitted when protocol fees are withdrawn
     * @param tokenFees array of TokenFee structs indicating address of fee token and amount
     */
    event FeesWithdrawn(TokenFee[3] tokenFees);

    /**
     * @notice emitted when an token is marked for sale
     * @param collection address of collection of token
     * @param tokenId id of token
     * @param price price in ETH of token
     */
    event TokenMarkedForSale(
        address collection,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice emitted when a token is sold
     * @param collection address of token collection
     * @param tokenId id of token
     */
    event TokenSold(address collection, uint256 tokenId);

    /**
     * @notice emitted when whitelistEndsAt is set
     * @param whitelistEndsAt the new whitelistEndsAt timestamp
     */
    event WhitelistEndsAtSet(uint48 whitelistEndsAt);

    /**
     * @notice emitted when reservedSupply is set
     * @param reservedSupply the new reservedSupply
     */
    event ReservedSupplySet(uint64 reservedSupply);

    /**
     * @notice emitted when isEnabled is set
     * @param isEnabled the new isEnabled value
     */
    event IsEnabledSet(bool isEnabled);

    /**
     * @notice emitted when maxMintBalance is set
     * @param maxMintBalance the new maxMintBalance
     */
    event MaxMintBalanceSet(uint64 maxMintBalance);

    /**
     * @notice emitted when maxSupply is set
     * @param maxSupply the new maxSupply
     */
    event MaxSupplySet(uint64 maxSupply);

    /**
     * @notice emitted when sale fee is set
     * @param feeBP the new sale fee basis points
     */
    event SaleFeeSet(uint16 feeBP);

    /**
     * @notice emitted when acquisition fee is set
     * @param feeBP the new acquisition fee basis points
     */
    event AcquisitionFeeSet(uint16 feeBP);

    /**
     * @notice emitted when yield fee is set
     * @param feeBP the new yield fee basis points
     */
    event YieldFeeSet(uint16 feeBP);

    /**
     * @notice emitted when ltvBufferBP is set
     * @param bufferBP new ltvBufferBP value
     */
    event LTVBufferSet(uint16 bufferBP);

    /**
     * @notice emitted when ltvDeviationBP is set
     * @param deviationBP new ltvDeviationBP value
     */
    event LTVDeviationSet(uint16 deviationBP);

    /**
     * @notice emitted when a collection is removed from vault collections
     * @param collection address of removed collection
     */
    event CollectionRemoved(address collection);

    /**
     * @notice emitted when a collection is added to vault collections
     * @param collection address of added collection
     */
    event CollectionAdded(address collection);

    /**
     * @notice emitted when an owned token is added to a collection manually
     * @param collection collection address
     * @param tokenId tokenId
     */
    event OwnedTokenAddedToCollection(address collection, uint256 tokenId);

    /**
     * @notice emitted when an owned token is removed from a collection manually
     * @param collection collection address
     * @param tokenId tokenId
     */
    event OwnedTokenRemovedFromCollection(address collection, uint256 tokenId);

    /**
     * @notice emmitted when the 'authorized' state is granted to or revoked from an account
     * @param account address of account to grant/revoke 'authorized'
     * @param isAuthorized value of 'authorized' state
     */
    event AuthorizedSet(address account, bool isAuthorized);

    /**
     * @notice emitted when an ERC721 asset is collateralized in a lending vendor
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param collection address of ERC721 collection
     * @param tokenId id of token
     */
    event ERC721AssetCollateralized(
        LendingAdaptor adaptor,
        address collection,
        uint256 tokenId
    );

    /**
     * @notice emitted when lending vendor tokens received for collateralizing and asset
     *  are staked in a lending vendor
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param shares lending vendor shares received after staking, if any
     */
    event Staked(StakingAdaptor adaptor, uint256 shares);

    /**
     * @notice emitted when a position in a lending vendor is unstaked and converted back
     * to the tokens which were initially staked
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param tokenAmount amount of tokens received for unstaking
     */
    event Unstaked(StakingAdaptor adaptor, uint256 tokenAmount);

    /**
     * @notice emitted when a certain amount of the staked position in a lending vendor is
     * unstaked and converted to tokens to be provided as yield
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param tokenYields array of token addresses and corresponding yields provided
     */
    event YieldProvided(StakingAdaptor adaptor, TokenYield[] tokenYields);

    /**
     * @notice emitted when a loan repayment is made for a collateralized position
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param paidDebt amount of debt repaid
     */
    event LoanPaymentMade(LendingAdaptor adaptor, uint256 paidDebt);

    /**
     * @notice emitted when a loan is repaid in full and the position is closed
     * @param adaptor enum indicating which lending vendor adaptor was used
     * @param receivedETH amount of ETH received after closing position
     */
    event PositionClosed(LendingAdaptor adaptor, uint256 receivedETH);
}
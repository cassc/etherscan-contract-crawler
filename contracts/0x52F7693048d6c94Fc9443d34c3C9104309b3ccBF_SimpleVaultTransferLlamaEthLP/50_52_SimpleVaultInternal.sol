// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableInternal } from '@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol';
import { ERC1155MetadataInternal } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol';
import { IERC173 } from '@solidstate/contracts/interfaces/IERC173.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC1155 } from '@solidstate/contracts/interfaces/IERC1155.sol';
import { IWETH } from '@solidstate/contracts/interfaces/IWETH.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { SimpleVaultStorage as s } from './SimpleVaultStorage.sol';
import { ISimpleVaultInternal } from './ISimpleVaultInternal.sol';
import { JPEGDLendingAdaptor as JPEGDLending } from '../adaptors/lending/JPEGDLendingAdaptor.sol';
import { NFTFILendingAdaptor as NFTFILending } from '../adaptors/lending/NFTFILendingAdaptor.sol';
import { JPEGDStakingAdaptor as JPEGDStaking } from '../adaptors/staking/JPEGDStakingAdaptor.sol';
import { SpiceFlagshipStakingAdaptor as SpiceFlagshipStaking } from '../adaptors/staking/SpiceFlagshipStakingAdaptor.sol';
import { JPEGDAdaptorStorage } from '../adaptors/storage/JPEGDAdaptorStorage.sol';
import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';
import { IDawnOfInsrt } from '../interfaces/insrt/IDawnOfInsrt.sol';
import { IWhitelist } from '../whitelist/IWhitelist.sol';

/**
 * @title SimpleVault internal functions
 * @dev inherited by all SimpleVault implementation contracts
 */
abstract contract SimpleVaultInternal is
    ISimpleVaultInternal,
    OwnableInternal,
    ERC1155BaseInternal,
    ERC1155EnumerableInternal,
    ERC1155MetadataInternal
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal immutable TREASURY;
    address internal immutable DAWN_OF_INSRT;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant LLAMA_ETH_LP =
        0x160CbD339Ec96E991c4C1b88901db8b8Df001Ed2;

    uint256 internal constant MINT_TOKEN_ID = 1;
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant DAWN_OF_INSRT_ZERO_BALANCE = type(uint256).max;
    uint256 internal constant TIER0_FEE_COEFFICIENT = 9000;
    uint256 internal constant TIER1_FEE_COEFFICIENT = 7500;
    uint256 internal constant TIER2_FEE_COEFFICIENT = 6000;
    uint256 internal constant TIER3_FEE_COEFFICIENT = 4000;
    uint256 internal constant TIER4_FEE_COEFFICIENT = 2000;

    constructor(address feeRecipient, address dawnOfInsrt) {
        TREASURY = feeRecipient;
        DAWN_OF_INSRT = dawnOfInsrt;
    }

    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    modifier onlyAuthorized() {
        _onlyAuthorized(msg.sender);
        _;
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert SimpleVault__NotProtocolOwner();
        }
    }

    function _onlyAuthorized(address account) internal view {
        if (
            account != _protocolOwner() &&
            s.layout().isAuthorized[account] == false
        ) {
            revert SimpleVault__NotAuthorized();
        }
    }

    /**
     * @notice transfers an ETH amount to the vault in exchange for ERC1155 shards of MINT_TOKEN_ID
     * @param data any encoded data required to perform whitelist check
     */
    function _deposit(bytes calldata data) internal {
        s.Layout storage l = s.layout();

        if (!l.isEnabled) {
            revert SimpleVault__NotEnabled();
        }

        uint64 maxSupply = l.maxSupply;
        uint64 maxMintBalance = l.maxMintBalance;
        uint256 balance = _balanceOf(msg.sender, MINT_TOKEN_ID);

        if (balance >= maxMintBalance) {
            revert SimpleVault__MaxMintBalance();
        }

        if (block.timestamp < l.whitelistEndsAt) {
            _enforceWhitelist(l.whitelist, msg.sender, data);
            maxSupply = l.reservedSupply;
        }

        uint256 amount = msg.value;
        uint256 shardValue = l.shardValue;
        uint256 totalSupply = _totalSupply(MINT_TOKEN_ID); //supply of token ID == 1

        if (amount % shardValue != 0 || amount == 0) {
            revert SimpleVault__InvalidDepositAmount();
        }
        if (totalSupply == maxSupply) {
            revert SimpleVault__DepositForbidden();
        }

        uint256 shards = amount / shardValue;
        uint256 excessShards;

        if (balance + shards > maxMintBalance) {
            excessShards = shards + balance - maxMintBalance;
            shards -= excessShards;
        }

        if (shards + totalSupply > maxSupply) {
            excessShards += shards + totalSupply - maxSupply;
            shards = maxSupply - totalSupply;
        }

        _mint(msg.sender, MINT_TOKEN_ID, shards, '0x');

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardValue);
        }
    }

    /**
     * @notice burn held shards before NFT acquisition and withdraw corresponding ETH
     * @param amount amount of shards to burn
     */
    function _withdraw(uint256 amount) internal {
        s.Layout storage l = s.layout();

        if (_totalSupply(MINT_TOKEN_ID) == l.maxSupply) {
            revert SimpleVault__WithdrawalForbidden();
        }

        _burn(msg.sender, MINT_TOKEN_ID, amount);
        payable(msg.sender).sendValue(amount * l.shardValue);
    }

    /**
     * @notice claims ETH and vendor token rewards for msg.sender
     * @param tokenId DAWN_OF_INSRT tokenId to claim with for discounting yield fee
     */
    function _claim(uint256 tokenId) internal {
        s.Layout storage l = s.layout();

        _updateUserRewards(msg.sender, tokenId);

        uint256 yield = l.userETHYield[msg.sender];
        delete l.userETHYield[msg.sender];

        if (l.activatedLendingAdaptors[LendingAdaptor.JPEGD]) {
            JPEGDLending.userClaim(msg.sender);
        }

        payable(msg.sender).sendValue(yield);
    }

    /**
     * @notice collateralizes an ERC721 asset on a lending vendor in exchange for lending
     * lending vendor tokens
     * @param adaptor enum indicating which lending vendor to interact with via the respective adaptor
     * @param collateralizationData encoded data needed to collateralize the ERC721 asset
     * @return amount amount of lending vendor token borrowed
     */
    function _collateralizeERC721Asset(
        LendingAdaptor adaptor,
        bytes calldata collateralizationData
    ) internal returns (uint256 amount) {
        s.Layout storage l = s.layout();
        address collection;
        uint256 tokenId;

        if (adaptor == LendingAdaptor.JPEGD) {
            uint16 ltvBufferBP = l.ltvBufferBP;
            uint16 ltvDeviationBP = l.ltvDeviationBP;

            (collection, tokenId, amount) = JPEGDLending
                .collateralizeERC721Asset(
                    collateralizationData,
                    ltvBufferBP,
                    ltvDeviationBP
                );
        }

        if (adaptor == LendingAdaptor.NFTFI) {
            (collection, tokenId, amount) = NFTFILending
                .collateralizeERC721Asset(collateralizationData);
        }

        l.collateralizedTokens[collection].add(tokenId);

        if (!l.activatedLendingAdaptors[adaptor]) {
            l.activatedLendingAdaptors[adaptor] = true;
        }

        emit ERC721AssetCollateralized(adaptor, collection, tokenId);
    }

    /**
     * @notice performs a staking sequence on a given adaptor
     * @param adaptor enum indicating which adaptor will perform staking
     * @param stakeData encoded data required in order to perform staking
     * @return shares amount of staking shares received, if any
     */
    function _stake(
        StakingAdaptor adaptor,
        bytes calldata stakeData
    ) internal returns (uint256 shares) {
        s.Layout storage l = s.layout();

        if (adaptor == StakingAdaptor.JPEGD) {
            shares = JPEGDStaking.stake(stakeData);
        }

        if (adaptor == StakingAdaptor.SPICE_FLAGSHIP) {
            shares = SpiceFlagshipStaking.stake(stakeData);
        }

        if (!l.activatedStakingAdaptors[adaptor]) {
            l.activatedStakingAdaptors[adaptor] = true;
        }

        emit Staked(adaptor, shares);
    }

    /**
     * @notice unstakes part or all of position from the protocol relating to the adaptor
     * @param adaptor adaptor to use in order to unstake
     * @param unstakeData encoded data required to perform unstaking steps
     * @return tokenAmount amount of tokens returns for unstaking
     */
    function _unstake(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) internal returns (uint256 tokenAmount) {
        if (adaptor == StakingAdaptor.JPEGD) {
            tokenAmount = JPEGDStaking.unstake(unstakeData);
        }

        if (adaptor == StakingAdaptor.SPICE_FLAGSHIP) {
            tokenAmount = SpiceFlagshipStaking.unstake(unstakeData);
        }

        emit Unstaked(adaptor, tokenAmount);
    }

    /**
     * @notice repays part or all of the loan owed to a lending vendor for a collateralized position
     * @param adaptor adaptor to use in order to repay loan
     * @param repayData encoded data required to pay back loan
     * @return paidDebt amount of debt repaid
     */
    function _repayLoan(
        LendingAdaptor adaptor,
        bytes calldata repayData
    ) internal returns (uint256 paidDebt) {
        if (adaptor == LendingAdaptor.JPEGD) {
            paidDebt = JPEGDLending.repayLoan(repayData);
        }

        if (adaptor == LendingAdaptor.NFTFI) {
            paidDebt = NFTFILending.repayLoan(repayData);
        }

        emit LoanPaymentMade(adaptor, paidDebt);
    }

    /**
     * @notice liquidates entire position in a lending vendor in order to pay back debt
     * and converts any surplus ETH and reward tokens into yield
     * @param adaptor adaptor to use in order to close position
     * @param closeData encoded data required to close lending vendor position
     * @return eth amount of ETH received after closing position
     */
    function _closePosition(
        LendingAdaptor adaptor,
        bytes calldata closeData
    ) internal returns (uint256 eth) {
        s.Layout storage l = s.layout();

        address collection;
        uint256 tokenId;

        if (adaptor == LendingAdaptor.JPEGD) {
            (eth, collection, tokenId) = JPEGDLending.closePosition(closeData);
        }

        if (adaptor == LendingAdaptor.NFTFI) {
            (eth, collection, tokenId) = NFTFILending.closePosition(closeData);
        }

        l.collateralizedTokens[collection].remove(tokenId);
        l.cumulativeETHPerShard += eth / _totalSupply(MINT_TOKEN_ID);

        emit PositionClosed(adaptor, eth);
    }

    /**
     * @notice makes loan repayment for a collateralized ERC721 asset using vault funds
     * @param adaptor adaptor to use in order to make loan repayment
     * @param directRepayData encoded data needed to directly repay loan
     */
    function _directRepayLoan(
        LendingAdaptor adaptor,
        bytes calldata directRepayData
    ) internal returns (uint256 paidDebt) {
        if (adaptor == LendingAdaptor.JPEGD) {
            paidDebt = JPEGDLending.directRepayLoan(directRepayData);
        }

        if (adaptor == LendingAdaptor.NFTFI) {
            paidDebt = NFTFILending.directRepayLoan(directRepayData);
        }

        emit LoanPaymentMade(adaptor, paidDebt);
    }

    /**
     * @notice converts part of position and/or claims rewards to provide as yield to users
     * @param adaptor adaptor to use in order liquidate convert part of position and/or claim rewards
     * @param unstakeData encoded data required in order to perform unstaking of position and reward claiming
     */
    function _provideYield(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) internal {
        s.Layout storage l = s.layout();

        TokenYield[] memory tokenYields = new TokenYield[](5);
        uint256 totalSupply = _totalSupply(MINT_TOKEN_ID);
        uint256 receivedETH;

        if (adaptor == StakingAdaptor.JPEGD) {
            uint256 receivedJPEG;
            (receivedETH, receivedJPEG) = JPEGDStaking.provideYield(
                unstakeData,
                totalSupply
            );

            tokenYields[0] = TokenYield({
                token: address(0),
                yield: receivedETH
            });
            tokenYields[1] = TokenYield({
                token: JPEGDAdaptorStorage.JPEG,
                yield: receivedJPEG
            });
        }

        if (adaptor == StakingAdaptor.SPICE_FLAGSHIP) {
            uint256 receivedWETH = SpiceFlagshipStaking.unstake(unstakeData);

            IWETH(WETH).withdraw(receivedWETH);

            receivedETH = receivedWETH;

            tokenYields[0] = TokenYield({
                token: address(0),
                yield: receivedETH
            });
        }

        l.cumulativeETHPerShard += receivedETH / totalSupply;

        if (!l.isYieldClaiming) {
            l.isYieldClaiming = true;
        }

        emit YieldProvided(adaptor, tokenYields);
    }

    /**
     * @notice transfers an ERC721 asset from the TREASURY in an "over-the-counter" (OTC) fashion
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 asset to transfer
     * @param price amount of ETH to send to TREASURY in exchange for ERC721 asset
     */
    function _transferERC721AssetOTC(
        address collection,
        uint256 tokenId,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.vaultCollections.contains(collection)) {
            revert SimpleVault__NotCollectionOfVault();
        }

        IERC721(collection).safeTransferFrom(TREASURY, address(this), tokenId);

        uint256 fee = (price * l.acquisitionFeeBP) / BASIS_POINTS;
        if (fee + price > address(this).balance) {
            revert SimpleVault__InsufficientETH();
        }

        if (_ownedTokenAmount() == 0) {
            l.maxSupply = uint64(_totalSupply(MINT_TOKEN_ID));
        }
        l.accruedFees += fee;
        l.collectionOwnedTokenIds[collection].add(tokenId);
        ++l.ownedTokenAmount;

        payable(TREASURY).sendValue(price);

        emit ERC721AssetTransferred(tokenId);
    }

    /**
     * @notice transfers an amount of ERC1155 assets from the TREASURY in an "over-the-counter" (OTC) fashion
     * @param collection address of ERC1155 collection
     * @param tokenId id of ERC155 asset to transfer
     * @param amount amount of ERC1155 assets to transfer
     * @param price amount of ETH to send to TREASURY in exchange for ERC1155 assets
     */
    function _transferERC1155AssetOTC(
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.vaultCollections.contains(collection)) {
            revert SimpleVault__NotCollectionOfVault();
        }

        IERC1155(collection).safeTransferFrom(
            TREASURY,
            address(this),
            tokenId,
            amount,
            '0x'
        );

        uint256 fee = (price * l.acquisitionFeeBP) / BASIS_POINTS;
        if (fee + price > address(this).balance) {
            revert SimpleVault__InsufficientETH();
        }

        if (_ownedTokenAmount() == 0) {
            l.maxSupply = uint64(_totalSupply(MINT_TOKEN_ID));
        }

        l.accruedFees += fee;
        l.collectionOwnedTokenIds[collection].add(tokenId);
        l.collectionOwnedTokenAmounts[collection][tokenId] += amount;
        ++l.ownedTokenAmount;

        payable(TREASURY).sendValue(price);

        emit ERC1155AssetsTransferred(tokenId, amount);
    }

    /**
     * @notice transfers a specified amount of LLAMA:ETH LP to the TREASURY
     * @param amount amount of LLAMA:ETH LP to transfer
     */
    function _transferLlamaEthLP(uint256 amount) internal {
        IERC20(LLAMA_ETH_LP).transfer(TREASURY, amount);
    }

    /**
     * @notice purchases a punk from the CryptoPunkMarket
     * @param punkMarket address of CryptoPunkMarket contract
     * @param punkId id of punk to purchase
     */
    function _purchasePunk(address punkMarket, uint256 punkId) internal {
        s.Layout storage l = s.layout();

        uint256 price = ICryptoPunkMarket(punkMarket)
            .punksOfferedForSale(punkId)
            .minValue;

        ICryptoPunkMarket(punkMarket).buyPunk{ value: price }(punkId);

        l.accruedFees += (price * l.acquisitionFeeBP) / BASIS_POINTS;
        l.collectionOwnedTokenIds[punkMarket].add(punkId);

        emit PunkPurchased(punkId);
    }

    /**
     * @notice lists a punk for sale on the CryptoPunkMarket
     * @param punkMarket CryptoPunkMarket contract address
     * @param punkId id of punk to list for sale
     * @param minValue minimum amount of ETH to accept for an instant sale
     */
    function _listPunk(
        address punkMarket,
        uint256 punkId,
        uint256 minValue
    ) internal {
        ICryptoPunkMarket(punkMarket).offerPunkForSale(punkId, minValue);

        emit PunkListed(punkId, minValue);
    }

    /**
     * @notice delists a punk listed for sale on CryptoPunkMarket
     * @param punkMarket CryptoPunkMarket contract address
     * @param punkId id of punk to delist
     */
    function _delistPunk(address punkMarket, uint256 punkId) internal {
        ICryptoPunkMarket(punkMarket).punkNoLongerForSale(punkId);

        emit PunkDelisted(punkId);
    }

    /**
     * @notice sells a punk  on the CryptoPunkMarket assuming there is an active bid on it
     * @param punkMarket CryptoPunkMarket contract address
     * @param punkId id of punk to list for sale
     * @param minValue minimum amount of ETH to accept for an instant sale
     */
    function _sellPunk(
        address punkMarket,
        uint256 punkId,
        uint256 minValue
    ) internal {
        s.Layout storage l = s.layout();

        uint256 oldBalance = address(this).balance;

        ICryptoPunkMarket(punkMarket).acceptBidForPunk(punkId, minValue);
        ICryptoPunkMarket(punkMarket).withdraw();

        uint256 proceeds = address(this).balance - oldBalance;

        l.accruedFees += (proceeds * l.saleFeeBP) / BASIS_POINTS;
        l.collectionOwnedTokenIds[punkMarket].remove(punkId);

        emit PunkSold(punkId);
        emit PunkProceedsReceived(proceeds);
    }

    /**
     * @notice receives all proceeds from punk sales on CryptoPunkMarket which were not initiated
     * by vault
     * @param punkMarket address of CryptoPunkMarket contract
     * @param punkIds array of punkIds which were sol
     */
    function _receivePunkProceeds(
        address punkMarket,
        uint256[] memory punkIds
    ) internal {
        s.Layout storage l = s.layout();

        uint256 oldBalance = address(this).balance;

        ICryptoPunkMarket(punkMarket).withdraw();

        uint256 proceeds = address(this).balance - oldBalance;

        for (uint256 i; i < punkIds.length; ++i) {
            l.collectionOwnedTokenIds[punkMarket].remove(punkIds[i]);
        }

        l.accruedFees += (proceeds * l.saleFeeBP) / BASIS_POINTS;

        emit PunkProceedsReceived(proceeds);
    }

    /**
     * @notice mark a vault owned ERC721 asset (token) as available for purchase
     * @param collection address of token collection
     * @param tokenId id of token
     * @param price sale price of token
     */
    function _markERC721AssetForSale(
        address collection,
        uint256 tokenId,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.collectionOwnedTokenIds[collection].contains(tokenId)) {
            revert SimpleVault__NotOwnedToken();
        }
        if (l.collateralizedTokens[collection].contains(tokenId)) {
            revert SimpleVault__TokenCollateralized();
        }

        l.priceOfSale[collection][tokenId] = price;

        emit TokenMarkedForSale(collection, tokenId, price);
    }

    /**
     * @notice mark vault owned ERC1155 assets (token) as available for purchase
     * @param collection address of token collection
     * @param tokenId id of tokens
     * @param amount amount of tokens
     * @param price sale price of tokens
     */
    function _markERC1155AssetsForSale(
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.collectionOwnedTokenIds[collection].contains(tokenId)) {
            revert SimpleVault__NotOwnedToken();
        }
        if (l.collateralizedTokens[collection].contains(tokenId)) {
            revert SimpleVault__TokenCollateralized();
        }

        l.priceOfSales[collection][tokenId][amount].add(price);

        emit TokensMarkedForSale(collection, tokenId, amount, price);
    }

    /**
     * @notice remove the price of sales from ERC1155 assets marked for sale
     * @param collection address of ERC1155 collection
     * @param tokenId id of ERC1155 assets
     * @param amount amount of ERC1155 assets
     * @param price price to remove
     */
    function _removeERC1155AssetsFromSale(
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.priceOfSales[collection][tokenId][amount].contains(price)) {
            revert SimpleVault__TokensNotForSale();
        }

        l.priceOfSales[collection][tokenId][amount].remove(price);

        emit TokensRemovedFromSale(collection, tokenId, amount, price);
    }

    /**
     * @notice sells an ERC721 asset (token) to msg.sender
     * @param collection collection address of token
     * @param tokenId id of token to sell
     */
    function _buyERC721Asset(address collection, uint256 tokenId) internal {
        s.Layout storage l = s.layout();
        uint256 price = l.priceOfSale[collection][tokenId];

        if (price == 0) {
            revert SimpleVault__TokenNotForSale();
        }
        if (msg.value != price) {
            revert SimpleVault__IncorrectETHReceived();
        }

        uint256 fees = (price * l.saleFeeBP) / BASIS_POINTS;
        l.accruedFees += fees;
        l.cumulativeETHPerShard += (price - fees) / _totalSupply(MINT_TOKEN_ID);
        l.collectionOwnedTokenIds[collection].remove(tokenId);
        --l.ownedTokenAmount;
        delete l.priceOfSale[collection][tokenId];

        if (_ownedTokenAmount() == 0) {
            l.isYieldClaiming = true;
        }

        IERC721(collection).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit TokenSold(collection, tokenId);
    }

    /**
     * @notice sells an amount of ERC1155  assets (token) to msg.sender
     * @param collection collection address of token
     * @param tokenId id of token to sell
     * @param amount amount of tokens to sell
     * @param price price of sales of ECR1155 assets
     */
    function _buyERC1155Assets(
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.priceOfSales[collection][tokenId][amount].contains(price)) {
            revert SimpleVault__TokensNotForSale();
        }
        if (msg.value != price) {
            revert SimpleVault__IncorrectETHReceived();
        }

        uint256 fees = (price * l.saleFeeBP) / BASIS_POINTS;
        l.accruedFees += fees;
        l.cumulativeETHPerShard += (price - fees) / _totalSupply(MINT_TOKEN_ID);
        l.collectionOwnedTokenAmounts[collection][tokenId] -= amount;

        if (l.collectionOwnedTokenAmounts[collection][tokenId] == 0) {
            --l.ownedTokenAmount;
        }

        if (_ownedTokenAmount() == 0) {
            l.isYieldClaiming = true;
        }

        l.priceOfSales[collection][tokenId][amount].remove(price);

        IERC1155(collection).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            '0x'
        );

        emit TokensSold(collection, tokenId, amount);
    }

    /**
     * @notice withdraw accrued protocol fees, and send to TREASURY address
     * @param adaptor enum indicating which adaptor to withdraw fees from
     * @return tokenFees an array of all the different fees withdrawn from the adaptor - currently supports up to 3 different tokens
     */
    function _withdrawFees(
        LendingAdaptor adaptor
    ) internal returns (TokenFee[3] memory tokenFees) {
        if (adaptor == LendingAdaptor.JPEGD) {
            tokenFees[0] = TokenFee({
                token: JPEGDAdaptorStorage.JPEG,
                fees: JPEGDLending.withdrawFees(TREASURY)
            });
        }

        if (adaptor == LendingAdaptor.DEFAULT) {
            s.Layout storage l = s.layout();

            uint256 fees = l.accruedFees;
            delete l.accruedFees;

            tokenFees[0] = TokenFee({ token: address(0), fees: fees });

            payable(TREASURY).sendValue(fees);
        }

        emit FeesWithdrawn(tokenFees);
    }

    /**
     * @notice sets the tokenURI for the MINT_TOKEN
     * @param tokenURI URI string
     */
    function _setMintTokenURI(string memory tokenURI) internal {
        _setTokenURI(MINT_TOKEN_ID, tokenURI);
    }

    /**
     * @notice sets the isEnabled flag
     * @param isEnabled boolean value
     */
    function _setIsEnabled(bool isEnabled) internal {
        s.layout().isEnabled = isEnabled;
        emit IsEnabledSet(isEnabled);
    }

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint64 maxSupply) internal {
        if (maxSupply < _totalSupply(MINT_TOKEN_ID)) {
            revert SimpleVault__MaxSupplyTooSmall();
        }
        s.layout().maxSupply = maxSupply;

        emit MaxSupplySet(maxSupply);
    }

    /**
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @param maxMintBalance new maxMintBalance value
     */
    function _setMaxMintBalance(uint64 maxMintBalance) internal {
        s.layout().maxMintBalance = maxMintBalance;
        emit MaxMintBalanceSet(maxMintBalance);
    }

    /**
     * @notice sets the whitelistEndsAt timestamp
     * @param whitelistEndsAt timestamp of whitelist end
     */
    function _setWhitelistEndsAt(uint48 whitelistEndsAt) internal {
        s.layout().whitelistEndsAt = whitelistEndsAt;
        emit WhitelistEndsAtSet(whitelistEndsAt);
    }

    /**
     * @notice sets the maximum amount of shard to be minted during whitelist
     * @param reservedSupply whitelist shard amount
     */
    function _setReservedSupply(uint64 reservedSupply) internal {
        s.Layout storage l = s.layout();

        if (l.maxSupply < reservedSupply) {
            revert SimpleVault__ExceededMaxSupply();
        }

        l.reservedSupply = reservedSupply;
        emit ReservedSupplySet(reservedSupply);
    }

    /**
     * @notice sets the sale fee BP
     * @param feeBP basis points value of fee
     */
    function _setSaleFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        s.layout().saleFeeBP = feeBP;
        emit SaleFeeSet(feeBP);
    }

    /**
     * @notice sets the acquisition fee BP
     * @param feeBP basis points value of fee
     */
    function _setAcquisitionFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        s.layout().acquisitionFeeBP = feeBP;
        emit AcquisitionFeeSet(feeBP);
    }

    /**
     * @notice sets the yield fee BP
     * @param feeBP basis poitns value of fee
     */
    function _setYieldFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        s.layout().yieldFeeBP = feeBP;
        emit YieldFeeSet(feeBP);
    }

    /**
     * @notice sets the ltvBufferBP value
     * @param bufferBP new ltvBufferBP value
     */
    function _setLTVBufferBP(uint16 bufferBP) internal {
        _enforceBasis(bufferBP);
        s.layout().ltvBufferBP = bufferBP;
        emit LTVBufferSet(bufferBP);
    }

    /**
     * @notice sets the ltvDeviationBP value
     * @param deviationBP new ltvDeviationBP value
     */
    function _setLTVDeviationBP(uint16 deviationBP) internal {
        _enforceBasis(deviationBP);
        s.layout().ltvDeviationBP = deviationBP;
        emit LTVDeviationSet(deviationBP);
    }

    /**
     * @notice grants or revokes the 'authorized' state to an account
     * @param account address of account to grant/revoke 'authorized'
     * @param isAuthorized value of 'authorized' state
     */
    function _setAuthorized(address account, bool isAuthorized) internal {
        s.layout().isAuthorized[account] = isAuthorized;
        emit AuthorizedSet(account, isAuthorized);
    }

    /**
     * @notice adds a collection to vault collections
     * @param collection address of collection to add
     */
    function _addCollection(address collection) internal {
        s.layout().vaultCollections.add(collection);
        emit CollectionAdded(collection);
    }

    /**
     * @notice removes a collection from vault collections
     * @param collection address of collection to remove
     */
    function _removeCollection(address collection) internal {
        s.layout().vaultCollections.remove(collection);
        emit CollectionRemoved(collection);
    }

    /**
     * @inheritdoc ERC1155BaseInternal
     * @notice claims rewards of both from/to accounts to ensure correct reward accounting
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0)) {
            _updateUserRewards(from, DAWN_OF_INSRT_ZERO_BALANCE);
        }

        if (to != address(0)) {
            _updateUserRewards(to, DAWN_OF_INSRT_ZERO_BALANCE);
        }
    }

    /**
     * @notice check to ensure account is whitelisted (holding a DAWN_OF_INSRT token or added to optinal mintWhitelist)
     * @param whitelist address of whitelist contract
     * @param account address to check
     * @param data any encoded data required to perform whitelist check
     */
    function _enforceWhitelist(
        address whitelist,
        address account,
        bytes calldata data
    ) internal view {
        if (
            IERC721(DAWN_OF_INSRT).balanceOf(account) == 0 &&
            !IWhitelist(whitelist).isWhitelisted(address(this), account, data)
        ) {
            revert SimpleVault__NotWhitelisted();
        }
    }

    /**
     * @notice check to ensure yield claiming is initialized
     */
    function _enforceYieldClaiming() internal view {
        if (!s.layout().isYieldClaiming) {
            revert SimpleVault__YieldClaimingForbidden();
        }
    }

    /**
     * @notice returns total fees accrued for given adaptor
     * @notice if adaptor is the default (no adaptor), then the sum of ETH fees accrued from sale, yield and acquisition is returned
     * @notice supports up to 5 different tokens and fees for each adaptor
     * @param adaptor enum indicating adaptor to check for token fees
     * @return tokenFees total token fees accrued for given adaptor
     */
    function _accruedFees(
        LendingAdaptor adaptor
    ) internal view returns (TokenFee[5] memory tokenFees) {
        if (adaptor == LendingAdaptor.DEFAULT) {
            tokenFees[0] = TokenFee({
                token: address(0),
                fees: s.layout().accruedFees
            });
        }

        if (adaptor == LendingAdaptor.JPEGD) {
            tokenFees[0] = TokenFee({
                token: JPEGDAdaptorStorage.JPEG,
                fees: JPEGDLending.accruedJPEGFees()
            });
        }
    }

    /**
     * @notice returns acquisition fee BP
     * @return feeBP basis points of acquisition fee
     */
    function _acquisitionFeeBP() internal view returns (uint16 feeBP) {
        feeBP = s.layout().acquisitionFeeBP;
    }

    /**
     * @notice returns sale fee BP
     * @return feeBP basis points of sale fee
     */
    function _saleFeeBP() internal view returns (uint16 feeBP) {
        feeBP = s.layout().saleFeeBP;
    }

    /**
     * @notice returns yield fee BP
     * @return feeBP basis points of yield fee
     */
    function _yieldFeeBP() internal view returns (uint16 feeBP) {
        feeBP = s.layout().yieldFeeBP;
    }

    /**
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @return maxMint maxMintBalance value
     */
    function _maxMintBalance() internal view returns (uint64 maxMint) {
        maxMint = s.layout().maxMintBalance;
    }

    /**
     * @notice returns underlying collection address
     * @return collections addresses of underlying collection
     */
    function _vaultCollections()
        internal
        view
        returns (address[] memory collections)
    {
        collections = s.layout().vaultCollections.toArray();
    }

    /**
     * @notice return array with owned token IDs of a vault collection
     * @param collection address of collection to query ownedTokenIds for
     * @return tokenIds  array of owned token IDs in collecion
     */
    function _collectionOwnedTokenIds(
        address collection
    ) internal view returns (uint256[] memory tokenIds) {
        tokenIds = s.layout().collectionOwnedTokenIds[collection].toArray();
    }

    /**
     * @notice return amount of tokens of a particular ERC1155 collection owned by vault
     * @param collection address of ERC1155 collection
     * @param tokenId tokenId to check
     * @return amount amount of tokens owned by vault
     */
    function _collectionOwnedTokenAmounts(
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 amount) {
        amount = s.layout().collectionOwnedTokenAmounts[collection][tokenId];
    }

    /**
     * @notice returns total number of NFTs owned across collections
     * @return amount total number of NFTs owned across collections
     */
    function _ownedTokenAmount() internal view returns (uint32 amount) {
        amount = s.layout().ownedTokenAmount;
    }

    /**
     * @notice return price of sale for a vault ERC721 token
     * @param collection collection address of token
     * @param tokenId id of token marked for sale
     * @return price price of token marked for sale
     */
    function _priceOfSale(
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 price) {
        price = s.layout().priceOfSale[collection][tokenId];
    }

    /**
     * @notice return prices of sales for an amount of vault owned ECR1155 tokens
     * @param collection collection address of token
     * @param tokenId id of token
     * @param amount amount of tokens marked for sale
     * @return prices prices of tokens marked for sale
     */
    function _priceOfSales(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) internal view returns (uint256[] memory prices) {
        prices = s.layout().priceOfSales[collection][tokenId][amount].toArray();
    }

    /**
     * @notice returns isEnabled status of vault deposits
     * @return status status of isEnabled
     */
    function _isEnabled() internal view returns (bool status) {
        status = s.layout().isEnabled;
    }

    /**
     * @notice returns the yield claiming status of the vault
     * @return status the yield claiming status of the vault
     */
    function _isYieldClaiming() internal view returns (bool status) {
        status = s.layout().isYieldClaiming;
    }

    /**
     * @notice returns timestamp of whitelist end
     * @return endTimestamp timestamp of whitelist end
     */
    function _whitelistEndsAt() internal view returns (uint48 endTimestamp) {
        endTimestamp = s.layout().whitelistEndsAt;
    }

    /**
     * @notice returns treasury address
     * @return feeRecipient address of treasury
     */
    function _treasury() internal view returns (address feeRecipient) {
        feeRecipient = TREASURY;
    }

    /**
     * @notice returns ETH value of a shard
     * @return shardETHValue ETH value of a shard
     */
    function _shardValue() internal view returns (uint256 shardETHValue) {
        shardETHValue = s.layout().shardValue;
    }

    /**
     * @notice return isInvested flag state indicating whether an asset has been purchased
     * @return status isInvested flag
     */
    function _isInvested() internal view returns (bool status) {
        if (_ownedTokenAmount() != 0) {
            status = true;
        }
    }

    /**
     * @notice returns maximum possible minted shards
     * @return supply maximum possible minted shards
     */
    function _maxSupply() internal view returns (uint64 supply) {
        supply = s.layout().maxSupply;
    }

    /**
     * @notice return amount of shards reserved for whitelist
     * @return supply amount of shards reserved for whitelist
     */
    function _reservedSupply() internal view returns (uint64 supply) {
        supply = s.layout().reservedSupply;
    }

    /**
     * @notice returns the address of the whitelist proxy
     * @return proxy whitelist proxy address
     */
    function _whitelist() internal view returns (address proxy) {
        proxy = s.layout().whitelist;
    }

    /**
     * @notice returns the cumulative ETH and tokens accrued per shard attained by the vault
     * @notice sum of all yield provided / totalSupply(MINT_TOKEN_ID)
     * @return ethPerShard cumulative ETH per shard attained by the vault
     * @return tokensPerShard array of amount of tokens yielded from vendors per shard
     */
    function _cumulativeTokensPerShard()
        internal
        view
        returns (uint256 ethPerShard, TokensPerShard[10] memory tokensPerShard)
    {
        s.Layout storage l = s.layout();

        ethPerShard = l.cumulativeETHPerShard;

        if (l.activatedLendingAdaptors[LendingAdaptor.JPEGD]) {
            tokensPerShard[0].token = JPEGDAdaptorStorage.JPEG;
            tokensPerShard[0].cumulativeAmount = JPEGDLending
                .cumulativeJPEGPerShard();
        }
    }

    /**
     * @notice returns the tokenIds of collateralized tokens for a collection
     * @param collection ERC721 collection address
     * @return tokens array of collateralized tokenIds
     */
    function _collateralizedTokens(
        address collection
    ) internal view returns (uint256[] memory tokens) {
        tokens = s.layout().collateralizedTokens[collection].toArray();
    }

    /**
     * @notice returns the total ETH and token yields from vendors an account may claim
     * @notice supports a total of 10 different tokens and their yields accross all adaptors
     * @param account account address
     * @param tokenId DOI tokenId used for yield fee discounting
     * @return yield total ETH yield claimable
     * @return tokenYields array of token yields available to user to claim
     */
    function _userRewards(
        address account,
        uint256 tokenId
    ) internal view returns (uint256 yield, TokenYield[10] memory tokenYields) {
        s.Layout storage l = s.layout();

        uint16 yieldFeeBP = _discountYieldFeeBP(account, tokenId, l.yieldFeeBP);
        uint256 shards = _balanceOf(account, MINT_TOKEN_ID);
        uint256 yieldPerShard = l.cumulativeETHPerShard -
            l.ethDeductionsPerShard[account];

        uint256 unclaimedYield = yieldPerShard * shards;
        uint256 yieldFee = (unclaimedYield * yieldFeeBP) / BASIS_POINTS;

        yield = l.userETHYield[account] + unclaimedYield - yieldFee;

        if (l.activatedLendingAdaptors[LendingAdaptor.JPEGD]) {
            tokenYields[0].token = JPEGDAdaptorStorage.JPEG;
            tokenYields[0].yield = JPEGDLending.userRewards(
                account,
                shards,
                yieldFeeBP
            );
        }
    }

    /**
     * @notice returns either interest debt or total debt on a given protocol
     * @param adaptor adaptor to query debt on
     * @param queryData encoded data required to query the debt
     * @return debt either total debt or debt interest
     */
    function _queryDebt(
        LendingAdaptor adaptor,
        bytes calldata queryData
    ) internal view returns (uint256 debt) {
        if (adaptor == LendingAdaptor.JPEGD) {
            debt = JPEGDLending.queryDebt(queryData);
        }

        if (adaptor == LendingAdaptor.NFTFI) {
            debt = NFTFILending.queryDebt(queryData);
        }
    }

    /**
     * @notice returns the activity status of an adaptor
     * @return status bool indicating whether an adaptor is active
     */
    function _isLendingAdaptorActive(
        LendingAdaptor adaptor
    ) internal view returns (bool status) {
        status = adaptor == LendingAdaptor.DEFAULT
            ? true
            : s.layout().activatedLendingAdaptors[adaptor];
    }

    /**
     * @notice returns the activity status of an adaptor
     * @return status bool indicating whether an adaptor is active
     */
    function _isStakingAdaptorActive(
        StakingAdaptor adaptor
    ) internal view returns (bool status) {
        status = adaptor == StakingAdaptor.DEFAULT
            ? true
            : s.layout().activatedStakingAdaptors[adaptor];
    }

    /**
     * @notice returns isAuthorized status of a given account
     * @param account address of account to check
     * @return status boolean indicating whether account is authorized
     */
    function _isAuthorized(
        address account
    ) internal view returns (bool status) {
        status = s.layout().isAuthorized[account];
    }

    /**
     * @notice returns the loan-to-value buffer in basis points
     * @return bufferBP loan-to-value buffer in basis points
     */
    function _ltvBufferBP() internal view returns (uint16 bufferBP) {
        bufferBP = s.layout().ltvBufferBP;
    }

    /**
     * @notice returns the loan-to-value deviation in basis points
     * @return deviationBP loan-to-value deviation in basis points
     */
    function _ltvDeviationBP() internal view returns (uint16 deviationBP) {
        deviationBP = s.layout().ltvDeviationBP;
    }

    /**
     * @notice returns the tokenId assigned to MINT_TOKEN
     * @return tokenId tokenId assigned to MINT_TOKEN
     */
    function _mintTokenId() internal pure returns (uint256 tokenId) {
        tokenId = MINT_TOKEN_ID;
    }

    /**
     * @notice enforces that a value cannot exceed BASIS_POINTS
     * @param value the value to check
     */
    function _enforceBasis(uint16 value) internal pure {
        if (value > BASIS_POINTS) revert SimpleVault__BasisExceeded();
    }

    /**
     * @notice records yield of an account without performing ETH/token transfers
     * @dev type(unit256).max is used to indicate no DAWN_OF_INSRT token is being used for fee deductions
     * @param account account address to record for
     * @param tokenId DAWN_OF_INSRT tokenId
     */
    function _updateUserRewards(address account, uint256 tokenId) private {
        s.Layout storage l = s.layout();

        uint256 yieldPerShard = l.cumulativeETHPerShard -
            l.ethDeductionsPerShard[account];

        uint256 shards = _balanceOf(account, MINT_TOKEN_ID);
        uint16 yieldFeeBP = _discountYieldFeeBP(account, tokenId, l.yieldFeeBP);

        if (yieldPerShard > 0) {
            uint256 totalYield = yieldPerShard * shards;
            uint256 fee = (totalYield * yieldFeeBP) / BASIS_POINTS;

            l.ethDeductionsPerShard[account] += yieldPerShard;
            l.accruedFees += fee;
            l.userETHYield[account] += totalYield - fee;
        }

        if (l.activatedLendingAdaptors[LendingAdaptor.JPEGD]) {
            JPEGDLending.updateUserRewards(account, shards, yieldFeeBP);
        }
    }

    /**
     * @notice applies a discount on yield fee
     * @param account address to check for discount
     * @param tokenId Dawn of Insrt token Id
     * @param rawYieldFeeBP the undiscounted yield fee in basis points
     */
    function _discountYieldFeeBP(
        address account,
        uint256 tokenId,
        uint16 rawYieldFeeBP
    ) private view returns (uint16 yieldFeeBP) {
        if (tokenId == DAWN_OF_INSRT_ZERO_BALANCE) {
            yieldFeeBP = rawYieldFeeBP;
        } else {
            if (account != IERC721(DAWN_OF_INSRT).ownerOf(tokenId)) {
                revert SimpleVault__NotDawnOfInsrtTokenOwner();
            }
            uint8 tier = IDawnOfInsrt(DAWN_OF_INSRT).tokenTier(tokenId);

            uint256 discount;
            if (tier == 0) {
                discount = TIER0_FEE_COEFFICIENT;
            } else if (tier == 1) {
                discount = TIER1_FEE_COEFFICIENT;
            } else if (tier == 2) {
                discount = TIER2_FEE_COEFFICIENT;
            } else if (tier == 3) {
                discount = TIER3_FEE_COEFFICIENT;
            } else {
                discount = TIER4_FEE_COEFFICIENT;
            }

            yieldFeeBP = uint16((rawYieldFeeBP * discount) / BASIS_POINTS);
        }
    }
}
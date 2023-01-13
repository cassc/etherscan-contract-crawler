/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./assets/LibAsset.sol";
import "../tokens/ERC721/ERC721Luxy.sol";
import "../tokens/ERC1155/ERC1155Luxy.sol";
import "./LibFill.sol";
import "./lib/LibFeeSide.sol";
import "./interfaces/ITransferManager.sol";
import "./interfaces/ITransferExecutor.sol";
import "./orderControl/LibOrderData.sol";
import "./lib/LibBP.sol";
import "./orderControl/LibOrderDataV1.sol";
import "../Royalties-registry/IRoyaltiesProvider.sol";
import "../LibsDiscount.sol";

abstract contract LuxyTransferManager is OwnableUpgradeable, ITransferManager {
    using LibBP for uint256;
    using SafeMathUpgradeable for uint256;
    uint256 public protocolFee;
    IRoyaltiesProvider public royaltiesRegistry;
    address public defaultFeeReceiver;
    uint256 public maxPercentRoyalties;
    mapping(address => address) public feeReceivers;
    mapping(address => uint256) public protocolFeeMake;
    mapping(address => uint256) public protocolFeeTake;
    mapping(address => bool) public protocolFeeSet;
    address public tierToken;
    LibTier.Tier[] public tiers;
    LibNFTHolder.NFTHolder[] public nftHolders;
    struct Fee {
        uint256 maker;
        uint256 taker;
        address token;
        address token2;
    }

    function __LuxyTransferManager_init_unchained(
        uint256 newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) internal initializer {
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;
        royaltiesRegistry = newRoyaltiesProvider;
        maxPercentRoyalties = 98000;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
        external
        onlyOwner
    {
        royaltiesRegistry = newRoyaltiesRegistry;
    }

    function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
        protocolFee = newProtocolFee;
    }

    function setMaxPercentRoyalties(uint256 newPercentage) external onlyOwner {
        maxPercentRoyalties = newPercentage;
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
        external
        onlyOwner
    {
        require(
            newDefaultFeeReceiver != address(0),
            "Default receiving address must be different than 0"
        );
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function setSpecialProtocolFee(
        address token,
        uint256 newProtocolFeeMake,
        uint256 newProtocolFeeTake
    ) external onlyOwner {
        protocolFeeMake[token] = newProtocolFeeMake;
        protocolFeeTake[token] = newProtocolFeeTake;
        protocolFeeSet[token] = true;
    }

    function setMakeProtocolFee(address token, uint256 newProtocolFeeMake)
        external
        onlyOwner
    {
        protocolFeeMake[token] = newProtocolFeeMake;
        protocolFeeSet[token] = true;
    }

    function setTakeProtocolFee(address token, uint256 newProtocolFeeTake)
        external
        onlyOwner
    {
        protocolFeeTake[token] = newProtocolFeeTake;
        protocolFeeSet[token] = true;
    }

    function setFeeReceiver(address token, address wallet) external onlyOwner {
        feeReceivers[token] = wallet;
    }

    function setNFTHolder(address token, uint96 percentual) external onlyOwner {
        require(
            token != address(0),
            "NFT contract address for holder must be different than 0"
        );
        for (uint256 i = 0; i < nftHolders.length; i++) {
            if (nftHolders[i].token == token) {
                nftHolders[i].percentual = percentual;
                return;
            }
        }
        LibNFTHolder.NFTHolder memory newToken;
        newToken.token = token;
        newToken.percentual = percentual;
        nftHolders.push(newToken);
    }

    function removeNFTHolder(address token) external onlyOwner {
        for (uint256 i = 0; i < nftHolders.length; i++) {
            if (nftHolders[i].token == token) {
                delete nftHolders[i];
                break;
            }
        }
    }

    function setTiers(LibTier.Tier[] memory _tiers) external onlyOwner {
        require(
            tierToken != address(0),
            "You must first set address of the tierToken at setTierToken"
        );
        for (uint256 i = 0; i < tiers.length; i++) {
            delete tiers[i];
        }
        for (uint256 i = 0; i < _tiers.length; i++) {
            require(
                _tiers[i].value >= 0,
                "Value can't be negative for tiers amount"
            );
            require(
                _tiers[i].percentual >= 0,
                "Percentual of Protocol Fee must be greater or equal to zero"
            );
            tiers.push(_tiers[i]);
        }
    }

    function setTierToken(address _token) external onlyOwner {
        require(_token != address(0), "Tier Token can't be address(0)");
        tierToken = _token;
    }

    function getUserTier(address account) public view returns (uint256) {
        if (tierToken == address(0)) {
            return 200;
        }
        IERC20Upgradeable token = IERC20Upgradeable(tierToken);
        uint256 balance = token.balanceOf(account);
        uint256 feepercentual = 200;
        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i].value <= balance) {
                if (tiers[i].percentual <= feepercentual) {
                    feepercentual = tiers[i].percentual;
                }
            }
        }
        return feepercentual;
    }

    function getHolderDiscount(address account) public view returns (uint256) {
        uint256 discount = 200;

        for (uint256 i = 0; i < nftHolders.length; i++) {
            if (nftHolders[i].token != address(0)) {
                if (
                    IERC721Upgradeable(nftHolders[i].token).balanceOf(account) >
                    0
                ) {
                    discount = nftHolders[i].percentual;
                }
            }
        }
        return discount;
    }

    function getFeeReceiver(address token) internal view returns (address) {
        address wallet = feeReceivers[token];
        if (wallet != address(0)) {
            return wallet;
        }
        return defaultFeeReceiver;
    }

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder
    )
        internal
        override
        returns (uint256 totalMakeValue, uint256 totalTakeValue)
    {
        LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(
            makeMatch.assetClass,
            takeMatch.assetClass
        );
        totalMakeValue = fill.makeValue;
        totalTakeValue = fill.takeValue;
        LibOrderDataV1.DataV1 memory leftOrderData = LibOrderData.parse(
            leftOrder
        );
        LibOrderDataV1.DataV1 memory rightOrderData = LibOrderData.parse(
            rightOrder
        );
        if (feeSide == LibFeeSide.FeeSide.MAKE) {
            totalMakeValue = doTransfersWithFees(
                fill.makeValue,
                (leftOrder.maker == address(0)) ? _msgSender() : leftOrder.maker,
                (rightOrder.maker == address(0)) ? _msgSender() : rightOrder.maker,
                rightOrderData,
                makeMatch,
                takeMatch,
                TO_TAKER
            );
            transferPayouts(
                takeMatch,
                fill.takeValue,
                (rightOrder.maker == address(0)) ? _msgSender() : rightOrder.maker,
                leftOrderData.payouts,
                TO_MAKER
            );
        } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
            totalTakeValue = doTransfersWithFees(
                fill.takeValue,
                (rightOrder.maker == address(0)) ? _msgSender() : rightOrder.maker,
                (leftOrder.maker == address(0)) ? _msgSender() : leftOrder.maker,
                leftOrderData,
                takeMatch,
                makeMatch,
                TO_MAKER
            );
            transferPayouts(
                makeMatch,
                fill.makeValue,
                (leftOrder.maker == address(0)) ? _msgSender() : leftOrder.maker,
                rightOrderData.payouts,
                TO_TAKER
            );
        } else {
            transferPayouts(
                makeMatch,
                fill.makeValue,
                (leftOrder.maker == address(0)) ? _msgSender() : leftOrder.maker,
                rightOrderData.payouts,
                TO_TAKER
            );
            transferPayouts(
                takeMatch,
                fill.takeValue,
                (rightOrder.maker == address(0)) ? _msgSender() : rightOrder.maker,
                leftOrderData.payouts,
                TO_MAKER
            );
        }
    }

    function doTransfersWithFees(
        uint256 amount,
        address from,
        address to,
        LibOrderDataV1.DataV1 memory dataNft,
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        bytes4 transferDirection
    ) internal returns (uint256 totalAmount) {
        uint256[2] memory specialFee;
        bool isEspecialFee;
        (totalAmount, specialFee, isEspecialFee) = calculateTotalAmount(
            amount,
            from,
            to,
            protocolFee,
            matchNft,
            matchCalculate,
            transferDirection
        );
        uint256 rest = transferProtocolFee(
            totalAmount,
            specialFee,
            isEspecialFee,
            amount,
            from,
            matchCalculate,
            transferDirection
        );
        rest = transferRoyalties(
            matchCalculate,
            matchNft,
            rest,
            amount,
            from,
            transferDirection
        );
        transferPayouts(
            matchCalculate,
            rest,
            from,
            dataNft.payouts,
            transferDirection
        );
    }

    function transferProtocolFee(
        uint256 totalAmount,
        uint256[2] memory specialFee,
        bool isEspecialFee,
        uint256 amount,
        address from,
        LibAsset.AssetType memory matchCalculate,
        bytes4 transferDirection
    ) internal returns (uint256) {
        uint256 rest;
        uint256 fee;
        if (!isEspecialFee) {
            (rest, fee) = subFeeInBp(totalAmount, amount, protocolFee.mul(2));
        } else {
            (rest, fee) = subFeeInBp(
                totalAmount,
                amount,
                specialFee[0].add(specialFee[1])
            );
        }
        if (fee > 0) {
            address tokenAddress = address(0);
            if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
                tokenAddress = abi.decode(matchCalculate.data, (address));
            } else if (
                matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS
            ) {
                uint256 tokenId;
                (tokenAddress, tokenId) = abi.decode(
                    matchCalculate.data,
                    (address, uint256)
                );
            }

            transfer(
                LibAsset.Asset(matchCalculate, fee),
                from,
                getFeeReceiver(tokenAddress),
                transferDirection,
                PROTOCOL
            );
        }
        return rest;
    }

    function transferRoyalties(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        uint256 rest,
        uint256 amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint256) {
        LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

        (uint256 result, uint256 totalRoyalties) = transferFees(
            matchCalculate,
            rest,
            amount,
            fees,
            from,
            transferDirection,
            ROYALTY
        );
        require(
            totalRoyalties <= maxPercentRoyalties,
            "Royalties are too high (>98%)"
        );
        return result;
    }

    function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
        internal
        returns (LibPart.Part[] memory)
    {
        if (
            matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS ||
            matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                matchNft.data,
                (address, uint256)
            );
            return royaltiesRegistry.getRoyalties(token, tokenId);
        }
        LibPart.Part[] memory empty;
        return empty;
    }

    function transferFees(
        LibAsset.AssetType memory matchCalculate,
        uint256 rest,
        uint256 amount,
        LibPart.Part[] memory fees,
        address from,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal returns (uint256 restValue, uint256 totalFees) {
        totalFees = 0;
        restValue = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );
            restValue = newRestValue;
            if (feeValue > 0) {
                transfer(
                    LibAsset.Asset(matchCalculate, feeValue),
                    from,
                    fees[i].account,
                    transferDirection,
                    transferType
                );
            }
        }
    }

    function transferPayouts(
        LibAsset.AssetType memory matchCalculate,
        uint256 amount,
        address from,
        LibPart.Part[] memory payouts,
        bytes4 transferDirection
    ) internal {
        uint256 sumBps = 0;
        uint256 restValue = amount;
        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint256 currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                restValue = restValue.sub(currentAmount);
                transfer(
                    LibAsset.Asset(matchCalculate, currentAmount),
                    from,
                    payouts[i].account,
                    transferDirection,
                    PAYOUT
                );
            }
        }
        LibPart.Part memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(sumBps == 10000, "Sum payouts Bps not equal 100%");
        if (restValue > 0) {
            transfer(
                LibAsset.Asset(matchCalculate, restValue),
                from,
                lastPayout.account,
                transferDirection,
                PAYOUT
            );
        }
    }

    function calculateTotalAmount(
        uint256 amount,
        address from,
        address to,
        uint256 feeOnTopBp,
        LibAsset.AssetType memory matchNft,
        LibAsset.AssetType memory matchCalculate,
        bytes4 transferDirection
    )
        internal
        view
        returns (
            uint256 total,
            uint256[2] memory specialFee,
            bool isSpecialFee
        )
    {
        Fee memory discountFee;
        discountFee.maker = getUserTier(from);
        discountFee.taker = getUserTier(to);

        if (transferDirection == TO_MAKER) {
            if (discountFee.maker > getHolderDiscount(from)) {
                discountFee.maker = getHolderDiscount(from);
            }
            if (discountFee.taker > getHolderDiscount(to)) {
                discountFee.taker = getHolderDiscount(to);
            }
        } else {
            discountFee.maker = getUserTier(to);
            discountFee.taker = getUserTier(from);
            if (discountFee.maker > getHolderDiscount(to)) {
                discountFee.maker = getHolderDiscount(to);
            }
            if (discountFee.taker > getHolderDiscount(from)) {
                discountFee.taker = getHolderDiscount(from);
            }
        }
        discountFee.token2 = address(0);
        discountFee.token = abi.decode(matchNft.data, (address));
        if (LibAsset.ETH_ASSET_CLASS != matchCalculate.assetClass) {
            (discountFee.token2) = abi.decode(matchCalculate.data, (address));
        }
        if (
            protocolFeeSet[discountFee.token] &&
            protocolFeeSet[discountFee.token2]
        ) {
            uint256 totalFeeToken = protocolFeeMake[discountFee.token].add(
                protocolFeeTake[discountFee.token]
            );
            uint256 totalFeeToken2 = protocolFeeMake[discountFee.token2].add(
                protocolFeeTake[discountFee.token2]
            );

            if (totalFeeToken > totalFeeToken2) {
                specialFee[0] = (protocolFeeMake[discountFee.token2]);
                specialFee[1] = (protocolFeeTake[discountFee.token2]);
                isSpecialFee = true;
            } else {
                specialFee[0] = (protocolFeeMake[discountFee.token]);
                specialFee[1] = (protocolFeeTake[discountFee.token]);
                isSpecialFee = true;
            }
        } else if (protocolFeeSet[discountFee.token]) {
            specialFee[0] = (protocolFeeMake[discountFee.token]);
            specialFee[1] = (protocolFeeTake[discountFee.token]);
            isSpecialFee = true;
        } else if (protocolFeeSet[discountFee.token2]) {
            specialFee[0] = (protocolFeeMake[discountFee.token2]);
            specialFee[1] = (protocolFeeTake[discountFee.token2]);
            isSpecialFee = true;
        }

        if (!isSpecialFee) {
            if (
                discountFee.maker < feeOnTopBp || discountFee.taker < feeOnTopBp
            ) {
                isSpecialFee = true;
                specialFee[0] = (discountFee.maker);
                specialFee[1] = (discountFee.taker);
                total = amount.add(
                    amount.bp(
                        transferDirection == TO_MAKER
                            ? specialFee[0]
                            : specialFee[1]
                    )
                );
            } else {
                total = amount.add(amount.bp(feeOnTopBp));
            }
        } else {
            if (specialFee[0] > discountFee.maker) {
                specialFee[0] = discountFee.maker;
            }
            if (specialFee[1] > discountFee.taker) {
                specialFee[1] = discountFee.taker;
            }
            total = amount.add(
                amount.bp(
                    transferDirection == TO_MAKER
                        ? specialFee[0]
                        : specialFee[1]
                )
            );
        }
    }

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    uint256[50] private __gap;
}
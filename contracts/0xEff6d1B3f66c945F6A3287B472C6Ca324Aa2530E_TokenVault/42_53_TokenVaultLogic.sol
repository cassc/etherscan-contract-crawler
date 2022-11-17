pragma solidity ^0.8.0;

import {Address} from "../openzeppelin/utils/Address.sol";
import {ClonesUpgradeable} from "../openzeppelin/upgradeable/proxy/ClonesUpgradeable.sol";
import {Errors} from "./../helpers/Errors.sol";
import {TransferHelper} from "./../helpers/TransferHelper.sol";
import {ECDSA} from "./../openzeppelin/cryptography/ECDSA.sol";
import {IERC20} from "./../openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "./../openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "./../openzeppelin/token/ERC1155/IERC1155.sol";
import {AddressUpgradeable} from "../openzeppelin/upgradeable/utils/AddressUpgradeable.sol";
import {ISettings} from "../../interfaces/ISettings.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {StringsUpgradeable} from "../openzeppelin/upgradeable/utils/StringsUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "../openzeppelin/upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {TokenVaultTreasuryLogic} from "./TokenVaultTreasuryLogic.sol";

library TokenVaultLogic {
    using ECDSA for bytes32;
    using StringsUpgradeable for uint256;

    function newBnftInstance(
        address settings,
        address vaultToken,
        address firstToken,
        uint256 firstId
    ) external returns (address) {
        string memory name = string(
            abi.encodePacked(
                IERC721MetadataUpgradeable(firstToken).name(),
                " #",
                firstId.toString()
            )
        );
        string memory symbol = string(
            abi.encodePacked(
                IERC721MetadataUpgradeable(firstToken).symbol(),
                firstId.toString()
            )
        );
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,string,string)",
            vaultToken,
            name,
            symbol
        );
        address bnft = ClonesUpgradeable.clone(ISettings(settings).bnftTpl());
        Address.functionCall(bnft, _initializationCalldata);
        return bnft;
    }

    function getUpdateUserPrice(DataTypes.VaultGetUpdateUserPrice memory params)
        external
        view
        returns (uint256, uint256)
    {
        address settings = params.settings;
        uint256 votingTokens = params.votingTokens;
        uint256 exitTotal = params.exitTotal;
        uint256 exitPrice = params.exitPrice;
        uint256 newPrice = params.newPrice;
        uint256 oldPrice = params.oldPrice;
        uint256 weight = params.weight;
        require(
            exitPrice == 0 ||
                (newPrice <=
                    ((exitPrice * ISettings(settings).maxExitFactor()) /
                        10000) &&
                    newPrice >=
                    ((exitPrice * ISettings(settings).minExitFactor()) /
                        10000)),
            Errors.VAULT_PRICE_INVALID
        );
        require(newPrice != oldPrice, Errors.VAULT_PRICE_INVALID);
        if (votingTokens == 0) {
            votingTokens = weight;
            exitTotal = weight * newPrice;
        }
        // they are the only one voting
        else if (weight == votingTokens && oldPrice != 0) {
            exitTotal = weight * newPrice;
        }
        // previously they were not voting
        else if (oldPrice == 0) {
            votingTokens += weight;
            exitTotal += weight * newPrice;
        }
        // they no longer want to vote
        else if (newPrice == 0) {
            votingTokens -= weight;
            exitTotal -= weight * oldPrice;
        }
        // they are updating their vote
        else {
            exitTotal = exitTotal + (weight * newPrice) - (weight * oldPrice);
        }

        return (votingTokens, exitTotal);
    }

    function getBeforeTokenTransferUserPrice(
        DataTypes.VaultGetBeforeTokenTransferUserPriceParams memory params
    ) external pure returns (uint256, uint256) {
        uint256 votingTokens = params.votingTokens;
        uint256 exitTotal = params.exitTotal;
        uint256 fromPrice = params.fromPrice;
        uint256 toPrice = params.toPrice;
        uint256 amount = params.amount;
        // only do something if users have different exit price
        if (toPrice != fromPrice) {
            // new holdPriceer is not a voter
            if (toPrice == 0) {
                // get the average exit price ignoring the senders amount
                votingTokens -= amount;
                exitTotal -= amount * fromPrice;
            }
            // oldPrice holdPriceer is not a voter
            else if (fromPrice == 0) {
                votingTokens += amount;
                exitTotal += amount * toPrice;
            }
            // both holdPriceers are voters
            else {
                exitTotal =
                    exitTotal +
                    (amount * toPrice) -
                    (amount * fromPrice);
            }
        }
        return (votingTokens, exitTotal);
    }

    event ProposalETHTransfer(
        address msgSender,
        address recipient,
        uint256 amount
    );

    event ProposalTargetCall(
        address msgSender,
        address target,
        uint256 value,
        bytes data
    );

    event AdminTargetCall(
        address msgSender,
        address target,
        uint256 value,
        bytes data,
        uint256 nonce
    );

    function proposalETHTransfer(
        DataTypes.VaultProposalETHTransferParams memory params
    ) external {
        address msgSender = params.msgSender;
        address government = params.government;
        address recipient = params.recipient;
        uint256 amount = params.amount;
        require(government == msgSender, Errors.VAULT_NOT_GOVERNOR);
        TransferHelper.safeTransferETH(recipient, amount);
        emit ProposalETHTransfer(params.msgSender, recipient, amount);
    }

    function proposalTargetCall(
        DataTypes.VaultProposalTargetCallParams memory params
    ) external {
        require(
            _proposalTargetCallValid(
                DataTypes.VaultProposalTargetCallValidParams({
                    msgSender: params.msgSender,
                    vaultToken: params.vaultToken,
                    government: params.government,
                    treasury: params.treasury,
                    staking: params.staking,
                    exchange: params.exchange,
                    target: params.target,
                    data: params.data
                })
            ),
            Errors.VAULT_NOT_TARGET_CALL
        );
        AddressUpgradeable.functionCallWithValue(
            params.target,
            params.data,
            params.value
        );
        if (params.isAdmin) {
            emit AdminTargetCall(
                params.msgSender,
                params.target,
                params.value,
                params.data,
                params.nonce
            );
        } else {
            emit ProposalTargetCall(
                params.msgSender,
                params.target,
                params.value,
                params.data
            );
        }
    }

    function proposalTargetCallValid(
        DataTypes.VaultProposalTargetCallValidParams memory params
    ) external view returns (bool) {
        return _proposalTargetCallValid(params);
    }

    function _proposalTargetCallValid(
        DataTypes.VaultProposalTargetCallValidParams memory params
    ) internal view returns (bool) {
        if (
            params.target == params.vaultToken ||
            params.target == params.government ||
            params.target == params.treasury ||
            params.target == params.staking ||
            params.target == params.exchange
        ) return false;
        for (
            uint256 i = 0;
            i < IVault(params.vaultToken).listTokensLength();
            i++
        ) {
            if (params.target == IVault(params.vaultToken).listTokens(i)) {
                return false;
            }
        }
        return true;
    }

    function verifyTargetCallSignature(
        address msgSender,
        address vaultToken,
        address target,
        bytes calldata data,
        uint256 nonce,
        address signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(msgSender, vaultToken, target, data, nonce)
        );
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        return ethSignedMessageHash.recover(signature) == signer;
    }

    function calculateRequestValue(
        uint256 bidPrice,
        uint256 totalBalance,
        uint256 userBalance,
        uint256 exitFeeForCuratorPercentage,
        uint256 exitFeeForPlatformPercentage
    ) internal pure returns (uint256) {
        return
            (bidPrice *
                (totalBalance -
                    userBalance +
                    ((userBalance *
                        (exitFeeForCuratorPercentage +
                            exitFeeForPlatformPercentage)) / 10000))) /
            totalBalance;
    }

    function start(
        address msgSender,
        address vaultAddress,
        uint256 bidPrice,
        uint256 reqValue
    )
        external
        returns (
            uint256 auctionEnd,
            DataTypes.State auctionState,
            address winning,
            uint256 bidHoldInETH,
            uint256 bidHoldInToken,
            uint256 livePrice
        )
    {
        IVault vault = IVault(vaultAddress);
        ISettings settings = ISettings(vault.settings());
        require(bidPrice > 0, Errors.VAULT_BID_PRICE_ZERO);
        require(
            vault.auctionState() == DataTypes.State.inactive,
            Errors.VAULT_STATE_INVALID
        );
        require(
            vault.votingTokens() * 10000 >=
                settings.minVotePercentage() * vault.totalSupply(),
            Errors.VAULT_NOT_VOTERS
        );
        // terminate treasury and swap all WETH to ETH
        TokenVaultTreasuryLogic.end(vault.treasury());
        TransferHelper.swapWETH2ETH(
            address(vault.weth()),
            vault.weth().balanceOf(vaultAddress)
        );
        //
        uint256 userBalance = vault.balanceOf(msgSender);
        uint256 totalBalance = vault.totalSupply();
        require(
            bidPrice >= vault.exitReducePrice(),
            Errors.VAULT_BID_PRICE_TOO_LOW
        );
        require(
            reqValue ==
                calculateRequestValue(
                    bidPrice,
                    totalBalance,
                    userBalance,
                    settings.exitFeeForCuratorPercentage(),
                    settings.exitFeeForPlatformPercentage()
                ),
            Errors.VAULT_REQ_VALUE_INVALID
        );

        require(totalBalance > userBalance, Errors.VAULT_BALANCE_INVALID);
        auctionEnd = block.timestamp + settings.auctionLength();
        auctionState = DataTypes.State.live;
        // update new winning
        winning = msgSender;
        bidHoldInETH = reqValue;
        bidHoldInToken = userBalance;
        livePrice = bidPrice;
    }

    function bid(
        address msgSender,
        address vaultAddress,
        uint256 bidPrice,
        uint256 reqValue
    )
        external
        returns (
            uint256 auctionEnd,
            address winning,
            uint256 bidHoldInETH,
            uint256 bidHoldInToken,
            uint256 livePrice
        )
    {
        IVault vault = IVault(vaultAddress);
        ISettings settings = ISettings(vault.settings());
        require(
            vault.auctionState() == DataTypes.State.live,
            Errors.VAULT_STATE_INVALID
        );
        uint256 userBalance = vault.balanceOf(msgSender);
        uint256 totalBalance = vault.totalSupply();
        require(
            bidPrice >=
                (vault.livePrice() * (10000 + settings.minBidIncrease())) /
                    10000,
            Errors.VAULT_BID_PRICE_TOO_LOW
        );
        require(
            reqValue ==
                calculateRequestValue(
                    bidPrice,
                    totalBalance,
                    userBalance,
                    settings.exitFeeForCuratorPercentage(),
                    settings.exitFeeForPlatformPercentage()
                ),
            Errors.VAULT_REQ_VALUE_INVALID
        );
        require(block.timestamp < vault.auctionEnd(), Errors.VAULT_AUCTION_END);
        // If bid is within 30 minutes of auction end, extend auction
        auctionEnd = vault.auctionEnd();
        winning = vault.winning();
        bidHoldInETH = vault.bidHoldInETH();
        bidHoldInToken = vault.bidHoldInToken();
        //
        if (auctionEnd - block.timestamp <= settings.auctionExtendLength()) {
            auctionEnd = (block.timestamp + settings.auctionExtendLength());
        }
        // return old winning
        TransferHelper.safeTransferETHOrWETH(
            address(vault.weth()),
            winning,
            bidHoldInETH
        );
        TransferHelper.safeTransfer(
            IERC20(vaultAddress),
            winning,
            bidHoldInToken
        );
        // update new winning
        winning = msgSender;
        bidHoldInETH = reqValue;
        bidHoldInToken = userBalance;
        livePrice = bidPrice;
    }

    function end(address vaultAddress)
        external
        returns (DataTypes.State auctionState)
    {
        IVault vault = IVault(vaultAddress);
        ISettings settings = ISettings(vault.settings());
        auctionState = vault.auctionState();
        require(
            auctionState == DataTypes.State.live,
            Errors.VAULT_STATE_INVALID
        );
        require(
            block.timestamp >= vault.auctionEnd(),
            Errors.VAULT_AUCTION_LIVE
        );
        // transfer erc721 to winner
        for (uint i = 0; i < vault.listTokensLength(); i++) {
            IERC721(vault.listTokens(i)).safeTransferFrom(
                vaultAddress,
                vault.winning(),
                vault.listIds(i)
            );
        }
        // share reward weth
        uint256 ethBalance = TransferHelper.balanceOfETH(vaultAddress);
        if (ethBalance > vault.bidHoldInETH()) {
            uint256 sharedBalance = ((ethBalance - vault.bidHoldInETH()) *
                vault.bidHoldInToken()) / vault.totalSupply();
            TransferHelper.safeTransferETHOrWETH(
                address(vault.weth()),
                vault.winning(),
                sharedBalance
            );
        }
        // transfer exit fee 1.25% cruator 1.25% fdao
        TransferHelper.safeTransferETHOrWETH(
            address(vault.weth()),
            vault.curator(),
            (vault.livePrice() * settings.exitFeeForCuratorPercentage()) / 10000
        );
        TransferHelper.safeTransferETHOrWETH(
            address(vault.weth()),
            settings.feeReceiver(),
            (vault.livePrice() * settings.exitFeeForPlatformPercentage()) /
                10000
        );
        auctionState = DataTypes.State.ended;
    }

    function redeem(address vaultAddress, address msgSender)
        external
        returns (DataTypes.State auctionState)
    {
        IVault vault = IVault(vaultAddress);
        ISettings settings = ISettings(vault.settings());
        auctionState = vault.auctionState();
        require(
            auctionState == DataTypes.State.inactive,
            Errors.VAULT_STATE_INVALID
        );
        // terminate treasury
        TokenVaultTreasuryLogic.end(vault.treasury());
        require(
            vault.balanceOf(msgSender) == vault.totalSupply(),
            Errors.VAULT_MISSING_TOKEN_TO_REDEEM
        );
        TransferHelper.swapWETH2ETH(
            address(vault.weth()),
            vault.weth().balanceOf(vaultAddress)
        );
        // transfer erc721 to redeemer
        for (uint i = 0; i < vault.listTokensLength(); i++) {
            IERC721(vault.listTokens(i)).safeTransferFrom(
                vaultAddress,
                msgSender,
                vault.listIds(i)
            );
        }
        // share weth balance
        uint256 ethBalance = TransferHelper.balanceOfETH(vaultAddress);
        if (ethBalance > 0) {
            TransferHelper.safeTransferETHOrWETH(
                address(vault.weth()),
                msgSender,
                ethBalance
            );
        }

        auctionState = DataTypes.State.redeemed;
    }
}
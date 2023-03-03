// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import {SwapTypes} from "./libraries/SwapTypes.sol";
import {EscrowStorage} from "./EscrowStorage.sol";
import {IEscrow} from "./interfaces/IEscrow.sol";

contract Escrow is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IEscrow,
    EscrowStorage
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    // For UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override {
        require(_msgSender() == owner(), "caller not owner");
    }

    modifier checkAssets(
        SwapTypes.Intent memory intent,
        SwapTypes.Assets[] memory makerAssets,
        SwapTypes.Assets[] memory takerAssets
    ) {
        require(
            (intent.makerValue > 0 || makerAssets.length > 0) &&
                (intent.takerValue > 0 || takerAssets.length > 0),
            "no assets"
        );
        _;
    }

    function createSwap(
        SwapTypes.Intent memory intent,
        SwapTypes.Assets[] memory makerAssets,
        SwapTypes.Assets[] memory takerAssets
    )
        external
        payable
        override
        whenNotPaused
        checkAssets(intent, makerAssets, takerAssets)
    {
        require(intent.endTime > block.timestamp, "invalid endtime");
        require(msg.value >= intent.makerValue + fee, "insufficient value");

        intent.maker = payable(_msgSender());
        intent.beginTime = block.timestamp;
        intent.makerFee = fee;
        intent.status = SwapTypes.SwapStatus.Opened;
        intents[swapId.current()] = intent;
        _addAssets(swapId.current(), makerAssets, true);
        _addAssets(swapId.current(), takerAssets, false);

        emit SwapEvent(
            intent.maker,
            intent.taker,
            swapId.current(),
            block.timestamp,
            SwapTypes.SwapStatus.Opened
        );
        swapId.increment();
    }

    function closeSwap(
        uint256 _swapId
    ) external payable override nonReentrant whenNotPaused {
        SwapTypes.Intent storage intent = intents[_swapId];
        require(intent.status == SwapTypes.SwapStatus.Opened, "not opened");
        require(
            intent.taker == _msgSender() || intent.taker == address(0),
            "not taker"
        );
        require(intent.endTime >= block.timestamp, "expired");
        require(msg.value >= intent.takerValue + fee, "insufficient value");

        intent.status = SwapTypes.SwapStatus.Closed;
        _transferAssets(
            _swapId,
            intent.maker,
            intent.taker,
            intent.makerValue,
            true
        );
        _transferAssets(
            _swapId,
            intent.taker,
            intent.maker,
            intent.takerValue,
            false
        );
        _transfer(feeRecipient, intent.makerFee + fee);

        emit SwapEvent(
            intent.maker,
            intent.taker,
            _swapId,
            block.timestamp,
            SwapTypes.SwapStatus.Closed
        );
    }

    function cancelSwap(uint256 _swapId) external override nonReentrant {
        SwapTypes.Intent storage intent = intents[_swapId];
        require(intent.maker == _msgSender(), "not maker");
        require(intent.status == SwapTypes.SwapStatus.Opened, "not opened");
        intent.status = SwapTypes.SwapStatus.Cancelled;
        _transfer(intent.maker, intent.makerValue + intent.makerFee);
        emit SwapEvent(
            intent.maker,
            intent.taker,
            _swapId,
            block.timestamp,
            SwapTypes.SwapStatus.Cancelled
        );
    }

    function getMakerAssetsLength(
        uint256 _swapId
    ) external view override returns (uint256) {
        return makers[_swapId].length;
    }

    function getTakerAssetsLength(
        uint256 _swapId
    ) external view override returns (uint256) {
        return takers[_swapId].length;
    }

    function getMakerAssets(
        uint256 _swapId,
        uint256 index
    ) external view override returns (SwapTypes.Assets memory) {
        return makers[_swapId][index];
    }

    function getTakerAssets(
        uint256 _swapId,
        uint256 index
    ) external view override returns (SwapTypes.Assets memory) {
        return takers[_swapId][index];
    }

    function _addAssets(
        uint256 _swapId,
        SwapTypes.Assets[] memory assets,
        bool maker
    ) internal {
        for (uint i = 0; i < assets.length; i++) {
            if (assets[i].typ == SwapTypes.TokenType.ERC20) {
                require(
                    erc20Allowlist[assets[i].token],
                    "unsupported erc20 token"
                );
                require(
                    assets[i].balance.length == 1 && assets[i].balance[0] > 0,
                    "invalid erc20 asset"
                );
            } else if (assets[i].typ == SwapTypes.TokenType.ERC721) {
                require(
                    nftAllowlist[assets[i].token],
                    "unsupported erc721 token"
                );
                require(assets[i].tokenId.length > 0, "invalid erc721 asset");
            } else {
                require(
                    nftAllowlist[assets[i].token],
                    "unsupported erc1155 token"
                );
                require(
                    assets[i].tokenId.length > 0 &&
                        assets[i].tokenId.length == assets[i].balance.length,
                    "invalid erc1155 asset"
                );
                for (uint j = 0; j < assets[i].balance.length; j++) {
                    require(
                        assets[i].balance[j] > 0,
                        "invalid erc1155 balance"
                    );
                }
            }
            if (maker) {
                makers[_swapId].push(assets[i]);
            } else {
                takers[_swapId].push(assets[i]);
            }
        }
    }

    function _transferAssets(
        uint256 _swapId,
        address sender,
        address payable receiver,
        uint256 value,
        bool makerToTaker
    ) internal {
        SwapTypes.Assets[] memory assets;
        if (makerToTaker) {
            assets = makers[_swapId];
        } else {
            assets = takers[_swapId];
        }

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].typ == SwapTypes.TokenType.ERC20) {
                IERC20Upgradeable(assets[i].token).safeTransferFrom(
                    sender,
                    receiver,
                    assets[i].balance[0]
                );
            } else if (assets[i].typ == SwapTypes.TokenType.ERC721) {
                for (uint j = 0; j < assets[i].tokenId.length; j++) {
                    IERC721Upgradeable(assets[i].token).safeTransferFrom(
                        sender,
                        receiver,
                        assets[i].tokenId[j],
                        assets[i].data
                    );
                }
            } else {
                IERC1155Upgradeable(assets[i].token).safeBatchTransferFrom(
                    sender,
                    receiver,
                    assets[i].tokenId,
                    assets[i].balance,
                    assets[i].data
                );
            }
        }
        _transfer(receiver, value);
    }

    function _transfer(address payable receiver, uint256 value) internal {
        if (value > 0) {
            (bool success, ) = receiver.call{value: value}("");
            require(success, "transfer failed");
        }
    }

    // admin functions
    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setErc20Allowlist(
        address[] calldata erc20s,
        bool allow
    ) external override onlyOwner {
        for (uint i = 0; i < erc20s.length; i++) {
            erc20Allowlist[erc20s[i]] = allow;
        }
        emit Erc20AllowlistSet(erc20s, allow);
    }

    function setNftAllowlist(
        address[] calldata nfts,
        bool allow
    ) external override onlyOwner {
        for (uint i = 0; i < nfts.length; i++) {
            nftAllowlist[nfts[i]] = allow;
        }
        emit NftAllowlistSet(nfts, allow);
    }

    function setFee(uint256 _fee) external override onlyOwner {
        fee = _fee;
        emit FeeUpdated(fee);
    }

    function setFeeRecipient(
        address payable _feeRecipient
    ) external override onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(feeRecipient);
    }
}
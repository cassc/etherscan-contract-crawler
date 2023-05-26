// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuardUpgradeable} from "openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IStrategy} from "src/interfaces/IStrategy.sol";
import {IAuraRouter} from "src/interfaces/IAuraRouter.sol";
import {AuraCompounderVault} from "src/compounder/vaults/AuraCompounderVault.sol";
import {IAuraVirtualVault} from "src/interfaces/IAuraVirtualVault.sol";
import {IERC20Upgradeable} from "openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import {Errors} from "src/errors/Errors.sol";

contract AuraRouter is IAuraRouter, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    AuraCompounderVault public jAura;
    IAuraVirtualVault public auraVirtualVault;
    IStrategy public strategy;

    IERC20Upgradeable public constant AURA = IERC20Upgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);

    struct UserData {
        uint128 userWithdrawRequests; // withdraw requests
        uint64 userLastDeposit; // last deposit timestamp
        uint64 userLastWithdrawRequest; // last withdraw request timestamp
    }

    // user => userData (Recorded user action data)
    mapping(address => UserData) private noTokenizedUserData;
    mapping(address => UserData) private lsdUserData;

    uint256 public totalWithdrawRequests;
    uint256 public totalWithdrawRequestsLSD;
    uint256 public totalWithdrawRequestsNoTokenized;

    uint256 public constant BASIS_POINTS = 1e12;
    uint256 public MIN_DEPOSIT_PERIOD;
    uint256 public MIN_WITHDRAW_PERIOD;

    address private incentiveReceiver;
    address private constant gov = 0x2a88a454A7b0C29d36D5A121b7Cf582db01bfCEC;

    function initialize(address _strategy, address _jAura, address _auraVirtualVault, address _incentiveReceiver)
        external
        initializer
    {
        if (msg.sender != gov) {
            revert Errors.notOwner();
        }

        __Ownable_init();
        __ReentrancyGuard_init();

        jAura = AuraCompounderVault(_jAura);
        auraVirtualVault = IAuraVirtualVault(_auraVirtualVault);
        strategy = IStrategy(payable(_strategy));
        incentiveReceiver = _incentiveReceiver;

        MIN_DEPOSIT_PERIOD = 1 weeks;
        MIN_WITHDRAW_PERIOD = 1 weeks;
    }

    /**
     * @notice Mints Vault shares to receiver by depositing underlying tokens.
     * @param _assets The amount of assets to deposit.
     * @return shares The amount of shares that were minted and received.
     */
    function deposit(uint256 _assets, bool _tokenized) external nonReentrant whenNotPaused returns (uint256) {
        uint256 shares;

        if (_assets == 0) {
            revert Errors.ZeroAmount();
        }

        if (_tokenized) {
            shares = jAura.deposit(_assets, msg.sender);
            // strategy deposit
            AURA.transferFrom(msg.sender, address(strategy), _assets);
            strategy.deposit(_assets, true);

            // update last user deposit
            lsdUserData[msg.sender].userLastDeposit = uint64(block.timestamp);
        } else {
            shares = auraVirtualVault.deposit(msg.sender, _assets);
            // strategy deposit
            AURA.transferFrom(msg.sender, address(strategy), _assets);
            strategy.deposit(_assets, false);
            // update last user deposit
            noTokenizedUserData[msg.sender].userLastDeposit = uint64(block.timestamp);
        }

        emit Deposit(msg.sender, _assets, _tokenized);

        return shares;
    }

    /**
     * @notice Requests to withdraw the given amount of shares from the message sender's balance.
     * The withdrawal request will be added to the total amount of withdrawal requests, and will be
     * added to the user's total withdrawal requests.
     *
     * @param _shares The amount of shares to withdraw.
     * @dev Reverts with DepositCooldown If the user's last deposit was less than the minimum deposit period ago.
     * Reverts with InsufficientShares If the user does not have enough shares to withdraw.
     */
    function withdrawRequest(uint256 _shares, bool _tokenized) external nonReentrant {
        uint256 assets;

        if (_shares == 0) {
            revert Errors.ZeroAmount();
        }

        if (_tokenized) {
            if (_shares > jAura.balanceOf(msg.sender)) {
                revert Errors.InsufficientShares();
            }

            unchecked {
                // Time cannot overflow
                if (lsdUserData[msg.sender].userLastDeposit + MIN_DEPOSIT_PERIOD > block.timestamp) {
                    revert Errors.DepositCooldown();
                }

                assets = jAura.previewRedeem(_shares);

                jAura.burn(msg.sender, _shares);

                totalWithdrawRequests = totalWithdrawRequests + assets;
                totalWithdrawRequestsLSD += assets;

                lsdUserData[msg.sender].userWithdrawRequests += uint128(assets);
                lsdUserData[msg.sender].userLastWithdrawRequest = uint64(block.timestamp);
            }

            emit WithdrawRequest(msg.sender, lsdUserData[msg.sender].userWithdrawRequests, true);
        } else {
            if (_shares > auraVirtualVault.virtualShares(msg.sender)) {
                revert Errors.InsufficientShares();
            }

            unchecked {
                // Time cannot overflow
                if (noTokenizedUserData[msg.sender].userLastDeposit + MIN_DEPOSIT_PERIOD > block.timestamp) {
                    revert Errors.DepositCooldown();
                }

                assets = auraVirtualVault.previewRedeem(_shares);

                auraVirtualVault.burn(msg.sender, _shares);

                totalWithdrawRequestsNoTokenized += assets;

                totalWithdrawRequests = totalWithdrawRequests + assets;

                noTokenizedUserData[msg.sender].userWithdrawRequests += uint128(assets);
                noTokenizedUserData[msg.sender].userLastWithdrawRequest = uint64(block.timestamp);

                emit WithdrawRequest(msg.sender, noTokenizedUserData[msg.sender].userWithdrawRequests, false);
            }
        }
    }

    /**
     * @notice Withdraws the given amount of assets from the message sender's balance to the specified receiver.
     * @param _assets The amount of assets to withdraw.
     * @dev Reverts with InsufficientRequest If the user has not made a withdrawal request for the given amount of assets.
     * Reverts with WithdrawCooldown If the user's last withdrawal request was made less than the minimum withdrawal period ago.
     */
    function withdraw(uint256 _assets, bool _tokenized) external nonReentrant returns (uint256) {
        uint128 assets = uint128(_assets);

        if (_assets == 0) {
            revert Errors.ZeroAmount();
        }
        unchecked {
            if (_tokenized) {
                uint128 request = lsdUserData[msg.sender].userWithdrawRequests;

                if (request < assets) {
                    revert Errors.InsufficientRequest();
                }

                // Time cannot overflow
                if (lsdUserData[msg.sender].userLastWithdrawRequest + MIN_WITHDRAW_PERIOD > block.timestamp) {
                    revert Errors.WithdrawCooldown();
                }

                lsdUserData[msg.sender].userWithdrawRequests = request - assets;

                totalWithdrawRequestsLSD = totalWithdrawRequestsLSD > assets ? totalWithdrawRequestsLSD - assets : 0;
            } else {
                uint128 request = noTokenizedUserData[msg.sender].userWithdrawRequests;

                if (request < assets) {
                    revert Errors.InsufficientRequest();
                }

                // Time cannot overflow
                if (noTokenizedUserData[msg.sender].userLastWithdrawRequest + MIN_WITHDRAW_PERIOD > block.timestamp) {
                    revert Errors.WithdrawCooldown();
                }
                noTokenizedUserData[msg.sender].userWithdrawRequests = request - assets;

                totalWithdrawRequestsNoTokenized =
                    totalWithdrawRequestsNoTokenized > assets ? totalWithdrawRequestsNoTokenized - assets : 0;
            }

            totalWithdrawRequests = totalWithdrawRequests > assets ? totalWithdrawRequests - assets : 0;
        }

        _assets = strategy.withdraw(msg.sender, uint256(assets), _tokenized);

        emit Withdraw(msg.sender, _assets, _tokenized);

        return _assets;
    }

    /**
     * @notice Rehypothecate user shares to user, charging a retention.
     * @param _assets The amount of assets to be rehypothecate.
     * @param _tokenized type of user.
     * @dev Reverts if the shares user is trying to redeem are worth more assets than he commited to withdraw
     */
    function rehypothecate(uint256 _assets, bool _tokenized) external nonReentrant returns (uint256) {
        uint128 assets = uint128(_assets);

        (uint256 shares, uint256 retention, uint256 lsdShares) = jAura.rehypothecate(assets, msg.sender);

        unchecked {
            if (_tokenized) {
                uint128 request = lsdUserData[msg.sender].userWithdrawRequests;

                if (assets > request) {
                    revert Errors.InsufficientShares();
                }

                lsdUserData[msg.sender].userWithdrawRequests = request - assets;

                totalWithdrawRequests = totalWithdrawRequests > assets ? totalWithdrawRequests - assets : 0;
                totalWithdrawRequestsLSD = totalWithdrawRequestsLSD > assets ? totalWithdrawRequestsLSD - assets : 0;
            } else {
                uint128 request = noTokenizedUserData[msg.sender].userWithdrawRequests;

                if (assets > request) {
                    revert Errors.InsufficientShares();
                }

                noTokenizedUserData[msg.sender].userWithdrawRequests = request - assets;

                totalWithdrawRequests = totalWithdrawRequests > assets ? totalWithdrawRequests - assets : 0;
                totalWithdrawRequestsNoTokenized =
                    totalWithdrawRequestsNoTokenized > assets ? totalWithdrawRequestsNoTokenized - assets : 0;
            }

            jAura.burn(address(this), lsdShares);

            strategy.afterRehyphotecate(assets, _tokenized);

            jAura.transfer(incentiveReceiver, retention - lsdShares);
            uint256 redeemed = shares - retention;
            jAura.transfer(msg.sender, redeemed);

            return redeemed;
        }
    }

    /**
     * @notice Set address to receive incentives.
     * @param _receiver The address of the receiver.
     * @dev Reverts if address is zero address.
     */
    function setIncentiveReceiver(address _receiver) external onlyOwner {
        if (_receiver == address(0)) {
            revert();
        }

        incentiveReceiver = _receiver;
    }

    function setCooldownPeriods(uint256 _deposit, uint256 _withdraw) external onlyOwner {
        MIN_DEPOSIT_PERIOD = _deposit;
        MIN_WITHDRAW_PERIOD = _withdraw;
    }

    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function noTokenizedUserInfo(address _user) external view returns (uint128, uint64, uint64) {
        UserData memory userData = noTokenizedUserData[_user];
        return (userData.userWithdrawRequests, userData.userLastDeposit, userData.userLastWithdrawRequest);
    }

    function lsdUserInfo(address _user) external view returns (uint128, uint64, uint64) {
        UserData memory userData = lsdUserData[_user];
        return (userData.userWithdrawRequests, userData.userLastDeposit, userData.userLastWithdrawRequest);
    }

    event Deposit(address indexed owner, uint256 assets, bool tokenized);
    event WithdrawRequest(address indexed owner, uint256 assets, bool tokenized);
    event Withdraw(address indexed owner, uint256 assets, bool tokenized);
}
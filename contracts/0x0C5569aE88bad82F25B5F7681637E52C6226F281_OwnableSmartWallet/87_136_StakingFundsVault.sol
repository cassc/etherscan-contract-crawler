// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";
import { Syndicate } from "../syndicate/Syndicate.sol";
import { ETHPoolLPFactory } from "./ETHPoolLPFactory.sol";
import { LiquidStakingManager } from "./LiquidStakingManager.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { LPToken } from "./LPToken.sol";
import { SyndicateRewardsProcessor } from "./SyndicateRewardsProcessor.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title MEV and fees vault for a specified liquid staking network
contract StakingFundsVault is
    Initializable,
    ITransferHookProcessor,
    StakehouseAPI,
    ETHPoolLPFactory,
    SyndicateRewardsProcessor,
    ReentrancyGuard
{

    /// @notice signalize that the vault received ETH
    event ETHDeposited(address sender, uint256 amount);

    /// @notice signalize ETH withdrawal from the vault
    event ETHWithdrawn(address receiver, address admin, uint256 amount);

    /// @notice signalize ERC20 token recovery by the admin
    event ERC20Recovered(address admin, address recipient, uint256 amount);

    /// @notice signalize unwrapping of WETH in the vault
    event WETHUnwrapped(address admin, uint256 amount);

    /// @notice Emitted when an LP from another liquid staking network is migrated
    event LPAddedForMigration(address indexed lpToken);

    /// @notice Emitted when an LP token has been swapped for a new one from this vault
    event LPMigrated(address indexed fromLPToken);

    /// @notice Address of the network manager
    LiquidStakingManager public liquidStakingNetworkManager;

    /// @notice Total number of LP tokens issued in WEI
    uint256 public totalShares;

    /// @notice Total amount of ETH from LPs that has not been staked in the Ethereum deposit contract
    uint256 public totalETHFromLPs;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _liquidStakingNetworkManager address of the liquid staking network manager
    function init(address _liquidStakingNetworkManager, LPTokenFactory _lpTokenFactory) external virtual initializer {
        _init(LiquidStakingManager(payable(_liquidStakingNetworkManager)), _lpTokenFactory);
    }

    modifier onlyManager() {
        require(msg.sender == address(liquidStakingNetworkManager), "Only network manager");
        _;
    }

    /// @notice Allows the liquid staking manager to notify funds vault about new derivatives minted to enable MEV claiming
    function updateDerivativesMinted(bytes calldata _blsPublicKey) external onlyManager {
        // update accumulated per LP before shares expand
        updateAccumulatedETHPerLP();

        // From this point onwards, we can use this variable to track ETH accrued to LP holders of this key
        accumulatedETHPerLPAtTimeOfMintingDerivatives[_blsPublicKey] = accumulatedETHPerLPShare;

        // We know 4 ETH for the KNOT came from this vault so increase the shares to get a % of vault rewards
        totalShares += 4 ether;
    }

    /// @notice For knots that have minted derivatives, update accumulated ETH per LP
    function updateAccumulatedETHPerLP() public {
        _updateAccumulatedETHPerLP(totalShares);
    }

    /// @notice Batch deposit ETH for staking against multiple BLS public keys
    /// @param _blsPublicKeyOfKnots List of BLS public keys being staked
    /// @param _amounts Amounts of ETH being staked for each BLS public key
    function batchDepositETHForStaking(bytes[] calldata _blsPublicKeyOfKnots, uint256[] calldata _amounts) external nonReentrant payable {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        require(numOfValidators > 0, "Empty arrays");
        require(numOfValidators == _amounts.length, "Inconsistent array lengths");

        // Track total ETH from LPs
        totalETHFromLPs += msg.value;

        // Update accrued ETH to contract per LP
        updateAccumulatedETHPerLP();

        uint256 totalAmount;
        for (uint256 i; i < numOfValidators; ++i) {
            require(liquidStakingNetworkManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i]) == false, "BLS public key is not part of LSD network");
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
                "Lifecycle status must be one"
            );

            LPToken tokenForKnot = lpTokenForKnot[_blsPublicKeyOfKnots[i]];
            if (address(tokenForKnot) != address(0)) {
                // Give anything owed to the user before making updates to user state
                uint256 due = _distributeETHRewardsToUserForToken(
                    msg.sender,
                    address(tokenForKnot),
                    tokenForKnot.balanceOf(msg.sender),
                    msg.sender
                );
                _transferETH(msg.sender, due);
            }

            uint256 amount = _amounts[i];
            totalAmount += amount;

            _depositETHForStaking(_blsPublicKeyOfKnots[i], amount, true);
        }

        // Ensure that the sum of LP tokens issued equals the ETH deposited into the contract
        require(msg.value == totalAmount, "Invalid ETH amount attached");
    }

    /// @notice Deposit ETH against a BLS public key for staking
    /// @param _blsPublicKeyOfKnot BLS public key of validator registered by a node runner
    /// @param _amount Amount of ETH being staked
    function depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount) public nonReentrant payable returns (uint256) {
        require(liquidStakingNetworkManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot) == false, "BLS public key is banned or not a part of LSD network");
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(msg.value == _amount, "Must provide correct amount of ETH");

        // Track total ETH from LPs
        totalETHFromLPs += _amount;

        // Update accrued ETH to contract per LP
        updateAccumulatedETHPerLP();

        // Give anything owed to the user before making updates to user state
        LPToken tokenForKnot = lpTokenForKnot[_blsPublicKeyOfKnot];
        if (address(tokenForKnot) != address(0)) {
            uint256 due = _distributeETHRewardsToUserForToken(
                msg.sender,
                address(tokenForKnot),
                tokenForKnot.balanceOf(msg.sender),
                msg.sender
            );
            _transferETH(msg.sender, due);
        }

        _depositETHForStaking(_blsPublicKeyOfKnot, _amount, true);

        return _amount;
    }

    /// @notice Burn a batch of LP tokens in order to get back ETH that has not been staked by BLS public key
    /// @param _blsPublicKeys List of BLS public keys that received ETH for staking
    /// @param _amounts List of amounts of LP tokens being burnt
    function burnLPTokensForETHByBLS(bytes[] calldata _blsPublicKeys, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _blsPublicKeys.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            LPToken token = lpTokenForKnot[_blsPublicKeys[i]];
            require(address(token) != address(0), "No ETH staked for specified BLS key");
            burnLPForETH(token, _amounts[i]);
        }
    }

    /// @notice Burn a batch of LP tokens in order to get back ETH that has not been staked
    /// @param _lpTokens Address of LP tokens being burnt
    /// @param _amounts Amount of LP tokens being burnt
    function burnLPTokensForETH(LPToken[] calldata _lpTokens, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _lpTokens.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            burnLPForETH(_lpTokens[i], _amounts[i]);
        }
    }

    /// @notice For a user that has deposited ETH that has not been staked, allow them to burn LP to get ETH back
    /// @param _lpToken Address of the LP token being burnt
    /// @param _amount Amount of LP token being burnt
    function burnLPForETH(LPToken _lpToken, uint256 _amount) public nonReentrant {
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount <= _lpToken.balanceOf(msg.sender), "Not enough balance");
        require(address(_lpToken) != address(0), "Zero address specified");

        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[_lpToken];
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Cannot burn LP tokens"
        );
        require(_lpToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp, "Too new");

        updateAccumulatedETHPerLP();

        _lpToken.burn(msg.sender, _amount);

        // Track total ETH from LPs
        totalETHFromLPs -= _amount;

        _transferETH(msg.sender, _amount);

        emit ETHWithdrawnByDepositor(msg.sender, _amount);

        emit LPTokenBurnt(blsPublicKeyOfKnot, address(_lpToken), msg.sender, _amount);
    }

    /// @notice Any LP tokens for BLS keys that have had their derivatives minted can claim ETH from the syndicate contract
    /// @param _blsPubKeys List of BLS public keys being processed
    function claimRewards(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        // Withdraw any ETH accrued on free floating SLOT from syndicate to this contract
        // If a partial list of BLS keys that have free floating staked are supplied, then partial funds accrued will be fetched
        _claimFundsFromSyndicateForDistribution(
            liquidStakingNetworkManager.syndicate(),
            _blsPubKeys
        );

        uint256 totalToSend;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            // Ensure that the BLS key has its derivatives minted
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPubKeys[i]) == IDataStructures.LifecycleStatus.TOKENS_MINTED,
                "Derivatives not minted"
            );

            // If msg.sender has a balance for the LP token associated with the BLS key, then send them any accrued ETH
            LPToken token = lpTokenForKnot[_blsPubKeys[i]];
            require(address(token) != address(0), "Invalid BLS key");
            totalToSend += _distributeETHRewardsToUserForToken(msg.sender, address(token), token.balanceOf(msg.sender), _recipient);
        }

        _transferETH(_recipient, totalToSend);
    }

    /// @notice function to allow admins to withdraw ETH from the vault for staking purpose
    /// @param _wallet address of the smart wallet that receives ETH
    /// @param _amount number of ETH withdrawn
    /// @return number of ETH withdrawn
    function withdrawETH(address _wallet, uint256 _amount) public onlyManager nonReentrant returns (uint256) {
        require(_amount >= 4 ether, "Amount cannot be less than 4 ether");
        require(_amount <= address(this).balance, "Not enough ETH to withdraw");
        require(_wallet != address(0), "Zero address");

        // As this tracks ETH that has not been sent to deposit contract, update it
        totalETHFromLPs -= _amount;

        // Transfer the ETH to the wallet
        _transferETH(_wallet, _amount);

        emit ETHWithdrawn(_wallet, msg.sender, _amount);

        return _amount;
    }

    /// @notice LP token holders can unstake sETH and leave the LSD network by burning their LP tokens
    /// @param _blsPublicKeys List of associated BLS public keys
    /// @param _amount Amount of LP token from user being burnt.
    function unstakeSyndicateSETHByBurningLP(
        bytes[] calldata _blsPublicKeys,
        uint256 _amount
    ) external nonReentrant {
        require(_blsPublicKeys.length == 1, "One unstake at a time");
        require(_amount > 0, "No amount specified");

        LPToken token = lpTokenForKnot[_blsPublicKeys[0]];
        require(token.balanceOf(msg.sender) >= _amount, "Not enough LP");

        // Bring ETH accrued into this contract and distribute it amongst existing LPs
        Syndicate syndicate = Syndicate(payable(liquidStakingNetworkManager.syndicate()));
        _claimFundsFromSyndicateForDistribution(address(syndicate), _blsPublicKeys);
        updateAccumulatedETHPerLP();

        // This will transfer rewards to user
        token.burn(msg.sender, _amount);

        // Reduce the shares in the contract
        totalShares -= _amount;

        // Unstake and send sETH to caller
        uint256[] memory amountsForUnstaking = new uint256[](1);
        amountsForUnstaking[0] = _amount * 3;
        syndicate.unstake(address(this), msg.sender, _blsPublicKeys, amountsForUnstaking);
    }

    /// @notice Preview total ETH accumulated by a staking funds LP token holder associated with many KNOTs that have minted derivatives
    function batchPreviewAccumulatedETH(address _user, LPToken[] calldata _token) external view returns (uint256) {
        uint256 totalUnclaimed;
        for (uint256 i; i < _token.length; ++i) {
            bytes memory associatedBLSPublicKeyOfLpToken = KnotAssociatedWithLPToken[_token[i]];
            if (getAccountManager().blsPublicKeyToLifecycleStatus(associatedBLSPublicKeyOfLpToken) != IDataStructures.LifecycleStatus.TOKENS_MINTED) {
                continue;
            }

            address payable syndicate = payable(liquidStakingNetworkManager.syndicate());
            totalUnclaimed += Syndicate(syndicate).previewUnclaimedETHAsFreeFloatingStaker(
                address(this),
                associatedBLSPublicKeyOfLpToken
            );
        }

        uint256 totalAccumulated;
        for (uint256 i; i < _token.length; ++i) {
            totalAccumulated += _previewAccumulatedETH(
                _user,
                address(_token[i]),
                _token[i].balanceOf(_user),
                totalShares,
                totalUnclaimed
            );
        }

        return totalAccumulated;
    }

    /// @notice before an LP token is transferred, pay the user any unclaimed ETH rewards
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external override {
        address syndicate = liquidStakingNetworkManager.syndicate();
        if (syndicate != address(0)) {
            LPToken token = LPToken(msg.sender);
            bytes memory blsPubKey = KnotAssociatedWithLPToken[token];
            require(blsPubKey.length > 0, "Invalid token");

            if (getAccountManager().blsPublicKeyToLifecycleStatus(blsPubKey) == IDataStructures.LifecycleStatus.TOKENS_MINTED) {
                // Claim any ETH for the BLS key mapped to this token
                bytes[] memory keys = new bytes[](1);
                keys[0] = blsPubKey;
                _claimFundsFromSyndicateForDistribution(syndicate, keys);

                // Update the accumulated ETH per minted derivative LP share
                updateAccumulatedETHPerLP();

                // distribute any due rewards for the `from` user
                if (_from != address(0)) {
                    uint256 fromBalance = token.balanceOf(_from);

                    _transferETH(
                        _from,
                        _distributeETHRewardsToUserForToken(_from, address(token), fromBalance, _from)
                    );

                    if (token.balanceOf(_from) != fromBalance) revert("ReentrancyCall");

                    // Ensure claimed amount is based on new balance
                    claimed[_from][address(token)] = fromBalance == 0 ?
                        0 : ((fromBalance - _amount) * accumulatedETHPerLPShare) / PRECISION;
                }

                // in case the new user has existing rewards - give it to them so that the after transfer hook does not wipe pending rewards
                if (_to != address(0)) {
                    uint256 toBalance = token.balanceOf(_to);

                    _transferETH(
                        _to,
                        _distributeETHRewardsToUserForToken(_to, address(token), toBalance, _to)
                    );

                    if (token.balanceOf(_to) != toBalance) revert("ReentrancyCall");

                    claimed[_to][address(token)] = ((toBalance + _amount) * accumulatedETHPerLPShare) / PRECISION;
                }
            }
        }
    }

    /// @notice After an LP token is transferred, ensure that the new account cannot claim historical rewards
    function afterTokenTransfer(address, address _to, uint256) external override {
        // No need to do anything here
    }

    /// @notice Claim ETH to this contract from the syndicate that was accrued by a list of actively staked validators
    /// @param _blsPubKeys List of BLS public key identifiers of validators that have sETH staked in the syndicate for the vault
    function claimFundsFromSyndicateForDistribution(bytes[] memory _blsPubKeys) external {
        _claimFundsFromSyndicateForDistribution(liquidStakingNetworkManager.syndicate(), _blsPubKeys);
    }

    /// @notice Total rewards received filtering out ETH that has been deposited by LPs
    function totalRewardsReceived() public view override returns (uint256) {
        return address(this).balance + totalClaimed - totalETHFromLPs;
    }

    /// @notice Return the address of the liquid staking manager associated with the vault
    function liquidStakingManager() external view returns (address) {
        return address(liquidStakingNetworkManager);
    }

    /// @dev Claim ETH from syndicate for a list of BLS public keys for later distribution amongst LPs
    function _claimFundsFromSyndicateForDistribution(address _syndicate, bytes[] memory _blsPubKeys) internal {
        require(_syndicate != address(0), "Invalid configuration");

        // Claim all of the ETH due from the syndicate for the auto-staked sETH
        Syndicate syndicateContract = Syndicate(payable(_syndicate));
        syndicateContract.claimAsStaker(address(this), _blsPubKeys);

        updateAccumulatedETHPerLP();
    }

    /// @dev Total claimed for a user and LP token needs to be based on when derivatives were minted so that pro-rated share is not earned too early causing phantom balances
    function _getTotalClaimedForUserAndToken(address _user, address _token, uint256 _balance) internal override view returns (uint256) {
        uint256 claimedSoFar = claimed[_user][_token];
        bytes memory blsPubKey = KnotAssociatedWithLPToken[LPToken(_token)];

        // Either user has a claimed amount or their claimed amount needs to be based on accumulated ETH at time of minting derivatives
        return claimedSoFar > 0 ?
                claimedSoFar : (_balance * accumulatedETHPerLPAtTimeOfMintingDerivatives[blsPubKey]) / PRECISION;
    }

    /// @dev Use _getTotalClaimedForUserAndToken to correctly track and save total claimed by a user for a token
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256 _balance
    ) internal override {
        // _getTotalClaimedForUserAndToken will factor in accumulated ETH at time of minting derivatives
        claimed[_user][_token] = _getTotalClaimedForUserAndToken(_user, _token, _balance) + _increase;
    }

    /// @dev Initialization logic
    function _init(LiquidStakingManager _liquidStakingNetworkManager, LPTokenFactory _lpTokenFactory) internal virtual {
        require(address(_liquidStakingNetworkManager) != address(0), "Zero Address");
        require(address(_lpTokenFactory) != address(0), "Zero Address");

        liquidStakingNetworkManager = _liquidStakingNetworkManager;
        lpTokenFactory = _lpTokenFactory;

        baseLPTokenName = "ETHLPToken_";
        baseLPTokenSymbol = "ETHLP_";
        maxStakingAmountPerValidator = 4 ether;
    }
}
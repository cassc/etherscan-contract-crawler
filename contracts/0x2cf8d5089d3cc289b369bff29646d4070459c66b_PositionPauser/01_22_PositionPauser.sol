// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IPositionPauser} from "../../interfaces/IPositionPauser.sol";
import {IHashnoteVault} from "../../interfaces/IHashnoteVault.sol";
import {IWhitelistManager} from "../../interfaces/IWhitelistManager.sol";

import "../../config/types.sol";
import "../../config/errors.sol";

contract PositionPauser is Ownable, IPositionPauser {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            Structures
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores all the vault's paused positions
    struct PauseReceipt {
        uint32 round;
        uint128 shares;
    }

    /*///////////////////////////////////////////////////////////////
                            Storage
    //////////////////////////////////////////////////////////////*/

    // vault => account => pause receipt
    mapping(address => mapping(address => PauseReceipt)) public pausedPositions;

    // vault => round => total withdrawn shares
    mapping(address => mapping(uint256 => uint128)) public roundTotalShares;

    // vault => round => array of collateral balances
    mapping(address => mapping(uint256 => uint256[])) public roundBalances;

    IWhitelistManager public immutable whitelist;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Pause(address indexed account, address indexed vaultAddress, uint256 share, uint256 round);

    event Withdraw(address indexed account, address indexed vaultAddress, uint256[] withdrawAmounts);

    event ProcessWithdraws(address indexed vaultAddress, uint256 round, uint256[] withdrawAmounts);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _whitelist is the the whitelist manager
     */
    constructor(address _owner, address _whitelist) {
        if (_owner == address(0)) revert BadAddress();
        if (_whitelist == address(0)) revert BadAddress();

        _transferOwnership(_owner);
        whitelist = IWhitelistManager(_whitelist);
    }

    /*///////////////////////////////////////////////////////////////
                            Getters
    //////////////////////////////////////////////////////////////*/

    function getPausePosition(address _vault, address _userAddress) external view returns (PauseReceipt memory) {
        return pausedPositions[_vault][_userAddress];
    }

    function roundTotalBalances(address _vault, uint256 _round) external view returns (uint256[] memory balances) {
        balances = roundBalances[address(_vault)][_round];
    }

    /*///////////////////////////////////////////////////////////////
                            Pauser Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice pause position from vault by redeem all the shares from vault to Pauser
     * @param _account user's address
     * @param _shares the amount of shares
     */
    function pausePosition(address _account, uint256 _shares) external override {
        address _vault = msg.sender;

        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        IHashnoteVault vault = IHashnoteVault(_vault);

        uint32 currentRound = vault.vaultState().round;

        PauseReceipt memory pausedPosition = pausedPositions[_vault][_account];

        uint256 pausedInRound = pausedPosition.round;

        // check if position is paused and no longer the same round
        if (pausedInRound > 0 && pausedInRound != currentRound) revert VP_PositionPaused();

        // tops up paused shares
        uint256 accountShares = pausedPosition.shares + _shares;

        if (accountShares > type(uint128).max) revert VP_Overflow();

        // updates storage with new pause receipt
        pausedPositions[_vault][_account] = PauseReceipt({round: currentRound, shares: uint128(accountShares)});

        // increases total shares for a given vault round
        uint256 roundShares = roundTotalShares[_vault][currentRound] + _shares;

        if (roundShares > type(uint128).max) revert VP_Overflow();

        roundTotalShares[_vault][currentRound] = uint128(roundShares);

        emit Pause(_account, _vault, _shares, currentRound);
    }

    /**
     * @notice customer withdraws collateral
     * @param _vault vault's address
     * @param _destination address
     */
    function withdrawCollaterals(address _vault, address _destination) external override {
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        if (_destination == address(0)) _destination = msg.sender;

        IHashnoteVault vault = IHashnoteVault(_vault);

        address vaultWhitelistAddr = vault.whitelist();

        // if whitelist set on vault, then check it for permissions
        if (vaultWhitelistAddr != address(0)) {
            IWhitelistManager vaultWhitelist = IWhitelistManager(vaultWhitelistAddr);

            if (!vaultWhitelist.isCustomer(msg.sender)) revert VP_CustomerNotPermissioned();

            if (_destination != msg.sender) {
                if (!vaultWhitelist.isCustomer(_destination)) revert VP_CustomerNotPermissioned();
            }
        }

        // get current round
        uint256 round = vault.vaultState().round;

        PauseReceipt memory pauseReceipt = pausedPositions[_vault][msg.sender];

        uint256 pauseReceiptRound = pauseReceipt.round;

        // check if round is closed before withdrawing user funds
        if (pauseReceiptRound >= round) revert VP_RoundOpen();

        // delete position once transfer (revert to zero)
        delete pausedPositions[_vault][msg.sender];

        _withdrawCollaterals(vault, pauseReceipt, _destination);
    }

    /**
     * @notice process withdrawals
     * @dev receives assets amount from vault
     */
    function processVaultWithdraw(uint256[] calldata balances) external override {
        address _vault = msg.sender;
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        IHashnoteVault vault = IHashnoteVault(_vault);
        // we can only process withdrawal after closing the previous round
        // hence round should be - 1
        uint256 round = vault.vaultState().round - 1;

        roundBalances[address(vault)][round] = balances;

        emit ProcessWithdraws(_vault, round, balances);
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     * @param amount of the recovered token to send
     */
    function recoverTokens(address token, address recipient, uint256 amount) external {
        _onlyOwner();

        if (recipient == address(0) || recipient == address(this)) revert BadAddress();

        IERC20(token).safeTransfer(recipient, amount);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    /**
     * @notice Helper function to withdraw collateral for a given vault account
     */
    function _withdrawCollaterals(IHashnoteVault vault, PauseReceipt memory pauseReceipt, address _destination) internal {
        uint256 round = pauseReceipt.round;
        uint256[] memory balances = roundBalances[address(vault)][round];
        uint256 totalShares = roundTotalShares[address(vault)][round];

        Collateral[] memory collaterals = vault.getCollaterals();

        uint256[] memory amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            amounts[i] = balances[i].mulDivDown(pauseReceipt.shares, totalShares);

            if (amounts[i] > 0) IERC20(collaterals[i].addr).safeTransfer(_destination, amounts[i]);

            unchecked {
                ++i;
            }
        }

        emit Withdraw(msg.sender, address(vault), amounts);
    }
}
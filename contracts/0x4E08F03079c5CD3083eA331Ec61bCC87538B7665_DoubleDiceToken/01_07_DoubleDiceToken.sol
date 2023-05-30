// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
 
import "./IDoubleDiceToken.sol";

/**
 *                            ________
 *                 ________  / o   o /\
 *                /     o /\/   o   /o \ 
 *               /   o   /  \o___o_/o   \
 *              /_o_____/o   \     \   o/ 
 *              \ o   o \   o/  o   \ o/ 
 *  ______     __\ o   o \  /\_______\/       _____     ____    ____    ____   _______ 
 * |  __  \   /   \_o___o_\/ |  _ \  | |     |  ___|   |  _ \  |_  _|  / ___| |   ____|
 * | |  \  | | / \ | | | | | | |_| | | |     | |_      | | \ |   ||   | /     |  |
 * | |   | | | | | | | | | | |  _ <  | |     |  _|     | | | |   I|   | |     |  |__
 * |D|   |D| |O\_/O| |U|_|U| |B|_|B| |L|___  |E|___    |D|_/D|  _I|_  |C\___  |EEEEE| 
 * |D|__/DD|  \OOO/   \UUU/  |BBBB/  |LLLLL| |EEEEE|   |DDDD/  |IIII|  \CCCC| |EE|____ 
 * |DDDDDD/  ================================================================ |EEEEEEE| 
 *
 * @title DoubleDice DODI token contract
 * @author DoubleDice Team <[email protected]>
 * @custom:security-contact [email protected]
 * @notice ERC-20 token extended with special yield-distribution functionality.
 *
 * A supply of 10 billion DODI was minted at contract creation: 
 * - 6.3 billion were minted to an initial token holder `initTokenHolder` 
 * - 3.7 billion were minted to a reserved `UNDISTRIBUTED_YIELD_ACCOUNT` address 
 * 
 * It is not possible to mint further DODI beyond the 10 billion DODI minted at contract creation. 
 *
 * The DODI on the `UNDISTRIBUTED_YIELD_ACCOUNT` is controlled by the `owner()` of this contract. 
 * The `owner()` may choose to: 
 * - Distribute a portion or all of the remaining undistributed yield to token holders via `distributeYield` 
 * - Burn a portion or all of the remaining undistributed yield via `burnUndistributedYield`, 
 *   thus decreasing the total DODI supply 
 *
 * The `owner()` of this contract has no special powers besides the ability 
 * to distribute or burn the 3.7 billion DODI yield.
 *
 * When an amount of yield is released from `UNDISTRIBUTED_YIELD_ACCOUNT` to be distributed to token 
 * holders, it is transferred to a second reserved `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` address. 
 * Token holders may then call `claimYield()` to transfer their received yield
 * from `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` to themselves.
 * 
 * Different operations affect `balanceOf(account)` and `unclaimedYieldOf(account)` as follows: 
 * - `transfer` and `transferFrom` alter `balanceOf(account)`, 
 *   but without altering `unclaimedYieldOf(account)`. 
 * - Unless `account` is explicitly excluded from a distribution, `distributeYield` alters `unclaimedYieldOf(account)`,
 *   but without altering `balanceOf(account)`. 
 * - `claimYield` and `claimYieldFor` alter both `balanceOf(account)` and `unclaimedYieldOf(account)`,
 *   but without altering their sum `balanceOf(account) + unclaimedYieldOf(account)` 
 */
contract DoubleDiceToken is
    IDoubleDiceToken, 
    ERC20("DoubleDice Token", "DODI"),
    Ownable
{
    /// @notice Account holding the portion of the 3.7 billion DODI that have not yet been distributed or burned by `owner()` 
    address constant public UNDISTRIBUTED_YIELD_ACCOUNT = 0xD0D1000000000000000000000000000000000001;

    /// @notice Account holding yield that has been distributed, but not yet claimed by its recipient
    address constant public UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT = 0xd0D1000000000000000000000000000000000002; 
 
    function _isReservedAccount(address account) internal pure returns (bool) { 
        return account == UNDISTRIBUTED_YIELD_ACCOUNT || account == UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT;
    }

    /// @dev Holds unclaimed-yield state for a specific account 
    struct AccountEntry {
        /// @dev The amount of unclaimed tokens for this account, at the instant it was last updated in 
        /// either `_captureUnclaimedYield()`, or `claimYieldFor()` or `distributeYield()`.
        uint256 capturedUnclaimedYield;

        /// @dev The value of `_factor` at the instant `capturedUnclaimedYield` was last updated
        uint256 factorAtCapture; 
    }
 
    /// @dev The state for an account is stored in this mapping in conjunction with 
    /// the ERC-20 balance, which is managed in the base ERC20 contract 
    mapping(address => AccountEntry) internal _entries;
 
    /// @dev Sets the precision at which calculations are performed in this contract.
    /// The larger the value of `ONE`, the more miniscule the rounding errors in this contract. 
    /// With `ONE` set to 1e47, it can be proven that the largest computation in this contract
    /// will never result in uint256 overflow, given the following 3 assumptions hold true. 
    uint256 constant internal ONE = 1e47;

    /// @dev Assumption 1 of 3: Holds true because the contract was created with 10 billion * 1e18 tokens 
    uint256 constant private _ASSUMED_MAX_INIT_TOTAL_SUPPLY = 20e9 * 1e18; 
 
    /// @dev Assumption 2 of 3: Holds true because 10 / (10 - 3.7) = 1.5873 <= 2
    uint256 constant private _ASSUMED_MAX_INIT_TOTAL_TO_INIT_CIRCULATING_SUPPLY_RATIO = 2;
 
    /// @dev Assumption 3 of 3: Holds true because it is `require`-d in `distributeYield()` 
    uint256 constant private _ASSUMED_MIN_TOTAL_CIRCULATING_TO_EXCLUDED_CIRCULATING_SUPPLY_RATIO = 2; 

    function _checkOverflowProtectionAssumptionsConstructor(uint256 initTotalSupply, uint256 totalYieldAmount) internal pure {
        require(initTotalSupply <= _ASSUMED_MAX_INIT_TOTAL_SUPPLY, "Broken assumption"); 
        uint256 initCirculatingSupply = initTotalSupply - totalYieldAmount;
        // C/T = initCirculatingSupply / initTotalSupply >= 0.5
        require(initCirculatingSupply * _ASSUMED_MAX_INIT_TOTAL_TO_INIT_CIRCULATING_SUPPLY_RATIO >= initTotalSupply, "Broken assumption"); 
    }
 
    function _checkOverflowProtectionAssumptionsDistributeYield(uint256 totalCirculatingSupply, uint256 excludedCirculatingSupply) internal pure { 
        // epsilon = excludedCirculatingSupply / totalCirculatingSupply <= 0.5
        require((excludedCirculatingSupply * _ASSUMED_MIN_TOTAL_CIRCULATING_TO_EXCLUDED_CIRCULATING_SUPPLY_RATIO) <= totalCirculatingSupply, "Broken assumption");
    } 
 
    /// @dev Yield distribution to all accounts is recorded by increasing (eagerly) this contract-wide `_factor`, 
    /// and received yield is acknowledged by an `account` by reconciling (lazily) its `_entries[account]`
    /// with this contract-wide `_factor`.
    uint256 internal _factor;
 
    /// @notice Returns `balanceOf(account) + unclaimedYieldOf(account)`
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    function balancePlusUnclaimedYieldOf(address account) public view returns (uint256) { 
        require(!_isReservedAccount(account), "Reserved account");

        AccountEntry storage entry = _entries[account];
        return ((ONE + _factor) * (balanceOf(account) + entry.capturedUnclaimedYield)) / (ONE + entry.factorAtCapture);
    } 

    /// @notice Returns the total yield token amount claimable by `account`.
    /// @dev The tokens received by `account` during a yield-distribution do not appear immediately on `balanceOf(account)`, 
    /// but they appear instantly on `unclaimedYieldOf(account)` and `balancePlusUnclaimedYieldOf(account)`.
    /// Transferring tokens from `account` to another account `other` does not affect 
    /// `unclaimedYieldOf(account)` or `unclaimedYieldOf(other)`.
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` 
    function unclaimedYieldOf(address account) public view returns (uint256) {
        return balancePlusUnclaimedYieldOf(account) - balanceOf(account);
    }

    /// @notice Emitted every time the yield claimable by `account` increases by a non-zero amount `byAmount`. 
    /// After `claimYieldFor(account)` is called, the sum of all yield ever claimed for `account`,
    /// (which equals the total amount ever transferred from `UNCLAIMED_DISTRIBUTED_YIELD` to `account`),
    /// should equal the sum of `byAmount` over all `UnclaimedYieldIncrease` events ever emitted for `account`.
    event UnclaimedYieldIncrease(address indexed account, uint256 byAmount);
 
    /// @dev The value `unclaimedYieldOf(account)` always reflects  exact amount of yield that is claimable by `account`.
    /// If there is a discrepancy between `unclaimedYieldOf(account)` and the value present in `_entries[account].capturedUnclaimedYield`,
    /// then this function rectifies that discrepancy while maintaining `balanceOf(account)` and `unclaimedYieldOf(account)` constant.
    function _captureUnclaimedYield(address account) internal {
        AccountEntry storage entry = _entries[account];

        // _factor can only increase, never decrease 
        assert(entry.factorAtCapture <= _factor); 
 
        if (entry.factorAtCapture == _factor) { 
            // No yield distribution since last calculation
            return; 
        } 

        // Recalculate *before* `factorAtCapture` is updated, 
        // because `unclaimedYieldOf` depends on its value pre-update
        uint256 newUnclaimedYield = unclaimedYieldOf(account);
 
        // Update *after* `unclaimedYieldOf` has been calculated 
        entry.factorAtCapture = _factor; 

        // Finally update `capturedUnclaimedYield` 
        uint256 increase = newUnclaimedYield - entry.capturedUnclaimedYield;
        if (increase > 0) { 
            entry.capturedUnclaimedYield = newUnclaimedYield;
            emit UnclaimedYieldIncrease(account, increase); 
        }
    } 
 
    constructor( 
        uint256 initTotalSupply, 
        uint256 totalYieldAmount,
        address initTokenHolder 
    ) {
        require(totalYieldAmount <= initTotalSupply, "Invalid params"); 
 
        _checkOverflowProtectionAssumptionsConstructor(initTotalSupply, totalYieldAmount);
 
        // invoke ERC._mint directly to bypass yield corrections
        ERC20._mint(UNDISTRIBUTED_YIELD_ACCOUNT, totalYieldAmount);
        ERC20._mint(initTokenHolder, initTotalSupply - totalYieldAmount);
    }


    /// @dev Overriding `_transfer` affects `transfer` and `transferFrom`. 
    /// `_mint` and `_burn` could be overridden in a similar fashion, but are not, 
    /// as all mints and burns are done directly via `ERC20._mint` and `ERC20._burn`
    /// so as to bypass yield correction. 
    /// @custom:reverts-with "Transfer from reserved account" if `from` is `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    /// @custom:reverts-with "Transfer to reserved account" if `to` is `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(!_isReservedAccount(from), "Transfer from reserved account");
        require(!_isReservedAccount(to), "Transfer to reserved account"); 
        _captureUnclaimedYield(from);
        _captureUnclaimedYield(to);
        // invoke ERC._transfer directly to bypass yield corrections 
        ERC20._transfer(from, to, amount); 
    }
 
    event YieldDistribution(uint256 yieldDistributed, address[] excludedAccounts); 
 
    /// @notice Distribute yield to all token holders except `excludedAccounts` 
    /// @custom:reverts-with "Ownable: caller is not the owner" if called by an account that is not `owner()`
    /// @custom:reverts-with "Duplicate/unordered account" if `excludedAccounts` contains 0-account,
    /// @custom:reverts-with "Reserved account" if `excludedAccounts` contains `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`,
    /// is not in ascending order, or contains duplicate addresses. 
    /// @custom:reverts-with "Broken assumption" if the total `balancePlusUnclaimedYieldOf` for all `excludedAccounts` 
    /// exceeds half the circulating supply (which is `totalSupply() - balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT)`). 
    /// @custom:emits-event UnclaimedYieldIncrease if operation results in an increase in `capturedUnclaimedYield` 
    /// for one of the `excludedAccounts`
    /// @custom:emits-event Transfer(UNDISTRIBUTED_YIELD_ACCOUNT, UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, yieldDistributed)
    /// @custom:emits-event YieldDistribution(amount, excludedAccounts)
    function distributeYield(uint256 amount, address[] calldata excludedAccounts) external onlyOwner {
        // ERC20 functions reject mints/transfers to zero-address, 
        // so zero-address can never have balance that we want to exclude from calculations. 
        address prevExcludedAccount = 0x0000000000000000000000000000000000000000; 

        uint256 excludedCirculatingSupply = 0; 
        for (uint256 i = 0; i < excludedAccounts.length; i++) {
            address account = excludedAccounts[i]; 
 
            require(prevExcludedAccount < account, "Duplicate/unordered account"); 
            prevExcludedAccount = account; // prepare for next iteration immediately 
 
            require(!_isReservedAccount(account), "Reserved account"); 

            // The excluded account itself might have a stale `capturedUnclaimedYield` value, 
            // so it is brought up to date with pre-distribution `_factor` 
            _captureUnclaimedYield(account);

            excludedCirculatingSupply += balancePlusUnclaimedYieldOf(account);
        } 

        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (sumOfBalanceOfExcluded + balanceOf(UNCLAIMED_DISTRIBUTED_YIELD) + sumOfBalanceOfIncludedBefore)
        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (            excludedCirculatingSupply        +        includedCirculatingSupplyBefore         ) 
        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (                               totalCirculatingSupplyBefore                                   ) 
        uint256 totalCirculatingSupplyBefore = totalSupply() - balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT);

        _checkOverflowProtectionAssumptionsDistributeYield(totalCirculatingSupplyBefore, excludedCirculatingSupply); 
 
        // includedCirculatingSupplyBefore = sum(balancePlusUnclaimedYieldOf(account) for account in includedAccounts)
        uint256 includedCirculatingSupplyBefore = totalCirculatingSupplyBefore - excludedCirculatingSupply; 

        // totalSupply = (balanceBeforeOf(UNDISTRIBUTED_YIELD)         ) + (           includedCirculatingSupplyBefore) + (excludedCirculatingSupply)
        // totalSupply = (balanceBeforeOf(UNDISTRIBUTED_YIELD) - amount) + (amount  +  includedCirculatingSupplyBefore) + (excludedCirculatingSupply)
        // totalSupply = (     balanceAfterOf(UNDISTRIBUTED_YIELD)     ) + (    includedCirculatingSupplyAfter        ) + (excludedCirculatingSupply) 
        uint256 includedCirculatingSupplyAfter = includedCirculatingSupplyBefore + amount; 
 
        _factor = ((ONE + _factor) * includedCirculatingSupplyAfter) / includedCirculatingSupplyBefore - ONE; 

        for (uint256 i = 0; i < excludedAccounts.length; i++) {
            // Force this account to "miss out on" this distribution
            // by "fast-forwarding" its `_factor` to the new value 
            // without actually changing its balance or unclaimedYield 
            _entries[excludedAccounts[i]].factorAtCapture = _factor; 
        } 

        // invoke ERC._transfer directly to bypass yield corrections 
        ERC20._transfer(UNDISTRIBUTED_YIELD_ACCOUNT, UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, amount); 

        emit YieldDistribution(amount, excludedAccounts);
    } 

    /// @notice Burn an `amount` of undistributed yield. 
    /// @custom:reverts-with "Ownable: caller is not the owner" if called by an account that is not `owner()` 
    /// @custom:reverts-with "ERC20: burn amount exceeds balance" if `amount` exceeds `balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT)`
    /// @custom:emits-event "Transfer(UNDISTRIBUTED_YIELD_ACCOUNT, address(0), amount)" 
    function burnUndistributedYield(uint256 amount) external onlyOwner {
        // invoke ERC._transfer directly to bypass yield corrections 
        ERC20._burn(UNDISTRIBUTED_YIELD_ACCOUNT, amount); 
    }
 
    /// @notice Yield received by `account` from a distribution will be reflected in `balanceOf(account)` 
    /// only after `claimYieldFor(account)` has been called. 
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    /// @custom:emits-event UnclaimedYieldIncrease if operation results in an increase in `capturedUnclaimedYield` 
    /// @custom:emits-event Transfer(UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, account, unclaimedYieldOf(account)) 
    function claimYieldFor(address account) public { 

        // Without this check (and without the check in balancePlusUnclaimedYieldOf), 
        // it would be possible for anyone to claim yield for one of the reserved accounts, 
        // and this would destabilize the accounting system.
        require(!_isReservedAccount(account), "Reserved account"); 

        // Not entirely necessary, because ERC20._transfer will block 0-account 
        // from receiving any balance, but it is stopped in its tracks anyway. 
        require(account != address(0), "Zero account");
 
        _captureUnclaimedYield(account); 
        AccountEntry storage entry = _entries[account]; 
 
        // balanceOf(account) += entry.capturedUnclaimedYield 
        // entry.capturedUnclaimedYield -= entry.capturedUnclaimedYield
        // => (balanceOf(account) + entry.capturedUnclaimedYield) is invariant
        ERC20._transfer(UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, account, entry.capturedUnclaimedYield); 
        entry.capturedUnclaimedYield = 0;
 
        // A `Transfer` event from `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` always signifies a yield-claim,
        // so no special "YieldClaim" event is emitted 
    } 

    /// @notice Calls `claimYieldFor` for the caller.
    function claimYield() external override {
        claimYieldFor(_msgSender()); 
    }
}
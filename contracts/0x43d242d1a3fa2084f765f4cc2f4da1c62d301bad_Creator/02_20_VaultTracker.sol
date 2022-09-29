// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/lib/Compounding.sol';

import 'src/interfaces/IVaultTracker.sol';

contract VaultTracker is IVaultTracker {
    /// @notice A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    struct Vault {
        uint256 notional;
        uint256 redeemable;
        uint256 exchangeRate;
        uint256 accrualBlock;
    }

    mapping(address => Vault) public vaults;

    address public immutable cTokenAddr;
    address public immutable marketPlace;
    address public immutable swivel;
    uint256 public immutable maturity;
    uint256 public maturityRate;
    uint8 public immutable protocol;

    /// @param m Maturity timestamp associated with this vault
    /// @param c Compounding Token address associated with this vault
    /// @param s Address of the deployed swivel contract
    /// @param mp Address of the designated admin, which is the Marketplace addess stored by the Creator contract
    constructor(
        uint8 p,
        uint256 m,
        address c,
        address s,
        address mp
    ) {
        protocol = p;
        maturity = m;
        cTokenAddr = c;
        swivel = s;
        marketPlace = mp;

        // instantiate swivel's vault (unblocking transferNotionalFee)
        vaults[s] = Vault({
            notional: 0,
            redeemable: 0,
            exchangeRate: Compounding.exchangeRate(p, c),
            accrualBlock: block.number
        });
    }

    /// @notice Adds notional to a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional added
    function addNotional(address o, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory vlt = vaults[o];

        if (vlt.notional > 0) {
            // If marginal interest has not been calculated up to the current block, calculate marginal interest and update exchangeRate + accrualBlock
            if (vlt.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
                // otherwise, calculate marginal exchange rate between current and previous exchange rate.
                uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
                uint256 interest = (yield * (vlt.notional + vlt.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                vlt.redeemable = vlt.redeemable + interest;
                // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
                vlt.exchangeRate = mRate < xRate ? mRate : xRate;
                // set vault's accrual block to the current block
                vlt.accrualBlock = block.number;
            }
            vlt.notional = vlt.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // set notional
            vlt.notional = a;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }

        vaults[o] = vlt;

        return true;
    }

    /// @notice Removes notional from a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional to remove
    function removeNotional(address o, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory vlt = vaults[o];

        if (a > vlt.notional) {
            revert Exception(31, a, vlt.notional, o, address(0));
        }

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            vlt.redeemable = vlt.redeemable + interest;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = maturityRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }
        vlt.notional = vlt.notional - a;

        vaults[o] = vlt;

        return true;
    }

    /// @notice Redeem's interest accrued by a given address
    /// @param o Address that owns a vault
    function redeemInterest(address o)
        external
        authorized(marketPlace)
        returns (uint256)
    {
        Vault memory vlt = vaults[o];

        uint256 redeemable = vlt.redeemable;

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;

            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            vlt.accrualBlock = block.number;
            // adds marginal interest to previously accrued redeemable interest
            redeemable += interest;
        }
        vlt.redeemable = 0;

        vaults[o] = vlt;

        // returns current redeemable if already accrued, redeemable + interest if not
        return redeemable;
    }

    /// @notice Matures the vault
    /// @param c The current cToken exchange rate
    function matureVault(uint256 c)
        external
        authorized(marketPlace)
        returns (bool)
    {
        maturityRate = c;
        return true;
    }

    /// @notice Transfers notional from one address to another
    /// @param f Owner of the amount
    /// @param t Recipient of the amount
    /// @param a Amount to transfer
    function transferNotionalFrom(
        address f,
        address t,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        if (f == t) {
            revert Exception(32, 0, 0, f, t);
        }

        Vault memory from = vaults[f];

        if (a > from.notional) {
            revert Exception(31, a, from.notional, f, t);
        }

        if (from.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / from.exchangeRate) - 1e26;
            uint256 interest = (yield * (from.notional + from.redeemable)) /
                1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            from.redeemable = from.redeemable + interest;
            from.exchangeRate = mRate < xRate ? mRate : xRate;
            from.accrualBlock = block.number;
        }
        from.notional = from.notional - a;
        vaults[f] = from;

        Vault memory to = vaults[t];

        // transfer notional to address "t", calculate interest if necessary
        if (to.notional > 0) {
            // if interest hasnt been calculated within the block, calculate it
            if (from.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                uint256 yield = ((mRate * 1e26) / to.exchangeRate) - 1e26;
                uint256 interest = (yield * (to.notional + to.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                to.redeemable = to.redeemable + interest;
                to.exchangeRate = mRate < xRate ? mRate : xRate;
                to.accrualBlock = block.number;
            }
            to.notional = to.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            to.notional = a;
            to.exchangeRate = mRate < xRate ? mRate : xRate;
            to.accrualBlock = block.number;
        }

        vaults[t] = to;

        return true;
    }

    /// @notice Transfers, in notional, a fee payment to the Swivel contract without recalculating marginal interest for the owner
    /// @param f Owner of the amount
    /// @param a Amount to transfer
    function transferNotionalFee(address f, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory oVault = vaults[f];

        if (a > oVault.notional) {
            revert Exception(31, a, oVault.notional, f, address(0));
        }
        // remove notional from its owner, marginal interest has been calculated already in the tx
        oVault.notional = oVault.notional - a;

        Vault memory sVault = vaults[swivel];

        // check if exchangeRate has been stored already this block. If not, calculate marginal interest + store exchangeRate
        if (sVault.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / sVault.exchangeRate) - 1e26;
            uint256 interest = (yield * (sVault.notional + sVault.redeemable)) /
                1e26;
            // add interest and amount, reset cToken exchange rate
            sVault.redeemable = sVault.redeemable + interest;
            // set to maturityRate only if both > 0 && < exchangeRate
            sVault.exchangeRate = (mRate < xRate) ? mRate : xRate;
            // set current accrual block
            sVault.accrualBlock = block.number;
        }
        // add notional to swivel's vault
        sVault.notional = sVault.notional + a;
        // store the adjusted vaults
        vaults[swivel] = sVault;
        vaults[f] = oVault;
        return true;
    }

    /// @notice Return both the current maturityRate if it's > 0 (or exchangeRate in its place) and the Compounding exchange rate
    /// @dev While it may seem unnecessarily redundant to return the exchangeRate twice, it prevents many kludges that would otherwise be necessary to guard it
    /// @return maturityRate, exchangeRate if maturityRate > 0, exchangeRate, exchangeRate if not.
    function rates() public returns (uint256, uint256) {
        uint256 exchangeRate = Compounding.exchangeRate(protocol, cTokenAddr);
        return ((maturityRate > 0 ? maturityRate : exchangeRate), exchangeRate);
    }

    /// @notice Returns both relevant balances for a given user's vault
    /// @param o Address that owns a vault
    function balancesOf(address o) external view returns (uint256, uint256) {
        Vault memory vault = vaults[o];
        return (vault.notional, vault.redeemable);
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}
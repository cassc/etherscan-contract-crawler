// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/lib/Compounding.sol';

import 'src/interfaces/IMarketPlace.sol';
import 'src/interfaces/ICreator.sol';
import 'src/interfaces/ISwivel.sol';
import 'src/interfaces/IVaultTracker.sol';
import 'src/interfaces/IZcToken.sol';

contract MarketPlace is IMarketPlace {
    /// @dev A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    struct Market {
        address cTokenAddr;
        address zcToken;
        address vaultTracker;
        uint256 maturityRate;
    }

    mapping(uint8 => mapping(address => mapping(uint256 => Market)))
        public markets;
    mapping(uint8 => bool) public paused;

    address public admin;
    address public swivel;
    address public immutable creator;

    event Create(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address cToken,
        address zcToken,
        address vaultTracker
    );
    event Mature(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        uint256 maturityRate,
        uint256 matured
    );
    event RedeemZcToken(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address sender,
        uint256 amount
    );
    event RedeemVaultInterest(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address sender
    );
    event CustodialInitiate(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address zcTarget,
        address nTarget,
        uint256 amount
    );
    event CustodialExit(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address zcTarget,
        address nTarget,
        uint256 amount
    );
    event P2pZcTokenExchange(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event P2pVaultExchange(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event TransferVaultNotional(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event SetAdmin(address indexed admin);

    /// @param c Address of the deployed creator contract
    constructor(address c) {
        admin = msg.sender;
        creator = c;
    }

    /// @param s Address of the deployed swivel contract
    /// @notice We only allow this to be set once
    /// @dev there is no emit here as it's only done once post deploy by the deploying admin
    function setSwivel(address s) external authorized(admin) returns (bool) {
        if (swivel != address(0)) {
            revert Exception(20, 0, 0, swivel, address(0));
        }

        swivel = s;
        return true;
    }

    /// @param a Address of a new admin
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;

        emit SetAdmin(a);

        return true;
    }

    /// @notice Allows the owner to create new markets
    /// @param p Protocol associated with the new market
    /// @param m Maturity timestamp of the new market
    /// @param c Compounding Token address associated with the new market
    /// @param n Name of the new market zcToken
    /// @dev the memory allocation of `s` is for alleviating STD err, there's no clearly superior scoping or abstracting alternative.
    /// @param s Symbol of the new market zcToken
    function createMarket(
        uint8 p,
        uint256 m,
        address c,
        string calldata n,
        string memory s
    ) external authorized(admin) unpaused(p) returns (bool) {
        if (swivel == address(0)) {
            revert Exception(21, 0, 0, address(0), address(0));
        }

        address underAddr = Compounding.underlying(p, c);

        if (markets[p][underAddr][m].vaultTracker != address(0)) {
            // NOTE: not saving and publishing that found tracker addr as stack limitations...
            revert Exception(22, 0, 0, address(0), address(0));
        }

        (address zct, address tracker) = ICreator(creator).create(
            p,
            underAddr,
            m,
            c,
            swivel,
            n,
            s,
            IERC20(underAddr).decimals()
        );

        markets[p][underAddr][m] = Market(c, zct, tracker, 0);

        emit Create(p, underAddr, m, c, zct, tracker);

        return true;
    }

    /// @notice Can be called after maturity, allowing all of the zcTokens to earn floating interest on Compound until they release their funds
    /// @param p Protocol Enum value associated with the market being matured
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    function matureMarket(
        uint8 p,
        address u,
        uint256 m
    ) public unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (market.maturityRate != 0) {
            revert Exception(
                23,
                market.maturityRate,
                0,
                address(0),
                address(0)
            );
        }

        if (block.timestamp < m) {
            revert Exception(24, block.timestamp, m, address(0), address(0));
        }

        // set the base maturity cToken exchange rate at maturity to the current cToken exchange rate
        uint256 xRate = Compounding.exchangeRate(p, market.cTokenAddr);
        markets[p][u][m].maturityRate = xRate;

        // NOTE we don't check the return of this simple operation
        IVaultTracker(market.vaultTracker).matureVault(xRate);

        emit Mature(p, u, m, xRate, block.timestamp);

        return true;
    }

    /// @notice Allows Swivel caller to deposit their underlying, in the process splitting it - minting both zcTokens and vault notional.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the depositing user
    /// @param a Amount of notional being added
    function mintZcTokenAddingNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (!IZcToken(market.zcToken).mint(t, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).addNotional(t, a)) {
            revert Exception(25, 0, 0, address(0), address(0));
        }

        return true;
    }

    /// @notice Allows Swivel caller to deposit/burn both zcTokens + vault notional. This process is "combining" the two and redeeming underlying.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the combining/redeeming user
    /// @param a Amount of zcTokens being burned
    function burnZcTokenRemovingNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (!IZcToken(market.zcToken).burn(t, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).removeNotional(t, a)) {
            revert Exception(26, 0, 0, address(0), address(0));
        }

        return true;
    }

    /// @notice Implementation of authRedeem to fulfill the IRedeemer interface for ERC5095
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Address of the user having their zcTokens burned
    /// @param t Address of the user receiving underlying
    /// @param a Amount of zcTokens being redeemed
    /// @return Amount of underlying being withdrawn (needed for 5095 return)
    function authRedeem(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    )
        external
        authorized(markets[p][u][m].zcToken)
        unpaused(p)
        returns (uint256)
    {
        /// @dev swiv needs to be set or the call to authRedeem there will be faulty
        if (swivel == address(0)) {
            revert Exception(21, 0, 0, address(0), address(0));
        }

        Market memory market = markets[p][u][m];
        // if the market has not matured, mature it...
        if (market.maturityRate == 0) {
            if (!matureMarket(p, u, m)) {
                revert Exception(30, 0, 0, address(0), address(0));
            }
        }

        if (!IZcToken(market.zcToken).burn(f, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        // depending on initial market maturity status adjust (or don't) the amount to be redemmed/returned
        uint256 amount = market.maturityRate == 0
            ? a
            : calculateReturn(p, u, m, a);

        if (!ISwivel(swivel).authRedeem(p, u, market.cTokenAddr, t, amount)) {
            revert Exception(37, amount, 0, market.cTokenAddr, t);
        }

        emit RedeemZcToken(p, u, m, t, amount);

        return amount;
    }

    /// @notice Allows (via swivel) zcToken holders to redeem their tokens for underlying tokens after maturity has been reached.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the redeeming user
    /// @param a Amount of zcTokens being redeemed
    function redeemZcToken(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (uint256) {
        Market memory market = markets[p][u][m];

        // if the market has not matured, mature it and redeem exactly the amount
        if (market.maturityRate == 0) {
            if (!matureMarket(p, u, m)) {
                revert Exception(30, 0, 0, address(0), address(0));
            }
        }

        if (!IZcToken(market.zcToken).burn(t, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        emit RedeemZcToken(p, u, m, t, a);

        if (market.maturityRate == 0) {
            return a;
        } else {
            // if the market was already mature the return should include the amount + marginal floating interest generated on Compound since maturity
            return calculateReturn(p, u, m, a);
        }
    }

    /// @notice Allows Vault owners (via Swivel) to redeem any currently accrued interest
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the redeeming user
    function redeemVaultInterest(
        uint8 p,
        address u,
        uint256 m,
        address t
    ) external authorized(swivel) unpaused(p) returns (uint256) {
        // call to the floating market contract to release the position and calculate the interest generated
        uint256 interest = IVaultTracker(markets[p][u][m].vaultTracker)
            .redeemInterest(t);

        emit RedeemVaultInterest(p, u, m, t);

        return interest;
    }

    /// @notice Calculates the total amount of underlying returned including interest generated since the `matureMarket` function has been called
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param a Amount of zcTokens being redeemed
    function calculateReturn(
        uint8 p,
        address u,
        uint256 m,
        uint256 a
    ) internal returns (uint256) {
        Market memory market = markets[p][u][m];

        uint256 xRate = Compounding.exchangeRate(p, market.cTokenAddr);

        return (a * xRate) / market.maturityRate;
    }

    /// @notice Return the compounding token address for a given market
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    function cTokenAddress(
        uint8 p,
        address u,
        uint256 m
    ) external view returns (address) {
        return markets[p][u][m].cTokenAddr;
    }

    /// @notice Return the exchange rate for a given protocol's compounding token
    /// @param p Protocol Enum value
    /// @param c Compounding token address
    function exchangeRate(uint8 p, address c) external returns (uint256) {
        return Compounding.exchangeRate(p, c);
    }

    /// @notice Return current rates (maturity, exchange) for a given vault. See VaultTracker.rates for details
    /// @dev While it's true that Compounding exchange rate is not strictly affiliated with a vault, the 2 data points are usually needed together.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @return maturityRate, exchangeRate*
    function rates(
        uint8 p,
        address u,
        uint256 m
    ) external returns (uint256, uint256) {
        return IVaultTracker(markets[p][u][m].vaultTracker).rates();
    }

    /// @notice Called by swivel IVFZI && IZFVI
    /// @dev Call with protocol, underlying, maturity, mint-target, add-notional-target and an amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param z Recipient of the minted zcToken
    /// @param n Recipient of the added notional
    /// @param a Amount of zcToken minted and notional added
    function custodialInitiate(
        uint8 p,
        address u,
        uint256 m,
        address z,
        address n,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];
        if (!IZcToken(market.zcToken).mint(z, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).addNotional(n, a)) {
            revert Exception(25, 0, 0, address(0), address(0));
        }

        emit CustodialInitiate(p, u, m, z, n, a);
        return true;
    }

    /// @notice Called by swivel EVFZE FF EZFVE
    /// @dev Call with protocol, underlying, maturity, burn-target, remove-notional-target and an amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param z Owner of the zcToken to be burned
    /// @param n Target to remove notional from
    /// @param a Amount of zcToken burned and notional removed
    function custodialExit(
        uint8 p,
        address u,
        uint256 m,
        address z,
        address n,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];
        if (!IZcToken(market.zcToken).burn(z, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).removeNotional(n, a)) {
            revert Exception(26, 0, 0, address(0), address(0));
        }

        emit CustodialExit(p, u, m, z, n, a);
        return true;
    }

    /// @notice Called by swivel IZFZE, EZFZI
    /// @dev Call with underlying, maturity, transfer-from, transfer-to, amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the zcToken to be burned
    /// @param t Target to be minted to
    /// @param a Amount of zcToken transfer
    function p2pZcTokenExchange(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        address zct = markets[p][u][m].zcToken;

        if (!IZcToken(zct).burn(f, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IZcToken(zct).mint(t, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        emit P2pZcTokenExchange(p, u, m, f, t, a);
        return true;
    }

    /// @notice Called by swivel IVFVE, EVFVI
    /// @dev Call with protocol, underlying, maturity, remove-from, add-to, amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the notional to be transferred
    /// @param t Target to be transferred to
    /// @param a Amount of notional transfer
    function p2pVaultExchange(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        if (
            !IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFrom(
                f,
                t,
                a
            )
        ) {
            revert Exception(27, 0, 0, address(0), address(0));
        }

        emit P2pVaultExchange(p, u, m, f, t, a);
        return true;
    }

    /// @notice External method giving access to this functionality within a given vault
    /// @dev Note that this method calculates yield and interest as well
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Target to be transferred to
    /// @param a Amount of notional to be transferred
    function transferVaultNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external unpaused(p) returns (bool) {
        if (
            !IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFrom(
                msg.sender,
                t,
                a
            )
        ) {
            revert Exception(27, 0, 0, address(0), address(0));
        }

        emit TransferVaultNotional(p, u, m, msg.sender, t, a);
        return true;
    }

    /// @notice Transfers notional fee to the Swivel contract without recalculating marginal interest for from
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the amount
    /// @param a Amount to transfer
    function transferVaultNotionalFee(
        uint8 p,
        address u,
        uint256 m,
        address f,
        uint256 a
    ) external authorized(swivel) returns (bool) {
        return
            IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFee(
                f,
                a
            );
    }

    /// @notice Called by admin at any point to pause / unpause market transactions in a specified protocol
    /// @param p Protocol Enum value of the protocol to be paused
    /// @param b Boolean which indicates the (protocol) markets paused status
    function pause(uint8 p, bool b) external authorized(admin) returns (bool) {
        paused[p] = b;
        return true;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }

    modifier unpaused(uint8 p) {
        if (paused[p]) {
            revert Exception(1, 0, 0, address(0), address(0));
        }
        _;
    }
}
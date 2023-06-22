/*
ERC20BondStakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IStakingModuleInfo.sol";
import "../interfaces/IStakingModule.sol";
import "../interfaces/IRewardModule.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IConfiguration.sol";
import "../ERC20BondStakingModule.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 bond staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20BondStakingModule contract.
 */
library ERC20BondStakingModuleInfo {
    using Strings for uint256;
    using Strings for address;
    using Address for address;
    using TokenUtilsInfo for IERC20;

    uint256 public constant MAX_BONDS = 128;

    // -- IStakingModuleInfo --------------------------------------------------

    /**
     * @notice convenience function to get all token metadata in a single call
     * @param module address of reward module
     * @return addresses_
     * @return names_
     * @return symbols_
     * @return decimals_
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory addresses_,
            string[] memory names_,
            string[] memory symbols_,
            uint8[] memory decimals_
        )
    {
        IStakingModule m = IStakingModule(module);

        addresses_ = m.tokens();
        names_ = new string[](addresses_.length);
        symbols_ = new string[](addresses_.length);
        decimals_ = new uint8[](addresses_.length);

        for (uint256 i; i < addresses_.length; ++i) {
            IERC20Metadata tkn = IERC20Metadata(addresses_[i]);
            names_[i] = tkn.name();
            symbols_[i] = tkn.symbol();
            decimals_[i] = tkn.decimals();
        }
    }

    /**
     * @notice get all staking positions for user
     * @param module address of staking module
     * @param addr user address of interest
     * @param data additional encoded data
     * @return accounts_
     * @return shares_
     */
    function positions(
        address module,
        address addr,
        bytes calldata data
    )
        external
        view
        returns (bytes32[] memory accounts_, uint256[] memory shares_)
    {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);
        uint256 count = m.balanceOf(addr);
        if (count > MAX_BONDS) count = MAX_BONDS;

        accounts_ = new bytes32[](count);
        shares_ = new uint256[](count);

        for (uint256 i; i < count; ++i) {
            uint256 id = m.ownerBonds(addr, i);
            (, , , uint256 debt) = m.bonds(id);
            accounts_[i] = bytes32(id);
            shares_[i] = debt;
        }
    }

    // -- IMetadata -----------------------------------------------------------

    /**
     * @notice provide the metadata URI for a bond position
     * @param module address of bond staking module
     * @param id bond position identifier
     */
    function metadata(
        address module,
        uint256 id,
        bytes calldata
    ) external view returns (string memory) {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);

        // get bond data
        (address market, uint64 timestamp, uint256 principal, uint256 debt) = m
            .bonds(id);
        IERC20Metadata stk = IERC20Metadata(market);
        require(timestamp > 0, "bsmi1");

        // try to get reward data
        address reward;
        if (m.owner().isContract()) {
            try
                IRewardModule(IPool(m.owner()).rewardModule()).tokens()
            returns (address[] memory r) {
                if (r.length == 1) reward = r[0];
            } catch {}
        }

        // svg
        bytes memory svg = abi.encodePacked(
            '<svg width="512"',
            ' height="512"',
            ' fill="',
            "white", //fg,
            '" font-size="24"',
            ' font-family="Monospace"',
            ' xmlns="http://www.w3.org/2000/svg">',
            '<rect x="0" y="0" width="100%" height="100%" style="fill:',
            "#080C42", //bg,
            '"<svg/>'
        );
        svg = abi.encodePacked(
            svg,
            '<text font-size="100%" y="10%" x="5%">',
            reward == address(0) ? "" : IERC20Metadata(reward).symbol(),
            " Bond Position</text>",
            '<text font-size="80%" y="18%" x="5%">Bond ID: ',
            id.toString(),
            "</text>"
        );
        svg = abi.encodePacked(
            svg,
            '<text font-size="60%" y="25%" x="5%">Principal token: ',
            stk.name(),
            "</text>",
            '<text font-size="60%" y="30%" x="5%">Remaining principal: ',
            (principal / 10 ** stk.decimals()).toString(),
            "</text>",
            '<text font-size="60%" y="35%" x="5%">Outstanding debt shares: ',
            (debt / 10 ** stk.decimals()).toString(),
            "</text>"
        );
        if (reward != address(0)) {
            svg = abi.encodePacked(
                svg,
                '<text font-size="60%" y="40%" x="5%">Reward token: ',
                IERC20Metadata(reward).name(),
                "</text>"
            );
        }
        svg = abi.encodePacked(svg, "</svg>");

        // attributes
        bytes memory attrs = abi.encodePacked(
            '{"principal_address":"',
            market.toHexString(),
            '","reward_address":"',
            reward.toHexString(),
            '","timestamp":',
            uint256(timestamp).toString(),
            ',"principal_shares":',
            principal.toString(),
            ',"debt_shares":',
            debt.toString(),
            "}"
        );

        // assemble metadata
        bytes memory data = abi.encodePacked(
            '{"name":"',
            reward == address(0) ? "" : IERC20Metadata(reward).symbol(),
            " Bond Position: ",
            id.toString(),
            '","description":"Bond position that was purchased with ',
            stk.name(),
            " and pays out in ",
            reward == address(0) ? "" : IERC20Metadata(reward).name(),
            '. Powered by GYSR Protocol.","image":"data:image/svg+xml;base64,',
            Base64.encode(svg),
            '","attributes":',
            attrs,
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(data)
                )
            );
    }

    // -- ERC20BondStakingModuleInfo ------------------------------------------

    /**
     * @notice quote the debt share values to be issued for an amount of tokens
     * @param module address of bond staking module
     * @param token address of market
     * @param amount number of tokens to be deposited
     * @return debt estimated debt shares issued
     * @return okay if debt amount is within max size and capacity of market (note: this does not check reward module funding)
     */
    function quote(
        address module,
        address token,
        uint256 amount
    ) public view returns (uint256, bool) {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);
        require(amount > 0, "bsmi2");

        // get market
        (, , uint256 mmax, uint256 mcapacity, uint256 mprincipal, , , , ) = m
            .markets(token);
        require(mmax > 0, "bsmi3");

        // principal shares
        uint256 principal = (mprincipal > 0)
            ? IERC20(token).getShares(module, mprincipal, amount)
            : amount * 1e6;

        // get current price
        uint256 price_ = price(module, token);

        // debt pricing
        uint256 debt = (principal * 1e18) / price_;

        return (debt, debt <= mmax && debt <= mcapacity);
    }

    /**
     * @notice quote the debt share values to be issued for an amount of tokens after protocol fees
     * @param module address of bond staking module
     * @param token address of market
     * @param amount number of tokens to be deposited
     * @param config address of configuration contract
     * @return debt estimated debt shares issued
     * @return okay if debt amount is within max size and capacity of market (note: this does not check reward module funding)
     */
    function quote(
        address module,
        address token,
        uint256 amount,
        address config
    ) external view returns (uint256, bool) {
        // get rate
        IConfiguration cfg = IConfiguration(config);
        (, uint256 rate) = cfg.getAddressUint96(
            keccak256("gysr.core.bond.stake.fee")
        );
        // subtract fee and get quote
        amount -= (amount * rate) / 1e18;
        return quote(module, token, amount);
    }

    /**
     * @notice get current price of debt share (reward token) in specified principal token shares
     * @param module address of bond staking module
     * @param token address of market
     * @return price current price of reward debt share in principal token shares
     */
    function price(
        address module,
        address token
    ) public view returns (uint256) {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);

        // get market
        (
            uint256 mprice,
            uint256 mcoeff,
            uint256 mmax,
            uint256 mcapacity,
            uint256 mprincipal,
            ,
            uint256 mdebt,
            uint128 mstart,
            uint128 mupdated
        ) = m.markets(token);
        require(mmax > 0, "bsmi4");

        // estimate debt decay
        uint256 end = mstart + m.period();
        if (block.timestamp < end) {
            mdebt -= (mdebt * (block.timestamp - mupdated)) / (end - mupdated); // approximation, exact value lower bound
        } else {
            mdebt = 0;
        }

        // current price
        return mprice + (mcoeff * mdebt) / 1e24;
    }

    /**
     * @notice preview amount of deposit to be returned for an unstake
     * @param module address of bond staking module
     * @param id bond position identifier
     * @param amount number of tokens to be unstaked (pass 0 for all)
     * @return principal token amount returned
     * @return debt shares to be redeemed (possibly not all vested)
     * @return okay if unstake is valid for bond id and principal amount
     */
    function unstakeable(
        address module,
        uint256 id,
        uint256 amount
    ) external view returns (uint256, uint256, bool) {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);

        // get bond and market
        (
            address btoken,
            uint64 btimestamp,
            uint256 bprincipal,
            uint256 bdebt
        ) = m.bonds(id);
        require(btimestamp > 0, "bsmi5");
        (, , , , uint256 mprincipal, , , , ) = m.markets(btoken);

        if (!m.burndown()) return (0, bdebt, amount == 0);

        uint256 period = m.period();
        uint256 elapsed = block.timestamp - btimestamp;

        // unstake specific nonzero amount
        if (amount > 0) {
            if (elapsed > period) return (0, bdebt, false);

            uint256 shares = IERC20(btoken).getShares(
                module,
                mprincipal,
                amount
            );
            uint256 burned = (shares * period) / (period - elapsed);
            uint256 debt = (bdebt * burned) / bprincipal;
            if (burned < bprincipal) return (amount, debt, true); // valid unstake
            // let invalid unstakes fall through to next block
        }

        // compute max returnable
        uint256 shares = elapsed < period
            ? (bprincipal * (period - elapsed)) / period
            : 0;

        return (
            IERC20(btoken).getAmount(module, mprincipal, shares),
            bdebt,
            amount == 0
        );
    }

    /**
     * @notice get current vested balance of specified principal token
     * @param module address of bond staking module
     * @param token address of market
     * @return withdrawable amount of principal token
     */
    function withdrawable(
        address module,
        address token
    ) public view returns (uint256) {
        ERC20BondStakingModule m = ERC20BondStakingModule(module);

        // get market
        (
            ,
            ,
            ,
            ,
            uint256 mprincipal,
            uint256 mvested,
            ,
            uint128 mstart,
            uint128 mupdated
        ) = m.markets(token);
        require(mstart > 0, "bsmi6");

        if (!m.burndown()) return mvested;

        // estimate principal vesting
        uint256 end = mstart + m.period();
        if (block.timestamp < end) {
            mvested +=
                ((mprincipal - mvested) * (block.timestamp - mupdated)) /
                (end - mupdated); // approximation, exact upper lower bound
        } else {
            mvested = mprincipal;
        }

        return IERC20(token).getAmount(module, mprincipal, mvested);
    }
}
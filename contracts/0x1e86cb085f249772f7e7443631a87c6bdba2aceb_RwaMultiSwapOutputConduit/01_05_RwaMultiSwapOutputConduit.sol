// SPDX-FileCopyrightText: © 2021 Lev Livnev <[email protected]>
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.6.12;

import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";
import {PsmAbstract} from "dss-interfaces/dss/PsmAbstract.sol";
import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";

/**
 * @author Lev Livnev <[email protected]>
 * @author 0xDecr1pto <[email protected]>
 * @title An Output Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaSwapOutputConduit](https://github.com/makerdao/rwa-toolkit/blob/92c79aac24ef7645902ce4be57ba41b19e6c7dd5/src/conduits/RwaSwapOutputConduit.sol):
 * - This conduit can handle multiple PSM. (`pal` whitelist of PSM's)
 * - Using `clap/slap` for managing the PSM whitelist.
 * - Using `hook` method for choosing PSM address. (PSM address should be whitelisted)
 * - `push` and `push(amt)` swap DAI to GEM using selected (`hooked`) PSM address.
 * - It's not possible to make `pick` and `push` permissionless by `hope`ing and `mate`ing `address(0)`. We realized that output conduits should never be permissionless.
 */
contract RwaMultiSwapOutputConduit {
    /// @notice DAI token contract address.
    DaiAbstract public immutable dai;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @dev Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;
    /// @notice Whitelist for addresses which can be picked. `bud[who]`
    mapping(address => uint256) public bud;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;
    /// @notice PSM addresses whitelist. `pal[psm]`
    mapping(address => uint256) public pal;

    /// @notice PSM contract address.
    address public psm;
    /// @notice GEM Recipient address.
    address public to;
    /// @notice Destination address for DAI after calling `quit`.
    address public quitTo;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice `usr` was granted operator access.
     * @param usr The user address.
     */
    event Hope(address indexed usr);
    /**
     * @notice `usr` operator access was revoked.
     * @param usr The user address.
     */
    event Nope(address indexed usr);
    /**
     * @notice `usr` was granted push access.
     * @param usr The user address.
     */
    event Mate(address indexed usr);
    /**
     * @notice `usr` push access was revoked.
     * @param usr The user address.
     */
    event Hate(address indexed usr);
    /**
     * @notice `who` address whitelisted for pick.
     * @param who The user address.
     */
    event Kiss(address indexed who);
    /**
     * @notice `who` address was removed from whitelist.
     * @param who The user address.
     */
    event Diss(address indexed who);
    /**
     * @notice `psm` address whitelisted for hook.
     * @param psm The PSM address.
     */
    event Clap(address indexed psm);
    /**
     * @notice `psm` address was removed from whitelist.
     * @param psm The user address.
     */
    event Slap(address indexed psm);
    /**
     * @notice `psm` address was choosen.
     * @param psm The PSM address.
     */
    event Hook(address indexed psm);
    /**
     * @notice `who` address was picked as the recipient.
     * @param who The user address.
     */
    event Pick(address indexed who);
    /**
     * @notice `amt` amount of GEM was pushed to the recipient `to` using `psm`.
     * @param psm PSM address used for swap.
     * @param gem GEM token address used.
     * @param to Destination address for GEM.
     * @param amt The amount of GEM.
     */
    event Push(address indexed psm, address indexed gem, address indexed to, uint256 amt);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "quitTo", "psm".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice The conduit outstanding DAI balance was flushed out to `quitTo` address.
     * @param quitTo The quitTo address.
     * @param wad The amount of DAI flushed out.
     */
    event Quit(address indexed quitTo, uint256 wad);
    /**
     * @notice `amt` outstanding `token` balance was flushed out to `usr`.
     * @param token The token address.
     * @param usr The destination address.
     * @param amt The amount of `token` flushed out.
     */
    event Yank(address indexed token, address indexed usr, uint256 amt);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaMultiSwapOutputConduit/not-authorized");
        _;
    }

    modifier onlyOperator() {
        require(can[msg.sender] == 1, "RwaMultiSwapOutputConduit/not-operator");
        _;
    }

    modifier onlyMate() {
        require(may[msg.sender] == 1, "RwaMultiSwapOutputConduit/not-mate");
        _;
    }

    /**
     * @notice Defines addresses and gives `msg.sender` admin access.
     * @param _dai DAI contract address.
     */
    constructor(address _dai) public {
        require(_dai != address(0), "RwaMultiSwapOutputConduit/wrong-dai-address");

        dai = DaiAbstract(_dai);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /*//////////////////////////////////
               Authorization
    //////////////////////////////////*/

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Grants `usr` operator access to this contract.
     * @param usr The user address.
     */
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }

    /**
     * @notice Revokes `usr` operator access from this contract.
     * @param usr The user address.
     */
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }

    /**
     * @notice Grants `usr` push access to this contract.
     * @param usr The user address.
     */
    function mate(address usr) external auth {
        may[usr] = 1;
        emit Mate(usr);
    }

    /**
     * @notice Revokes `usr` push access from this contract.
     * @param usr The user address.
     */
    function hate(address usr) external auth {
        may[usr] = 0;
        emit Hate(usr);
    }

    /**
     * @notice Whitelist `who` address for `pick`.
     * @param who The user address.
     */
    function kiss(address who) external auth {
        bud[who] = 1;
        emit Kiss(who);
    }

    /**
     * @notice Remove `who` address from `pick` whitelist.
     * @param who The user address.
     */
    function diss(address who) external auth {
        if (to == who) to = address(0);
        bud[who] = 0;
        emit Diss(who);
    }

    /**
     * @notice Whitelist `psm` address for `hook`.
     * @param _psm The PSM address.
     */
    function clap(address _psm) external auth {
        require(PsmAbstract(_psm).dai() == address(dai), "RwaMultiSwapOutputConduit/wrong-dai-for-psm");

        // Check if GEM `decimals` is not greater then DAI decimals.
        // We assume that DAI will always have 18 decimals
        require(
            GemAbstract(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem()).decimals() <= 18,
            "RwaMultiSwapOutputConduit/unsupported-gem-decimals"
        );

        // Give unlimited approval to PSM
        dai.approve(_psm, type(uint256).max);

        pal[_psm] = 1;
        emit Clap(_psm);
    }

    /**
     * @notice Remove `psm` address from `hook` whitelist.
     * @param _psm The PSM address.
     */
    function slap(address _psm) external auth {
        dai.approve(address(_psm), 0);

        if (psm == _psm) psm = address(0);
        pal[_psm] = 0;
        emit Slap(_psm);
    }

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @param what The changed parameter name. `"quitTo"`.
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "quitTo") {
            quitTo = data;
        } else {
            revert("RwaMultiSwapOutputConduit/unrecognised-param");
        }

        emit File(what, data);
    }

    /**
     * @notice Sets `who` address as the recipient.
     * @param who Recipient address.
     * @dev `who` address should have been whitelisted using `kiss`.
     */
    function pick(address who) external onlyOperator {
        require(bud[who] == 1 || who == address(0), "RwaMultiSwapOutputConduit/not-bud");
        to = who;
        emit Pick(who);
    }

    /**
     * @notice Sets `psm` address which will be used for swap DAI -> GEM.
     * @param _psm PSM address.
     * @dev `psm` address should have been whitelisted using `clap`.
     */
    function hook(address _psm) external onlyOperator {
        require(pal[_psm] == 1 || _psm == address(0), "RwaMultiSwapOutputConduit/not-pal");

        psm = _psm;

        emit Hook(_psm);
    }

    /*//////////////////////////////////
               Operations
    //////////////////////////////////*/

    /**
     * @notice Swaps the DAI balance of this contract into GEM through the PSM and push it into the recipient address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function push() external onlyMate {
        _doPush(dai.balanceOf(address(this)));
    }

    /**
     * @notice Swaps the specified amount of DAI into GEM through the PSM and push it to the recipient address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param wad DAI amount.
     */
    function push(uint256 wad) external onlyMate {
        _doPush(wad);
    }

    /**
     * @notice Flushes out any DAI balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function quit() external onlyMate {
        _doQuit(dai.balanceOf(address(this)));
    }

    /**
     * @notice Flushes out the specified amount of DAI to the `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param wad DAI amount.
     */
    function quit(uint256 wad) external onlyMate {
        _doQuit(wad);
    }

    /**
     * @notice Flushes out `amt` of `token` sitting in this contract to `usr` address.
     * @dev Can only be called by the admin.
     * @param token Token address.
     * @param usr Destination address.
     * @param amt Token amount.
     */
    function yank(
        address token,
        address usr,
        uint256 amt
    ) external auth {
        GemAbstract(token).transfer(usr, amt);
        emit Yank(token, usr, amt);
    }

    /**
     * @notice Return Gem address of the selected PSM
     * @return gem Gem address.
     */
    function gem() external view returns (address) {
        return psm == address(0) ? address(0) : GemJoinAbstract(PsmAbstract(psm).gemJoin()).gem();
    }

    /**
     * @notice Calculates the amount of GEM received for swapping `wad` of DAI.
     * @param _psm The PSM instance.
     * @param wad DAI amount.
     * @return amt Expected GEM amount.
     */
    function expectedGemAmt(address _psm, uint256 wad) public view returns (uint256 amt) {
        uint256 decimals = GemAbstract(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem()).decimals();
        // By using any PSM, we cannot guarantee its gem has 18 decimals or less, so we need SafeMath.
        uint256 to18ConversionFactor = 10**_sub(18, decimals);
        return _mul(wad, WAD) / _mul(_add(WAD, PsmAbstract(_psm).tout()), to18ConversionFactor);
    }

    /**
     * @notice Calculates the required amount of DAI to get `amt` amount of GEM.
     * @param _psm The PSM instance.
     * @param amt GEM amount.
     * @return wad Required DAI amount.
     */
    function requiredDaiWad(address _psm, uint256 amt) external view returns (uint256 wad) {
        uint256 decimals = GemAbstract(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem()).decimals();
        // By using any PSM, we cannot guarantee its gem has 18 decimals or less, so we need SafeMath.
        uint256 to18ConversionFactor = 10**_sub(18, decimals);
        uint256 amt18 = _mul(amt, to18ConversionFactor);
        uint256 fee = _mul(amt18, PsmAbstract(_psm).tout()) / WAD;
        return _add(amt18, fee);
    }

    /**
     * @notice Swaps the specified amount of DAI into GEM through the PSM and push it to the recipient address.
     * @param wad DAI amount.
     */
    function _doPush(uint256 wad) internal {
        require(to != address(0), "RwaMultiSwapOutputConduit/to-not-picked");
        require(psm != address(0), "RwaMultiSwapOutputConduit/psm-not-hooked");

        // We might lose some dust here because of rounding errors. I.e.: USDC has 6 dec and DAI has 18.
        uint256 gemAmt = expectedGemAmt(psm, wad);
        require(gemAmt > 0, "RwaMultiSwapOutputConduit/insufficient-swap-gem-amount");

        address recipient = to;
        address _psm = psm;
        address _gem = GemJoinAbstract(PsmAbstract(psm).gemJoin()).gem();
        to = address(0);
        psm = address(0);

        PsmAbstract(_psm).buyGem(recipient, gemAmt);
        emit Push(_psm, _gem, recipient, gemAmt);
    }

    /**
     * @notice Flushes out the specified amount of DAI to `quitTo` address.
     * @param wad The DAI amount.
     */
    function _doQuit(uint256 wad) internal {
        require(quitTo != address(0), "RwaMultiSwapOutputConduit/invalid-quit-to-address");

        dai.transfer(quitTo, wad);
        emit Quit(quitTo, wad);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    uint256 internal constant WAD = 10**18;

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/add-overflow");
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/sub-overflow");
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "Math/mul-overflow");
    }
}
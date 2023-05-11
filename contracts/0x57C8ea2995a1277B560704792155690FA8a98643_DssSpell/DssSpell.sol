/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.16 >=0.8.16 <0.9.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
//
// CollateralOpts.sol -- Data structure for onboarding collateral
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address clip;
    address calc;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 startingPriceFactor;
    uint256 breakerTolerance;
    uint256 auctionDuration;
    uint256 permittedDrop;
    uint256 liquidationRatio;
    uint256 kprFlatReward;
    uint256 kprPctReward;
}

////// lib/dss-exec-lib/src/DssExecLib.sol
//
// DssExecLib.sol -- MakerDAO Executive Spellcrafting Library
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint256) external;
}

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
}

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// Includes Median and OSM functions
interface OracleLike_2 {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface MomLike {
    function setOsm(bytes32, address) external;
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

interface IAMLike {
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
}

interface LerpFactoryLike {
    function newLerp(bytes32 name_, address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
    function newIlkLerp(bytes32 name_, address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function tick() external returns (uint256);
}

interface RwaOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
}


library DssExecLib {

    /* WARNING

The following library code acts as an interface to the actual DssExecLib
library, which can be found in its own deployed contract. Only trust the actual
library's implementation.

    */

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

/* import { DssExecLib } from "./DssExecLib.sol"; */
/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface OracleLike_1 {
    function src() external view returns (address);
}

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public view virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view virtual returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external view returns (uint256 castTime) {
        require(eta <= type(uint40).max);
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// src/DssSpell.sol
// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity 0.8.16; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

interface StarknetLike {
    function setCeiling(uint256 _ceiling) external;
}

interface GemLike {
    function allowance(address src, address guy) external view returns (uint256);
    function approve(address guy, uint256 wad) external returns (bool);
}

interface VestLike {
    function file(bytes32 what, uint256 data) external;
    function restrict(uint256 _id) external;
    function create(address _usr, uint256 _tot, uint256 _bgn, uint256 _tau, uint256 _eta, address _mgr) external returns (uint256 id);
    function yank(uint256 _id) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/4593c4f4d947b6393d49ea8d6ddfc018d8ad963b/governance/votes/Executive%20vote%20-%20May%2010%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-10 MakerDAO Executive Spell | Hash: 0xd6627860aae2eeeabc22baf5afcb90a4e528239cd8a71cb1a72194342e20fd47";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return false;
    }

    uint256 internal constant ZERO_PT_SEVEN_FIVE_PCT_RATE    = 1000000000236936036262880196;
    uint256 internal constant ONE_PCT_RATE                   = 1000000000315522921573372069;
    uint256 internal constant ONE_PT_SEVEN_FIVE_PCT_RATE     = 1000000000550121712943459312;
    uint256 internal constant THREE_PT_TWO_FIVE_PCT_RATE     = 1000000001014175731521720677;

    uint256 internal constant MILLION                        = 10 ** 6;
    uint256 internal constant WAD                            = 10 ** 18;

    // 01 May 2023 12:00:00 AM UTC
    uint256 internal constant MAY_01_2023                    = 1682899200;
    // 30 Apr 2024 11:59:59 PM UTC
    uint256 internal constant APR_30_2024                    = 1714521599;
    // 30 Apr 2025 11:59:59 PM UTC
    uint256 internal constant APR_30_2025                    = 1746057599;

    // ECOSYSTEM ACTORS
    address internal constant PHOENIX_LABS_2_WALLET          = 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA;
    address internal constant PULLUP_LABS_WALLET             = 0x42aD911c75d25E21727E45eCa2A9d999D5A7f94c;

    address internal constant PULLUP_LABS_VEST_MGR_WALLET    = 0x9B6213D350A4AFbda2361b6572A07C90c22002F1;

    address internal immutable MCD_VEST_MKR_TREASURY         = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable MCD_VEST_DAI                  = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MKR                           = DssExecLib.mkr();

    address internal immutable STARKNET_DAI_BRIDGE           = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");

    function actions() public override {

        // ---------- Starknet ----------
        // Increase L1 Starknet Bridge Limit from 1,000,000 DAI to 5,000,000 DAI
        // Forum: https://forum.makerdao.com/t/april-26th-2023-spell-starknet-bridge-limit/20589
        // Poll: https://vote.makerdao.com/polling/QmUnhQZy#vote-breakdown
        StarknetLike(STARKNET_DAI_BRIDGE).setCeiling(5 * MILLION * WAD);

        // ---------- Risk Parameters Changes (Stability Fee & DC-IAM) ----------
        // Poll: https://vote.makerdao.com/polling/QmYFfRuR#poll-detail
        // Forum: https://forum.makerdao.com/t/out-of-scope-proposed-risk-parameters-changes-stability-fee-dc-iam/20564

        // Increase ETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("ETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase ETH-B Stability Fee by 0.25% from 3% to 3.25%.
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PT_TWO_FIVE_PCT_RATE, true);

        // Increase ETH-C Stability Fee by 0.25% from 0.75% to 1%.
        DssExecLib.setIlkStabilityFee("ETH-C", ONE_PCT_RATE, true);

        // Increase WSTETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase WSTETH-B Stability Fee by 0.25% from 0.75% to 1%.
        DssExecLib.setIlkStabilityFee("WSTETH-B", ONE_PCT_RATE, true);

        // Increase RETH-A Stability Fee by 0.25% from 0.5% to 0.75%.
        DssExecLib.setIlkStabilityFee("RETH-A", ZERO_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase CRVV1ETHSTETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);


        // Increase the WSTETH-A gap by 15 million DAI from 15 million DAI to 30 million DAI.
        // Increase the WSTETH-A ttl by 21,600 seconds from 21,600 seconds to 43,200 seconds
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 500 * MILLION, 30 * MILLION, 12 hours);

        // Increase the WSTETH-B gap by 15 million DAI from 15 million DAI to 30 million DAI.
        // Increase the WSTETH-B ttl by 28,800 seconds from 28,800 seconds to 57,600 seconds.
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 500 * MILLION, 30 * MILLION, 16 hours);

        // Reduce the WBTC-A gap by 10 million DAI from 20 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 500 * MILLION, 10 * MILLION, 24 hours);

        // Reduce the WBTC-B gap by 5 million DAI from 10 million DAI to 5 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 250 * MILLION, 5 * MILLION, 24 hours);

        // Reduce the WBTC-C gap by 10 million DAI from 20 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-C", 500 * MILLION, 10 * MILLION, 24 hours);


        // ----- Stream Yanks -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Yank DAI Stream ID 22 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_DAI).yank(22);

        // Yank MKR Stream ID 37 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_MKR_TREASURY).yank(37);

        // ----- Ecosystem Actor Dai Streams -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Phoenix Labs | 2023-05-01 to 2024-05-01 | 1,534,000 DAI
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                PHOENIX_LABS_2_WALLET,     // usr
                1_534_000 * WAD,           // tot
                MAY_01_2023,               // bgn
                APR_30_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Poll: https://vote.makerdao.com/polling/QmebPdpa#poll-detail
        // PullUp Labs | 2023-05-01 to 2024-05-01 | 3,300,000 DAI
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                PULLUP_LABS_WALLET,         // usr
                3_300_000 * WAD,            // tot
                MAY_01_2023,                // bgn
                APR_30_2024 - MAY_01_2023,  // tau
                0,                          // eta
                PULLUP_LABS_VEST_MGR_WALLET // mgr
            )
        );


        // ----- Ecosystem Actor MKR Streams -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Set system-wide cap on maximum vesting speed
        VestLike(MCD_VEST_MKR_TREASURY).file("cap", 2_200 * WAD / 365 days);

        // Increase allowance by new vesting delta
        // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        uint256 newVesting = 4_000 ether;  // PullUp Labs
               newVesting += 986.25 ether; // Phoenix Labs
        GemLike(MKR).approve(MCD_VEST_MKR_TREASURY, GemLike(MKR).allowance(address(this), MCD_VEST_MKR_TREASURY) + newVesting);

        // Phoenix Labs | 2023-05-01 to 2024-05-01 | Cliff 2023-05-01 | 986.25 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                PHOENIX_LABS_2_WALLET,     // usr
                986.25 ether,              // tot
                MAY_01_2023,               // bgn
                APR_30_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Poll: https://vote.makerdao.com/polling/QmcswbHs#poll-detail, https://vote.makerdao.com/polling/QmebPdpa#poll-detail
        // PullUp Labs | 2023-05-01 to 2025-05-01 | Cliff 2023-05-01 | 4,000 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                PULLUP_LABS_WALLET,         // usr
                4_000 ether,                // tot
                MAY_01_2023,                // bgn
                APR_30_2025 - MAY_01_2023,  // tau
                0,                          // eta
                PULLUP_LABS_VEST_MGR_WALLET // mgr
            )
        );

        // ----- Ecosystem Actor Dai Transfers -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-
        // Poll:  https://vote.makerdao.com/polling/QmTYdpaU#poll-detail

        // Phoenix Labs - 318,000 DAI - 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA
        DssExecLib.sendPaymentFromSurplusBuffer(PHOENIX_LABS_2_WALLET, 318_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
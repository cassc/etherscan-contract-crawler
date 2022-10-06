/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;
// pragma experimental ABIEncoderV2;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.12; */

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
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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
/* pragma solidity ^0.6.12; */
/* // pragma experimental ABIEncoderV2; */

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
    function suck(address, address, uint) external;
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
    function join(address, uint) external;
    function exit(address, uint) external;
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
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setContract(address _base, bytes32 _what, address _addr) public {}
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

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
    function officeHours() public virtual returns (bool) {
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
    function description() external virtual view returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external returns (uint256 castTime) {
        require(eta <= uint40(-1));
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

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
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) public {
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
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// lib/dss-interfaces/src/ERC/GemAbstract.sol
/* pragma solidity >=0.5.12; */

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

////// lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/ilk-registry
interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function dog() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint96, address, address, uint8, uint96, address, address, string memory, string memory
    );
    function ilks() external view returns (bytes32[] memory);
    function ilks(uint) external view returns (bytes32);
    function add(address) external;
    function remove(bytes32) external;
    function update(bytes32) external;
    function removeAuth(bytes32) external;
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, string calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (bytes32[] memory);
    function list(uint256, uint256) external view returns (bytes32[] memory);
    function get(uint256) external view returns (bytes32);
    function info(bytes32) external view returns (
        string memory, string memory, uint256, uint256, address, address, address, address
    );
    function pos(bytes32) external view returns (uint256);
    function class(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function xlip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
    function put(bytes32, address, address, uint256, uint256, address, address, string calldata, string calldata) external;
}

////// src/DssSpellCollateral.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity 0.6.12; */
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExecLib.sol"; */
/* import "dss-interfaces/dss/GemJoinAbstract.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/ERC/GemAbstract.sol"; */

interface RwaLiquidationLike_2 {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike_3 {
    function vat() external view returns(address);
    function jug() external view returns(address);
    function gemJoin() external view returns(address);
    function daiJoin() external view returns(address);
    function outputConduit() external view returns(address);
    function hope(address) external;
}

interface RwaJarLike {
    function chainlog() external view returns(address);
    function dai() external view returns(address);
    function daiJoin() external view returns(address);
}

interface RwaOutputConduitLike_2 {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function file(bytes32 what, address data) external;
    function hope(address) external;
    function mate(address) external;
    function kiss(address) external;
}

interface RwaInputConduitLike_2 {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function to() external view returns(address);
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
}
contract DssSpellCollateralAction {
    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6

    // --- Math ---
    uint256 internal constant WAD = 10**18;

    // -- RWA007 MIP21 components --
    address internal constant RWA007                         = 0x078fb926b041a816FaccEd3614Cf1E4bc3C723bD;
    address internal constant MCD_JOIN_RWA007_A              = 0x476aaD14F42469989EFad0b7A31f07b795FF0621;
    address internal constant RWA007_A_URN                   = 0x481bA2d2e86a1c41427893899B5B0cEae41c6726;
    address internal constant RWA007_A_JAR                   = 0xef1B095F700BE471981aae025f92B03091c3AD47;
    // Goerli: Coinbase / Mainnet: Coinbase
    address internal constant RWA007_A_OUTPUT_CONDUIT        = 0x701C3a384c613157bf473152844f368F2d6EF191;
    // Jar and URN Input Conduits
    address internal constant RWA007_A_INPUT_CONDUIT_URN     = 0x58f5e979eF74b60a9e5F955553ab8e0e65ba89c9;
    address internal constant RWA007_A_INPUT_CONDUIT_JAR     = 0xc8bb4e2B249703640e89265e2Ae7c9D5eA2aF742;

    // MIP21_LIQUIDATION_ORACLE params

    // https://gateway.pinata.cloud/ipfs/QmRLwB7Ty3ywSzq17GdDdwHvsZGwBg79oUTpSTJGtodToY
    string  internal constant RWA007_DOC                     = "QmRLwB7Ty3ywSzq17GdDdwHvsZGwBg79oUTpSTJGtodToY";
    // There is no DssExecLib helper, so WAD precision is used.
    uint256 internal constant RWA007_A_INITIAL_PRICE         = 250_000_000 * WAD;
    uint48  internal constant RWA007_A_TAU                   = 0;

    // Ilk registry params
    uint256 internal constant RWA007_REG_CLASS_RWA           = 3;

    // Remaining params
    uint256 internal constant RWA007_A_LINE                  = 1_000_000;
    uint256 internal constant RWA007_A_MAT                   = 100_00; // 100% in basis-points

    // Monetalis operator address
    address internal constant RWA007_A_OPERATOR              = 0x94cfBF071f8be325A5821bFeAe00eEbE9CE7c279;
    // Coinbase custody address
    address internal constant RWA007_A_COINBASE_CUSTODY      = 0xC3acf3B96E46Aa35dBD2aA3BD12D23c11295E774;

    // -- RWA007 END --

    function onboardRwa007(
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI,
        address MCD_PSM_USDC_A
    ) internal {
        // RWA007-A collateral deploy
        bytes32 ilk      = "RWA007-A";
        uint256 decimals = GemAbstract(RWA007).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).vat()                             == MCD_VAT,                                    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).ilk()                             == ilk,                                        "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).gem()                             == RWA007,                                     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).dec()                             == decimals,                                   "join-dec-not-match");

        require(RwaUrnLike_3(RWA007_A_URN).vat()                                       == MCD_VAT,                                    "urn-vat-not-match");
        require(RwaUrnLike_3(RWA007_A_URN).jug()                                       == MCD_JUG,                                    "urn-jug-not-match");
        require(RwaUrnLike_3(RWA007_A_URN).daiJoin()                                   == MCD_JOIN_DAI,                               "urn-daijoin-not-match");
        require(RwaUrnLike_3(RWA007_A_URN).gemJoin()                                   == MCD_JOIN_RWA007_A,                          "urn-gemjoin-not-match");
        require(RwaUrnLike_3(RWA007_A_URN).outputConduit()                             == RWA007_A_OUTPUT_CONDUIT,                    "urn-outputconduit-not-match");
        
        require(RwaJarLike(RWA007_A_JAR).chainlog()                                  == DssExecLib.LOG,                             "jar-chainlog-not-match");
        require(RwaJarLike(RWA007_A_JAR).dai()                                       == DssExecLib.dai(),                           "jar-dai-not-match");
        require(RwaJarLike(RWA007_A_JAR).daiJoin()                                   == MCD_JOIN_DAI,                               "jar-daijoin-not-match");

        require(RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).dai()                  == DssExecLib.dai(),                           "output-conduit-dai-not-match");
        require(RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).gem()                  == DssExecLib.getChangelogAddress("USDC"),     "output-conduit-gem-not-match");
        require(RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).psm()                  == MCD_PSM_USDC_A,                             "output-conduit-psm-not-match");
        
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).psm()                == MCD_PSM_USDC_A,                             "input-conduit-urn-psm-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).to()                 == RWA007_A_URN,                               "input-conduit-urn-to-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).dai()                == DssExecLib.dai(),                           "input-conduit-urn-dai-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-urn-gem-not-match");

        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).psm()                == MCD_PSM_USDC_A,                             "input-conduit-jar-psm-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).to()                 == RWA007_A_JAR,                               "input-conduit-jar-to-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).dai()                == DssExecLib.dai(),                           "input-conduit-jar-dai-not-match");
        require(RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-jar-gem-not-match");


        // Init the RwaLiquidationOracle
        RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA007_A_INITIAL_PRICE, RWA007_DOC, RWA007_A_TAU);
        (, address pip, , ) = RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA007 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA007 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA007 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA007_A);

        // 1m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA007_A_LINE, /* _global = */ true);

        // Set price feed for RWA007
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA007_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA007_A, RWA007_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on URN
        RwaUrnLike_3(RWA007_A_URN).hope(address(this));
        RwaUrnLike_3(RWA007_A_URN).hope(address(RWA007_A_OPERATOR));

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).mate(address(this));
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).hope(RWA007_A_OPERATOR);
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).mate(RWA007_A_OPERATOR);
        // Coinbase custody whitelist for URN destination address
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).kiss(address(RWA007_A_COINBASE_CUSTODY));
        // Set "quitTo" address for RWA007_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_2(RWA007_A_OUTPUT_CONDUIT).file("quitTo", RWA007_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_INPUT_CONDUIT_URN
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).mate(RWA007_A_OPERATOR);
        // Set "quitTo" address for RWA007_A_INPUT_CONDUIT_URN
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_URN).file("quitTo", RWA007_A_COINBASE_CUSTODY);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).mate(address(this));
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).mate(RWA007_A_OPERATOR);
        // Set "quitTo" address for RWA007_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike_2(RWA007_A_INPUT_CONDUIT_JAR).file("quitTo", RWA007_A_COINBASE_CUSTODY);

        // Add RWA007 contract to the changelog
        DssExecLib.setChangelogAddress("RWA007",                     RWA007);
        DssExecLib.setChangelogAddress("PIP_RWA007",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA007_A",          MCD_JOIN_RWA007_A);
        DssExecLib.setChangelogAddress("RWA007_A_URN",               RWA007_A_URN);
        DssExecLib.setChangelogAddress("RWA007_A_JAR",               RWA007_A_JAR);
        DssExecLib.setChangelogAddress("RWA007_A_INPUT_CONDUIT_URN", RWA007_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA007_A_INPUT_CONDUIT_JAR", RWA007_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA007_A_OUTPUT_CONDUIT",    RWA007_A_OUTPUT_CONDUIT);

        // Add RWA007 to ILK REGISTRY
        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA007_A,
            RWA007,
            decimals,
            RWA007_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA007-A: Monetalis Clydesdale",
            GemAbstract(RWA007).symbol()
        );
    }

    function onboardNewCollaterals() internal {
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
        address MCD_PSM_USDC_A           = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard Monetalis: https://vote.makerdao.com/polling/QmXHM6us
        onboardRwa007(REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI, MCD_PSM_USDC_A);
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

/* pragma solidity 0.6.12; */
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralAction } from "./DssSpellCollateral.sol"; */

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface RwaUrnLike_1 {
    function lock(uint256) external;
}

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/ef7c8c881c961e9b4b3cc9644619986a75ef83d7/governance/votes/Executive%20vote%20-%20October%205%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-10-05 MakerDAO Executive Spell | Hash: 0xf791ea9d7a97cace07a1cd79de48ce9a41dc79f53a43465faad83a30292dfc81";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    uint256 constant AUG_01_2022 = 1659312000;
    uint256 constant AUG_01_2023 = 1690848000;
    uint256 constant SEP_28_2022 = 1664323200;
    uint256 constant SEP_28_2024 = 1727481600;

    // --- Wallets ---
    address internal constant GOV_WALLET1       = 0xbfDD0E744723192f7880493b66501253C34e1241;
    address internal constant GOV_WALLET2       = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
    address internal constant GOV_WALLET3       = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address internal constant AMBASSADOR_WALLET = 0xF411d823a48D18B32e608274Df16a9957fE33E45;
    address internal constant STARKNET_WALLET   = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address internal constant SES_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        onboardNewCollaterals();

        // lock RWA007 Token in the URN
        GemLike(RWA007).approve(RWA007_A_URN, 1 * WAD);
        RwaUrnLike_1(RWA007_A_URN).lock(1 * WAD);

        // --- MKR Vests ---
        GemLike mkr = GemLike(DssExecLib.mkr());
        VestLike vest = VestLike(
            DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY")
        );

        // Increase allowance by new vesting delta
        mkr.approve(address(vest), mkr.allowance(address(this), address(vest)) + 787.70 ether);

        // https://mips.makerdao.com/mips/details/MIP40c3SP80
        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 62.51 MKR | 0xbfDD0E744723192f7880493b66501253C34e1241
        vest.restrict(
            vest.create(
                GOV_WALLET1,                                             // usr
                62.50 ether,                                             // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 32.69 MKR | 0xbb147E995c9f159b93Da683dCa7893d6157199B9
        vest.restrict(
            vest.create(
                GOV_WALLET2,                                             // usr
                32.69 ether,                                             // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 152.51 MKR | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73
        vest.restrict(
            vest.create(
                GOV_WALLET3,                                             // usr
                152.51 ether,                                            // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // SNE-001 | 2022-09-28 to 2024-09-28 | Cliff date = start = 2022-09-28 | 540 MKR | 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        vest.restrict(
            vest.create(
                STARKNET_WALLET,                                         // usr
                540.00 ether,                                            // tot
                SEP_28_2022,                                             // bgn
                SEP_28_2024 - SEP_28_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // --- MKR Transfers ---

        // https://mips.makerdao.com/mips/details/MIP40c3SP79
        // SNE-001 - 270 MKR - 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        mkr.transfer(STARKNET_WALLET, 270.00 ether);

        // https://mips.makerdao.com/mips/details/MIP40c3SP17
        // SES-001 - 227.64 MKR - 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        mkr.transfer(SES_WALLET, 227.64 ether);

        // --- DAI Transfers ---

        // https://mips.makerdao.com/mips/details/MIP55c3SP7
        // Ambassadors  - 81,000.0 DAI - 0xF411d823a48D18B32e608274Df16a9957fE33E45
        DssExecLib.sendPaymentFromSurplusBuffer(AMBASSADOR_WALLET, 81_000);
        
        DssExecLib.setChangelogVersion("1.14.2");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
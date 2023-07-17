/**
 *Submitted for verification at Etherscan.io on 2023-06-28
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
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
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
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
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

interface RwaLiquidationLike_1 {
    function ilks(bytes32) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string memory doc, uint48 tau) external;
    function bump(bytes32 ilk, uint256 val) external;
}

interface RwaOutputConduitLike_1 {
    function hope(address usr) external;
    function nope(address usr) external;
    function mate(address usr) external;
    function hate(address usr) external;
    function kiss(address who) external;
    function file(bytes32 what, address data) external;
}

interface RwaUrnLike_1 {
    function file(bytes32 what, address data) external;
}

interface NetworkPaymentAdapterLike_1 {
    function file(bytes32 what, address data) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/e4bf988dd35f82e2828e1ce02c6762ddd398ff92/governance/votes/Executive%20vote%20-%20June%2028%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-06-28 MakerDAO Executive Spell | Hash: 0x79a176bb631e7877acbdca1253e29354aa8fd4e3276dfd503fb3cd43f07d4fcd";

    address internal immutable MIP21_LIQUIDATION_ORACLE       = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable MCD_PSM_GUSD_A                 = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
    address internal immutable RWA015_A_URN                   = DssExecLib.getChangelogAddress("RWA015_A_URN");
    address internal immutable RWA015_A_OUTPUT_CONDUIT_LEGACY = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT");
    address internal immutable MCD_ESM                        = DssExecLib.esm();
    GemLike internal immutable MKR                            = GemLike(DssExecLib.mkr());

    uint256 internal constant MILLION           = 10 ** 6;
    uint256 internal constant WAD               = 10 ** 18;

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

    // -- RWA015 components --

    // Operator address
    address internal constant RWA015_A_OPERATOR          = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    // Custody address
    address internal constant RWA015_A_CUSTODY           = 0x65729807485F6f7695AF863d97D62140B7d69d83;
    // USDP Swap Output Conduit
    address internal constant RWA015_A_OUTPUT_CONDUIT    = 0x1a976926bF6105Ff6dA1F7b1667bBe825974961E;

    // -- RWA015 END --

    // -- ChainLink Keeper Network addresses --
    address internal constant CHAINLINK_PAYMENT_ADAPTER  = 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065;
    address internal constant CHAINLINK_TREASURY         = 0xaBAbd5e7d6d05672391aB2A914F57ce343D5CFA6;

    // -- MKR TRANSFERS --
    address internal constant ORA_WALLET                 = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    address internal constant RISK_WALLET_VEST           = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
    address internal constant SES_WALLET                 = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    address internal constant VIGILANT_WALLET            = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant DEFENSOR_WALLET            = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BONAPUBLICA_WALLET         = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant FRONTIERRESEARCH_WALLET    = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant GFXLABS_WALLET             = 0x9B68c14e936104e9a7a24c712BEecdc220002984;
    address internal constant QGOV_WALLET                = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant TRUENAME_WALLET            = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant UPMAKER_WALLET             = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant WBC_WALLET                 = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant LIBERTAS_WALLET            = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant CODEKNIGHT_WALLET          = 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D;
    address internal constant PBG_WALLET                 = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant FLIPFLOPFLAP_WALLET        = 0x3d9751EFd857662f2B007A881e05CfD1D7833484;
    address internal constant BANDHAR_WALLET             = 0xE83B6a503A94a5b764CCF00667689B3a522ABc21;

    // -- DAI TRANSFERS --
    address internal constant BLOCKTOWER_WALLET_2        = 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767;

    // Function from https://github.com/makerdao/spells-goerli/blob/7d783931a6799fe8278e416b5ac60d4bb9c20047/archive/2022-11-14-DssSpell/Goerli-DssSpell.sol#L59
    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function actions() public override {
        // --- Activate Andromeda Autoline ---
        // Forum: https://forum.makerdao.com/t/consolidated-action-items-for-2023-06-28-executive/21187
        // Forum: https://forum.makerdao.com/t/rwa015-project-andromeda-technical-assessment/20974

        // Activate autoline with line 1.28 billion DAI, gap 50 million DAI, ttl 86400
        DssExecLib.setIlkAutoLineParameters("RWA015-A", 1_280 * MILLION, 50 * MILLION, 24 hours);

        // Bump Oracle Price to 1.28 billion DAI
        // Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio
        // As we have SF 0 for this deal, this should be equal to ilk DC
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA015-A",
            1_280 * MILLION * WAD
        );
        DssExecLib.updateCollateralPrice("RWA015-A");


        // --- Initialize New Andromeda OutputConduit ---
        // Poll: https://forum.makerdao.com/t/consolidated-action-items-for-2023-06-28-executive/21187

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Custody whitelist for output conduit destination address
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY);
        // Set "quitTo" address for RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).file("quitTo", RWA015_A_URN);
        // Route URN to new conduit
        RwaUrnLike_1(RWA015_A_URN).file("outputConduit", RWA015_A_OUTPUT_CONDUIT);

        // ----- Additional ESM authorization -----
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT, MCD_ESM);

        // Revoke OPERATOR permissions on RWA015_A_OUTPUT_CONDUIT_LEGACY
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT_LEGACY).nope(RWA015_A_OPERATOR);
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT_LEGACY).hate(RWA015_A_OPERATOR);

        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT", RWA015_A_OUTPUT_CONDUIT);
        // Add Legacy Conduit to Changelog
        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT_LEGACY", RWA015_A_OUTPUT_CONDUIT_LEGACY);

        // --- CU MKR Vesting Transfers ---
        // Forum: https://mips.makerdao.com/mips/details/MIP40c3SP75#mkr-vesting
        // ORA-001 - 297.3 MKR - 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf

        MKR.transfer(ORA_WALLET, 297.3 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // --- CU MKR Vesting Transfers ---
        // Forum: https://mips.makerdao.com/mips/details/MIP40c3SP25#mkr-vesting-schedule
        // RISK-001 - 175 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c

        MKR.transfer(RISK_WALLET_VEST, 175 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // --- CU MKR Vesting Transfers ---
        // Forum: https://mips.makerdao.com/mips/details/MIP40c3SP17
        // SES-001 - 10.3 MKR - 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6

        MKR.transfer(SES_WALLET, 10.3 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // --- RWA007 doc parameter update ---
        // Forum: https://forum.makerdao.com/t/consolidated-action-items-for-2023-06-28-executive/21187

        _updateDoc("RWA007-A", "QmY185L4tuxFkpSQ33cPHUHSNpwy8V6TMXbXvtVraxXtb5");

        // --- Delegate Compensation for May (including offboarded Delegates) ---
        // Forum: https://forum.makerdao.com/t/aligned-delegate-compensation-for-may-2023/21197
        
        // vigilant - 29.76 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT_WALLET,         29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // 0xDefensor - 29.76 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR_WALLET,         29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 29.76 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA_WALLET,      29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Frontier Research - 29.76 MKR - 0xa2d55b89654079987cf3985aeff5a7bd44da15a8
        MKR.transfer(FRONTIERRESEARCH_WALLET, 29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // GFX Labs - 29.76 MKR - 0x9b68c14e936104e9a7a24c712beecdc220002984
        MKR.transfer(GFXLABS_WALLET,          29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // QGov - 29.76 MKR - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV_WALLET,             29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // TRUE NAME - 29.76 MKR - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        MKR.transfer(TRUENAME_WALLET,         29.76 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // UPMaker - 9.92 MKR - 0xbb819df169670dc71a16f58f55956fe642cc6bcd
        MKR.transfer(UPMAKER_WALLET,          9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // WBC - 9.92 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC_WALLET,              9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Libertas - 9.92 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        MKR.transfer(LIBERTAS_WALLET,         9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Codeknight - 9.92 MKR - 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D
        MKR.transfer(CODEKNIGHT_WALLET,       9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // PBG - 9.92 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG_WALLET,              9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Flip Flop Flap Delegate - 9.92 MKR - 0x3d9751EFd857662f2B007A881e05CfD1D7833484
        MKR.transfer(FLIPFLOPFLAP_WALLET,     9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Bandhar - 9.92 MKR - 0xE83B6a503A94a5b764CCF00667689B3a522ABc21
        MKR.transfer(BANDHAR_WALLET,          9.92 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // --- Add Chainlink Keeper Network Treasury Address ---
        // Forum: https://forum.makerdao.com/t/poll-notice-keeper-network-follow-up-updates/21056
        // Forum: https://forum.makerdao.com/t/consolidated-action-items-for-2023-06-28-executive/21187
        // Poll: https://vote.makerdao.com/polling/QmZZJcCj#vote-breakdown

        NetworkPaymentAdapterLike_1(CHAINLINK_PAYMENT_ADAPTER).file("treasury", CHAINLINK_TREASURY);

        // --- GUSD PSM Parameter Changes ---
        // Poll: https://vote.makerdao.com/polling/QmaXg3JT#vote-breakdown

        // Reduce the line by 390 million DAI from 500 million DAI to 110 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("PSM-GUSD-A", 110 * MILLION);
        // Reduce the tout by 0.01% from 0.01% to 0%.
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", 0);

        // --- BlockTower Legal Expenses DAI Transfer ---
        // Forum: https://forum.makerdao.com/t/project-andromeda-legal-expenses/20984
        // MIP: https://mips.makerdao.com/mips/details/MIP104#5-2-legal-recourse-asset-budget

        // BlockTower Legal Expenses - 133,466 DAI - 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKTOWER_WALLET_2, 133_466);

        DssExecLib.setChangelogVersion("1.14.14");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
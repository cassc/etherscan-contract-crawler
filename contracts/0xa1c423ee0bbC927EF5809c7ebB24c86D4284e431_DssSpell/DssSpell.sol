/**
 *Submitted for verification at Etherscan.io on 2023-05-17
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
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {}
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

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/8f548f10a4ce1db0acdc30fb171eebb72b236c39/governance/votes/Executive%20Vote%20-%20May%2017%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-17 MakerDAO Executive Spell | Hash: 0x867a1f6f1b68414fba87ccbb7d0d1fd0ba5e29336f59b88ea4a997780d019859";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant WAD       = 10 ** 18;
    uint256 internal constant RAY       = 10 ** 27;

    // 01 May 2023 00:00:00 UTC
    uint256 internal constant MAY_01_2023 = 1682899200;
    // 30 Apr 2024 23:59:59 UTC
    uint256 internal constant APR_30_2024 = 1714521599;

    // Constitutional Delegates
    address internal constant DEFENSOR                 = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BONAPUBLICA              = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant FRONTIERRESEARCH         = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant GFXLABS_2                = 0x9B68c14e936104e9a7a24c712BEecdc220002984;
    address internal constant QGOV                     = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant TRUENAME                 = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant VIGILANT                 = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant CODEKNIGHT               = 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D;
    address internal constant FLIPFLOPFLAP_2           = 0x3d9751EFd857662f2B007A881e05CfD1D7833484;
    address internal constant PBG                      = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant UPMAKER                  = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;

    // Protocol Engineering Scope
    address internal constant GOV_SECURITY_ENGINEERING = 0x569fAD613887ddd8c1815b56A00005BCA7FDa9C0;
    address internal constant MULTICHAIN_ENGINEERING   = 0x868B44e8191A2574334deB8E7efA38910df941FA;

    // Data Insights Core Unit (DIN-001)
    address internal constant DIN_WALLET               = 0x7327Aed0Ddf75391098e8753512D8aEc8D740a1F;

    address internal immutable MCD_SPOT         = DssExecLib.spotter();
    GemLike internal immutable MKR              = GemLike(DssExecLib.mkr());
    DssVestLike internal immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    function actions() public override {
        // --------- Collateral Offboardings ---------
        // Poll: https://vote.makerdao.com/polling/QmPwHhLT#poll-detail
        // Forum: https://forum.makerdao.com/t/decentralized-collateral-scope-parameter-changes-1-april-2023/20302

        // Set Liquidation Penalty (chop) to 0%.
        DssExecLib.setIlkLiquidationPenalty("YFI-A", 0);
        // Set Flat Kick Incentive (tip) to 0.
        DssExecLib.setKeeperIncentiveFlatRate("YFI-A", 0);
        // Set Proportional Kick Incentive (chip) to 0.
        DssExecLib.setKeeperIncentivePercent("YFI-A", 0);
        // Set Liquidation Ratio (mat) to 10,000%.
        // We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "YFI-A", "mat", 100 * RAY);
        // Update spotter price
        DssExecLib.updateCollateralPrice("YFI-A");

        // Set Liquidation Penalty (chop) to 0%.
        DssExecLib.setIlkLiquidationPenalty("LINK-A", 0);
        // Set Flat Kick Incentive (tip) to 0.
        DssExecLib.setKeeperIncentiveFlatRate("LINK-A", 0);
        // Set Proportional Kick Incentive (chip) to 0.
        DssExecLib.setKeeperIncentivePercent("LINK-A", 0);
        // Set Liquidation Ratio (mat) to 10,000%.
        // We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "LINK-A", "mat", 100 * RAY);
        // Update spotter price
        DssExecLib.updateCollateralPrice("LINK-A");

        // Set Liquidation Penalty (chop) to 0%.
        DssExecLib.setIlkLiquidationPenalty("MATIC-A", 0);
        // Set Flat Kick Incentive (tip) to 0.
        DssExecLib.setKeeperIncentiveFlatRate("MATIC-A", 0);
        // Set Proportional Kick Incentive (chip) to 0.
        DssExecLib.setKeeperIncentivePercent("MATIC-A", 0);
        // Set Liquidation Ratio (mat) to 10,000%.
        // We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "MATIC-A", "mat", 100 * RAY);
        // Update spotter price
        DssExecLib.updateCollateralPrice("MATIC-A");

        // Set Liquidation Penalty (chop) to 0%.
        DssExecLib.setIlkLiquidationPenalty("UNIV2USDCETH-A", 0);
        // Set Flat Kick Incentive (tip) to 0.
        DssExecLib.setKeeperIncentiveFlatRate("UNIV2USDCETH-A", 0);
        // Set Proportional Kick Incentive (chip) to 0.
        DssExecLib.setKeeperIncentivePercent("UNIV2USDCETH-A", 0);
        // Set Liquidation Ratio (mat) to 10,000%.
        // We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "UNIV2USDCETH-A", "mat", 100 * RAY);
        // Update spotter price
        DssExecLib.updateCollateralPrice("UNIV2USDCETH-A");

        // --------- Delegate Compensation MKR Transfers ---------
        // Poll: N/A
        // Forum: https://forum.makerdao.com/t/constitutional-delegate-compensation-april-2023/20804
        // Mip: https://mips.makerdao.com/mips/details/MIP113#5-4-constitutional-delegate-income-management

        // 0xDefensor                  - 23.8 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR,           23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // BONAPUBLICA                 - 23.8 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA,        23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // Frontier Research           - 23.8 MKR - 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8
        MKR.transfer(FRONTIERRESEARCH,   23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // GFX Labs                    - 23.8 MKR - 0x9B68c14e936104e9a7a24c712BEecdc220002984
        MKR.transfer(GFXLABS_2,          23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // QGov                        - 23.8 MKR - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV,               23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // TRUE NAME                   - 23.8 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME,           23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // vigilant                    - 23.8 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT,           23.8 ether); // note: ether is a keyword helper, only MKR is transferred here

        // CodeKnight                  - 5.95 MKR - 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D
        MKR.transfer(CODEKNIGHT,         5.95 ether); // note: ether is a keyword helper, only MKR is transferred here

        // Flip Flop Flap Delegate LLC - 5.95 MKR - 0x3d9751EFd857662f2B007A881e05CfD1D7833484
        MKR.transfer(FLIPFLOPFLAP_2,     5.95 ether); // note: ether is a keyword helper, only MKR is transferred here

        // PBG                         - 5.95 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG,                5.95 ether); // note: ether is a keyword helper, only MKR is transferred here

        // UPMaker                     - 5.95 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER,            5.95 ether); // note: ether is a keyword helper, only MKR is transferred here

        // --------- DAI Budget Streams ---------
        // Poll: https://vote.makerdao.com/polling/Qmbndmkr#poll-detail
        // Forum: https://forum.makerdao.com/t/mip101-the-maker-constitution/19621

        // Mip: https://mips.makerdao.com/mips/details/MIP107#6-1-governance-security-engineering-budget
        // Governance Security Engineering Budget | 2023-05-01 00:00:00 to 2024-04-30 23:59:59 | 2,200,000 DAI | 0x569fAD613887ddd8c1815b56A00005BCA7FDa9C0
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GOV_SECURITY_ENGINEERING,  // usr
                2_200_000 * WAD,           // tot
                MAY_01_2023,               // bgn
                APR_30_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Mip: https://mips.makerdao.com/mips/details/MIP107#7-1-multichain-engineering-budget
        // Multichain Engineering Budget          | 2023-05-01 00:00:00 to 2024-04-30 23:59:59 | 2,300,000 DAI | 0x868B44e8191A2574334deB8E7efA38910df941FA
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                MULTICHAIN_ENGINEERING,    // usr
                2_300_000 * WAD,           // tot
                MAY_01_2023,               // bgn
                APR_30_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // --------- Data Insights MKR Transfer ---------
        // Mip: https://mips.makerdao.com/mips/details/MIP40c3SP64#mkr-vesting
        // DIN-001 - 103.16 MKR - 0x7327Aed0Ddf75391098e8753512D8aEc8D740a1F
        MKR.transfer(DIN_WALLET, 103.16 ether); // note: ether is a keyword helper, only MKR is transferred here
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './TRKeys.sol';

/// @notice The Reliquary Color Palettes
library TRColors {

  function get(string memory palette)
    public
    pure
    returns (uint256[] memory, uint256)
  {
    uint256[] memory colorInts = new uint256[](12);
    uint256 colorIntCount = 0;

    if (TRUtils.compare(palette, TRKeys.NAT_PAL_JUNGLE)) {
      colorInts[0] = uint256(3299866);
      colorInts[1] = uint256(1256965);
      colorInts[2] = uint256(2375731);
      colorInts[3] = uint256(67585);
      colorInts[4] = uint256(16749568);
      colorInts[5] = uint256(16776295);
      colorInts[6] = uint256(16748230);
      colorInts[7] = uint256(16749568);
      colorInts[8] = uint256(67585);
      colorInts[9] = uint256(2375731);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_CAMOUFLAGE)) {
      colorInts[0] = uint256(10328673);
      colorInts[1] = uint256(6245168);
      colorInts[2] = uint256(2171169);
      colorInts[3] = uint256(4610624);
      colorInts[4] = uint256(5269320);
      colorInts[5] = uint256(4994846);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_BIOLUMINESCENCE)) {
      colorInts[0] = uint256(2434341);
      colorInts[1] = uint256(4194315);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(7270568);
      colorInts[4] = uint256(9117400);
      colorInts[5] = uint256(1599944);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_PASTEL)) {
      colorInts[0] = uint256(16761760);
      colorInts[1] = uint256(16756669);
      colorInts[2] = uint256(16636817);
      colorInts[3] = uint256(13762047);
      colorInts[4] = uint256(8714928);
      colorInts[5] = uint256(9425908);
      colorInts[6] = uint256(16499435);
      colorInts[7] = uint256(10587345);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_INFRARED)) {
      colorInts[0] = uint256(16642938);
      colorInts[1] = uint256(16755712);
      colorInts[2] = uint256(15883521);
      colorInts[3] = uint256(13503623);
      colorInts[4] = uint256(8257951);
      colorInts[5] = uint256(327783);
      colorInts[6] = uint256(13503623);
      colorInts[7] = uint256(15883521);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_ULTRAVIOLET)) {
      colorInts[0] = uint256(14200063);
      colorInts[1] = uint256(5046460);
      colorInts[2] = uint256(16775167);
      colorInts[3] = uint256(16024318);
      colorInts[4] = uint256(11665662);
      colorInts[5] = uint256(1507410);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_FROZEN)) {
      colorInts[0] = uint256(13034750);
      colorInts[1] = uint256(4102128);
      colorInts[2] = uint256(826589);
      colorInts[3] = uint256(346764);
      colorInts[4] = uint256(6707);
      colorInts[5] = uint256(1277652);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_DAWN)) {
      colorInts[0] = uint256(334699);
      colorInts[1] = uint256(610965);
      colorInts[2] = uint256(5408708);
      colorInts[3] = uint256(16755539);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_OPALESCENT)) {
      colorInts[0] = uint256(15985337);
      colorInts[1] = uint256(15981758);
      colorInts[2] = uint256(15713994);
      colorInts[3] = uint256(13941977);
      colorInts[4] = uint256(8242919);
      colorInts[5] = uint256(15985337);
      colorInts[6] = uint256(15981758);
      colorInts[7] = uint256(15713994);
      colorInts[8] = uint256(13941977);
      colorInts[9] = uint256(8242919);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_COAL)) {
      colorInts[0] = uint256(3613475);
      colorInts[1] = uint256(1577233);
      colorInts[2] = uint256(4407359);
      colorInts[3] = uint256(2894892);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_SILVER)) {
      colorInts[0] = uint256(16053492);
      colorInts[1] = uint256(15329769);
      colorInts[2] = uint256(10132122);
      colorInts[3] = uint256(6776679);
      colorInts[4] = uint256(3881787);
      colorInts[5] = uint256(1579032);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_GOLD)) {
      colorInts[0] = uint256(16373583);
      colorInts[1] = uint256(12152866);
      colorInts[2] = uint256(12806164);
      colorInts[3] = uint256(4725765);
      colorInts[4] = uint256(2557441);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_BERRY)) {
      colorInts[0] = uint256(5428970);
      colorInts[1] = uint256(13323211);
      colorInts[2] = uint256(15385745);
      colorInts[3] = uint256(13355851);
      colorInts[4] = uint256(15356630);
      colorInts[5] = uint256(14903600);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_THUNDER)) {
      colorInts[0] = uint256(924722);
      colorInts[1] = uint256(9464002);
      colorInts[2] = uint256(470093);
      colorInts[3] = uint256(6378394);
      colorInts[4] = uint256(16246484);
      colorInts[5] = uint256(12114921);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_AERO)) {
      colorInts[0] = uint256(4609);
      colorInts[1] = uint256(803087);
      colorInts[2] = uint256(2062109);
      colorInts[3] = uint256(11009906);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_FROSTFIRE)) {
      colorInts[0] = uint256(16772570);
      colorInts[1] = uint256(4043519);
      colorInts[2] = uint256(16758832);
      colorInts[3] = uint256(16720962);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COSMIC)) {
      colorInts[0] = uint256(1182264);
      colorInts[1] = uint256(10834562);
      colorInts[2] = uint256(4269159);
      colorInts[3] = uint256(16769495);
      colorInts[4] = uint256(3351916);
      colorInts[5] = uint256(12612224);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COLORLESS)) {
      colorInts[0] = uint256(1644825);
      colorInts[1] = uint256(15132390);
      colorIntCount = uint256(2);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_DARKNESS)) {
      colorInts[0] = uint256(2885188);
      colorInts[1] = uint256(1572943);
      colorInts[2] = uint256(1179979);
      colorInts[3] = uint256(657930);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_VOID)) {
      colorInts[0] = uint256(1572943);
      colorInts[1] = uint256(4194415);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(13051525);
      colorInts[4] = uint256(657930);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_UNDEAD)) {
      colorInts[0] = uint256(3546937);
      colorInts[1] = uint256(50595);
      colorInts[2] = uint256(7511983);
      colorInts[3] = uint256(7563923);
      colorInts[4] = uint256(10535352);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_HEAT)) {
      colorInts[0] = uint256(590337);
      colorInts[1] = uint256(12141574);
      colorInts[2] = uint256(15908162);
      colorInts[3] = uint256(6886400);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_EMBER)) {
      colorInts[0] = uint256(1180162);
      colorInts[1] = uint256(7929858);
      colorInts[2] = uint256(7012357);
      colorInts[3] = uint256(16744737);
      colorIntCount = uint256(4);
    } else {
      colorInts[0] = uint256(197391);
      colorInts[1] = uint256(3604610);
      colorInts[2] = uint256(6553778);
      colorInts[3] = uint256(14305728);
      colorIntCount = uint256(4);
    }

    return (colorInts, colorIntCount);
  }

}
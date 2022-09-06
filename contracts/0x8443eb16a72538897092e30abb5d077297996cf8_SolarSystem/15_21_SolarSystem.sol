// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Yazo
/// @author: Yazo
//  https://yazo.fun

import "./ERC721Tradable.sol";
import "./strings.sol";
import "./base64.sol";
contract SolarSystem is ERC721Tradable {
    using strings for *;
    uint constant SECONDS = 24 * 60 * 60;
    string private SVG_CODE = '';
    bool can_save_svg = true;
    mapping (uint => mapping (string => int)) VALUES;
    constructor(address _proxyRegistryAddress) ERC721Tradable("SolarSystem", "Solar", _proxyRegistryAddress) {        

        //MERCURY
        VALUES[0]["ecc"] = 2056;
        VALUES[0]["per"] = 88;
        VALUES[0]["dev"] = 88;
        VALUES[0]["start"] = 1490227200;
        VALUES[0]["deg"] = 73;

        //VENUS
        VALUES[1]["ecc"] = 68;
        VALUES[1]["per"] = 225;
        VALUES[1]["dev"] = 225;
        VALUES[1]["start"] = 1487548800;
        VALUES[1]["deg"] = 130;

        //EARTH
        VALUES[2]["ecc"] = 167;
        VALUES[2]["per"] = 365;
        VALUES[2]["dev"] = 365;
        VALUES[2]["start"] = 1483488000;
        VALUES[2]["deg"] = 104;

        //MARS
        VALUES[3]["ecc"] = 934;
        VALUES[3]["per"] = 686;
        VALUES[3]["dev"] = 686;
        VALUES[3]["start"] = 1477440000;
        VALUES[3]["deg"] = 334;

        //JUPITER
        VALUES[4]["ecc"] = 484;
        VALUES[4]["per"] = 4329;
        VALUES[4]["dev"] = 4329;
        VALUES[4]["start"] = 1300320000;
        VALUES[4]["deg"] = 14;

        //SATURN
        VALUES[5]["ecc"] = 541;
        VALUES[5]["per"] = 10753;
        VALUES[5]["dev"] = 10753;
        VALUES[5]["start"] = 1059264000;
        VALUES[5]["deg"] = 94;

        //URANUS
        VALUES[6]["ecc"] = 472;
        VALUES[6]["per"] = 30664;
        VALUES[6]["dev"] = 24820;
        VALUES[6]["start"] = -113097600;
        VALUES[6]["deg"] = 169;

        //NEPTUNE
        VALUES[7]["ecc"] = 86;
        VALUES[7]["per"] = 60148;
        VALUES[7]["dev"] = 24820;
        VALUES[7]["start"] = -2805753600;
        VALUES[7]["deg"] = 45;
    }

    function f( uint x, uint e, uint k) public pure returns (int) {
        return int(x) - (int(e)*sin(x))/10000 - int(k);
    }

    function f1( uint x, uint e) public pure returns (int) {
        return int(TWO_PI) - int(e) * cos(x)/10000;
    }

    function mean_anomaly(uint planet,uint t, uint offset) public view returns (uint) {
        uint e    = uint(VALUES[planet]["ecc"]);
        uint T    = uint(VALUES[planet]["per"]);
        uint deg  = uint(VALUES[planet]["deg"]);
        int  t0   = VALUES[planet]["start"];
        uint M    = TWO_PI / T * uint( uint((int(t)-t0) )%(T*SECONDS)) / SECONDS;
        uint E    = eccentric_anomaly_from_mean_anomaly(M,e) * 360 / TWO_PI;
        uint ME   = (offset + deg + E)%360;
        return ME;
    }

    function eccentric_anomaly_from_mean_anomaly(uint M, uint e) public pure returns (uint) {
        uint i = 0;
        uint x = M; 
        while ( i < 5 ) {
            x = uint(int(x) - f(x,e,M) * int(TWO_PI) / f1(x,e)) ;
            i ++;
        }
        return x;
    }

    function tokenURI(uint _tokenId) override public view returns (string memory) {
        uint t = block.timestamp;
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',"Solar System"'", "image":"',getTOKEN(t),'"}'
                        )
                    )
                )
            )
        );
    }

    function setSVG(string memory SVG) external onlyOwner {
        require(can_save_svg);
        SVG_CODE = SVG;
        can_save_svg = false;
    }

   function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        '{"name":"Solar System","description":"Real-time on-chain Solar System","image":"","external_link":"https://yazo.fun/","seller_fee_basis_points":0,"fee_recipient":""}'
                    )
                )
        ));
    }

    function decompress(strings.slice memory text_slice) internal pure returns (string memory) {
        uint count = text_slice.count("|".toSlice());
        strings.slice memory _temp_slice;
        strings.slice memory MASK = text_slice.split("|".toSlice());
        strings.slice[] memory HTML_PARTS = new strings.slice[](count);
        strings.slice[] memory parts = new strings.slice[](MASK.count(",".toSlice()) + 1);
        for(uint i = 0; i < parts.length;) {
            parts[i] = MASK.split(",".toSlice());
            unchecked { i++; }
        }
        for(uint i = 1; i <= count;) {
            _temp_slice = text_slice.split("|".toSlice());
            HTML_PARTS[i-1] = (i%2 == 0) ? parts[st2num(_temp_slice.toString())] : _temp_slice;
            unchecked { i++; }
       } 
       return "".toSlice().join(HTML_PARTS);
    }

    function getTOKEN(uint t) public view returns (string memory) {
        strings.slice[] memory parts = new strings.slice[](8);
        for (uint i=0; i<8;) {
            parts[i] = (Strings.toString(uint(VALUES[i]["dev"])*SECONDS*(mean_anomaly(i,t,180)*100/360)/100)).toSlice();
            unchecked { i++; }
        }
       return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(decompress(",".toSlice().join(parts).toSlice().concat(SVG_CODE.toSlice()).toSlice())))));
    }

    function withdraw(address payable recipient, uint amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function premine() external onlyOwner {
        mintTo(msg.sender);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "";
    }

    function st2num(string memory numString) public pure returns(uint) {
        uint val=0;
        bytes memory stringBytes = bytes(numString);
        for (uint i = 0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
            val += (uint(jval) * (10**(exp-1))); 
        }
        return val;
    }

    uint constant INDEX_WIDTH         = 8;
    uint constant INTERP_WIDTH        = 16;
    uint constant INDEX_OFFSET        = 28 - INDEX_WIDTH;
    uint constant INTERP_OFFSET       = INDEX_OFFSET - INTERP_WIDTH;
    uint constant ANGLES_IN_CYCLE     = 1073741824;
    uint constant QUADRANT_HIGH_MASK  = 536870912;
    uint constant QUADRANT_LOW_MASK   = 268435456;
    uint constant SINE_TABLE_SIZE     = 256;
    uint constant PI          = 3141592653589793238;
    uint constant TWO_PI      = 2 * PI;
    uint constant PI_OVER_TWO = PI / 2;
    uint8   constant entry_bytes = 4; 
    uint constant entry_mask  = ((1 << 8*entry_bytes) - 1); 
    bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";
    function sin(uint _angle) public pure returns (int256) {
      unchecked {
        _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;
        uint interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
        uint index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);
        bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
        bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;
        if (!is_odd_quadrant) {
          index = SINE_TABLE_SIZE - 1 - index;
        }
        bytes memory table = sin_table;
        uint offset1_2 = (index + 2) * entry_bytes;
        uint x1_2; assembly {
          x1_2 := mload(add(table, offset1_2))
        }
        uint x1 = x1_2 >> 8*entry_bytes & entry_mask;
        uint x2 = x1_2 & entry_mask;
        uint approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
        int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
        if (is_negative_quadrant) {
          sine *= -1;
        }
        return sine * 1e18 / 2_147_483_647;
      }
    }
    function cos(uint _angle) public pure returns (int256) {
      unchecked {
        return sin(_angle + PI_OVER_TWO);
      }
    }


}
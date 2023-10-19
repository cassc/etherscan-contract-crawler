// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.6.3
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid solidity code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

contract DecompiledContract {
    
    bytes32 public stor_k;
    bytes32 public stor_v;
    bytes32 public stor_y;
    bytes32 public stor_aa;
    bytes32 public stor_ap;
    bytes32 public stor_at;
    bytes32 public stor_bg;
    mapping(bytes => bytes) public stor_map_b;
    mapping(bytes => bytes) public stor_map_c;
    mapping(bytes => bytes) public stor_map_d;
    mapping(bytes => bytes) public stor_map_e;
    mapping(bytes => bytes) public stor_map_f;
    mapping(bytes => bytes) public stor_map_g;
    mapping(bytes => bytes) public stor_map_h;
    mapping(bytes => bytes) public stor_map_i;
    mapping(bytes => bytes) public stor_map_j;
    mapping(bytes => bytes32) public stor_map_a;
    mapping(bytes32 => bool) public stor_map_bl;
    mapping(bytes32 => bytes) public stor_map_ba;
    mapping(address => address) public stor_map_l;
    mapping(address => address) public stor_map_p;
    mapping(address => address) public stor_map_q;
    mapping(address => address) public stor_map_r;
    mapping(address => address) public stor_map_t;
    mapping(address => bytes32) public stor_map_s;
    mapping(bytes32 => bytes32) public stor_map_m;
    mapping(bytes32 => bytes32) public stor_map_n;
    mapping(bytes32 => bytes32) public stor_map_o;
    mapping(bytes32 => bytes32) public stor_map_u;
    mapping(bytes32 => bytes32) public stor_map_w;
    mapping(bytes32 => bytes32) public stor_map_x;
    mapping(bytes32 => bytes32) public stor_map_z;
    mapping(address => address) public stor_map_ao;
    mapping(address => address) public stor_map_aq;
    mapping(address => address) public stor_map_as;
    mapping(address => address) public stor_map_bh;
    mapping(address => address) public stor_map_bi;
    mapping(address => address) public stor_map_bj;
    mapping(address => bytes32) public stor_map_ar;
    mapping(address => bytes32) public stor_map_bm;
    mapping(bytes32 => bytes32) public stor_map_ab;
    mapping(bytes32 => bytes32) public stor_map_ac;
    mapping(bytes32 => bytes32) public stor_map_ad;
    mapping(bytes32 => bytes32) public stor_map_ae;
    mapping(bytes32 => bytes32) public stor_map_af;
    mapping(bytes32 => bytes32) public stor_map_ag;
    mapping(bytes32 => bytes32) public stor_map_ah;
    mapping(bytes32 => bytes32) public stor_map_ai;
    mapping(bytes32 => bytes32) public stor_map_aj;
    mapping(bytes32 => bytes32) public stor_map_ak;
    mapping(bytes32 => bytes32) public stor_map_al;
    mapping(bytes32 => bytes32) public stor_map_am;
    mapping(bytes32 => bytes32) public stor_map_an;
    mapping(bytes32 => bytes32) public stor_map_au;
    mapping(bytes32 => bytes32) public stor_map_av;
    mapping(bytes32 => bytes32) public stor_map_aw;
    mapping(bytes32 => bytes32) public stor_map_ax;
    mapping(bytes32 => bytes32) public stor_map_ay;
    mapping(bytes32 => bytes32) public stor_map_az;
    mapping(bytes32 => bytes32) public stor_map_bb;
    mapping(bytes32 => bytes32) public stor_map_bc;
    mapping(bytes32 => bytes32) public stor_map_bd;
    mapping(bytes32 => bytes32) public stor_map_be;
    mapping(bytes32 => bytes32) public stor_map_bf;
    mapping(bytes32 => bytes32) public stor_map_bk;
    
    event Event_8f36579a();
    event Event_dd617643();
    
    /// @custom:selector    0x24c33d33
    /// @custom:name        Unresolved_24c33d33
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_24c33d33(bytes memory arg0) public view returns (bytes memory) {
        bytes memory var_b = arg0;
        return abi.encodePacked(stor_map_a[var_b], stor_map_b[var_b], stor_map_c[var_b], !(!bytes1(stor_map_d[var_b])), stor_map_e[var_b], stor_map_f[var_b], stor_map_g[var_b], stor_map_h[var_b], stor_map_i[var_b], stor_map_j[var_b]);
    }
    
    /// @custom:selector    0x10f01eba
    /// @custom:name        Unresolved_10f01eba
    /// @param              arg0 ["address", "bytes", "bytes20", "bytes32", "int", "int160", "int256", "string", "uint", "uint160", "uint256"]
    function Unresolved_10f01eba(address arg0) public view returns (uint256) {
        address var_b = arg0;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0x6c52660d
    /// @custom:name        Unresolved_6c52660d
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_6c52660d(bytes memory arg0) public view returns (bool) {
        bytes memory var_a = 0x20 + (var_a + (0x20 * ((arg0 + 0x1f) / 0x20)));
        require(var_a.length > 0x20, "must be between 1 and 32 characters");
        require(!(var_a.length > 0x20), "must be between 1 and 32 characters");
        require(!(!0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start or end with space");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start or end with space");
        require(!(0x3000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(0x7800000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_j / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(0x5800000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_j / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x4000000000000000000000000000000000000000000000000000000000000000), "spaces error");
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x5b00000000000000000000000000000000000000000000000000000000000000), "spaces error");
        require(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000))), "spaces error");
        require(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000))), "spaces error");
        require(!(!0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_j / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        if (0) {
            if (0) {
            }
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x3000000000000000000000000000000000000000000000000000000000000000) {
                if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x3900000000000000000000000000000000000000000000000000000000000000) {
                }
                if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x3000000000000000000000000000000000000000000000000000000000000000) {
                }
            }
        }
        if (0) {
        }
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x2f00000000000000000000000000000000000000000000000000000000000000), "invalid characters");
        require(!(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000))) < 0x3a00000000000000000000000000000000000000000000000000000000000000), "invalid characters");
        if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x2f00000000000000000000000000000000000000000000000000000000000000) {
        }
        if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x6000000000000000000000000000000000000000000000000000000000000000) {
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x7b00000000000000000000000000000000000000000000000000000000000000) {
                if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x7b00000000000000000000000000000000000000000000000000000000000000) {
                }
            }
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x6000000000000000000000000000000000000000000000000000000000000000) {
            }
        }
        if (0) {
        }
        if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_i / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x4000000000000000000000000000000000000000000000000000000000000000) {
        }
        if (0 == 0x01) {
            require(0 == 0x01, "only num");
            return 0;
            return 0x01;
        }
        if ((var_a.length - 0x01) < var_a.length) {
            if (!0x2000000000000000000000000000000000000000000000000000000000000000 == (0x0100000000000000000000000000000000000000000000000000000000000000 * (var_n / 0x0100000000000000000000000000000000000000000000000000000000000000))) {
            }
        }
        require(!(!var_a.length > 0), "must be between 1 and 32 characters");
    }
    
    /// @custom:selector    0x63066434
    /// @custom:name        Unresolved_63066434
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_63066434(bytes memory arg0) public view returns (bytes memory) {
        var_a = stor_k;
        require(!(0x01 == (bytes1(stor_map_l[var_a]))), "sub failed");
        var_a = stor_k;
        require(!(block.timestamp > (stor_map_m[var_a])), "sub failed");
        require(!(block.timestamp > (stor_map_m[var_a])), "sub failed");
        require(!(block.timestamp > (stor_map_m[var_a])), "sub failed");
        bytes memory var_a = arg0;
        var_a = arg0;
        var_a = stor_map_n[var_a];
        require(!(stor_map_o[var_a] > (stor_map_p[var_a])), "sub failed");
        require(!(stor_map_p[var_a] - (stor_map_o[var_a]) > 0), "mul failed");
        var_a = arg0;
        var_a = stor_map_n[var_a];
        var_a = stor_map_q[var_a];
        require(!(stor_map_l[var_a] > 0), "mul failed");
        var_a = arg0;
        var_a = stor_map_n[var_a];
        var_a = stor_map_q[var_a];
        var_a = stor_map_n[var_a];
        require(!(!stor_map_r[var_a]), "mul failed");
        require(!(!stor_map_r[var_a]), "mul failed");
        require(stor_map_l[var_a] * (stor_map_r[var_a]) / (stor_map_r[var_a]) == stor_map_l[var_a], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_a = arg0;
        require(!((stor_map_l[var_a] * (stor_map_r[var_a]) / 0x0de0b6b3a7640000) + (stor_map_s[var_a]) < (stor_map_s[var_a])), "add failed");
        var_a = arg0;
        bytes memory var_g = (stor_map_l[var_a] * (stor_map_r[var_a]) / 0x0de0b6b3a7640000) + (stor_map_s[var_a]);
        return abi.encodePacked(stor_map_t[var_a], var_g, stor_map_o[var_a]);
        if (0x0de0b6b3a7640000) {
        }
        var_a = arg0;
        if (!(0 + (stor_map_s[var_a])) < (stor_map_s[var_a])) {
        }
        if (!(stor_map_p[var_a] - (stor_map_o[var_a])) > 0) {
        }
        var_a = stor_k;
        if (!arg0 == stor_map_l[var_a]) {
            var_a = stor_k;
            var_a = stor_map_q[var_a];
            var_a = stor_k;
            var_a = stor_map_q[var_a];
            var_a = stor_k;
            if (stor_map_u[var_a]) {
                require(!(arg0 == stor_map_l[var_a]), "mul failed");
                require(!(!stor_map_u[var_a]), "mul failed");
                require(!(!stor_map_u[var_a]), "mul failed");
                require((0x1e * (stor_map_u[var_a])) / (stor_map_u[var_a]) == 0x1e, "mul failed");
                require(0x64, "mul failed");
                require(!(!(0x1e * (stor_map_u[var_a])) / 0x64), "mul failed");
                require(!(!(0x1e * (stor_map_u[var_a])) / 0x64), "mul failed");
                require((0x0de0b6b3a7640000 * ((0x1e * (stor_map_u[var_a])) / 0x64)) / ((0x1e * (stor_map_u[var_a])) / 0x64) == 0x0de0b6b3a7640000, "mul failed");
            }
        }
        if (stor_map_l[var_a]) {
        }
        if (0x64) {
        }
        var_a = stor_k;
        require(!(!stor_map_u[var_a]), "add failed");
        require(!(!stor_map_u[var_a]), "add failed");
        require((0x32 * (stor_map_u[var_a])) / (stor_map_u[var_a]) == 0x32, "add failed");
        require(0x64, "add failed");
        var_a = arg0;
        require(!(((0x32 * (stor_map_u[var_a])) / 0x64) + (stor_map_m[var_a]) < (stor_map_m[var_a])), "add failed");
        var_a = stor_k;
        var_a = stor_map_q[var_a];
        var_a = stor_k;
        var_a = stor_map_q[var_a];
        var_a = stor_k;
        if (stor_map_u[var_a]) {
        }
        if (0x64) {
        }
        var_a = stor_k;
        if (!stor_map_l[var_a]) {
            var_a = stor_k;
            if (!arg0 == stor_map_l[var_a]) {
            }
            var_a = arg0;
            var_a = arg0;
            var_a = stor_map_n[var_a];
            if (!(stor_map_o[var_a]) > (stor_map_p[var_a])) {
            }
        }
        var_a = stor_k;
        if (stor_map_s[var_a]) {
        }
        if (!0x01 == (stor_map_l[var_a])) {
            var_a = stor_k;
            if (stor_map_s[var_a]) {
            }
            if (!0x01 == (stor_map_l[var_a])) {
                var_a = stor_k;
                if (!stor_map_l[var_a]) {
                }
                if (!0x01 == (stor_map_l[var_a])) {
                }
            }
        }
    }
    
    /// @custom:selector    0xca93e3c2
    /// @custom:name        Unresolved_ca93e3c2
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_ca93e3c2(bytes memory arg0, bytes memory arg1) public view returns (uint256) {
        bytes memory var_b = arg0;
        var_b = arg1;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0x2ce21999
    /// @custom:name        Unresolved_2ce21999
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_2ce21999(bytes memory arg0) public view returns (bytes memory) {
        bytes memory var_b = arg0;
        return abi.encodePacked(stor_map_a[var_b], stor_map_b[var_b]);
    }
    
    /// @custom:selector    0x624ae5c0
    /// @custom:name        Unresolved_624ae5c0
    function Unresolved_624ae5c0() public view returns (uint256) {
        return stor_k;
    }
    
    /// @custom:selector    0x11a09ae7
    /// @custom:name        Unresolved_11a09ae7
    function Unresolved_11a09ae7() public view returns (uint256) {
        return stor_v;
    }
    
    /// @custom:selector    0x747dff42
    /// @custom:name        Unresolved_747dff42
    function Unresolved_747dff42() public view returns (bytes memory) {
        var_a = 0;
        var_a = stor_k;
        return abi.encodePacked(stor_k, stor_map_n[var_a], stor_map_m[var_a], stor_map_w[var_a], stor_map_x[var_a], stor_map_q[var_a], stor_map_l[var_a], stor_map_l[var_a], stor_map_l[var_a], stor_map_l[var_a], stor_map_l[var_a], stor_y, stor_v, stor_map_z[var_a]);
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:name        Unresolved_95d89b41
    function Unresolved_95d89b41() public pure returns (bytes memory) {
        var_a = 0x40 + var_a;
        if (!var_a.length) {
            return abi.encodePacked(0x20, var_a.length);
            return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
        }
        if (!var_a.length) {
        }
    }
    
    /// @custom:selector    0x2e19ebdc
    /// @custom:name        Unresolved_2e19ebdc
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_2e19ebdc(bytes memory arg0) public view returns (uint256) {
        bytes memory var_b = arg0;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0x3ccfd60b
    /// @custom:name        Unresolved_3ccfd60b
    function Unresolved_3ccfd60b() public {
        var_a = var_a + 0x0100;
        require(0x01 == (bytes1(stor_aa)), "sub failed");
        require(!address(msg.sender).code.length, "sub failed");
        var_j = stor_k;
        require(!(0x01 == (bytes1(stor_map_ab[var_j]))), "sub failed");
        var_j = stor_k;
        require(!(block.timestamp > (stor_map_ac[var_j])), "sub failed");
        require(!(block.timestamp > (stor_map_ac[var_j])), "sub failed");
        require(!(block.timestamp > (stor_map_ac[var_j])), "sub failed");
        var_j = stor_map_ab[var_j];
        var_j = stor_map_ad[var_j];
        var_j = stor_map_ab[var_j];
        var_j = stor_map_ad[var_j];
        require(!(stor_map_ae[var_j] > (stor_map_af[var_j])), "sub failed");
        require(!(stor_map_af[var_j] - (stor_map_ae[var_j]) > 0), "mul failed");
        var_j = stor_map_ab[var_j];
        var_j = stor_map_ad[var_j];
        var_j = stor_map_ag[var_j];
        require(!(stor_map_ab[var_j] > 0), "mul failed");
        var_j = stor_map_ad[var_j];
        var_j = stor_map_ab[var_j];
        var_j = stor_map_ad[var_j];
        stor_map_ae[var_j] = stor_map_ah[var_j];
        var_j = stor_map_ab[var_j];
        var_j = stor_map_ad[var_j];
        var_j = stor_map_ag[var_j];
        var_j = stor_map_ad[var_j];
        require(!(!stor_map_ah[var_j]), "mul failed");
        require(!(!stor_map_ah[var_j]), "mul failed");
        require(stor_map_ab[var_j] * (stor_map_ah[var_j]) / (stor_map_ah[var_j]) == stor_map_ab[var_j], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_j = stor_map_ab[var_j];
        require(!((stor_map_ab[var_j] * (stor_map_ah[var_j]) / 0x0de0b6b3a7640000) + (stor_map_ai[var_j]) < (stor_map_ai[var_j])), "add failed");
        var_j = stor_map_ab[var_j];
        stor_map_ai[var_j] = (stor_map_ab[var_j] * (stor_map_ah[var_j]) / 0x0de0b6b3a7640000) + (stor_map_ai[var_j]);
        var_j = stor_map_ab[var_j];
        require(!(stor_map_aj[var_j] + (stor_map_ak[var_j]) < (stor_map_ak[var_j])), "add failed");
        require(!(stor_map_al[var_j] + (stor_map_aj[var_j] + (stor_map_ak[var_j])) < (stor_map_aj[var_j] + (stor_map_ak[var_j]))), "add failed");
        require(!(stor_map_al[var_j] + (stor_map_aj[var_j] + (stor_map_ak[var_j]))) > 0);
        stor_map_ak[var_j] = 0;
        stor_map_aj[var_j] = 0;
        stor_map_ae[var_j] = 0;
        require(!(stor_map_al[var_j] + (stor_map_aj[var_j] + (stor_map_ak[var_j]))) > 0);
        var_j = stor_map_ab[var_j];
        (bool success, bytes memory ret0) = address(stor_map_ab[var_j]).call{ gas: 0x08fc * (!(stor_map_al[var_j]) + (stor_map_aj[var_j] + (stor_map_ak[var_j]))), value: (stor_map_al[var_j]) + (stor_map_aj[var_j] + (stor_map_ak[var_j])) }(abi.encode());
        var_j = stor_map_ab[var_j];
        var_q = (stor_map_al[var_j]) + (stor_map_aj[var_j] + (stor_map_ak[var_j]));
        emit Event_8f36579a(stor_map_ab[var_j], msg.sender, stor_map_am[var_j], var_q, block.timestamp);
        var_j = stor_map_ab[var_j];
        if (!(stor_map_al[var_j] + (stor_map_aj[var_j] + (stor_map_ak[var_j]))) > 0) {
        }
        if (0x0de0b6b3a7640000) {
        }
        var_j = stor_map_ab[var_j];
        if (!(stor_map_aj[var_j] + (stor_map_ak[var_j])) < (stor_map_ak[var_j])) {
        }
        if (!(stor_map_af[var_j] - (stor_map_ae[var_j])) > 0) {
        }
        var_j = stor_k;
        stor_map_ai[var_j] = 0x01 | (uint248(stor_map_ai[var_j]));
        var_a = var_a + 0x0100;
        var_j = stor_k;
        if (stor_map_an[var_j]) {
            if (stor_map_an[var_j]) {
                if ((0x32 * (stor_map_an[var_j])) / (stor_map_an[var_j]) == 0x32) {
                    if (0x64) {
                        if (stor_map_an[var_j]) {
                            require((0x32 * (stor_map_an[var_j])) / (stor_map_an[var_j]) == 0x32, "mul failed");
                        }
                        require(!(!stor_map_an[var_j]), "mul failed");
                        require(!(!stor_map_an[var_j]), "mul failed");
                    }
                }
            }
        }
        if (0x64) {
        }
        var_j = stor_k;
        if (!stor_map_ab[var_j]) {
            var_j = stor_k;
            stor_map_ai[var_j] = 0x01 | (uint248(stor_map_ai[var_j]));
            var_j = stor_k;
            if (stor_map_an[var_j]) {
            }
            var_j = stor_map_ab[var_j];
            var_j = stor_map_ad[var_j];
            var_j = stor_map_ab[var_j];
            var_j = stor_map_ad[var_j];
            if (!(stor_map_ae[var_j]) > (stor_map_af[var_j])) {
            }
        }
        var_j = stor_k;
        if (stor_map_ai[var_j]) {
        }
        if (!0x01 == (stor_map_ab[var_j])) {
            var_j = stor_k;
            if (stor_map_ai[var_j]) {
            }
            if (!0x01 == (stor_map_ab[var_j])) {
                var_j = stor_k;
                if (!stor_map_ab[var_j]) {
                }
                if (!0x01 == (stor_map_ab[var_j])) {
                }
            }
        }
        var_j = this.code[17785:17817]
        var_j = var_j;
        var_j = this.code[17721:17753]
        var_j = var_j;
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:name        Unresolved_06fdde03
    function Unresolved_06fdde03() public pure returns (bytes memory) {
        var_a = 0x40 + var_a;
        if (!var_a.length) {
            return abi.encodePacked(0x20, var_a.length);
            return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
        }
        if (!var_a.length) {
        }
    }
    
    /// @custom:selector    0xd87574e0
    /// @custom:name        Unresolved_d87574e0
    function Unresolved_d87574e0() public view returns (uint256) {
        return stor_y;
    }
    
    /// @custom:selector    0x27d87924
    /// @custom:name        Unresolved_27d87924
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["address", "bytes", "bytes20", "bytes32", "int", "int160", "int256", "string", "uint", "uint160", "uint256"]
    function Unresolved_27d87924(bytes memory arg0, address arg1) public {
        bytes memory var_a = 0x20 + (var_a + (0x20 * ((arg0 + 0x1f) / 0x20)));
        var_a = var_a + 0x0100;
        require(!address(msg.sender).code.length, "register fail");
        var_l = msg.sender;
        require(!stor_map_ao[var_l], "register fail");
        require(!(!address(arg1)), "must be between 1 and 32 characters");
        address var_l = arg1;
        require(stor_map_ao[var_l], "must be between 1 and 32 characters");
        require(var_a.length > 0x20, "must be between 1 and 32 characters");
        require(!(var_a.length > 0x20), "must be between 1 and 32 characters");
        require(!(!0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start or end with space");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start or end with space");
        require(!(0x3000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(0x7800000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_t / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(0x5800000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_t / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "cannot start with 0x");
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x4000000000000000000000000000000000000000000000000000000000000000), "spaces error");
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x5b00000000000000000000000000000000000000000000000000000000000000), "spaces error");
        require(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000))), "spaces error");
        require(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000))), "spaces error");
        require(!(!0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        require(!(0x2000000000000000000000000000000000000000000000000000000000000000 == (bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_t / 0x0100000000000000000000000000000000000000000000000000000000000000)))), "spaces error");
        if (0) {
            if (0) {
            }
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x3000000000000000000000000000000000000000000000000000000000000000) {
                if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x3900000000000000000000000000000000000000000000000000000000000000) {
                }
                if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x3000000000000000000000000000000000000000000000000000000000000000) {
                }
            }
        }
        if (0) {
        }
        require(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x2f00000000000000000000000000000000000000000000000000000000000000), "invalid characters");
        require(!(!(bytes1(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000))) < 0x3a00000000000000000000000000000000000000000000000000000000000000), "invalid characters");
        if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x2f00000000000000000000000000000000000000000000000000000000000000) {
        }
        if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x6000000000000000000000000000000000000000000000000000000000000000) {
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x7b00000000000000000000000000000000000000000000000000000000000000) {
                if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) < 0x7b00000000000000000000000000000000000000000000000000000000000000) {
                }
            }
            if ((0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x6000000000000000000000000000000000000000000000000000000000000000) {
            }
        }
        if (0) {
        }
        if (!(0x0100000000000000000000000000000000000000000000000000000000000000 * (var_s / 0x0100000000000000000000000000000000000000000000000000000000000000)) > 0x4000000000000000000000000000000000000000000000000000000000000000) {
        }
        if (0 == 0x01) {
            stor_ap = 0x01 + stor_ap;
            stor_map_ao[var_l] = stor_ap;
            var_l = stor_map_ao[var_l];
            stor_map_ao[var_l] = (address(msg.sender)) | (uint96(stor_map_ao[var_l]));
            var_l = stor_map_ao[var_l];
            stor_map_aq[var_l] = stor_map_ao[var_l];
            stor_map_ar[var_l] = var_u;
            var_l = var_u;
            stor_map_ao[var_l] = stor_map_ao[var_l];
            var_l = var_u;
            require(0 == 0x01, "only num");
            var_l = stor_map_ao[var_l];
            emit Event_dd617643(stor_map_ao[var_l], address(msg.sender), var_u, 0x01, stor_map_ao[var_l], address(stor_map_ao[var_l]), stor_map_as[var_l], msg.value, block.timestamp);
            var_l = var_u;
            stor_map_ao[var_l] = 0x01 | (uint248(stor_map_ao[var_l]));
            var_l = stor_map_ao[var_l];
        }
        if ((var_a.length - 0x01) < var_a.length) {
            if (!0x2000000000000000000000000000000000000000000000000000000000000000 == (0x0100000000000000000000000000000000000000000000000000000000000000 * (var_aa / 0x0100000000000000000000000000000000000000000000000000000000000000))) {
            }
        }
        require(!(!var_a.length > 0), "must be between 1 and 32 characters");
        var_l = this.code[17785:17817]
        var_l = var_l;
    }
    
    /// @custom:selector    0x018a25e8
    /// @custom:name        Unresolved_018a25e8
    function Unresolved_018a25e8() public view returns (uint256) {
        var_a = stor_k;
        if (!block.timestamp > (stor_map_o[var_a])) {
            require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
            require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
            return 0x6a94d74f430000;
            var_a = stor_k;
            require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
            require(0x0de0b6b3a7640000, "mul failed");
            return 0;
        }
        require(0x0de0b6b3a7640000, "mul failed");
        require(((stor_map_u[var_a] * 0x0de0b6b3a7640000) / 0x0de0b6b3a7640000) == (stor_map_u[var_a]), "mul failed");
        if (0x021e19e0c9bab2400000) {
            var_c = (stor_map_u[var_a] * 0x0de0b6b3a7640000) / 0x021e19e0c9bab2400000;
            return var_c;
        }
        var_a = stor_k;
        if (stor_map_u[var_a] < stor_at) {
        }
        var_a = stor_k;
        if (!block.timestamp > (stor_map_m[var_a])) {
            if (block.timestamp > (stor_map_m[var_a])) {
                var_a = stor_k;
                if (stor_map_u[var_a] < stor_at) {
                }
                if (block.timestamp > (stor_map_m[var_a])) {
                    if (0x0de0b6b3a7640000) {
                    }
                    return 0x6a94d74f430000;
                }
            }
            var_a = stor_k;
            if (!block.timestamp > (stor_map_m[var_a])) {
                if (!block.timestamp > (stor_map_m[var_a])) {
                }
                var_a = stor_k;
                if (stor_map_l[var_a]) {
                }
            }
        }
    }
    
    /// @custom:selector    0x9be5bb0d
    /// @custom:name        Unresolved_9be5bb0d
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_9be5bb0d(bytes memory arg0) public view returns (bool) {
        bytes memory var_b = arg0;
        return !(!bytes1(stor_map_a[var_b]));
    }
    
    /// @custom:selector    0x5fd9a484
    /// @custom:name        Unresolved_5fd9a484
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_5fd9a484(bytes memory arg0) public payable {
        var_a = var_a + 0x0100;
        require(0x01 == (bytes1(stor_aa)), "eth more");
        require(!address(msg.sender).code.length, "eth more");
        require(!(msg.value < 0x3b9aca00), "eth more");
        require(!(msg.value > 0x152d02c7e14af6800000), "eth more");
        var_n = msg.sender;
        require(stor_map_au[var_n], "add failed");
        require(arg0 < 0, "add failed");
        require(!(arg0 < 0), "add failed");
        var_n = stor_k;
        require(!(bytes1(stor_map_au[var_n])), "add failed");
        var_n = stor_k;
        require(!(block.timestamp > (stor_map_av[var_n])), "add failed");
        require(!(block.timestamp > (stor_map_av[var_n])), "add failed");
        var_n = stor_k;
        require(!(block.timestamp > (stor_map_aw[var_n])), "add failed");
        require(!(block.timestamp > (stor_map_aw[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        require(!((msg.value + (stor_map_ax[var_n])) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = msg.value + (stor_map_ax[var_n]);
        var_n = stor_k;
        stor_map_ax[var_n] = 0x01 | (uint248(stor_map_ax[var_n]));
        var_a = var_a + 0x0100;
        var_n = stor_k;
        if (stor_map_ay[var_n]) {
            if (stor_map_ay[var_n]) {
                if ((0x32 * (stor_map_ay[var_n])) / (stor_map_ay[var_n]) == 0x32) {
                    if (0x64) {
                        if (stor_map_ay[var_n]) {
                            require((0x32 * (stor_map_ay[var_n])) / (stor_map_ay[var_n]) == 0x32, "mul failed");
                        }
                        require(!(!stor_map_ay[var_n]), "mul failed");
                        require(!(!stor_map_ay[var_n]), "mul failed");
                    }
                }
            }
        }
        if (0x64) {
        }
        var_n = stor_k;
        if (stor_map_ax[var_n]) {
        }
        var_n = stor_k;
        require(!(!stor_map_aw[var_n]), "add failed");
        require(!(msg.value > 0x3b9aca00), "add failed");
        var_n = stor_k;
        require(!(!bytes1(stor_map_au[var_n])), "add failed");
        var_n = stor_k;
        require(msg.value, "add failed");
        require(msg.value, "add failed");
        require(((0x021e19e0c9bab2400000 * msg.value) / msg.value) == 0x021e19e0c9bab2400000, "add failed");
        require(!(!stor_map_az[var_n]), "add failed");
        require((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) < 0x0de0b6b3a7640000, "add failed");
        var_n = stor_k;
        require(!(0x01 == (bytes1(stor_map_au[var_n]))), "add failed");
        var_n = stor_k;
        require(!(!(stor_map_az[var_n]) < stor_at), "add failed");
        var_n = stor_k;
        require(stor_map_au[var_n] == stor_map_au[var_n], "add failed");
        var_n = stor_k;
        stor_map_au[var_n] = stor_map_au[var_n];
        var_n = stor_k;
        require(0 == (stor_map_ba[var_n]), "add failed");
        stor_map_ba[var_n] = 0;
        require(msg.value < 0x016345785d8a0000, "add failed");
        stor_v = 0x01 + stor_v;
        var_a = 0x14 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20, "add failed");
        require(block.timestamp, "add failed");
        var_a = 0x14 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20, "add failed");
        require(block.timestamp, "add failed");
        require(!((block.difficulty + block.timestamp) < block.timestamp), "add failed");
        require(!((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp) < (block.difficulty + block.timestamp)), "add failed");
        require(!((block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))) < ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))), "add failed");
        require(!((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))) < (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp)))), "add failed");
        require(!((block.number + ((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))))) < ((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))))), "add failed");
        var_a = 0x20 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require(!(keccak256(var_aj) - (0x03e8 * (keccak256(var_aj) / 0x03e8)) < stor_v), "add failed");
        require(!(0x01 == 0x01), "add failed");
        var_n = stor_k;
        require(!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))), "add failed");
        var_n = stor_k;
        stor_map_bb[var_n] = (stor_map_aw[var_n]) + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]));
        if (!(stor_map_ax[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
        }
        if (msg.value < 0x8ac7230489e80000) {
            if (stor_y) {
                require(msg.value < 0x8ac7230489e80000, "mul failed");
                require(stor_y, "mul failed");
                require(stor_y, "mul failed");
                var_n = stor_map_au[var_n];
                require(((0x4b * stor_y) / stor_y) == 0x4b, "mul failed");
            }
        }
        if (0x64) {
        }
        if (msg.value < 0x0de0b6b3a7640000) {
            if (!msg.value < 0x8ac7230489e80000) {
                if (msg.value < 0x016345785d8a0000) {
                    if (!msg.value < 0x0de0b6b3a7640000) {
                        stor_v = 0;
                        var_n = stor_k;
                        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
                        }
                        if (stor_y) {
                            if (stor_y) {
                            }
                            if (0x64) {
                                var_n = stor_map_au[var_n];
                                if (!(0 + (stor_map_aw[var_n])) < (stor_map_aw[var_n])) {
                                }
                            }
                        }
                    }
                    if (msg.value < 0x016345785d8a0000) {
                        if (stor_y) {
                        }
                        stor_v = 0;
                        var_n = stor_k;
                        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
                        }
                    }
                }
                if (stor_y) {
                    if (stor_y) {
                    }
                    if (0x64) {
                        var_n = stor_map_au[var_n];
                        if (!(0 + (stor_map_aw[var_n])) < (stor_map_aw[var_n])) {
                        }
                    }
                }
            }
            if (msg.value < 0x0de0b6b3a7640000) {
                if (stor_y) {
                }
                if (msg.value < 0x016345785d8a0000) {
                }
            }
        }
        if (!0x01 == 0) {
            if (msg.value < 0x8ac7230489e80000) {
            }
            var_n = stor_k;
            if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
            }
        }
        if ((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
            if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
            }
            if (!(keccak256(var_aj) - (0x03e8 * (keccak256(var_aj) / 0x03e8))) < stor_v) {
            }
        }
        if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
        }
        if (block.timestamp) {
        }
        if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
        }
        if (block.timestamp) {
        }
        var_n = stor_k;
        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
        }
        if (msg.value < 0x016345785d8a0000) {
        }
        var_n = stor_k;
        if (0 == (stor_map_ba[var_n])) {
        }
        var_n = stor_k;
        if (!block.timestamp > (stor_map_aw[var_n])) {
            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            var_n = stor_k;
            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require((0x78 * ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000)) / ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) == 0x78, "mul failed");
        }
        if (!(stor_map_aw[var_n] + 0) < 0) {
        }
        if ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) {
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require((0x78 * ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000)) / ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) == 0x78, "mul failed");
        }
        if (!(block.timestamp + 0) < 0) {
        }
        var_n = stor_k;
        if (stor_map_au[var_n]) {
        }
        if (!0x01 == (stor_map_au[var_n])) {
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
            }
            var_n = stor_k;
            if (stor_map_au[var_n] == stor_map_au[var_n]) {
            }
        }
        if (msg.value < 0x016345785d8a0000) {
        }
        if (stor_map_az[var_n]) {
        }
        if (msg.value) {
        }
        var_a = var_a + 0x0100;
        var_n = stor_map_au[var_n];
        require(!(stor_map_bc[var_n]), "sub failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!((stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        if (0x0de0b6b3a7640000) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        var_n = stor_k;
        if (!block.timestamp > (stor_map_aw[var_n])) {
            if (block.timestamp > (stor_map_aw[var_n])) {
                var_n = stor_k;
                if (stor_map_aw[var_n]) {
                }
                var_n = stor_k;
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
            }
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
                var_n = stor_k;
                if (stor_map_au[var_n]) {
                }
            }
        }
        if (stor_map_au[var_n]) {
        }
        var_n = stor_k;
        require(!(bytes1(stor_map_au[var_n])), "add failed");
        var_n = stor_k;
        require(!(block.timestamp > (stor_map_av[var_n])), "add failed");
        require(!(block.timestamp > (stor_map_av[var_n])), "add failed");
        var_n = stor_k;
        require(!(block.timestamp > (stor_map_aw[var_n])), "add failed");
        require(!(block.timestamp > (stor_map_aw[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        require(!((msg.value + (stor_map_ax[var_n])) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = msg.value + (stor_map_ax[var_n]);
        var_n = stor_k;
        stor_map_ax[var_n] = 0x01 | (uint248(stor_map_ax[var_n]));
        var_a = var_a + 0x0100;
        var_n = stor_k;
        if (stor_map_ay[var_n]) {
        }
        var_n = stor_k;
        if (stor_map_ax[var_n]) {
        }
        var_n = stor_k;
        if (stor_map_aw[var_n]) {
            if (!msg.value > 0x3b9aca00) {
                var_n = stor_k;
                if (stor_map_au[var_n]) {
                    var_n = stor_k;
                    if (msg.value) {
                        if (msg.value) {
                            require(!(!stor_map_aw[var_n]), "mul failed");
                            require(!(msg.value > 0x3b9aca00), "mul failed");
                            require(!(!bytes1(stor_map_au[var_n])), "mul failed");
                            require(msg.value, "mul failed");
                            require(msg.value, "mul failed");
                            require(((0x021e19e0c9bab2400000 * msg.value) / msg.value) == 0x021e19e0c9bab2400000, "mul failed");
                            var_n = stor_k;
                            stor_map_au[var_n] = stor_map_au[var_n];
                            var_n = stor_k;
                            require(!(!stor_map_az[var_n]), "mul failed");
                        }
                        var_n = stor_k;
                        require((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) < 0x0de0b6b3a7640000, "mul failed");
                    }
                }
                var_n = stor_k;
                require(!(0x01 == (bytes1(stor_map_au[var_n]))), "mul failed");
                require(!(!(stor_map_az[var_n]) < stor_at), "mul failed");
                var_n = stor_k;
                require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            }
            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require((0x78 * ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000)) / ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) == 0x78, "mul failed");
        }
        if (!(block.timestamp + 0) < 0) {
        }
        var_n = stor_k;
        if (stor_map_au[var_n]) {
        }
        if (!0x01 == (stor_map_au[var_n])) {
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
            }
            var_n = stor_k;
            if (stor_map_au[var_n] == stor_map_au[var_n]) {
            }
        }
        if (msg.value < 0x016345785d8a0000) {
            stor_v = 0x01 + stor_v;
            var_a = 0x14 + (0x20 + var_a);
            if (var_a.length < 0x20) {
                require(msg.value < 0x016345785d8a0000, "add failed");
            }
            require(var_a.length < 0x20, "add failed");
            var_a = 0x14 + (0x20 + var_a);
            require(block.timestamp, "add failed");
            require(var_a.length < 0x20, "add failed");
        }
        require(block.timestamp, "add failed");
        require(!((block.difficulty + block.timestamp) < block.timestamp), "add failed");
        require(!((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp) < (block.difficulty + block.timestamp)), "add failed");
        require(!((block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))) < ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))), "add failed");
        if (!((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp)))) < (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp)))) {
        }
        var_n = stor_k;
        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * msg.value) / (stor_map_az[var_n]))) {
        }
        if (stor_map_az[var_n]) {
        }
        if (msg.value) {
        }
        var_a = var_a + 0x0100;
        var_n = stor_map_au[var_n];
        require(!(stor_map_bc[var_n]), "sub failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!((stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        if (0x0de0b6b3a7640000) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!msg.value > 0x3b9aca00) {
        }
        var_n = stor_k;
        if (!block.timestamp > (stor_map_aw[var_n])) {
            if (block.timestamp > (stor_map_aw[var_n])) {
                var_n = stor_k;
                if (stor_map_aw[var_n]) {
                }
                var_n = stor_k;
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
            }
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
                var_n = stor_k;
                if (stor_map_au[var_n]) {
                }
            }
        }
        if (stor_map_au[var_n]) {
        }
        if (!arg0 > 0x03) {
        }
        var_n = this.code[17785:17817]
        var_n = var_n;
        var_n = this.code[17721:17753]
        var_n = var_n;
    }
    
    /// @custom:selector    0xcf808000
    /// @custom:name        Unresolved_cf808000
    /// @param              arg0 ["bool", "bytes", "bytes1", "bytes32", "int", "int256", "int8", "string", "uint", "uint256", "uint8"]
    function Unresolved_cf808000(bool arg0) public view returns (uint256) {
        var_a = stor_k;
        require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
        require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
        require(!(block.timestamp > (stor_map_o[var_a])), "mul failed");
        require(arg0, "mul failed");
        require(arg0, "mul failed");
        require(((0x6a94d74f430000 * arg0) / arg0) == 0x6a94d74f430000, "mul failed");
        return 0x6a94d74f430000 * arg0;
        return 0;
        var_a = stor_k;
        require(arg0, "mul failed");
        require(arg0, "mul failed");
        require(((0x0de0b6b3a7640000 * arg0) / arg0) == 0x0de0b6b3a7640000, "mul failed");
        require(!(!0x0de0b6b3a7640000 * arg0), "mul failed");
        require(!(!0x0de0b6b3a7640000 * arg0), "mul failed");
        require(stor_map_u[var_a] * (0x0de0b6b3a7640000 * arg0) / (0x0de0b6b3a7640000 * arg0) == (stor_map_u[var_a]), "mul failed");
        if (0x021e19e0c9bab2400000) {
            var_c = (stor_map_u[var_a] * (0x0de0b6b3a7640000 * arg0)) / 0x021e19e0c9bab2400000;
            return var_c;
        }
        if (0x021e19e0c9bab2400000) {
        }
        if (0) {
        }
        var_a = stor_k;
        if (stor_map_u[var_a] < stor_at) {
        }
        var_a = stor_k;
        if (!block.timestamp > (stor_map_m[var_a])) {
            if (block.timestamp > (stor_map_m[var_a])) {
                var_a = stor_k;
                if (stor_map_u[var_a] < stor_at) {
                }
                if (block.timestamp > (stor_map_m[var_a])) {
                    if (arg0) {
                    }
                    if (arg0) {
                    }
                }
            }
            var_a = stor_k;
            if (!block.timestamp > (stor_map_m[var_a])) {
                if (!block.timestamp > (stor_map_m[var_a])) {
                }
                var_a = stor_k;
                if (stor_map_l[var_a]) {
                }
            }
        }
    }
    
    /// @custom:selector    0xec2a6e3d
    /// @custom:name        Unresolved_ec2a6e3d
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg2 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_ec2a6e3d(bytes memory arg0, bytes memory arg1, bytes memory arg2) public view returns (uint256) {
        bytes memory var_b = arg0;
        var_b = arg1;
        var_b = arg2;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0x0f15f4c0
    /// @custom:name        Unresolved_0f15f4c0
    function Unresolved_0f15f4c0() public {
        require(msg.sender == 0x39cfdb0c1e952f65e76d2b114dd6bf86e4fb2f81, "game already activated");
        require(!(bytes1(stor_aa)), "game already activated");
        stor_aa = 0x01 | (uint248(stor_aa));
        stor_k = 0x01;
        uint248 stor_bg = stor_bg;
    }
    
    /// @custom:selector    0x7092dd3b
    /// @custom:name        Unresolved_7092dd3b
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_7092dd3b(bytes memory arg0) public {
        require(msg.sender == 0x39cfdb0c1e952f65e76d2b114dd6bf86e4fb2f81, "only manager just can activate");
        stor_at = arg0;
    }
    
    /// @custom:selector    0x9baa66f7
    /// @custom:name        Unresolved_9baa66f7
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_9baa66f7(bytes memory arg0) public view returns (uint256) {
        bytes memory var_b = arg0;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0xee0b5d8b
    /// @custom:name        Unresolved_ee0b5d8b
    /// @param              arg0 ["address", "bytes", "bytes20", "bytes32", "int", "int160", "int256", "string", "uint", "uint160", "uint256"]
    function Unresolved_ee0b5d8b(address arg0) public view returns (bytes memory) {
        address var_a = arg0;
        var_a = stor_k;
        var_a = stor_map_l[var_a];
        var_a = stor_map_bh[var_a];
        var_a = stor_map_l[var_a];
        var_a = stor_map_bh[var_a];
        require(!(stor_map_o[var_a] > (stor_map_p[var_a])), "sub failed");
        require(!(stor_map_p[var_a] - (stor_map_o[var_a]) > 0), "mul failed");
        var_a = stor_map_l[var_a];
        var_a = stor_map_bh[var_a];
        var_a = stor_map_q[var_a];
        require(!(stor_map_l[var_a] > 0), "mul failed");
        var_a = stor_map_l[var_a];
        var_a = stor_map_bh[var_a];
        var_a = stor_map_q[var_a];
        var_a = stor_map_bh[var_a];
        require(!(!stor_map_r[var_a]), "mul failed");
        require(!(!stor_map_r[var_a]), "mul failed");
        require(stor_map_l[var_a] * (stor_map_r[var_a]) / (stor_map_r[var_a]) == stor_map_l[var_a], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_a = stor_map_l[var_a];
        require(!((stor_map_l[var_a] * (stor_map_r[var_a]) / 0x0de0b6b3a7640000) + (stor_map_s[var_a]) < (stor_map_s[var_a])), "add failed");
        var_a = stor_map_l[var_a];
        var_a = stor_k;
        var_a = stor_map_l[var_a];
        address var_j = (stor_map_l[var_a] * (stor_map_r[var_a]) / 0x0de0b6b3a7640000) + (stor_map_s[var_a]);
        return abi.encodePacked(stor_map_l[var_a], stor_map_q[var_a], stor_map_m[var_a], stor_map_t[var_a], var_j, stor_map_o[var_a], stor_map_bi[var_a], stor_map_bj[var_a]);
        if (0x0de0b6b3a7640000) {
        }
        var_a = stor_map_l[var_a];
        if (!(0 + (stor_map_s[var_a])) < (stor_map_s[var_a])) {
        }
        if (!(stor_map_p[var_a] - (stor_map_o[var_a])) > 0) {
        }
    }
    
    /// @custom:selector    0x0b864f26
    /// @custom:name        Unresolved_0b864f26
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg2 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_0b864f26(bytes memory arg0, bytes memory arg1, bytes memory arg2) public view returns (uint256) {
        bytes memory var_b = arg0;
        var_b = arg1;
        var_b = arg2;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0xbade2c65
    /// @custom:name        Unresolved_bade2c65
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bool", "bytes", "bytes1", "bytes32", "int", "int256", "int8", "string", "uint", "uint256", "uint8"]
    function Unresolved_bade2c65(bytes memory arg0, bool arg1) public {
        var_a = var_a + 0x0100;
        require(0x01 == (bytes1(stor_aa)), "eth more");
        require(!address(msg.sender).code.length, "eth more");
        require(!(arg1 < 0x3b9aca00), "eth more");
        require(!(arg1 > 0x152d02c7e14af6800000), "eth more");
        var_n = msg.sender;
        if (stor_map_au[var_n]) {
            if (arg0 < 0) {
                if (!arg0 < 0) {
                    var_n = stor_k;
                    if (!stor_map_au[var_n]) {
                        var_n = stor_k;
                        if (!block.timestamp > (stor_map_av[var_n])) {
                            require(stor_map_au[var_n], "mul failed");
                            require(arg0 < 0, "mul failed");
                            require(!(arg0 < 0), "mul failed");
                            var_n = stor_k;
                            stor_map_ax[var_n] = 0x01 | (uint248(stor_map_ax[var_n]));
                            var_a = var_a + 0x0100;
                            var_n = stor_k;
                            require(!(bytes1(stor_map_au[var_n])), "mul failed");
                            require(!(block.timestamp > (stor_map_av[var_n])), "mul failed");
                            require(!(block.timestamp > (stor_map_av[var_n])), "mul failed");
                            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
                            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
                            require((0x32 * (stor_map_ay[var_n])) / (stor_map_ay[var_n]) == 0x32, "mul failed");
                        }
                        require(!(!stor_map_ay[var_n]), "mul failed");
                        require(!(!stor_map_ay[var_n]), "mul failed");
                    }
                }
            }
        }
        if (0x64) {
        }
        var_n = stor_k;
        if (stor_map_ax[var_n]) {
        }
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!((stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        var_n = stor_map_au[var_n];
        require(!(stor_map_bk[var_n] + (stor_map_bb[var_n]) < (stor_map_bb[var_n])), "add failed");
        require(!(stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])) < (stor_map_bk[var_n] + (stor_map_bb[var_n]))), "add failed");
        require(!(stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])) > 0), "sub failed");
        stor_map_bb[var_n] = 0;
        stor_map_bk[var_n] = 0;
        stor_map_av[var_n] = 0;
        require(!(arg1 > (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])))), "sub failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n]))) - arg1;
        var_n = stor_k;
        require(!(!stor_map_aw[var_n]), "add failed");
        require(!(arg1 > 0x3b9aca00), "add failed");
        var_n = stor_k;
        require(!(!bytes1(stor_map_au[var_n])), "add failed");
        var_n = stor_k;
        require(arg1, "add failed");
        require(arg1, "add failed");
        require(((0x021e19e0c9bab2400000 * arg1) / arg1) == 0x021e19e0c9bab2400000, "add failed");
        require(!(!stor_map_az[var_n]), "add failed");
        require((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) < 0x0de0b6b3a7640000, "add failed");
        var_n = stor_k;
        require(!(0x01 == (bytes1(stor_map_au[var_n]))), "add failed");
        var_n = stor_k;
        require(!(!(stor_map_az[var_n]) < stor_at), "add failed");
        var_n = stor_k;
        require(stor_map_au[var_n] == stor_map_au[var_n], "add failed");
        var_n = stor_k;
        stor_map_au[var_n] = stor_map_au[var_n];
        var_n = stor_k;
        require(0 == (stor_map_ba[var_n]), "add failed");
        stor_map_ba[var_n] = 0;
        require(arg1 < 0x016345785d8a0000, "add failed");
        stor_v = 0x01 + stor_v;
        var_a = 0x14 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20, "add failed");
        require(block.timestamp, "add failed");
        var_a = 0x14 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20, "add failed");
        require(block.timestamp, "add failed");
        require(!((block.difficulty + block.timestamp) < block.timestamp), "add failed");
        require(!((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp) < (block.difficulty + block.timestamp)), "add failed");
        require(!((block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))) < ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))), "add failed");
        require(!((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))) < (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp)))), "add failed");
        require(!((block.number + ((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))))) < ((keccak256(var_aj) / block.timestamp) + (block.gaslimit + ((keccak256(var_aj) / block.timestamp) + (block.difficulty + block.timestamp))))), "add failed");
        var_a = 0x20 + (0x20 + var_a);
        require(var_a.length < 0x20, "add failed");
        require(!(keccak256(var_aj) - (0x03e8 * (keccak256(var_aj) / 0x03e8)) < stor_v), "add failed");
        require(!(0x01 == 0x01), "add failed");
        var_n = stor_k;
        require(!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n])) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))), "add failed");
        var_n = stor_k;
        stor_map_bb[var_n] = (stor_map_aw[var_n]) + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]));
        if (!(stor_map_ax[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) {
        }
        if (arg1 < 0x8ac7230489e80000) {
            if (stor_y) {
                require(arg1 < 0x8ac7230489e80000, "mul failed");
                require(stor_y, "mul failed");
                require(stor_y, "mul failed");
                var_n = stor_map_au[var_n];
                require(((0x4b * stor_y) / stor_y) == 0x4b, "mul failed");
            }
        }
        if (0x64) {
        }
        if (arg1 < 0x0de0b6b3a7640000) {
            if (!arg1 < 0x8ac7230489e80000) {
                if (arg1 < 0x016345785d8a0000) {
                    if (!arg1 < 0x0de0b6b3a7640000) {
                        stor_v = 0;
                        var_n = stor_k;
                        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) {
                        }
                        if (stor_y) {
                            if (stor_y) {
                            }
                            if (0x64) {
                                var_n = stor_map_au[var_n];
                                if (!(0 + (stor_map_aw[var_n])) < (stor_map_aw[var_n])) {
                                }
                            }
                        }
                    }
                    if (arg1 < 0x016345785d8a0000) {
                        if (stor_y) {
                        }
                        stor_v = 0;
                        var_n = stor_k;
                        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) {
                        }
                    }
                }
                if (stor_y) {
                    if (stor_y) {
                    }
                    if (0x64) {
                        var_n = stor_map_au[var_n];
                        if (!(0 + (stor_map_aw[var_n])) < (stor_map_aw[var_n])) {
                        }
                    }
                }
            }
            if (arg1 < 0x0de0b6b3a7640000) {
                if (stor_y) {
                }
                if (arg1 < 0x016345785d8a0000) {
                }
            }
        }
        if (!0x01 == 0) {
            if (arg1 < 0x8ac7230489e80000) {
            }
            var_n = stor_k;
            if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) {
            }
        }
        if ((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
            if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
            }
            if (!(keccak256(var_aj) - (0x03e8 * (keccak256(var_aj) / 0x03e8))) < stor_v) {
            }
        }
        if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
        }
        if (block.timestamp) {
        }
        if (((var_a.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0) < 0x20) {
        }
        if (block.timestamp) {
        }
        var_n = stor_k;
        if (!(stor_map_aw[var_n] + ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) < ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]))) {
        }
        if (arg1 < 0x016345785d8a0000) {
        }
        var_n = stor_k;
        if (0 == (stor_map_ba[var_n])) {
        }
        var_n = stor_k;
        if (!block.timestamp > (stor_map_aw[var_n])) {
            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            var_n = stor_k;
            require(!(block.timestamp > (stor_map_aw[var_n])), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require((0x78 * ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000)) / ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) == 0x78, "mul failed");
        }
        if (!(stor_map_aw[var_n] + 0) < 0) {
        }
        if ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) {
            require(!(!((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require(!(!((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n])) / 0x0de0b6b3a7640000), "mul failed");
            require((0x78 * ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000)) / ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) / 0x0de0b6b3a7640000) == 0x78, "mul failed");
        }
        if (!(block.timestamp + 0) < 0) {
        }
        var_n = stor_k;
        if (stor_map_au[var_n]) {
        }
        if (!0x01 == (stor_map_au[var_n])) {
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
            }
            var_n = stor_k;
            if (stor_map_au[var_n] == stor_map_au[var_n]) {
            }
        }
        if (arg1 < 0x016345785d8a0000) {
        }
        if (stor_map_az[var_n]) {
        }
        if (arg1) {
        }
        var_a = var_a + 0x0100;
        var_n = stor_map_au[var_n];
        require(!(stor_map_bc[var_n]), "sub failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!((stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (0x0de0b6b3a7640000) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (!arg1 > (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])))) {
        }
        if (0x0de0b6b3a7640000) {
        }
        var_n = stor_map_au[var_n];
        if (!(stor_map_bk[var_n] + (stor_map_bb[var_n])) < (stor_map_bb[var_n])) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        var_n = stor_k;
        if (!block.timestamp > (stor_map_aw[var_n])) {
            if (block.timestamp > (stor_map_aw[var_n])) {
                var_n = stor_map_au[var_n];
                var_n = stor_map_bc[var_n];
                var_n = stor_map_au[var_n];
                var_n = stor_map_bc[var_n];
                if (!(stor_map_av[var_n]) > (stor_map_bd[var_n])) {
                }
                var_n = stor_k;
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
            }
            var_n = stor_k;
            if (!block.timestamp > (stor_map_aw[var_n])) {
                if (!block.timestamp > (stor_map_aw[var_n])) {
                }
                var_n = stor_k;
                if (stor_map_au[var_n]) {
                }
            }
        }
        if (stor_map_au[var_n]) {
        }
        var_n = stor_k;
        if (!stor_map_au[var_n]) {
            var_n = stor_k;
            if (!block.timestamp > (stor_map_av[var_n])) {
            }
            require(!(bytes1(stor_map_au[var_n])), "sub failed");
            var_n = stor_k;
            require(!(!bytes1(stor_map_au[var_n])), "sub failed");
        }
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!(stor_map_ax[var_n] < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        var_n = stor_map_au[var_n];
        require(!(stor_map_bk[var_n] + (stor_map_bb[var_n]) < (stor_map_bb[var_n])), "add failed");
        require(!(stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])) < (stor_map_bk[var_n] + (stor_map_bb[var_n]))), "add failed");
        require(!(stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])) > 0), "sub failed");
        stor_map_bb[var_n] = 0;
        stor_map_bk[var_n] = 0;
        stor_map_av[var_n] = 0;
        require(!(arg1 > (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])))), "sub failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n]))) - arg1;
        var_n = stor_k;
        if (stor_map_aw[var_n]) {
            if (!arg1 > 0x3b9aca00) {
                var_n = stor_k;
                if (stor_map_au[var_n]) {
                    var_n = stor_k;
                    if (arg1) {
                        if (arg1) {
                            if (((0x021e19e0c9bab2400000 * arg1) / arg1) == 0x021e19e0c9bab2400000) {
                                if (stor_map_az[var_n]) {
                                    if ((0x021e19e0c9bab2400000 * arg1) / (stor_map_az[var_n]) < 0x0de0b6b3a7640000) {
                                        var_n = stor_k;
                                        if (!0x01 == (stor_map_au[var_n])) {
                                            var_n = stor_k;
                                            if (stor_map_az[var_n] < stor_at) {
                                                var_n = stor_k;
                                                if (stor_map_au[var_n] == stor_map_au[var_n]) {
                                                    var_n = stor_k;
                                                    stor_map_au[var_n] = stor_map_au[var_n];
                                                    var_n = stor_k;
                                                    if (arg0 == (stor_map_ba[var_n])) {
                                                    }
                                                    var_n = stor_k;
                                                    if (arg0 == (stor_map_ba[var_n])) {
                                                    }
                                                }
                                                var_n = stor_k;
                                                if (!block.timestamp > (stor_map_aw[var_n])) {
                                                }
                                            }
                                            if (!0x01 == (stor_map_au[var_n])) {
                                                var_n = stor_k;
                                                if (!block.timestamp > (stor_map_aw[var_n])) {
                                                }
                                                var_n = stor_k;
                                                require(!(!stor_map_aw[var_n]), "mul failed");
                                            }
                                        }
                                    }
                                    require(!(arg1 > 0x3b9aca00), "mul failed");
                                    stor_v = 0x01 + stor_v;
                                    var_a = 0x14 + (0x20 + var_a);
                                    require(!(!bytes1(stor_map_au[var_n])), "mul failed");
                                    require(arg1, "mul failed");
                                }
                                require(arg1, "mul failed");
                            }
                        }
                        var_n = stor_k;
                        require(((0x021e19e0c9bab2400000 * arg1) / arg1) == 0x021e19e0c9bab2400000, "mul failed");
                    }
                }
            }
        }
        if (stor_map_az[var_n]) {
        }
        if (arg1) {
        }
        var_a = var_a + 0x0100;
        var_n = stor_map_au[var_n];
        require(!(stor_map_bc[var_n]), "sub failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        require(!(stor_map_av[var_n] > (stor_map_bd[var_n])), "sub failed");
        require(!(stor_map_bd[var_n] - (stor_map_av[var_n]) > 0), "mul failed");
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        require(!(stor_map_au[var_n] > 0), "mul failed");
        var_n = stor_map_bc[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        stor_map_av[var_n] = stor_map_bf[var_n];
        var_n = stor_map_au[var_n];
        var_n = stor_map_bc[var_n];
        var_n = stor_map_be[var_n];
        var_n = stor_map_bc[var_n];
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(!(!stor_map_bf[var_n]), "mul failed");
        require(stor_map_au[var_n] * (stor_map_bf[var_n]) / (stor_map_bf[var_n]) == stor_map_au[var_n], "mul failed");
        require(0x0de0b6b3a7640000, "add failed");
        var_n = stor_map_au[var_n];
        require(!((stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]) < (stor_map_ax[var_n])), "add failed");
        var_n = stor_map_au[var_n];
        stor_map_ax[var_n] = (stor_map_au[var_n] * (stor_map_bf[var_n]) / 0x0de0b6b3a7640000) + (stor_map_ax[var_n]);
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (0x0de0b6b3a7640000) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        stor_map_bc[var_n] = stor_k;
        if (!arg1 > 0x3b9aca00) {
        }
        if (!arg1 > (stor_map_bl[var_n] + (stor_map_bk[var_n] + (stor_map_bb[var_n])))) {
        }
        if (0x0de0b6b3a7640000) {
        }
        var_n = stor_map_au[var_n];
        if (!(stor_map_bk[var_n] + (stor_map_bb[var_n])) < (stor_map_bb[var_n])) {
        }
        if (!(stor_map_bd[var_n] - (stor_map_av[var_n])) > 0) {
        }
        if (!arg0 > 0x03) {
        }
        var_n = this.code[17785:17817]
        var_n = var_n;
        var_n = this.code[17721:17753]
        var_n = var_n;
    }
    
    /// @custom:selector    0xb81d3c0a
    /// @custom:name        Unresolved_b81d3c0a
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_b81d3c0a(bytes memory arg0) public view returns (bytes memory) {
        bytes memory var_b = arg0;
        return abi.encodePacked(address(stor_map_a[var_b]), stor_map_b[var_b], stor_map_c[var_b], stor_map_d[var_b], stor_map_e[var_b], stor_map_f[var_b], stor_map_g[var_b]);
    }
    
    /// @custom:selector    0xdcc617bd
    /// @custom:name        Unresolved_dcc617bd
    function Unresolved_dcc617bd() public view returns (uint256) {
        return stor_at;
    }
    
    /// @custom:selector    0xa071c7ac
    /// @custom:name        Unresolved_a071c7ac
    /// @param              arg0 ["address", "bytes", "bytes20", "bytes32", "int", "int160", "int256", "string", "uint", "uint160", "uint256"]
    function Unresolved_a071c7ac(address arg0) public view returns (bool) {
        address var_a = arg0;
        var_a = stor_map_l[var_a];
        if (!stor_map_bm[var_a]) {
            return 0x01;
            return 0;
        }
    }
    
    /// @custom:selector    0xc7e284b8
    /// @custom:name        Unresolved_c7e284b8
    function Unresolved_c7e284b8() public view returns (uint256) {
        var_a = stor_k;
        require(!(block.timestamp < (stor_map_m[var_a])), "sub failed");
        var_a = stor_k;
        require(!(block.timestamp > (stor_map_o[var_a])), "sub failed");
        var_a = stor_k;
        require(!(block.timestamp > (stor_map_o[var_a])), "sub failed");
        var_c = (stor_map_o[var_a]) - block.timestamp;
        return var_c;
        var_a = stor_k;
        if (!block.timestamp > (stor_map_m[var_a])) {
        }
        return 0;
    }
    
    /// @custom:selector    0xc2c46413
    /// @custom:name        Unresolved_c2c46413
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_c2c46413(bytes memory arg0, bytes memory arg1) public view returns (bytes memory) {
        bytes memory var_b = arg0;
        var_b = arg1;
        return abi.encodePacked(stor_map_a[var_b], stor_map_b[var_b], stor_map_c[var_b], stor_map_d[var_b], stor_map_e[var_b]);
    }
    
    /// @custom:selector    0x0d261c25
    /// @custom:name        Unresolved_0d261c25
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_0d261c25(bytes memory arg0, bytes memory arg1) public view returns (uint256) {
        bytes memory var_b = arg0;
        var_b = arg1;
        return stor_map_a[var_b];
    }
    
    /// @custom:selector    0x4b227176
    /// @custom:name        Unresolved_4b227176
    function Unresolved_4b227176() public view returns (uint256) {
        return stor_ap;
    }
    
    /// @custom:selector    0x76c008c9
    /// @custom:name        Unresolved_76c008c9
    /// @param              arg0 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    /// @param              arg1 ["bytes", "uint256", "int256", "string", "bytes32", "uint", "int"]
    function Unresolved_76c008c9(bytes memory arg0, bytes memory arg1) public view returns (bool) {
        bytes memory var_b = arg0;
        var_b = arg1;
        return !(!bytes1(stor_map_a[var_b]));
    }
    
    /// @custom:selector    0xd53b2679
    /// @custom:name        Unresolved_d53b2679
    function Unresolved_d53b2679() public view returns (bool) {
        return !(!bytes1(stor_aa));
    }
}
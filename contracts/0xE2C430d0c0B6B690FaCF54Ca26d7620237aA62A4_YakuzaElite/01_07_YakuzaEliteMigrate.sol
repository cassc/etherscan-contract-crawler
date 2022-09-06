// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Yakuza Inc - ELITE
 * ERC-721A Migration  with Token Locking.
 * S/O to owl of moistness for locking inspiration, @ChiruLabs for ERC721A.
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

interface ITempura {
    function startDripping(address addr, uint128 multiplier) external;

    function stopDripping(address addr, uint128 multiplier) external;
}

contract YakuzaElite is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 333;

    ITempura public Tempura;

    mapping(uint256 => uint256) public tierByToken;
    mapping(uint256 => bool) public lockStatus;
    mapping(uint256 => uint256) public lockData;

    bool public lockingAllowed;

    event Lock(uint256 token, uint256 timeStamp, address user);
    event Unlock(uint256 token, uint256 timeStamp, address user);

    /*
    ================================================
                    CONSTRUCTION        
    ================================================
*/

    constructor() ERC721A("Yakuza Elite", "YKELITE") {
        migrateTokens();
        initializeLock();
        initializeTiers();
        Tempura = ITempura(0xf52ae754AE9aaAC2f3A6C8730871d980389a424d);
        baseURI = "https://yakuza-api.vercel.app/api/";
    }

    /*
    ================================================
            Public/External Write Functions         
    ================================================
*/

    function lockTokens(uint256[] calldata tokenIds) external nonReentrant {
        require(lockingAllowed, "Locking is not currently allowed.");
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            _lockToken(tokenIds[i]);
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
        }
        Tempura.startDripping(msg.sender, value);
    }

    function unlockTokens(uint256[] calldata tokenIds) external {
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
            _unlockToken(tokenIds[i]);
        }
        Tempura.stopDripping(msg.sender, value);
    }

    /*
    ================================================
               ACCESS RESTRICTED FUNCTIONS        
    ================================================
*/

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setTier(uint256[] calldata tokenIds, uint128 tier) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            tierByToken[tokenIds[i]] = tier;
        }
    }

    function unlockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            uint128 value;
            if (tierByToken[tokens[i]] != 0) value += 20;
            else value += 10;
            Tempura.stopDripping(ownerOf(tokens[i]), value);
            _unlockToken(tokens[i]);
        }
    }

    function lockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            _lockToken(tokens[i]);
            uint128 value;
            if (tierByToken[tokens[i]] != 0) value += 20;
            else value += 10;
            Tempura.startDripping(ownerOf(tokens[i]), value);
        }
    }

    function setTempura(address tempura) external onlyOwner {
        Tempura = ITempura(tempura);
    }

    function toggleLocking() external onlyOwner {
        lockingAllowed = !lockingAllowed;
    }


    /*
    ================================================
                Migration/Initialization       
    ================================================
*/

    function initializeLock() internal {
        lockStatus[1] = true;
        lockStatus[5] = true;
        lockStatus[6] = true;
        lockStatus[7] = true;
        lockStatus[9] = true;
        lockStatus[10] = true;
        lockStatus[11] = true;
        lockStatus[12] = true;
        lockStatus[13] = true;
        lockStatus[15] = true;
        lockStatus[16] = true;
        lockStatus[17] = true;
        lockStatus[18] = true;
        lockStatus[19] = true;
        lockStatus[20] = true;
        lockStatus[21] = true;
        lockStatus[22] = true;
        lockStatus[23] = true;
        lockStatus[24] = true;
        lockStatus[25] = true;
        lockStatus[26] = true;
        lockStatus[27] = true;
        lockStatus[28] = true;
        lockStatus[29] = true;
        lockStatus[30] = true;
        lockStatus[31] = true;
        lockStatus[32] = true;
        lockStatus[33] = true;
        lockStatus[35] = true;
        lockStatus[36] = true;
        lockStatus[37] = true;
        lockStatus[38] = true;
        lockStatus[40] = true;
        lockStatus[41] = true;
        lockStatus[42] = true;
        lockStatus[43] = true;
        lockStatus[44] = true;
        lockStatus[46] = true;
        lockStatus[47] = true;
        lockStatus[48] = true;
        lockStatus[49] = true;
        lockStatus[50] = true;
        lockStatus[51] = true;
        lockStatus[52] = true;
        lockStatus[53] = true;
        lockStatus[54] = true;
        lockStatus[55] = true;
        lockStatus[56] = true;
        lockStatus[57] = true;
        lockStatus[58] = true;
        lockStatus[59] = true;
        lockStatus[60] = true;
        lockStatus[61] = true;
        lockStatus[62] = true;
        lockStatus[63] = true;
        lockStatus[64] = true;
        lockStatus[65] = true;
        lockStatus[66] = true;
        lockStatus[67] = true;
        lockStatus[68] = true;
        lockStatus[69] = true;
        lockStatus[70] = true;
        lockStatus[71] = true;
        lockStatus[72] = true;
        lockStatus[73] = true;
        lockStatus[74] = true;
        lockStatus[75] = true;
        lockStatus[77] = true;
        lockStatus[78] = true;
        lockStatus[79] = true;
        lockStatus[80] = true;
        lockStatus[81] = true;
        lockStatus[82] = true;
        lockStatus[83] = true;
        lockStatus[84] = true;
        lockStatus[86] = true;
        lockStatus[87] = true;
        lockStatus[88] = true;
        lockStatus[89] = true;
        lockStatus[90] = true;
        lockStatus[91] = true;
        lockStatus[92] = true;
        lockStatus[93] = true;
        lockStatus[94] = true;
        lockStatus[95] = true;
        lockStatus[96] = true;
        lockStatus[98] = true;
        lockStatus[100] = true;
        lockStatus[101] = true;
        lockStatus[103] = true;
        lockStatus[104] = true;
        lockStatus[105] = true;
        lockStatus[107] = true;
        lockStatus[109] = true;
        lockStatus[110] = true;
        lockStatus[111] = true;
        lockStatus[115] = true;
        lockStatus[117] = true;
        lockStatus[118] = true;
        lockStatus[119] = true;
        lockStatus[122] = true;
        lockStatus[123] = true;
        lockStatus[125] = true;
        lockStatus[126] = true;
        lockStatus[127] = true;
        lockStatus[128] = true;
        lockStatus[129] = true;
        lockStatus[130] = true;
        lockStatus[132] = true;
        lockStatus[133] = true;
        lockStatus[134] = true;
        lockStatus[135] = true;
        lockStatus[136] = true;
        lockStatus[137] = true;
        lockStatus[139] = true;
        lockStatus[140] = true;
        lockStatus[141] = true;
        lockStatus[142] = true;
        lockStatus[143] = true;
        lockStatus[144] = true;
        lockStatus[145] = true;
        lockStatus[147] = true;
        lockStatus[149] = true;
        lockStatus[150] = true;
        lockStatus[152] = true;
        lockStatus[153] = true;
        lockStatus[155] = true;
        lockStatus[157] = true;
        lockStatus[158] = true;
        lockStatus[159] = true;
        lockStatus[161] = true;
        lockStatus[165] = true;
        lockStatus[166] = true;
        lockStatus[168] = true;
        lockStatus[169] = true;
        lockStatus[170] = true;
        lockStatus[171] = true;
        lockStatus[173] = true;
        lockStatus[175] = true;
        lockStatus[177] = true;
        lockStatus[178] = true;
        lockStatus[181] = true;
        lockStatus[182] = true;
        lockStatus[183] = true;
        lockStatus[184] = true;
        lockStatus[185] = true;
        lockStatus[187] = true;
        lockStatus[190] = true;
        lockStatus[192] = true;
        lockStatus[193] = true;
        lockStatus[194] = true;
        lockStatus[195] = true;
        lockStatus[196] = true;
        lockStatus[197] = true;
        lockStatus[198] = true;
        lockStatus[200] = true;
        lockStatus[201] = true;
        lockStatus[203] = true;
        lockStatus[204] = true;
        lockStatus[205] = true;
        lockStatus[207] = true;
        lockStatus[208] = true;
        lockStatus[209] = true;
        lockStatus[211] = true;
        lockStatus[213] = true;
        lockStatus[215] = true;
        lockStatus[217] = true;
        lockStatus[218] = true;
        lockStatus[219] = true;
        lockStatus[220] = true;
        lockStatus[222] = true;
        lockStatus[226] = true;
        lockStatus[227] = true;
        lockStatus[228] = true;
        lockStatus[232] = true;
        lockStatus[233] = true;
        lockStatus[234] = true;
        lockStatus[236] = true;
        lockStatus[237] = true;
        lockStatus[238] = true;
        lockStatus[239] = true;
        lockStatus[240] = true;
        lockStatus[241] = true;
        lockStatus[242] = true;
        lockStatus[244] = true;
        lockStatus[246] = true;
        lockStatus[251] = true;
        lockStatus[252] = true;
        lockStatus[258] = true;
        lockStatus[259] = true;
        lockStatus[261] = true;
        lockStatus[262] = true;
        lockStatus[264] = true;
        lockStatus[266] = true;
        lockStatus[267] = true;
        lockStatus[268] = true;
        lockStatus[269] = true;
        lockStatus[273] = true;
        lockStatus[274] = true;
        lockStatus[276] = true;
        lockStatus[277] = true;
        lockStatus[278] = true;
        lockStatus[280] = true;
        lockStatus[281] = true;
        lockStatus[287] = true;
        lockStatus[289] = true;
        lockStatus[292] = true;
        lockStatus[294] = true;
        lockStatus[295] = true;
        lockStatus[297] = true;
        lockStatus[298] = true;
        lockStatus[299] = true;
        lockStatus[300] = true;
        lockStatus[301] = true;
        lockStatus[302] = true;
        lockStatus[303] = true;
        lockStatus[306] = true;
        lockStatus[307] = true;
    }

    function migrateTokens() internal {
        _mintERC2309(0x3B36Cb2c6826349eEC1F717417f47C06cB70b7Ea, 1);
        _mintERC2309(0xdF66301bb229dAFB491e68faF9b895b9CdFe5EBc, 1);
        _mintERC2309(0x76D75605C770d6B17eFE12C17C001626D371710a, 1);
        _mintERC2309(0x984b6d329d3aa1D6d5A14B134FB1Fb8BcC66D60C, 1);
        _mintERC2309(0xa724F5c322c6c281ABa5d49DcFD69dF1CE11511F, 1);
        _mintERC2309(0xc2445F027e5e3E0d9ED0EB9fFE20fbB5C580C847, 1);
        _mintERC2309(0xb8410f47e152E6ec0E7578f8e0D79d10FB90e09b, 1);
        _mintERC2309(0xc4a6d14d083ca6e6893EA0059195616FDd61F655, 1);
        _mintERC2309(0x2FF6B407D0baC20a27E80D6BAbe8a5149852f4BF, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x2520D890B24AA71E9200183a8B53Af87bB6eBeeE, 1);
        _mintERC2309(0x590f4faFe1966803c79a038c462C8F28B06668d8, 1);
        _mintERC2309(0x552e366f9D3c4f4C1f9F2bebC493715F866Fe9D9, 1);
        _mintERC2309(0x3c9A29649EBf0270a3214916A8A76e0844Cf8DB9, 1);
        _mintERC2309(0x02B004114503F5E75121EF528eac3C08f0D19305, 1);
        _mintERC2309(0x346affc5c5E7bF14Ebbc33530B6e0488Fb8b265e, 1);
        _mintERC2309(0xEeBa29bc63c008B39a432B17382d5441CBA5Fc31, 1);
        _mintERC2309(0x0A90B83884870046B73441AF03b76c35C1d21763, 1);
        _mintERC2309(0x87E974Eea31c0B5bed051bd7569dE8176b447e53, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x6249cd17AaEEF4CdD467785780c669b03b2ACf86, 1);
        _mintERC2309(0xc1692cD69493436b01cddcbE5FeDbC911746A7C1, 1);
        _mintERC2309(0xAcE7858A2514075f5Ab8dD7B947143C0A82a5813, 1);
        _mintERC2309(0x17ff38F48f36bd691B5322DDb68792000440fdd6, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0x2e24A856D65Be4319a883E0489f1CAFBB0F3c468, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x02F60fEF631AC1691fe3d38191b8E3430930d2f4, 1);
        _mintERC2309(0x5B85b432317bc8E16b4895555c2F822271400d6b, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x0064f54f2084758afA4E013B606A9fdD718Ec53c, 1);
        _mintERC2309(0xdac5B25AD77C0a726B95D6A448483cEdc5284fAB, 1);
        _mintERC2309(0x18A01e6c1159d606fcc3148A2b9836669611c0A0, 1);
        _mintERC2309(0xcED0ed8Cb5E884aE4e2A5E8aa9eCe1fD3404330e, 1);
        _mintERC2309(0xC502b4E8346524cD679FBbAdA962317c8f0e1291, 1);
        _mintERC2309(0x6d9ed472Da62B604eD479026185995889ae8f80e, 1);
        _mintERC2309(0x5587C8C50F189b79E93cCeFC62a00669A0D181dc, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0x011e2747F5E393E67CE0372cB9cfBd0B9a4C8F12, 1);
        _mintERC2309(0x2741C7A3159F2a01a19F53Cff8972a7812CF6418, 1);
        _mintERC2309(0xd6081A2823F9Ce4e78fB441a693F91f0bcbEd328, 1);
        _mintERC2309(0x87E974Eea31c0B5bed051bd7569dE8176b447e53, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xEeBa29bc63c008B39a432B17382d5441CBA5Fc31, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0x6249cd17AaEEF4CdD467785780c669b03b2ACf86, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x5587C8C50F189b79E93cCeFC62a00669A0D181dc, 1);
        _mintERC2309(0x0A90B83884870046B73441AF03b76c35C1d21763, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xb73c6dD54f3d1723d7d76Cf230175B9100c36915, 1);
        _mintERC2309(0x462eA027f18B85e550225E3A767cbc8c0833d973, 1);
        _mintERC2309(0xf52e3f7625B56A59F6CaA0aeAd91A1646C983bE8, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0xd71514E903F1E3cABa8b92f8B980a16F0A3a413d, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0xDbAAD435aC3a81858123b9b6ddFcd1851021e826, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xb73c6dD54f3d1723d7d76Cf230175B9100c36915, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xd71514E903F1E3cABa8b92f8B980a16F0A3a413d, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0xCdA87A974DA84D23920071B5d71cF8ad76AEDF9f, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0xDe308A5F7EAE545e5dc312A5bC4689Ae82CdD9eE, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0x68f0FAA81837D10aaF23974fa0CEb40220717f4e, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x49f7989010Fe2751d60b6f239b6C61a497227Aef, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x49f7989010Fe2751d60b6f239b6C61a497227Aef, 1);
        _mintERC2309(0xfE13A69994743AE68053CCC7A4d601d2B63c9318, 1);
        _mintERC2309(0x1790B08c57400Fe9b28Aa7c6C18272078cBEba25, 1);
        _mintERC2309(0x221AF81adDFaef129AD9a5e1aaE643fd00689b4E, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0x51EC173342aEfd977A9481Cf0Ff474195b63E0b0, 1);
        _mintERC2309(0xe5E689114D80aBFB955a06B7b27d3226b65De421, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x4349Ad665636d65CEb89e415dC0d250Cb7b1D693, 1);
        _mintERC2309(0x68f0FAA81837D10aaF23974fa0CEb40220717f4e, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x475205225dBf2A2E4115574DA89b8F806af418b8, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0x221AF81adDFaef129AD9a5e1aaE643fd00689b4E, 1);
        _mintERC2309(0x69012192E2886D311a2FA6b6e0C8ea153dcccB7B, 1);
        _mintERC2309(0x27889b0CaCC1705b0E61780B16DF21C81dDB03F8, 1);
        _mintERC2309(0x9997E502d002506541Dd05264d717d0D6aFbB673, 1);
        _mintERC2309(0xB573D55bB681b091cA01ef0E78D519ED26238C38, 1);
        _mintERC2309(0xce3A505702d1f374B9CB277c7aCc4396944Fd238, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x216222ec646E764dA7995Ed3c02848568072cb58, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0x2806cA13d7dA9a2EC03101D9dAa0A011E2b21c04, 2);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0xAC844941f038ff6493B1eec17D4ec775DeC210DD, 2);
        _mintERC2309(0xce3A505702d1f374B9CB277c7aCc4396944Fd238, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0x699a4Fbf7f094cff9e894a83b9a599B03b2723A1, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0x8A4565Fb0C2862f85265af4794ffBED4Cf3e441D, 1);
        _mintERC2309(0x18AaC583c5782F4A7494A304c5F721ce4F02B471, 1);
        _mintERC2309(0xf44324E28bB9ce5C2a8B843377E92cb7f4Fdf376, 1);
        _mintERC2309(0x42d6B53B205CC931a93b845ac3A58B99c88437eD, 1);
        _mintERC2309(0x76b2F8C6DA7BFFB5A63eA41f794481E5C7D81e44, 1);
        _mintERC2309(0xE10820407810935e2d321E0641Bf4DABeeD61E12, 1);
        _mintERC2309(0xa724F5c322c6c281ABa5d49DcFD69dF1CE11511F, 1);
        _mintERC2309(0xcaf0624d4Ab1b0B45Aeee977a6008832e5860C93, 1);
        _mintERC2309(0x7185538FC7FA1220C9FCB6758D4AB60238Eaac5b, 1);
        _mintERC2309(0x87ac0553e62Fc074BcBAF9D348cC12D41A4c041e, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x42d6B53B205CC931a93b845ac3A58B99c88437eD, 1);
        _mintERC2309(0x289C4dCB0B69BA183f0519C0D4191479327Cb06B, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0xc821eE063C0aBe2be67D0621b676C2Bcaa63cf4b, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x35fEC93300ce629707218950B88f071e2F2f437f, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0xc821eE063C0aBe2be67D0621b676C2Bcaa63cf4b, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0x62b4618af958aBF3a4F803dFED365FD37618095c, 1);
        _mintERC2309(0xE4DEa04fa6FA74f0d62D7e987738a83E606C92a1, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 1);
        _mintERC2309(0x023f5B749860964393ae1217BB5d9bB56fe5dF23, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 2);
        _mintERC2309(0x838450e58a9Ba982BB1866fcc2396Db8b307B9C9, 1);
        _mintERC2309(0xAA7c21fCe545fc47c80636127E408168e88c1a60, 1);
        _mintERC2309(0x896aE45164b0EB741074A1cDb3Df170f5ed8F664, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 2);
        _mintERC2309(0x00386637CF48eB0341B3fcFE80edab62b78C866e, 1);
        _mintERC2309(0x8Dd982D63183E42dE34CeE77079CCACAEbe8B14F, 1);
        _mintERC2309(0x00386637CF48eB0341B3fcFE80edab62b78C866e, 1);
        _mintERC2309(0xa7f879Eee9C76b4b7Cf7c067e3CBf43A5E28ef33, 1);
        _mintERC2309(0x023f5B749860964393ae1217BB5d9bB56fe5dF23, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0x2cC71CffB7eBeE2596e60b70088fa195397494b2, 1);
        _mintERC2309(0xD87ad6e7D350CE4D568AE7b04558B8b6041d1DA3, 1);
        _mintERC2309(0xa7f879Eee9C76b4b7Cf7c067e3CBf43A5E28ef33, 1);
        _mintERC2309(0x8830516fDA3821fc0e805E9A982B143E8792d5DC, 2);
        _mintERC2309(0xbe85F5aDf3aFfFEa08a2529Bf992Ee96525Cfd2f, 1);
        _mintERC2309(0x2cC71CffB7eBeE2596e60b70088fa195397494b2, 1);
        _mintERC2309(0x789d757EB17a56eC7fAbcFaaa13f48BdcA651C18, 1);
        _mintERC2309(0xcED0ed8Cb5E884aE4e2A5E8aa9eCe1fD3404330e, 1);
        _mintERC2309(0xA90e35c6BE67920AdaB21F1a207eB3A736E06649, 1);
        _mintERC2309(0x3181955d2646998f7150065E2A48823D78123928, 1);
        _mintERC2309(0x679eB39CC05CE43B9b813dF8abc4f66da896bcD6, 1);
        _mintERC2309(0x8CF6B98F59487ed43f64c7a94516dCA2f010ACC8, 1);
        _mintERC2309(0x4fa0e8318DFBb42233eCb5330661691fa802c458, 1);
        _mintERC2309(0x838450e58a9Ba982BB1866fcc2396Db8b307B9C9, 1);
        _mintERC2309(0x2b0A63c55F5926699Be551C968A1EA3B22B08691, 1);
        _mintERC2309(0x99b096CE65C4A273dfdE3E7F14d792C2F76BCc98, 1);
        _mintERC2309(0x042CFA58735B52790E3F25eDc99Aca32677b3b50, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x515d1a7b1982826D53194E03fbBAcDf392034b83, 2);
        _mintERC2309(0x71Ef3244fDac9168Ee3382aF5aD99dA09632649a, 1);
        _mintERC2309(0x515d1a7b1982826D53194E03fbBAcDf392034b83, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x4DBE8b56E3D2a481bbdC4cF4Be98Fc5cBb888FbF, 1);
        _mintERC2309(0x7ADEE4C1Ec5427519A0cb78E354828E6dA58e871, 1);
        _mintERC2309(0xbb1fF00e5Af0f3b81e2F464a329ae4EE7C1DfbA5, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 2);
        _mintERC2309(0xCDD094642F5fB2445f108758929770257C9DA8e6, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 3);
        _mintERC2309(0x0Cb2ECEfAb110966a117358abf5Dd3a635F9c3A1, 1);
        _mintERC2309(0x042CFA58735B52790E3F25eDc99Aca32677b3b50, 1);
        _mintERC2309(0x81134166c117ae6C8366C36BE9e886B0F7147faE, 1);
        _mintERC2309(0x1ff69103A094eFDc748A35ee0A6c193fF7f4728f, 1);
        _mintERC2309(0x1C96E40DA3eF76039D3cadD7892bF8209E5a8C99, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x67c4E74Eaa79b6F7114B56D17B5BEd2F60c69fB5, 1);
        _mintERC2309(0xCA0E051598cbE53057ed34AAAFC32a3310f4aEe7, 1);
        _mintERC2309(0x3076dD2c4f6797034Ffb11cedFca352b579b120E, 2);
        _mintERC2309(0x5bB4E468d79Dce3C878F76535BeC388CcBCc4031, 1);
        _mintERC2309(0x9eD81f00b587781D7ee4473A878a07560944427b, 1);
        _mintERC2309(0xc181f3828fE39bbE39e78354795a676304a825A3, 1);
        _mintERC2309(0xB1d3A4c1907AD74f35dBBb5F1478dD456a9d81dF, 1);
        _mintERC2309(0x76D75605C770d6B17eFE12C17C001626D371710a, 1);
        _mintERC2309(0x010298F5dDE499b371A86d6ce7ee454b68B62780, 1);
        _mintERC2309(0x52bE0A4F75DF6fD45770f5A6E71ac269185D48e0, 1);
        _mintERC2309(0x9e86cC88D072e1c0259ee96cFBc457fEFfCC1Fee, 1);
        _mintERC2309(0xb9fA7689bDfE2f3718f3b101af60936D6f993324, 2);
        _mintERC2309(0xa7b065AB08a41609b508aFCd87473cb22af3a08A, 2);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x9d79F12e677822C2d3F9745e422Cb1CdBc5A41AA, 1);
        _mintERC2309(0xbC9bB672d0732165535C49eD8bBa7c9e9BA988Cc, 1);
        _mintERC2309(0x8a1635C39C53DeEdf9fD8a1A28B0f0f4d2fF5a78, 1);
        _mintERC2309(0x826EC552A86b20302a3f01B6980b662Eb1Ba7a44, 1);
        _mintERC2309(0x58E6a5cD87d38Ae2C35007B1bD7b25026be9b0b1, 1);
        _mintERC2309(0x462eA027f18B85e550225E3A767cbc8c0833d973, 1);
        _mintERC2309(0x58E6a5cD87d38Ae2C35007B1bD7b25026be9b0b1, 1);
        _mintERC2309(0x8a1635C39C53DeEdf9fD8a1A28B0f0f4d2fF5a78, 1);
        _mintERC2309(0x187D8e97ffb6a92Ad0Ca25F80d97ada595513C88, 1);
        _mintERC2309(0xCa5334CE5a579C72413B58411F3E0Fb4CD4c345c, 1);
        _mintERC2309(0x95a00FFb2EaE9420287BF374F08dE040e7637D3A, 1);
        _mintERC2309(0x84Df49B1D4FdceE1e3B410669B7e5087412B411B, 1);
        _mintERC2309(0xb34b19f30D0E72c407ccF136aA6ac9E71B7B0684, 1);
        _mintERC2309(0x5f3fEa69BfC3fe51E9E43e3BE05dD5794AC50AB6, 1);
        _mintERC2309(0x865901C6bB1dD7842975f66E2B5Db494735F3655, 1);
        _mintERC2309(0x200cA9451C7d1fD027b3b04B1A08Bce257e21888, 2);
        _mintERC2309(0x408fdb9063b25542e95b171aE53046a6950E50Cd, 1);
        _mintERC2309(0x552e366f9D3c4f4C1f9F2bebC493715F866Fe9D9, 1);
        _mintERC2309(0x408fdb9063b25542e95b171aE53046a6950E50Cd, 1);
        _mintERC2309(0x6aE5bf41457D9f938F4f2588b9200f4390B23f9c, 1);
        _mintERC2309(0xB609d966A45ec87AfB84BF4a3F3DD29DE2deeD83, 1);
        _mintERC2309(0x413Cf568d0aA5aE64C9A0161b207e165Cb8D35C4, 1);
        _mintERC2309(0xB609d966A45ec87AfB84BF4a3F3DD29DE2deeD83, 1);
        _mintERC2309(0x289C4dCB0B69BA183f0519C0D4191479327Cb06B, 1);
        _mintERC2309(0x0C375dA33507197f318E0F92aCAc6f45B53f2629, 1);
        _mintERC2309(0xf932755165312e18b62484B9A23B517Cc07a7ba2, 1);
        _mintERC2309(0x6dBBa020D28DDEc7A8859Cc10F7641b7F8c11419, 1);
        _mintERC2309(0xFeEC85c46f99a9722636044D5EA0B5DFDD5C5CD7, 1);
        _mintERC2309(0xcaf0624d4Ab1b0B45Aeee977a6008832e5860C93, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x385fd77f7B5A1e67222c94304D342ff4752ce92c, 2);
        _mintERC2309(0x997708fe9e316F6E6b3Ef91a53374148795f0e5C, 2);
        _mintERC2309(0xfcF8a7B49539154CCf149Ca2FF4Fdf12E39A1DB7, 1);
        _mintERC2309(0xfAd606Fe2181966C8703C84125BfdAd2A541BE2b, 1);
        _mintERC2309(0x308a4Fa5D38Ff273eD2E4618f66bDD864a3dDA7E, 1);
        _mintERC2309(0x18AaC583c5782F4A7494A304c5F721ce4F02B471, 1);
        _mintERC2309(0x7e2aA3047eb37eBAeF3438A1becC0c1FdF14B383, 1);
        _mintERC2309(0x0CDD65d3e6e80dA2e5A11F7C1cEdaCE730372D7E, 1);
        _mintERC2309(0xAbb9190C87955BdabDfd3DF0D4E0D415ec18dfB1, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x8f5FBdc4a08d48cACC468B30b55705529944bC8c, 1);
        _mintERC2309(0xAA7c21fCe545fc47c80636127E408168e88c1a60, 1);
        _mintERC2309(0x67c4E74Eaa79b6F7114B56D17B5BEd2F60c69fB5, 2);
        _mintERC2309(0x9DE9b25139df40e04202E42e4F53e52c9Ef6e949, 1);
        _mintERC2309(0x3E0d3071DA4Fc3139E11cb92a49460748712051a, 1);
        _mintERC2309(0xbf2C8b554a1D227F41EAc0e6F50fe5700e9EAc8D, 2);
        _mintERC2309(0x6d557322D7a8f399d6dD61DA819592AcE36E556c, 1);
        _mintERC2309(0x590f4faFe1966803c79a038c462C8F28B06668d8, 1);
        _mintERC2309(0xfbcD2a7Fa20c267b8d9363098399BFD307c7748b, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 1);
        _mintERC2309(0x252aD4c147630634170971fE0BEe72FeaF7DfCb3, 1);
        _mintERC2309(0xe35932989927AF1Ce78F54af6578FD22dB3ce675, 1);
        _mintERC2309(0xe2B0cEb92Ee82D48d06c5c41bb307DCb367EA94A, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x6619032e9fb486d738CF6db6ba39F18e59C38B10, 1);
        _mintERC2309(0x62c912f6B8727Af47DC0bcB6862E5E4804b26f24, 1);
        _mintERC2309(0xb50260f2076D744A6a87d4Ba0102fA8770c08e34, 2);
        _mintERC2309(0xfcf7cF49aB34E43EFDeEaD51eEDc0f1D25E43cC5, 1);
        _mintERC2309(0xD0010f430E836137bCCB778C5e9886E0c58B4b6C, 1);
        _mintERC2309(0x8eb80a451c61116395CF7BDA5B641a4569A11e63, 1);
        _mintERC2309(0xB94664acC7c7750B92f028b1e7139e19BF4922e9, 1);
        _mintERC2309(0x340ee74B7257C6b11b7Bf47fD279558Ea9E143f8, 1);
        _mintERC2309(0x46acF7AaF70e7dFC2AAA4c176E05fBa9F5c0A009, 1);
        _mintERC2309(0x744e14680b3C9693442e8526e22E1d5F60101846, 1);
        _mintERC2309(0x5EAe85C3dc16032878a579a39C85Ad7eCa3e7dc5, 1);
        _mintERC2309(0xb8410f47e152E6ec0E7578f8e0D79d10FB90e09b, 1);
        _mintERC2309(0x6bade65A3C3CB9E81cF8316c76a799947bA87d32, 1);
        _mintERC2309(0x3CFd1a2CF9585AfB5c0B18C15b174BAAae58ac21, 1);
        _mintERC2309(0x99b096CE65C4A273dfdE3E7F14d792C2F76BCc98, 1);
        _mintERC2309(0x778c1694994C24D701accb42F48c1BD10d10EE4C, 1);
        _mintERC2309(0x85150706937Ec68194677131A1F1F94c3dD38664, 1);
        _mintERC2309(0x415bd9A5e2fDcB8310ceE3F785F25B5E4D4564E3, 2);
        _mintERC2309(0x216222ec646E764dA7995Ed3c02848568072cb58, 1);
        _mintERC2309(0x7B056DcF6551f96d54AC2040ae89f8b30e0D77cb, 1);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 2);
        _mintERC2309(0x7B056DcF6551f96d54AC2040ae89f8b30e0D77cb, 2);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 3);
        _mintERC2309(0x26349cC1373c1e8A834815e930aD05632C375B27, 1);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 22);
    }

    function initializeTiers() internal {
        tierByToken[1] = 2;
        tierByToken[3] = 2;
        tierByToken[4] = 2;
        tierByToken[5] = 1;
        tierByToken[6] = 1;
        tierByToken[7] = 1;
        tierByToken[9] = 1;
        tierByToken[10] = 1;
        tierByToken[11] = 2;
        tierByToken[13] = 1;
        tierByToken[17] = 1;
        tierByToken[20] = 1;
        tierByToken[21] = 1;
        tierByToken[22] = 1;
        tierByToken[25] = 1;
        tierByToken[26] = 1;
        tierByToken[27] = 1;
        tierByToken[28] = 1;
        tierByToken[29] = 1;
        tierByToken[31] = 1;
        tierByToken[32] = 1;
        tierByToken[33] = 1;
        tierByToken[35] = 1;
        tierByToken[37] = 1;
        tierByToken[39] = 1;
        tierByToken[40] = 1;
        tierByToken[41] = 1;
        tierByToken[42] = 1;
        tierByToken[43] = 1;
        tierByToken[44] = 1;
        tierByToken[48] = 1;
        tierByToken[49] = 1;
        tierByToken[50] = 1;
        tierByToken[51] = 1;
        tierByToken[52] = 1;
        tierByToken[53] = 1;
        tierByToken[55] = 1;
        tierByToken[56] = 1;
        tierByToken[57] = 1;
        tierByToken[58] = 1;
        tierByToken[59] = 1;
        tierByToken[60] = 1;
        tierByToken[61] = 1;
        tierByToken[62] = 1;
        tierByToken[63] = 1;
        tierByToken[64] = 1;
        tierByToken[65] = 1;
        tierByToken[66] = 1;
        tierByToken[67] = 1;
        tierByToken[68] = 1;
        tierByToken[70] = 1;
        tierByToken[72] = 1;
        tierByToken[74] = 1;
        tierByToken[75] = 1;
        tierByToken[79] = 1;
        tierByToken[81] = 1;
        tierByToken[82] = 1;
        tierByToken[83] = 1;
        tierByToken[84] = 2;
        tierByToken[85] = 2;
        tierByToken[86] = 1;
        tierByToken[87] = 2;
        tierByToken[90] = 1;
        tierByToken[91] = 1;
        tierByToken[92] = 1;
        tierByToken[94] = 1;
        tierByToken[96] = 1;
        tierByToken[97] = 1;
        tierByToken[98] = 2;
        tierByToken[99] = 1;
        tierByToken[100] = 1;
        tierByToken[101] = 1;
        tierByToken[103] = 1;
        tierByToken[105] = 1;
        tierByToken[107] = 1;
        tierByToken[109] = 1;
        tierByToken[110] = 2;
        tierByToken[111] = 1;
        tierByToken[112] = 1;
        tierByToken[113] = 1;
        tierByToken[115] = 1;
        tierByToken[116] = 1;
        tierByToken[117] = 1;
        tierByToken[118] = 1;
        tierByToken[120] = 1;
        tierByToken[122] = 1;
        tierByToken[124] = 1;
        tierByToken[125] = 1;
        tierByToken[126] = 1;
        tierByToken[128] = 1;
        tierByToken[130] = 1;
        tierByToken[132] = 1;
        tierByToken[136] = 2;
        tierByToken[140] = 2;
        tierByToken[143] = 1;
        tierByToken[146] = 1;
        tierByToken[149] = 1;
        tierByToken[150] = 1;
        tierByToken[151] = 1;
        tierByToken[153] = 1;
        tierByToken[154] = 2;
        tierByToken[155] = 1;
        tierByToken[156] = 1;
        tierByToken[157] = 2;
        tierByToken[159] = 1;
        tierByToken[161] = 1;
        tierByToken[162] = 1;
        tierByToken[164] = 1;
        tierByToken[167] = 1;
        tierByToken[168] = 1;
        tierByToken[169] = 1;
        tierByToken[174] = 1;
        tierByToken[175] = 1;
        tierByToken[177] = 1;
        tierByToken[179] = 2;
        tierByToken[180] = 1;
        tierByToken[181] = 1;
        tierByToken[182] = 1;
        tierByToken[183] = 1;
        tierByToken[184] = 1;
        tierByToken[188] = 1;
        tierByToken[193] = 2;
        tierByToken[194] = 1;
        tierByToken[195] = 1;
        tierByToken[196] = 1;
        tierByToken[197] = 1;
        tierByToken[198] = 1;
        tierByToken[199] = 1;
        tierByToken[205] = 1;
        tierByToken[207] = 1;
        tierByToken[210] = 1;
        tierByToken[211] = 2;
        tierByToken[214] = 1;
        tierByToken[217] = 1;
        tierByToken[219] = 1;
        tierByToken[222] = 1;
        tierByToken[224] = 1;
        tierByToken[226] = 2;
        tierByToken[228] = 2;
        tierByToken[231] = 1;
        tierByToken[232] = 1;
        tierByToken[237] = 1;
        tierByToken[238] = 1;
        tierByToken[241] = 1;
        tierByToken[244] = 1;
        tierByToken[248] = 1;
        tierByToken[250] = 2;
        tierByToken[252] = 1;
        tierByToken[257] = 1;
        tierByToken[266] = 1;
        tierByToken[267] = 1;
        tierByToken[270] = 1;
        tierByToken[271] = 1;
        tierByToken[277] = 1;
        tierByToken[284] = 2;
        tierByToken[300] = 2;
        tierByToken[331] = 2;
        tierByToken[332] = 2;
        tierByToken[333] = 2;
    }

    /*
    ================================================
                Internal Write Functions         
    ================================================
*/

    function _lockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == false, "token already locked");
        lockStatus[tokenId] = true;
        lockData[tokenId] = block.timestamp;
        emit Lock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _unlockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == true, "token not locked");
        lockStatus[tokenId] = false;
        lockData[tokenId] = 0;
        emit Unlock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        bool lock = false;
        for (uint256 i; i < quantity; i++) {
            if (lockStatus[startTokenId + i] == true) {
                lock = true;
            }
        }
        require(lock == false, "Token Locked");
    }

    /*
    ================================================
                    VIEW FUNCTIONS        
    ================================================
*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}
// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/ICodec.sol";

import "./lib/Ownable.sol";

/**
 * @title Manages a list supported dex
 * @author Padoriku
 */
abstract contract DexRegistry is Ownable, Initializable {
    event DexCodecUpdated(address dex, bytes4 selector, address codec);

    // supported swap functions
    // 0x3df02124 exchange(int128,int128,uint256,uint256)
    // 0xa6417ed6 exchange_underlying(int128,int128,uint256,uint256)
    // 0x44ee1986 exchange_underlying(int128,int128,uint256,uint256,address)
    // 0x38ed1739 swapExactTokensForTokens(uint256,uint256,address[],address,uint256)
    // 0xc04b8d59 exactInput((bytes,address,uint256,uint256,uint256))
    // 0xb0431182 clipperSwap(address,address,uint256,uint256)
    // 0xe449022e uniswapV3Swap(uint256,uint256,uint256[])
    // 0x2e95b6c8 unoswap(address,uint256,uint256,bytes32[])
    // 0x7c025200 swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)
    // 0xd0a3b665 fillOrderRFQ((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256)
    mapping(address => mapping(bytes4 => address)) public dexFunc2Codec;

    function initDexRegistry(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) internal onlyInitializing {
        _setDexCodecs(_dexList, _funcs, _codecs);
    }

    function setDexCodecs(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) external onlyOwner {
        _setDexCodecs(_dexList, _funcs, _codecs);
    }

    function _setDexCodecs(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) private {
        for (uint256 i = 0; i < _dexList.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_funcs[i])));
            _setDexCodec(_dexList[i], selector, _codecs[i]);
        }
    }

    function _setDexCodec(
        address _dex,
        bytes4 _selector,
        address _codec
    ) private {
        address codec = dexFunc2Codec[_dex][_selector];
        require(codec != _codec, "nop");
        dexFunc2Codec[_dex][_selector] = _codec;
        emit DexCodecUpdated(_dex, _selector, _codec);
    }

    function getCodec(address _dex, bytes4 _selector) internal view returns (ICodec) {
        require(dexFunc2Codec[_dex][_selector] != address(0), "unsupported dex");
        return ICodec(dexFunc2Codec[_dex][_selector]);
    }
}
// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Manages a list supported dex
 * @author Padoriku
 */
abstract contract DexRegistry is Ownable {
    event SupportedDexUpdated(address dex, bytes4 selector, bool enabled);

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
    mapping(address => mapping(bytes4 => bool)) public dexRegistry;

    constructor(address[] memory _supportedDexList, string[] memory _supportedFuncs) {
        for (uint256 i = 0; i < _supportedDexList.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_supportedFuncs[i])));
            _setSupportedDex(_supportedDexList[i], selector, true);
        }
    }

    function setSupportedDex(
        address _dex,
        bytes4 _selector,
        bool _enabled
    ) external onlyOwner {
        _setSupportedDex(_dex, _selector, _enabled);
        emit SupportedDexUpdated(_dex, _selector, _enabled);
    }

    function _setSupportedDex(
        address _dex,
        bytes4 _selector,
        bool _enabled
    ) private {
        bool enabled = dexRegistry[_dex][_selector];
        require(enabled != _enabled, "nop");
        dexRegistry[_dex][_selector] = _enabled;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/IOptiSwap.sol";

contract OptiSwap is Ownable, IOptiSwap {
    address public immutable override weth;

    mapping(address => address) getBridge;
    address[] public override bridgeFromTokens;

    DexInfo[] dexList;
    mapping(address => bool) public override getDexEnabled;

    constructor(address _weth) {
        weth = _weth;
    }

    function getBridgeToken(address _token) external view override returns (address bridgeToken) {
        bridgeToken = getBridge[_token];
        if (bridgeToken == address(0)) {
            bridgeToken = weth;
        }
    }

    function bridgeFromTokensLength() external view override returns (uint256) {
        return bridgeFromTokens.length;
    }

    function addBridgeToken(address _token, address _bridgeToken) public override onlyOwner {
        require(_token != weth, "OptiSwap: INVALID_TOKEN_WETH");
        require(_token != _bridgeToken, "OptiSwap: INVALID_BRIDGE_TOKEN_SAME");
        require(_bridgeToken != address(0), "OptiSwap: INVALID_BRIDGE_TOKEN_ZERO");
        require(_bridgeToken.code.length > 0, "OptiSwap: INVALID_BRIDGE_TOKEN");
        require(getBridge[_bridgeToken] != _token, "OptiSwap: INVALID_BRIDGE_LOOP");
        if (getBridge[_token] == address(0)) {
            bridgeFromTokens.push(_token);
        }
        getBridge[_token] = _bridgeToken;
    }

    function addBridgeTokenBulk(TokenBridge[] calldata _tokenBridgeList) external override onlyOwner {
        uint256 count = _tokenBridgeList.length;
        require(count > 0, "EMPTY_LIST");
        for (uint256 i = 0; i < count; i++) {
            addBridgeToken(_tokenBridgeList[i].token, _tokenBridgeList[i].bridgeToken);
        }
    }

    function addDex(address _dex, address _handler) public override onlyOwner {
        require(!getDexEnabled[_dex], "OptiSwap: DEX_ALREADY_ENABLED");
        dexList.push(DexInfo({dex: _dex, handler: _handler}));
        getDexEnabled[_dex] = true;
    }

    function addDexBulk(DexInfo[] calldata _dexList) external override onlyOwner {
        uint256 count = _dexList.length;
        require(count > 0, "EMPTY_LIST");
        for (uint256 i = 0; i < count; i++) {
            addDex(_dexList[i].dex, _dexList[i].handler);
        }
    }

    function indexOfDex(address _dex) public view override returns (uint256 index) {
        for (uint256 i = 0; i < dexList.length; i++) {
            if (dexList[i].dex == _dex) {
                return i;
            }
        }
        require(false, "OptiSwap: DEX_NOT_FOUND");
    }

    function removeDex(address _dex) external override onlyOwner {
        require(getDexEnabled[_dex], "OptiSwap: DEX_NOT_ENABLED");
        uint256 index = indexOfDex(_dex);
        DexInfo memory last = dexList[dexList.length - 1];
        dexList[index] = last;
        dexList.pop();
        delete getDexEnabled[_dex];
    }

    function dexListLength() external view override returns (uint256) {
        return dexList.length;
    }

    function getDexInfo(uint256 index) external view override returns (address dex, address handler) {
        dex = dexList[index].dex;
        handler = dexList[index].handler;
    }

    function getBestAmountOut(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view override returns (address pair, uint256 amountOut) {
        uint256 dexCount = dexList.length;
        for (uint256 dexIndex = 0; dexIndex < dexCount; dexIndex++) {
            DexInfo storage dexInfo = dexList[dexIndex];
            try IDexHandler(dexInfo.handler).getAmountOut(dexInfo.dex, _amountIn, _tokenIn, _tokenOut) returns (address dexPair, uint256 dexAmountOut) {
                if (dexPair == address(0)) {
                    continue;
                }
                if (dexAmountOut > amountOut) {
                    pair = dexPair;
                    amountOut = dexAmountOut;
                }
            } catch {
                continue;
            }
        }
    }
}
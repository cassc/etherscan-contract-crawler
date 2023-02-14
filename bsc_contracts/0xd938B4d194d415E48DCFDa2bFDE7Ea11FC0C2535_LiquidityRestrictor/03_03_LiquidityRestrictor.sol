// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract LiquidityRestrictor is Ownable {
    struct Parameters {
        bool bypass;
        mapping(address => bool) isInitializer;
        mapping(address => uint256) startedAt;
        mapping(address => bool) isLocalAgent;
    }
    mapping(address => Parameters) public parameters;
    mapping(address => bool) public isTrustedAgent;

    event SetBypass(address indexed token, bool bypassed);
    event SetInitializer(address indexed token, address indexed who, bool isInitializer);
    event SetLocalAgent(address indexed token, address indexed who, bool isLocalAgent);
    event SetTrustedAgent(address indexed who, bool isTrustedAgent);
    event Started(address indexed token, address indexed pair, uint256 timestamp);

    function setParameters(
        address token,
        address[] memory initializers,
        address[] memory localAgents
    ) external onlyOwner {
        setInitializers(token, initializers, true);
        setLocalAgents(token, localAgents, true);
    }

    function setBypass(address token, bool bypass) external onlyOwner {
        parameters[token].bypass = bypass;
        emit SetBypass(token, bypass);
    }

    function setInitializers(
        address token,
        address[] memory who,
        bool isInitializer
    ) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            parameters[token].isInitializer[who[i]] = isInitializer;
            emit SetInitializer(token, who[i], isInitializer);
        }
    }

    function setLocalAgents(
        address token,
        address[] memory who,
        bool isLocalAgent
    ) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            parameters[token].isLocalAgent[who[i]] = isLocalAgent;
            emit SetLocalAgent(token, who[i], isLocalAgent);
        }
    }

    function setTrustedAgents(address[] memory who, bool isTrustedAgent_) external onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            isTrustedAgent[who[i]] = isTrustedAgent_;
            emit SetTrustedAgent(who[i], isTrustedAgent_);
        }
    }

    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message) {
        if (!(isTrustedAgent[msg.sender] || parameters[token].isLocalAgent[msg.sender]))
            return (false, 'LR: not agent');
        return _assureLiquidityRestrictions(token, from, to);
    }

    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message)
    {
        return _assureLiquidityRestrictions(msg.sender, from, to);
    }

    function _assureLiquidityRestrictions(
        address token,
        address from,
        address to
    ) internal returns (bool allow, string memory message) {
        Parameters storage params = parameters[token];
        if (params.startedAt[to] > 0 || params.bypass || !checkPair(token, to)) return (true, '');
        if (!params.isInitializer[from]) return (false, 'LR: unauthorized');
        params.startedAt[to] = block.timestamp;
        emit Started(token, to, block.timestamp);
        return (true, 'start');
    }

    function checkPair(address token, address possiblyPair) public view returns (bool isPair) {
        try this._checkPair(token, possiblyPair) returns (bool value) {
            if (token == address(0)) return true;
            return value;
        } catch {
            return false;
        }
    }

    function _checkPair(address token, address possiblyPair) public view returns (bool isPair) {
        address token0 = IUniswapV2Pair(possiblyPair).token0();
        address token1 = IUniswapV2Pair(possiblyPair).token1();
        return token0 == token || token1 == token;
    }

    function seeRights(address token, address who)
        public
        view
        returns (
            bool isInitializer,
            bool isLocalAgent,
            bool isTrustedAgent_
        )
    {
        return (parameters[token].isInitializer[who], parameters[token].isLocalAgent[who], isTrustedAgent[who]);
    }

    function seeStart(address token, address pair) public view returns (uint256 startedAt) {
        return parameters[token].startedAt[pair];
    }
}
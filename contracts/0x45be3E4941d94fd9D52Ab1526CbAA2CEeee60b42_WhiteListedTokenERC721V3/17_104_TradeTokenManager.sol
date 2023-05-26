// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/ITokenManager.sol";
import "../roles/AdminRole.sol";
import "../tge/interfaces/IBEP20.sol";

contract TradeTokenManager is ITokenManager, AdminRole {

    struct TradeToken {
        string symbol;
        bool created;
        bool active;
    }

    /// @notice ERC20 Token address -> active boolean
    mapping(address => TradeToken) public tokens;

    modifier exist(address _token) {
        require(tokens[_token].created != false, "TradeTokenManager: Token is not added");
        _;
    }

    function addToken(address _erc20Token,string calldata _symbol, bool _active) onlyAdmin external {
        require(_erc20Token != address(0), "TradeTokenManager: Cannot be zero address");
        require(tokens[_erc20Token].created == false, "TradeTokenManager: Token already exist");
        require(IBEP20(_erc20Token).totalSupply() != 0, "TradeTokenManager: Token is not ERC20 standard");
        tokens[_erc20Token] = TradeToken({
            symbol: _symbol,
            created: true,
            active: _active
        });
    }

    function setToken(address _erc20Token, bool _active) onlyAdmin exist(_erc20Token) external override {
        tokens[_erc20Token].active = _active;
    }

    function removeToken(address _erc20Token) onlyAdmin exist(_erc20Token) external override {
        delete tokens[_erc20Token];
    }

    function supportToken(address _erc20Token) exist(_erc20Token) external view override returns (bool) {
        return tokens[_erc20Token].active;
    }
}
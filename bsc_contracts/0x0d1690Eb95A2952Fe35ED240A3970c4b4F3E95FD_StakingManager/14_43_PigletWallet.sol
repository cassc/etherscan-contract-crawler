// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/Denominations.sol";

import "./IPigletWallet.sol";

import "../oracle/IOracle.sol";

contract PigletWallet is Ownable, ReentrancyGuard, IPigletWallet {
    mapping(address => uint256) private _tokenBalances;
    address[] private _tokens;
    IOracle private _oracle;
    bool _initialized = false;

    constructor() {}

    function init(IOracle oracle) public override {
        require(_initialized == false, "Wallet already initialized");
        _transferOwnership(msg.sender);
        _oracle = oracle;
        _initialized = true;
    }

    receive() external payable {}

    function getBalanceInUSD() external view override returns (uint256) {
        uint256 usdBalance = _oracle.getNativeTokenPrice(address(this).balance);

        for (uint256 i = 0; i < _tokens.length; i++) {
            usdBalance += _getTokenUSDPrice(_tokens[i], _tokenBalances[_tokens[i]]);
        }

        return usdBalance;
    }

    function _getTokenUSDPrice(address token, uint256 balance) internal view returns (uint256) {
        try IOracle(_oracle).getTokenUSDPrice(token, balance) returns (uint256 price) {
            if (price > 0) return uint256(price);
        } catch {
            return 0;
        }
        return 0;
    }

    function maxTokenTypes() public pure override returns (uint256) {
        return 10;
    }

    function listTokens() public view override returns (TokenData[] memory) {
        TokenData[] memory list = new TokenData[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            list[i] = TokenData({ token: _tokens[i], balance: _tokenBalances[_tokens[i]] });
        }

        return list;
    }

    function _findTokenIndex(address token) internal view returns (uint256) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) return i;
        }
        return _tokens.length;
    }

    function registerDeposit(address token) external override onlyOwner {
        require(token != address(0), "invalid token");
        require(token != address(this), "cannot register self");
        require(token != address(msg.sender), "cannot register self");
        try IERC20(token).balanceOf(address(this)) returns (uint256 balance) {
            require(balance > 0, "Token must have a balance greater than 0");

            uint256 index = _findTokenIndex(token);
            if (index == _tokens.length) {
                _tokens.push(token);
            }
            require(index < _tokens.length);
            _tokens[index] = token;
            _tokenBalances[token] = balance;

            emit TokenTransfered(token, address(this), balance);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, address(this), "Unable to transfer");
            } else {
                emit TokenTransferError(token, address(this), string(reason));
            }
        }
    }

    function deposit(
        address token,
        address sender,
        uint256 amount
    ) external override onlyOwner returns (bool) {
        require(amount > 0, "Amount to invest has to be non-zero");
        require(listTokens().length < maxTokenTypes(), "Max different token types reached");
        try IERC20(token).transferFrom(sender, address(this), amount) returns (bool result) {
            assert(result == true);

            if (_tokenBalances[token] == 0) {
                _tokens.push(token);
            }
            _tokenBalances[token] += amount;

            emit TokenTransfered(token, address(this), amount);

            return true;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, sender, "Unable to transfer");
            } else {
                emit TokenTransferError(token, sender, string(reason));
            }
        }
        return false;
    }

    function destroy(address recipient) external override onlyOwner nonReentrant {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 balance = _tokenBalances[token];
            _withdrawToken(token, recipient, balance);
        }

        // Transfer ethers if any
        payable(recipient).transfer(address(this).balance);

        emit Destroyed(address(this));
    }

    function _withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) private {
        try IERC20(token).transfer(recipient, amount) returns (bool result) {
            assert(result == true);
            emit TokenTransfered(token, recipient, amount);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, recipient, "Unable to transfer, approving instead");
            } else {
                emit TokenTransferError(token, recipient, string(reason));
            }
            IERC20(token).approve(recipient, amount);
        }
    }
}
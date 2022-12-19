// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

abstract contract Dividends {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => mapping(address => uint256)) public _dividendPayments;
    mapping(uint256 => uint256) public _totalDividends;

    address public _paymentToken;
    
    function payDividends(
        uint256 id,
        uint256 amount
    ) public isExist(id) virtual {
        IERC20Upgradeable(_paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _totalDividends[id] += amount / tokenSupply(id);
        emit PayDividends(id, amount);
    }

    function withdrawDividends(
        uint256 id,
        uint256 coef,
        address payable recipient
    ) external isExist(id) virtual {
        uint256 dividendPayment = _dividendPayments[id][msg.sender];
        require(_totalDividends[id] >= dividendPayment + coef, 'Dividends: limits are exceeded');
        unchecked {
            _dividendPayments[id][msg.sender] += coef; 
        }
        _sendDividends(id, coef, recipient);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids
    ) internal virtual {
        uint256 length = ids.length;
        if (from != address(0)) {
            for (uint256 i = 0; i < length;) {
                _assignDividends(ids[i], payable(from));
                _assignDividends(ids[i], payable(to));
                unchecked {
                    i++;
                }
            }
        }
    } 
    
    function _assignDividends(
        uint256 id,
        address payable holder
    ) internal virtual {
        uint256 coef;
        uint256 dividendPayments = _dividendPayments[id][holder];
        unchecked {
            coef = _totalDividends[id] - dividendPayments;
        }
        _dividendPayments[id][holder] = _totalDividends[id];
        _sendDividends(id, coef, holder);
    }

    function _sendDividends(
        uint256 id,
        uint256 coef,
        address recipient
    ) internal virtual {
        uint256 dividendAmount = balanceOf(recipient, id) * coef;
        if (dividendAmount > 0) {
            IERC20Upgradeable(_paymentToken).safeTransfer(
                recipient,
                dividendAmount
            );
            emit WithdrawDividends(id, dividendAmount, recipient);
        }
    }

    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
    }

    function tokenSupply(uint256 id) public view virtual returns (uint256) {
    }

    function isExists(uint256 id) public view virtual returns (bool) {
    }

    function _setPaymentToken(address paymentToken) internal {
        _paymentToken = paymentToken;
    }

    modifier isExist(uint256 id) {
        require(isExists(id), 'Dividends: non-existent token');
        _;
    }

    event PayDividends(
        uint256 indexed id,
        uint256 value
    );

    event WithdrawDividends(
        uint256 indexed id,
        uint256 value,
        address recipient
    );

}
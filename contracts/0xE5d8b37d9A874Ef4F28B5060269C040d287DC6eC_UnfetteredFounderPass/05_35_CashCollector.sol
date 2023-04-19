// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../ext-contracts/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../util/Errors.sol";

abstract contract CashCollector {
    IERC20[] _paymentTokens;
    bool internal _locked;
    address public _accountOwner;

    constructor(address accountOwner, IERC20[] memory paymentTokens) {
        _setAccountOwner(accountOwner);
        for (uint i = 0; i < paymentTokens.length; i++)
            _addRemovePaymentToken(paymentTokens[i], false);
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function _setAccountOwner(address accountOwner) internal {
        if (accountOwner == address(0)) revert ZeroAddress();

        _accountOwner = accountOwner;
    }

    function _addRemovePaymentToken(IERC20 paymentToken, bool remove) internal {
        if (address(paymentToken) == address(0)) revert ZeroAddress();

        uint256 ind;
        for (uint i = 0; i < _paymentTokens.length; i++) {
            if (address(_paymentTokens[i]) == address(paymentToken)) {
                ind = i + 1;
                break;
            }
        }

        if (!remove && ind == 0) _paymentTokens.push(paymentToken);
        else if (remove && ind > 0) {
            if (ind < _paymentTokens.length)
                _paymentTokens[ind - 1] = _paymentTokens[
                    _paymentTokens.length - 1
                ];
            _paymentTokens.pop();
        }
    }

    function getPaymentTokens() public view returns (IERC20[] memory) {
        return _paymentTokens;
    }

    function _withdraw() internal virtual noReentrant onlyAccountOwner {
        if (_accountOwner == address(0)) revert ZeroAddress();

        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_accountOwner).call{value: balance}("");
        }

        uint256[] memory tokenBalances = new uint256[](_paymentTokens.length);
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            IERC20 paymentToken = _paymentTokens[i];
            balance = paymentToken.balanceOf(address(this));
            if (balance > 0) {
                paymentToken.transfer(_accountOwner, balance);
            }

            tokenBalances[i] = balance;
        }

        emit Withdrawn(_accountOwner, balance, _paymentTokens, tokenBalances);
    }

    event Withdrawn(
        address receiver,
        uint256 balance,
        IERC20[] paymentTokens,
        uint256[] tokenBalances
    );
    event Receive(address sender, uint256 amount);

    error NoReEntrancy();

    modifier onlyAccountOwner() {
        if (msg.sender != _accountOwner) revert Unauthorized();

        _;
    }
    modifier noReentrant() {
        if (_locked) revert NoReEntrancy();
        _locked = true;
        _;
        _locked = false;
    }
}
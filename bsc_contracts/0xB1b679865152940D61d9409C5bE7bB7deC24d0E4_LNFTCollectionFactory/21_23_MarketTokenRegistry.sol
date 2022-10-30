// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error TokenNotExist(address token);
error TokenExist(address token);

contract MarketTokenRegistry is Ownable {
    event TokenAdded(address token);
    event TokenRemoved(address token);

    mapping(address => bool) private _paymentTokens;

    // LUST address on BSC testnet
    // https://testnet.bscscan.com/address/0x9D8229cBf08B40B0Dd36bdD344d55495113f05f3
    address internal constant LUST =
        address(0x5FbDB2315678afecb367f032d93F642f64180aa3);

    // LWAP address on BSC testnet
    // https://testnet.bscscan.com/address/0x00460933FEA5cf36BeB3a0054ae5b4384E1C8b83
    address internal constant LWAP =
        address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    constructor() {
        _paymentTokens[LUST] = true;
        _paymentTokens[LWAP] = true;
    }

    function addPaymentToken(address token) external onlyOwner {
        if (!_isTokenPayment(token)) {
            _paymentTokens[token] = true;
            emit TokenAdded(token);
        } else {
            revert TokenExist(token);
        }
    }

    function removePaymentToken(address token) external onlyOwner {
        if (_isTokenPayment(token)) {
            _paymentTokens[token] = false;
            emit TokenRemoved(token);
        } else {
            revert TokenNotExist(token);
        }
    }

    function _isTokenPayment(address token) internal view returns (bool) {
        return _paymentTokens[token];
    }
}
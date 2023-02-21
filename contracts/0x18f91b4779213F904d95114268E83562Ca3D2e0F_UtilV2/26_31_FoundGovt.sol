// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./constants.sol";

  /*$$$$$   /$$$$$$  /$$    /$$ /$$$$$$$$ /$$$$$$$  /$$   /$$  /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
 /$$__  $$ /$$__  $$| $$   | $$| $$_____/| $$__  $$| $$$ | $$ /$$__  $$| $$$ | $$ /$$__  $$| $$_____/
| $$  \__/| $$  \ $$| $$   | $$| $$      | $$  \ $$| $$$$| $$| $$  \ $$| $$$$| $$| $$  \__/| $$
| $$ /$$$$| $$  | $$|  $$ / $$/| $$$$$   | $$$$$$$/| $$ $$ $$| $$$$$$$$| $$ $$ $$| $$      | $$$$$
| $$|_  $$| $$  | $$ \  $$ $$/ | $$__/   | $$__  $$| $$  $$$$| $$__  $$| $$  $$$$| $$      | $$__/
| $$  \ $$| $$  | $$  \  $$$/  | $$      | $$  \ $$| $$\  $$$| $$  | $$| $$\  $$$| $$    $$| $$
|  $$$$$$/|  $$$$$$/   \  $/   | $$$$$$$$| $$  | $$| $$ \  $$| $$  | $$| $$ \  $$|  $$$$$$/| $$$$$$$$
 \______/  \______/     \_/    |________/|__/  |__/|__/  \__/|__/  |__/|__/  \__/ \______/ |_______*/

contract Governed is Pausable, Ownable {
    IFoundFund private _proxy;
    bool private _proxyLocked;

    event SetProxy(
        IFoundFund indexed proxy,
        uint timestamp
    );

    event LockProxy(
        uint timestamp
    );

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function proxy() external view returns (IFoundFund) {
        return _proxy;
    }

    function proxyLocked() external view returns (bool) {
        return _proxyLocked;
    }

    function setProxy(IFoundFund proxy_) external onlyOwner {
        require(
            !_proxyLocked,
            "Proxy is locked"
        );

        _proxy = proxy_;

        emit SetProxy(
            proxy_,
            block.timestamp
        );
    }

    function lockProxy() external onlyOwner {
        require(
            !_proxyLocked,
            "Proxy is locked"
        );

        require(
            address(_proxy) != address(0),
            "Proxy is not set"
        );

        _proxyLocked = true;

        emit LockProxy(
            block.timestamp
        );
    }

    function payeeOf(uint fund) public view returns (address) {
        if (_isProxyActive(fund)) {
            return _proxy.payeeOf(fund);
        }

        return address(0);
    }

    function rewardOf(uint fund) public view returns (uint16) {
        if (!_isProxyActive(fund)) return 0;

        uint16 rate = _proxy.rewardOf(fund);
        if (rate > 10000) rate = 10000;

        return rate;
    }

    function _credit(address account, uint fund, uint note, uint amount) internal {
        if (_isProxyActive(fund)) {
            _proxy.credit(account, fund, note, amount);
        }
    }

    function _isProxyActive(uint fund) internal view returns (bool) {
        return address(_proxy) != address(0) && fund > 0 && _proxy.isActive(fund);
    }
}
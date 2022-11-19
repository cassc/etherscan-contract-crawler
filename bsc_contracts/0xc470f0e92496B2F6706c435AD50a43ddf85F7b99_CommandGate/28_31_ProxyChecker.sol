// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract ProxyChecker {
    modifier onlyEOA() {
        _onlyEOA(msg.sender);
        _;
    }

    function _onlyEOA(address sender_) internal view {
        _onlyEOA(sender_, _txOrigin());
    }

    function _onlyEOA(address msgSender_, address txOrigin_) internal view {
        require(
            !_isProxyCall(msgSender_, txOrigin_) && !_isProxy(msgSender_),
            "PROXY_CHECKER: PROXY_UNALLOWED"
        );
    }

    function _onlyProxy(address sender_) internal view {
        require(
            _isProxyCall(sender_, _txOrigin()) || _isProxy(sender_),
            "PROXY_CHECKER: EOA_UNALLOWED"
        );
    }

    function _onlyProxy(address msgSender_, address txOrigin_) internal view {
        require(
            _isProxyCall(msgSender_, txOrigin_) || _isProxy(msgSender_),
            "PROXY_CHECKER: EOA_UNALLOWED"
        );
    }

    function _isProxyCall(
        address msgSender_,
        address txOrigin_
    ) internal pure returns (bool) {
        return msgSender_ != txOrigin_;
    }

    function _isProxy(address caller_) internal view returns (bool) {
        return caller_.code.length != 0;
    }

    function _txOrigin() internal view returns (address) {
        return tx.origin;
    }
}
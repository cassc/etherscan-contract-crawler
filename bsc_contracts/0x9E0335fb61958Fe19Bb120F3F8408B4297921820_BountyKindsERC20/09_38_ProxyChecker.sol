// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Revert error if call is made from a proxy contract
 */
error ProxyChecker__EOAUnallowed();
/**
 * @dev Revert error if call is made from an externally owned account
 */
error ProxyChecker__ProxyUnallowed();

/**
 * @title ProxyChecker
 * @dev Abstract contract for checking if a call was made by a proxy contract or an externally owned account.
 */
abstract contract ProxyChecker {
    modifier onlyProxy() {
        _onlyProxy(msg.sender);
        _;
    }

    /**
     * @dev Modifier to allow a function to be called only by an externally owned account
     */
    modifier onlyEOA() {
        _onlyEOA(msg.sender);
        _;
    }

    /**
     * @dev Check if the sender is an externally owned account
     * @param sender_ Address of the sender
     */
    function _onlyEOA(address sender_) internal view {
        _onlyEOA(sender_, _txOrigin());
    }

    /**
     * @dev Check if the sender is an externally owned account
     * @param msgSender_ Address of the sender
     * @param txOrigin_ Origin of the transaction
     */
    function _onlyEOA(address msgSender_, address txOrigin_) internal pure {
        if (_isProxyCall(msgSender_, txOrigin_))
            revert ProxyChecker__ProxyUnallowed();
    }

    /**
     * @dev Check if the sender is a proxy contract
     * @param sender_ Address of the sender
     */
    function _onlyProxy(address sender_) internal view {
        if (!(_isProxyCall(sender_, _txOrigin()) || _isProxy(sender_)))
            revert ProxyChecker__EOAUnallowed();
    }

    /**
     * @dev Check if the sender is a proxy contract
     * @param msgSender_ Address of the sender
     * @param txOrigin_ Origin of the transaction
     */
    function _onlyProxy(address msgSender_, address txOrigin_) internal view {
        if (!(_isProxyCall(msgSender_, txOrigin_) || _isProxy(msgSender_)))
            revert ProxyChecker__EOAUnallowed();
    }

    /**
     * @dev Check if the call was made by a proxy contract
     * @param msgSender_ Address of the sender
     * @param txOrigin_ Origin of the transaction
     * @return True if the call was made by a proxy contract, false otherwise
     */
    function _isProxyCall(
        address msgSender_,
        address txOrigin_
    ) internal pure returns (bool) {
        return msgSender_ != txOrigin_;
    }

    /**
     * @dev Check if the caller is a proxy contract
     * @param caller_ Address of the caller
     * @return True if the caller is a proxy contract, false otherwise
     */
    function _isProxy(address caller_) internal view returns (bool) {
        return caller_.code.length != 0;
    }

    /**
     * @dev Returns the origin of the transaction
     * @return Origin of the transaction
     */
    function _txOrigin() internal view returns (address) {
        return tx.origin;
    }
}
// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IYieldImplementation.sol";

/**
 * @title YieldConnector
 */
contract YieldConnector {
    function _delegateInitialize(address _impl, address _token) internal {
        _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.initialize.selector, _token));
    }

    function _delegateExit(address _impl, address _token) internal {
        _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.exit.selector, _token));
    }

    function _delegateInvest(address _impl, address _token, uint256 _amount) internal {
        _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.invest.selector, _token, _amount));
    }

    function _delegateWithdraw(address _impl, address _token, uint256 _amount) internal {
        _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.withdraw.selector, _token, _amount));
    }

    function _delegateInvestedAmount(address _impl, address _token) internal returns (uint256) {
        bytes memory data =
            _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.investedAmount.selector, _token));
        return abi.decode(data, (uint256));
    }

    function _delegateFarmExtra(
        address _impl,
        address _token,
        address _to,
        bytes calldata _data
    )
        internal
        returns (bytes memory)
    {
        return _delegate(_impl, abi.encodeWithSelector(IYieldImplementation.farmExtra.selector, _token, _to, _data));
    }

    function _delegate(address _impl, bytes memory _data) private returns (bytes memory) {
        (bool status, bytes memory data) = _impl.delegatecall(_data);
        require(status, "YieldConnector: delegatecall failed");
        return data;
    }
}
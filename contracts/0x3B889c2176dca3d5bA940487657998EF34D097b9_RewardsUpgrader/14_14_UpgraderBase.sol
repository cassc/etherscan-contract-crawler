// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../dependencies/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../interface/external/IMulticall.sol";

abstract contract UpgraderBase is ProxyAdmin {
    // Note: `Multicall3` contract has same address for all chains
    address public constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

    function upgrade(TransparentUpgradeableProxy _proxy, address _implementation) public override onlyOwner {
        bytes[] memory calls = _calls();
        bytes[] memory beforeResults = _aggregate(_proxy, calls);

        _proxy.upgradeTo(_implementation);

        bytes[] memory afterResults = _aggregate(_proxy, calls);
        _checkResults(beforeResults, afterResults);
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy _proxy,
        address _implementation,
        bytes calldata _data
    ) public payable override onlyOwner {
        bytes[] memory calls = _calls();
        bytes[] memory beforeResults = _aggregate(_proxy, calls);

        TransparentUpgradeableProxy(payable(_proxy)).upgradeToAndCall{value: msg.value}(_implementation, _data);

        bytes[] memory afterResults = _aggregate(_proxy, calls);
        _checkResults(beforeResults, afterResults);
    }

    function _aggregate(
        TransparentUpgradeableProxy _proxy,
        bytes[] memory _callDatas
    ) internal returns (bytes[] memory results) {
        uint256 _length = _callDatas.length;
        IMulticall.Call[] memory calls = new IMulticall.Call[](_length);
        for (uint256 i; i < _length; i++) {
            calls[i].target = address(_proxy);
            calls[i].callData = _callDatas[i];
        }
        (, results) = IMulticall(MULTICALL3_ADDRESS).aggregate(calls);
    }

    function _calls() internal virtual returns (bytes[] memory calls);

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal virtual;

    function _checkStringResults(
        bytes[] memory _beforeResults,
        bytes[] memory _afterResults,
        uint256 _from,
        uint256 _to
    ) internal pure {
        for (uint256 i = _from; i <= _to; ++i) {
            string memory _before = abi.decode(_beforeResults[i], (string));
            string memory _after = abi.decode(_afterResults[i], (string));
            require(keccak256(bytes(_before)) == keccak256(bytes(_after)), "a-string-simple-field-failed");
        }
    }

    function _checkUint8Results(
        bytes[] memory _beforeResults,
        bytes[] memory _afterResults,
        uint8 _from,
        uint8 _to
    ) internal pure {
        for (uint256 i = _from; i <= _to; ++i) {
            uint256 _before = abi.decode(_beforeResults[i], (uint8));
            uint256 _after = abi.decode(_afterResults[i], (uint8));
            require(_before == _after, "an-uint8-simple-field-failed");
        }
    }

    function _checkUint256Results(
        bytes[] memory _beforeResults,
        bytes[] memory _afterResults,
        uint256 _from,
        uint256 _to
    ) internal pure {
        for (uint256 i = _from; i <= _to; ++i) {
            uint256 _before = abi.decode(_beforeResults[i], (uint256));
            uint256 _after = abi.decode(_afterResults[i], (uint256));
            require(_before == _after, "an-uint256-simple-field-failed");
        }
    }

    function _checkAddressResults(
        bytes[] memory _beforeResults,
        bytes[] memory _afterResults,
        uint256 _from,
        uint256 _to
    ) internal pure {
        for (uint256 i = _from; i <= _to; ++i) {
            address _before = abi.decode(_beforeResults[i], (address));
            address _after = abi.decode(_afterResults[i], (address));
            require(_before == _after, "an-address-simple-field-failed");
        }
    }

    function _checkBooleanResults(
        bytes[] memory _beforeResults,
        bytes[] memory _afterResults,
        uint256 _from,
        uint256 _to
    ) internal pure {
        for (uint256 i = _from; i <= _to; ++i) {
            bool _before = abi.decode(_beforeResults[i], (bool));
            bool _after = abi.decode(_afterResults[i], (bool));
            require(_before == _after, "an-address-simple-field-failed");
        }
    }
}
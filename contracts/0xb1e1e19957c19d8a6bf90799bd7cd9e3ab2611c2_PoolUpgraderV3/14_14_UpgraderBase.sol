// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "../dependencies/openzeppelin//proxy/transparent/TransparentUpgradeableProxy.sol";
import "../interfaces/external/IMulticall.sol";

error StorageValueIsNotEqual();

abstract contract UpgraderBase is ProxyAdmin {
    // Note: `Multicall3` contract has same address for all chains
    // solhint-disable-next-line const-name-snakecase
    address public constant multicall = 0xcA11bde05977b3631167028862bE2a173976CA11;

    /// @inheritdoc ProxyAdmin
    function upgrade(TransparentUpgradeableProxy proxy_, address implementation_) public override onlyOwner {
        bytes[] memory _callsList = _calls();
        bytes[] memory _beforeResults = _aggregate(proxy_, _callsList);

        proxy_.upgradeTo(implementation_);

        bytes[] memory _afterResults = _aggregate(proxy_, _callsList);
        _checkResults(_beforeResults, _afterResults);
    }

    /// @inheritdoc ProxyAdmin
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy_,
        address implementation_,
        bytes calldata data_
    ) public payable override onlyOwner {
        bytes[] memory _callsList = _calls();
        bytes[] memory _beforeResults = _aggregate(proxy_, _callsList);

        TransparentUpgradeableProxy(payable(proxy_)).upgradeToAndCall{value: msg.value}(implementation_, data_);

        bytes[] memory _afterResults = _aggregate(proxy_, _callsList);
        _checkResults(_beforeResults, _afterResults);
    }

    /**
     * @notice Execute storage check calls using `Multicall3` contract
     * @param proxy_ The proxy being upgraded is the target contract
     * @param callDatas_ The array of storage calls to check
     * @return _results The storage values
     */
    function _aggregate(
        TransparentUpgradeableProxy proxy_,
        bytes[] memory callDatas_
    ) private returns (bytes[] memory _results) {
        uint256 _length = callDatas_.length;
        IMulticall.Call[] memory _callsList = new IMulticall.Call[](_length);
        for (uint256 i; i < _length; ++i) {
            _callsList[i].target = address(proxy_);
            _callsList[i].callData = callDatas_[i];
        }
        (, _results) = IMulticall(multicall).aggregate(_callsList);
    }

    /**
     * @notice Return list of storage calls
     * @dev The values of those calls will be compared before and after upgrade to check storage integrity
     */
    function _calls() internal virtual returns (bytes[] memory _callsList);

    /**
     * @notice Compare values
     * @dev Throws if values are inconsistent
     */
    function _checkResults(bytes[] memory before_, bytes[] memory after_) private pure {
        uint256 _length = before_.length;
        for (uint256 i; i < _length; ++i) {
            if (keccak256(before_[i]) != keccak256(after_[i])) revert StorageValueIsNotEqual();
        }
    }
}
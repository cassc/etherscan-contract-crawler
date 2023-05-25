//SPDX-License-Identifier: GPL-3.0
// Creator: Metalist Labs
pragma solidity ^0.8.0;

import "./lib/ProxyOwnable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice 通用代理合约
/// @dev 升级约束：新版本合约只可以在上一版本合约的基础上增加数据，且声明顺序必须位于原有数据的后面。

contract UniversalProxy is Proxy, ProxyOwnable {
    using Address for address;

    /// @dev 实际业务实现的地址位置，采用这种方式，是为了不被被代理合约中本身的数据覆盖
    bytes32 private constant _IMPLEMENT_ADDRESS_POSITION = keccak256("Gaas.impl.address.84c2ce47");

    /// @dev 实际存储Owner的位置
    bytes32 private constant _OWNER_POSITION = keccak256("Gaas-Proxy.owner.7e2efd65");

    /// @dev 设置被代理的合约地址， 仅owner调用
    function setImplementAddress(address nft)public onlyProxyOwner {
        require(nft.isContract(), "ADDRESS SHOULD BE CONTRACT");

        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;
        assembly {
            sstore(position, nft)
        }
    }

    /// @dev 返回被代理的合约地址
    function getImplementAddress() public view returns (address) {
        return _implementation();
    }

    /// @dev 重载该函数，返回被代理的合约地址
    function _implementation() internal view virtual override returns (address) {
        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;
        address impl;

        assembly {
            impl := sload(position)
        }

        return impl;
    }

    /// @dev 存储owner
    function _storeProxyOwner(address _owner) internal override {
        bytes32 position = _OWNER_POSITION;

        assembly {
            sstore(position, _owner)
        }
    }

    /// @dev 读取owner
    function _loadProxyOwner() internal view override returns (address) {
        bytes32 position = _OWNER_POSITION;
        address _owner;

        assembly {
            _owner := sload(position)
        }

        return _owner;
    }

}
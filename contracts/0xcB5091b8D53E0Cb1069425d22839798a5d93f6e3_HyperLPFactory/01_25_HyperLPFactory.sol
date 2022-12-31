// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3TickSpacing} from "./interfaces/IUniswapV3TickSpacing.sol";
import {IHyperLPFactory, TYPES} from "./interfaces/IHyper.sol";
import {IHyperLPoolStorage} from "./interfaces/IHyperStorage.sol";
import {HyperLPFactoryStorage} from "./abstract/HyperLPFactoryStorage.sol";
import {EIP173Proxy} from "./vendor/proxy/EIP173Proxy.sol";
import {IEIP173Proxy} from "./interfaces/IEIP173Proxy.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableSetMap} from "./utils/EnumerableSetMap.sol";

contract HyperLPFactory is HyperLPFactoryStorage, IHyperLPFactory, Context {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSetMap for EnumerableSetMap.Bytes32ToAddressSetMap;

    constructor(address _uniswapV3Factory)
        HyperLPFactoryStorage(_uniswapV3Factory)
    {} // solhint-disable-line no-empty-blocks

    /// @notice createPool creates a new instance of a HyperLP token on a specified
    /// UniswapV3Pool. The msg.sender is the initial manager of the pool and will
    /// forever be associated with the HyperLP pool as it's `deployer`
    /// @param attributes The attributes of pool
    /// @return pool the address of the newly created HyperLP pool (proxy)
    function createPool(TYPES.HPoolAttributes calldata attributes)
        external
        override
        returns (address pool)
    {
        (address token0, address token1) =
            _getTokenOrder(attributes.tokenA, attributes.tokenB);
        pool = _createPool(
            token0,
            token1,
            attributes.uniFee,
            attributes.lowerTick,
            attributes.upperTick,
            attributes.manager,
            attributes.managerFee
        );
        _deployers.add(_msgSender());
        _trustedPools[pool] = true;
        bytes32 poolKey = _getPoolKey(token0, token1, attributes.uniFee);
        EnumerableSetMap.Bytes32ToAddressSetMap storage pools =
            _pools[_msgSender()];
        pools.set(poolKey, pool);
    }

    function _createPool(
        address token0,
        address token1,
        uint24 uniFee,
        int24 lowerTick,
        int24 upperTick,
        address manager,
        uint16 managerFee
    ) private returns (address pool) {
        pool = address(new EIP173Proxy(poolImplementation, address(this), ""));

        string memory name = "HyperPools Uniswap LP";
        try this.getTokenName(token0, token1) returns (string memory result) {
            name = result;
        } catch {} // solhint-disable-line no-empty-blocks

        address uniPool =
            IUniswapV3Factory(factory).getPool(token0, token1, uniFee);
        require(uniPool != address(0), "uniswap pool does not exist");
        require(
            _validateTickSpacing(uniPool, lowerTick, upperTick),
            "tickSpacing mismatch"
        );

        IHyperLPoolStorage(pool).initialize(
            name,
            "HyperLP",
            uniPool,
            managerFee,
            lowerTick,
            upperTick,
            manager
        );

        emit PoolCreated(uniPool, manager, pool);
    }

    function _getPoolKey(
        address token0,
        address token1,
        uint24 uniFee
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token1, uniFee));
    }

    function _validateTickSpacing(
        address uniPool,
        int24 lowerTick,
        int24 upperTick
    ) internal view returns (bool) {
        int24 spacing = IUniswapV3TickSpacing(uniPool).tickSpacing();
        return
            lowerTick < upperTick &&
            lowerTick % spacing == 0 &&
            upperTick % spacing == 0;
    }

    function getTokenName(address token0, address token1)
        external
        view
        returns (string memory)
    {
        string memory symbol0 = IERC20Metadata(token0).symbol();
        string memory symbol1 = IERC20Metadata(token1).symbol();

        return _append("HyperPools Uniswap ", symbol0, "/", symbol1, " LP");
    }

    function upgradePools(address[] memory pools) external onlyManager {
        for (uint256 i = 0; i < pools.length; i++) {
            IEIP173Proxy(pools[i]).upgradeTo(poolImplementation);
        }
    }

    function upgradePoolsAndCall(address[] memory pools, bytes[] calldata datas)
        external
        onlyManager
    {
        require(pools.length == datas.length, "mismatching array length");
        for (uint256 i = 0; i < pools.length; i++) {
            IEIP173Proxy(pools[i]).upgradeToAndCall(
                poolImplementation,
                datas[i]
            );
        }
    }

    function makePoolsImmutable(address[] memory pools) external onlyManager {
        for (uint256 i = 0; i < pools.length; i++) {
            IEIP173Proxy(pools[i]).transferProxyAdmin(address(0));
        }
    }

    /// @notice isPoolImmutable checks if a certain HyperLP pool is "immutable" i.e. that the
    /// proxyAdmin is the zero address and thus the underlying implementation cannot be upgraded
    /// @param pool address of the HyperLP pool
    /// @return bool signaling if pool is immutable (true) or not (false)
    function isPoolImmutable(address pool) external view returns (bool) {
        return address(0) == getProxyAdmin(pool);
    }

    /// @notice getHyperPools gets all the Hyper pools deployed by HyperPools's
    /// default deployer address (since anyone can deploy and manage HyperPools pools)
    /// @return list of HyperPools managed Hyper pool addresses
    function getHyperPools(TYPES.UPoolAttributes calldata attributes)
        external
        view
        returns (address[] memory)
    {
        return getPools(hyperpoolsDeployer, attributes);
    }

    /// @notice getDeployers fetches all addresses that have deployed a HyperLP pool
    /// @return deployers the list of deployer addresses
    function getDeployers() public view returns (address[] memory) {
        uint256 length = numDeployers();
        address[] memory deployers = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            deployers[i] = _getDeployer(i);
        }

        return deployers;
    }

    /// @notice getPools fetches all the HyperLP pool addresses deployed by `deployer`
    /// @param deployer address that has potentially deployed HyperLP pools
    /// @return pools the list of HyperLP pool addresses deployed by `deployer`
    function getPools(
        address deployer,
        TYPES.UPoolAttributes calldata attributes
    ) public view override returns (address[] memory) {
        (address token0, address token1) =
            _getTokenOrder(attributes.tokenA, attributes.tokenB);
        bytes32 poolKey = _getPoolKey(token0, token1, attributes.uniFee);
        uint256 length = numDeployerPools(deployer, attributes);
        address[] memory pools = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            pools[i] = _getPool(deployer, poolKey, i);
        }

        return pools;
    }

    /// @notice numPools counts the total number of HyperLP pools in existence
    /// @return result total number of HyperLP pools deployed
    function numPools(TYPES.UPoolAttributes calldata attributes)
        public
        view
        override
        returns (uint256 result)
    {
        address[] memory deployers = getDeployers();
        for (uint256 i = 0; i < deployers.length; i++) {
            result += numDeployerPools(deployers[i], attributes);
        }
    }

    /// @notice verifies is pool is trsuted
    /// @param pool address of HyperLP pool to verify
    /// @return true if trusted otherwise false
    function isTrustedPool(address pool) external view override returns (bool) {
        return _trustedPools[pool];
    }

    /// @notice numDeployers counts the total number of HyperLP pool deployer addresses
    /// @return total number of HyperLP pool deployer addresses
    function numDeployers() public view returns (uint256) {
        return _deployers.length();
    }

    /// @notice numPools counts the total number of HyperLP pools deployed by `deployer`
    /// @param deployer deployer address
    /// @return total number of HyperLP pools deployed by `deployer`
    function numDeployerPools(
        address deployer,
        TYPES.UPoolAttributes calldata attributes
    ) public view override returns (uint256) {
        (address token0, address token1) =
            _getTokenOrder(attributes.tokenA, attributes.tokenB);
        bytes32 poolKey = _getPoolKey(token0, token1, attributes.uniFee);
        return _pools[deployer].length(poolKey);
    }

    /// @notice getProxyAdmin gets the current address who controls the underlying implementation
    /// of a HyperLP pool.
    /// For most all pools either this contract address or the zero address will
    /// be the proxyAdmin. If the admin is the zero address the pool's implementation is naturally
    /// no longer upgradable (no one owns the zero address).
    /// @param pool address of the HyperLP pool
    /// @return address that controls the HyperLP implementation (has power to upgrade it)
    function getProxyAdmin(address pool) public view returns (address) {
        return IEIP173Proxy(pool).proxyAdmin();
    }

    function _getDeployer(uint256 index) internal view returns (address) {
        return _deployers.at(index);
    }

    function _getPool(
        address deployer,
        bytes32 poolKey,
        uint256 index
    ) internal view returns (address _pool) {
        _pool = address(
            uint160(uint256(_pools[deployer].get(poolKey).at(index)))
        );
    }

    function _getTokenOrder(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "same token");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "no address zero");
    }

    function _append(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
}
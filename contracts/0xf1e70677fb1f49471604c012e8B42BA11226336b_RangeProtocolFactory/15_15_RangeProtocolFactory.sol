//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3PoolImmutables} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
import {IRangeProtocolFactory} from "./interfaces/IRangeProtocolFactory.sol";
import {FactoryErrors} from "./errors/FactoryErrors.sol";

/**
 * @dev [email protected]
 * @notice RangeProtocolFactory deploys and upgrades proxies for Range Protocol vault contracts.
 * Owner can deploy and upgrade vault contracts.
 */
contract RangeProtocolFactory is IRangeProtocolFactory, Ownable {
    bytes4 public constant INIT_SELECTOR =
        bytes4(keccak256(bytes("initialize(address,int24,bytes)")));

    bytes4 public constant UPGRADE_SELECTOR = bytes4(keccak256(bytes("upgradeTo(address)")));

    /// @notice Uniswap v3 factory
    address public immutable factory;

    /// @notice all deployed vault instances
    address[] private _vaultsList;

    constructor(address _uniswapV3Factory) Ownable() {
        factory = _uniswapV3Factory;
    }

    // @notice createVault creates a ERC1967 proxy instance for the given implementation of vault contract
    // @param tokenA one of the tokens in the uniswap pair
    // @param tokenB the other token in the uniswap pair
    // @param fee fee tier of the uniswap pair
    // @param implementation address of the implementation
    // @param configData additional data associated with the specific implementation of vault
    function createVault(
        address tokenA,
        address tokenB,
        uint24 fee,
        address implementation,
        bytes memory data
    ) external override onlyOwner {
        address pool = IUniswapV3Factory(factory).getPool(tokenA, tokenB, fee);
        if (pool == address(0x0)) revert FactoryErrors.ZeroPoolAddress();
        address vault = _createVault(tokenA, tokenB, fee, pool, implementation, data);

        emit VaultCreated(pool, vault);
    }

    /**
     * @notice upgradeVaults it allows upgrading the implementation contracts for deployed vault proxies.
     * only owner of the factory contract can call it. Internally calls _upgradeVault.
     * @param _vaults list of vaults to upgrade
     * @param _impls new implementation contracts of corresponding vaults
     */
    function upgradeVaults(
        address[] calldata _vaults,
        address[] calldata _impls
    ) external override onlyOwner {
        if (_vaults.length != _impls.length) revert FactoryErrors.MismatchedVaultsAndImplsLength();

        for (uint256 i = 0; i < _vaults.length; i++) {
            _upgradeVault(_vaults[i], _impls[i]);
        }
    }

    /**
     * @notice upgradeVault it allows upgrading the implementation contract for deployed vault proxy.
     * only owner of the factory contract can call it. Internally calls _upgradeVault.
     * @param _vault a vault to upgrade
     * @param _impl new implementation contract of corresponding vault
     */
    function upgradeVault(address _vault, address _impl) public override onlyOwner {
        _upgradeVault(_vault, _impl);
    }

    /**
     * @notice returns the vaults addresses based on the provided indexes
     * @param startIdx the index in vaults to start retrieval from.
     * @param endIdx the index in vaults to end retrieval from.
     * @return vaultList list of fetched vault addresses
     */
    function getVaultAddresses(
        uint256 startIdx,
        uint256 endIdx
    ) external view returns (address[] memory vaultList) {
        vaultList = new address[](endIdx - startIdx + 1);
        for (uint256 i = startIdx; i <= endIdx; i++) {
            vaultList[i] = _vaultsList[i];
        }
    }

    /// @notice vaultCount counts the total number of vaults in existence
    /// @return total count of vaults
    function vaultCount() public view returns (uint256) {
        return _vaultsList.length;
    }

    /**
     * @dev Internal function to create vault proxy.
     */
    function _createVault(
        address tokenA,
        address tokenB,
        uint24 fee,
        address pool,
        address implementation,
        bytes memory data
    ) internal returns (address vault) {
        if (data.length == 0) revert FactoryErrors.NoVaultInitDataProvided();
        if (tokenA == tokenB) revert();
        address token0 = tokenA < tokenB ? tokenA : tokenB;
        if (token0 == address(0x0)) revert("token cannot be a zero address");

        int24 tickSpacing = IUniswapV3Factory(factory).feeAmountTickSpacing(fee);
        vault = address(
            new ERC1967Proxy(
                implementation,
                abi.encodeWithSelector(INIT_SELECTOR, pool, tickSpacing, data)
            )
        );
        _vaultsList.push(vault);
    }

    /**
     * @dev Internal function to upgrade a vault's implementation.
     */
    function _upgradeVault(address _vault, address _impl) internal {
        (bool success, ) = _vault.call(abi.encodeWithSelector(UPGRADE_SELECTOR, _impl));

        if (!success) revert FactoryErrors.VaultUpgradeFailed();
        emit VaultImplUpgraded(_vault, _impl);
    }
}
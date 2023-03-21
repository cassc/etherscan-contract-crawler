//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
import "./abstract/Ownable.sol";
import "./interfaces/IRangeProtocolFactory.sol";

/**
 * @dev [email protected]
 * @notice RangeProtocolFactory deploys and upgrades proxies for Range Protocol vault contracts.
 * Manager can deploy and upgrade vault contracts.
 */
contract RangeProtocolFactory is IRangeProtocolFactory, Ownable {
    bytes4 public constant INIT_SELECTOR =
        bytes4(keccak256(bytes("initialize(address,int24,bytes)")));

    bytes4 public constant UPGRADE_SELECTOR = bytes4(keccak256(bytes("upgradeTo(address)")));

    /// @notice Uniswap v3 factory
    address public immutable factory;

    /// @notice all deployed vault instances
    address[] public allVaults;
    // toke0, token1, fee -> RangeProtocol vault address
    mapping(address => mapping(address => mapping(uint24 => address))) public vaults;

    constructor(address _uniswapV3Factory) {
        factory = _uniswapV3Factory;
        _manager = msg.sender;
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
    ) external override onlyManager {
        address pool = IUniswapV3Factory(factory).getPool(tokenA, tokenB, fee);
        if (pool == address(0x0)) revert ZeroPoolAddress();
        address vault = _createVault(tokenA, tokenB, fee, pool, implementation, data);

        emit VaultCreated(pool, vault);
    }

    /**
     * @notice upgradeVaults it allows upgrading the implementation contracts for deployed vault proxies.
     * only manager of the factory contract can call it. Internally calls _upgradeVault.
     * @param _vaults list of vaults to upgrade
     * @param _impls new implementation contracts of corresponding vaults
     */
    function upgradeVaults(
        address[] calldata _vaults,
        address[] calldata _impls
    ) external override onlyManager {
        if (_vaults.length != _impls.length) revert MismatchedVaultsAndImplsLength();

        for (uint256 i = 0; i < _vaults.length; i++) {
            _upgradeVault(_vaults[i], _impls[i]);
        }
    }

    /**
     * @notice upgradeVault it allows upgrading the implementation contract for deployed vault proxy.
     * only manager of the factory contract can call it. Internally calls _upgradeVault.
     * @param _vault a vault to upgrade
     * @param _impl new implementation contract of corresponding vault
     */
    function upgradeVault(address _vault, address _impl) public override onlyManager {
        _upgradeVault(_vault, _impl);
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
        if (data.length == 0) revert NoVaultInitDataProvided();
        if (tokenA == tokenB) revert();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0x0)) revert();
        if (vaults[token0][token1][fee] != address(0)) revert VaultAlreadyExists();

        int24 tickSpacing = IUniswapV3Factory(factory).feeAmountTickSpacing(fee);
        vault = address(
            new ERC1967Proxy{salt: keccak256(abi.encodePacked(token0, token1, fee))}(
                implementation,
                abi.encodeWithSelector(INIT_SELECTOR, pool, tickSpacing, data)
            )
        );
        vaults[token0][token1][fee] = vault;
        vaults[token1][token0][fee] = vault;
        allVaults.push(vault);
    }

    /**
     * @dev Internal function to upgrade a vault's implementation.
     */
    function _upgradeVault(address _vault, address _impl) internal {
        (bool success, ) = _vault.call(abi.encodeWithSelector(UPGRADE_SELECTOR, _impl));

        if (!success) revert VaultUpgradeFailed();
        emit VaultImplUpgraded(_vault, _impl);
    }
}
// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import "src/vaults/ImpactVault128.sol";
import "src/interfaces/yearn/IYearnVault.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title SpiralsUSDCImpactVault
 * @author @douglasqian @Zuan0x
 * @notice Implementation of ImpactVault on USD coin (USDC) on Ethereum mainnet
 *   using Yearn Finance's USDC yVault. Wraps yvUSDC into wyvUSDC to track
 *   a non-rebasing yield asset.
 */

contract SpiralsUSDCImpactVault is ImpactVault128 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event DependenciesUpdated(address indexed yvUSDC, address indexed wyvUSDC);

    IYearnVault public c_yvUSDC;
    IERC4626Upgradeable public c_wyvUSDC;

    /**
     * Inititalize as ImpactVault.
     *   asset -> USDC
     *   yieldAsset -> wyvUSDC
     */
    function initialize(
        address _yvUSDC,
        address _wyvUSDC,
        address _impactVaultManager
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        // Ensures that `_owner` is set.
        setDependencies(_yvUSDC, _wyvUSDC);

        __ERC20_init("Green USD Coin", "gUSDC");
        __ImpactVault_init(
            getUSDC(),
            IERC20Upgradeable(_wyvUSDC),
            _impactVaultManager
        );
    }

    /**
     * @notice Sets dependencies on Yearn vault contracts.
     */
    function setDependencies(address _yvUSDC, address _wyvUSDC)
        public
        onlyOwner
    {
        c_yvUSDC = IYearnVault(_yvUSDC);
        c_wyvUSDC = IERC4626Upgradeable(_wyvUSDC);
        require(c_wyvUSDC.asset() == _yvUSDC, "NON_MATCHING_YVUSDC_ADDRESS");

        emit DependenciesUpdated(_yvUSDC, _wyvUSDC);
    }

    /**
     * @dev Deposit USDC into Yearn vault and receive yvUSDC. Returns the amount
     * of USDC associated with the deposit after Yearn fees are taken into account.
     */
    function _stake(uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        // slither-disable-next-line unused-return (SafeERC20)
        asset.approve(address(c_yvUSDC), _amount);
        uint256 yvUSDCReceived = c_yvUSDC.deposit(_amount, address(this));

        // Deposit yvUSDC for wyvUSDC (non-rebasing)
        // slither-disable-next-line unused-return (SafeERC20)
        c_yvUSDC.approve(address(c_wyvUSDC), yvUSDCReceived);
        uint256 wyvUSDCReceived = c_wyvUSDC.deposit(
            yvUSDCReceived,
            address(this)
        );
        return convertToAsset(wyvUSDCReceived);
    }

    /**
     * @dev Withdraws wyvUSDC into yvUSDC and then converts it to USDC to
     * transfer to receiver.
     */
    function _withdraw(address _receiver, uint256 _amount)
        internal
        virtual
        override
    {
        uint256 yvUSDCBefore = c_yvUSDC.balanceOf(address(this));
        c_wyvUSDC.withdraw(_amount, address(this), address(this));
        uint256 yvUSDCReceived = c_yvUSDC.balanceOf(address(this)) -
            yvUSDCBefore;

        // slither-disable-next-line unused-return
        c_yvUSDC.withdraw(yvUSDCReceived, _receiver);
    }

    /**
     * @dev USDC -> USD
     */
    function convertToUSD(uint256 _amountAsset)
        public
        view
        virtual
        override
        returns (uint256 usdAmount)
    {
        return _amountAsset;
    }

    /**
     * @dev wyvUSDC -> USDC (yvUSDC)
     */
    function convertToAsset(uint256 _amountYieldAsset)
        public
        view
        virtual
        override
        returns (uint256 amountAsset)
    {
        return c_wyvUSDC.convertToAssets(_amountYieldAsset);
    }

    /**
     * @dev USDC (yvUSDC) -> wyvUSDC
     */
    function convertToYieldAsset(uint256 _amountAsset)
        public
        view
        virtual
        override
        returns (uint256 amountYieldAsset)
    {
        return c_wyvUSDC.convertToShares(_amountAsset);
    }

    /**
     * @dev Returns the USDC contract.
     */
    function getUSDC() public view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(c_yvUSDC.token());
    }
}
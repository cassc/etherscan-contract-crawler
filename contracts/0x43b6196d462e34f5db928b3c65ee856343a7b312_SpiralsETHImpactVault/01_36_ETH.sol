// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import "src/interfaces/INativeTokenImpactVault128.sol";
import "src/interfaces/lido/ILido.sol";
import "src/interfaces/lido/IWstETH.sol";
import "src/interfaces/IWrappedEther.sol";
import "src/interfaces/IChainlinkEACAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title SpiralsETHImpactVault
 * @author @douglasqian @blackmarkt @DaoDeCyrus
 * @notice Implementation of the Spirals ImpactVault on the Lido liquid
 *   staking protocol. This vault accrues yield through holding wstETH.
 *   For now, unstaking on Ethereum isn't supported yet which means that
 *   Lido doesn't really officially support withdrawals. When the time
 *   comes, we will upgrade the proxy contract to include this functionality.
 *   For now, the only withdrawals supported are withdrawing wstETH.
 */
contract SpiralsETHImpactVault is INativeTokenImpactVault128 {
    using SafeERC20 for IERC20Upgradeable;

    event DependenciesUpdated(
        address indexed wETH,
        address indexed lido,
        address indexed wstETH,
        address chainlinkOracle
    );

    event Receive(address indexed sender, uint256 indexed amount);

    ILido public c_lido;
    IWstETH public c_wstETH;
    IWrappedEther public c_wETH;
    IChainlinkEACAggregator public c_ethPriceOracle;

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    /**
     * Inititalize as ImpactVault.
     *   asset -> wETH
     *   yieldAsset -> wstETH
     */
    function initialize(
        address _wrappedEthAddress,
        address _lidoAddress,
        address _wrappedStEthAddress,
        address _chainlinkEtherOracleAddress,
        address _impactVaultManagerAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        // Ensures that `_owner` is set.
        setDependencies(
            _wrappedEthAddress,
            _lidoAddress,
            _wrappedStEthAddress,
            _chainlinkEtherOracleAddress
        );

        __ERC20_init("Green Ether", "gETH");
        __ImpactVault_init(
            IERC20Upgradeable(_wrappedEthAddress),
            IERC20Upgradeable(_wrappedStEthAddress),
            _impactVaultManagerAddress
        );
    }

    /**
     * @notice Sets dependencies on contract (RP Deposit Pool contract addresses).
     */
    function setDependencies(
        address _wrappedEthAddress,
        address _lidoAddress,
        address _wrappedStEthAddress,
        address _chainlinkEtherOracleAddress
    ) public onlyOwner {
        c_wETH = IWrappedEther(_wrappedEthAddress);
        c_lido = ILido(_lidoAddress);
        c_wstETH = IWstETH(_wrappedStEthAddress);
        c_ethPriceOracle = IChainlinkEACAggregator(
            _chainlinkEtherOracleAddress
        );

        emit DependenciesUpdated(
            _wrappedEthAddress,
            _lidoAddress,
            _wrappedStEthAddress,
            _chainlinkEtherOracleAddress
        );
    }

    /**
     * DEPOSIT
     */

    /**
     * @notice Flow for wETH slightly different than default implementation
     *  because we have to unwrap into ether before staking.
     */
    function deposit(uint256 _amount, address _receiver)
        public
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        if (_amount == 0) {
            revert ZeroDeposit();
        }
        // Using SafeERC20Upgradeable
        // slither-disable-next-line unchecked-transfer
        asset.transferFrom(_msgSender(), address(this), _amount);
        c_wETH.withdraw(_amount); // wETH -> ETH, hits "receive" function

        uint256 amountToMint = _stake(_amount);
        _mint(_receiver, amountToMint);

        emit Deposit(_amount, amountToMint, _receiver);
    }

    /**
     * @dev Deposit ETH into Lido deposit and wrap into wstETH.
     * Returns the amount of ETH associated with this deposit after RocketPool
     * fees are taken into account.
     */
    function _stake(uint256 _amountETH)
        internal
        virtual
        override
        returns (uint256)
    {
        uint256 stEthReceived = c_lido.submit{value: _amountETH}(address(0)); // no referral code
        c_lido.approve(address(c_wstETH), stEthReceived);
        uint256 wstETHReceived = c_wstETH.wrap(stEthReceived);
        return convertToAsset(wstETHReceived);
    }

    /**
     * @notice Lido doesn't support ETH withdrawals yet so this function sends
     * stETH to the receiver. Use "withdrawYieldAsset" to withdraw wstETH instead.
     */
    function _withdraw(address _receiver, uint256 _amountETH)
        internal
        virtual
        override
    {
        uint256 stETHReceived = c_wstETH.unwrap(
            convertToYieldAsset(_amountETH)
        );
        // slither-disable-next-line unchecked-transfer (SafeERC20)
        c_lido.transfer(_receiver, stETHReceived);
    }

    /**
     * @dev Used to track pending withdrawals. Need a dummy implementation for
     * now to comply with INativeTokenImpactVault interface. Implement this
     * when unstaking from ETH is available & supported by Rocket Pool.
     */
    function withdrawals(address)
        public
        pure
        virtual
        override
        returns (uint256, uint256)
    {
        return (0, 0);
    }

    /**
     * @dev Used to claim a withdrawal that's ready. Need a dummy implementation
     * for now to comply with INativeTokenImpactVault interface. Implement
     * this when unstaking from ETH is available & supported by Rocket Pool.
     */
    function claim() external pure {
        revert NotYetImplemented();
    }

    /**
     * @notice Returns total asset value of vault. Overriden to accomodate ETH.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return
            address(this).balance +
            asset.balanceOf(address(this)) +
            convertToAsset(yieldAsset.balanceOf(address(this)));
    }

    /**
     * @dev Convert ETH to USD value by querying Chainlink oracle.
     * Note that Chainlink oracle returns answers in their own decimals, so
     * we need to scale it down before multiplying by the amount of ETH.
     */
    function convertToUSD(uint256 _amountETH)
        public
        view
        virtual
        override
        returns (uint256 usdAmount)
    {
        uint256 priceOfEth = uint256(c_ethPriceOracle.latestAnswer());
        return (priceOfEth * _amountETH) / 10**c_ethPriceOracle.decimals();
    }

    /**
     * @dev wstETH -> ETH (stETH)
     */
    function convertToAsset(uint256 _amountWstETH)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return c_wstETH.getStETHByWstETH(_amountWstETH);
    }

    /**
     * @dev ETH (stETH) -> wstETH
     */
    function convertToYieldAsset(uint256 _amountETH)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return c_wstETH.getWstETHByStETH(_amountETH);
    }
}
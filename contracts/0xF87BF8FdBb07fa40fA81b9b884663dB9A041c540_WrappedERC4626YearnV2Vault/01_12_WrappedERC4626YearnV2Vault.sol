pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20Metadata.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "PricePerTokenMixin.sol";

interface IYearnV2Vault is IERC20Metadata {
    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares, address receiver)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);
}

contract WrappedERC4626YearnV2Vault is ERC4626, PricePerTokenMixin {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IYearnV2Vault public vault;

    constructor(
        IYearnV2Vault _vault,
        string memory name,
        string memory symbol
    ) ERC4626(IERC20Metadata(_vault.token())) ERC20(name, symbol) {
        require(address(_vault) != address(0), "Zero address provided");
        vault = _vault;
        IERC20(asset()).safeIncreaseAllowance(
            address(_vault),
            type(uint256).max
        );
    }

	function totalAssets() public view virtual override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    /** 
	 @notice Function which returns how many contracts's shares the given amount of yearn shares
	 is representing at the moment
     @param yearnShares Amount of yearn shares
     @return shares Amount of shares
	 */
    function _convertYearnSharesToShares(uint256 yearnShares)
        internal
        view
        returns (uint256 shares)
    {
        shares = (yearnShares * (10**decimals())) / (10**vault.decimals());
    }

	/** 
	 Function which returns how many yearn shares the given amount of contract's shares
	 is representing at the moment

	 @param shares Amount of shares
	 */
    function _convertSharesToYearnShares(uint256 shares)
        internal
        view
        returns (uint256 yearnShares)
    {
        yearnShares = (shares * (10**vault.decimals())) / (10**decimals());
    }

	/** 
	 Converts amount of asset to shares using current Yearn price per share
	 @inheritdoc ERC4626
	 */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        return (assets * (10**decimals())) / vault.pricePerShare();
    }

	/** 
	 Converts amount of shares to amount of asset using current Yearn price per share
	 @inheritdoc ERC4626
	 */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        return (shares * vault.pricePerShare()) / (10**decimals());
    }

    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return type(uint256).max;
    }

	/** 
	 Process user deposit by depositing tokens to Yearn vault
	 @inheritdoc ERC4626
	 */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        IERC20 token = IERC20(asset());
        token.safeTransferFrom(caller, address(this), assets);
        uint256 yearnShares = vault.deposit(assets);
        shares = _convertYearnSharesToShares(yearnShares);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

	/** 
	 Process withdrawal by withdrawing tokens from Yearn vault
	 @inheritdoc ERC4626
	 */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override
	{
		_burn(owner, shares);
		assets = vault.withdraw(_convertSharesToYearnShares(shares), receiver);

		emit Withdraw(caller, receiver, owner, assets, shares);
	}
}
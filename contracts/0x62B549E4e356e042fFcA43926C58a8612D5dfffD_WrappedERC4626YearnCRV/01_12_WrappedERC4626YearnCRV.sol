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

interface ICurvePool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);
}

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

contract WrappedERC4626YearnCRV is ERC4626, PricePerTokenMixin {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint8 private immutable _decimals;

    IERC20 public immutable crv;
    IERC20 public immutable ycrv;
    IYearnV2Vault public immutable stycrv;
    ICurvePool public immutable curveYCRVpool;
    IChainlinkOracle public immutable crvPriceOracle;

    constructor(
        IERC20 _crv,
        IERC20 _ycrv,
        IYearnV2Vault _stycrv,
        ICurvePool _curveYCRVPool,
        IChainlinkOracle _crvPriceOracle,
        string memory name,
        string memory symbol
    ) ERC4626(IERC20Metadata(address(_crv))) ERC20(name, symbol) {
        require(address(_crv) != address(0), "Zero address provided");
        require(address(_ycrv) != address(0), "Zero address provided");
        require(address(_stycrv) != address(0), "Zero address provided");
        require(address(_curveYCRVPool) != address(0), "Zero address provided");

        crv = _crv;
        ycrv = _ycrv;
        stycrv = _stycrv;
        curveYCRVpool = _curveYCRVPool;
        crvPriceOracle = _crvPriceOracle;

        _decimals = stycrv.decimals();

        crv.safeIncreaseAllowance(address(curveYCRVpool), type(uint256).max);
        ycrv.safeIncreaseAllowance(address(curveYCRVpool), type(uint256).max);
        ycrv.safeIncreaseAllowance(address(stycrv), type(uint256).max);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    function convertToUSD(uint256 shares) public view returns (uint256) {
        return
            (convertToAssets(shares) *
                uint256(crvPriceOracle.latestAnswer()) *
                (10**decimals())) / (10**crvPriceOracle.decimals());
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
        return
            (curveYCRVpool.get_dy(0, 1, assets) * (10**decimals())) /
            stycrv.pricePerShare();
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
        return
            curveYCRVpool.get_dy(
                1,
                0,
                (shares * stycrv.pricePerShare()) / (10**decimals())
            );
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
        crv.safeTransferFrom(caller, address(this), assets);
        uint256 ycrvAmount = curveYCRVpool.exchange(
            0,
            1,
            assets,
            0,
            address(this)
        );
        shares = stycrv.deposit(ycrvAmount);

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
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        uint256 ycrvAmount = stycrv.withdraw(shares, address(this));
        _burn(owner, shares);
        if (ycrvAmount > 0)
            assets = curveYCRVpool.exchange(1, 0, ycrvAmount, 0, receiver);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
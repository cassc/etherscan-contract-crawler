//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./interfaces/ILibertiPriceFeed.sol";
import "./interfaces/ISanctionsList.sol";
import "./interfaces/IWeth9.sol";
import "./LibertiAggregationRouterV4.sol";

contract LibertiVault is
    LibertiAggregationRouterV4,
    Initializable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable
{
    using MathUpgradeable for uint256;

    IWeth9 public immutable weth; // Blockchain native currency wrapped token
    ILibertiPriceFeed public immutable priceFeed; // Chainlink price feed directory
    ISanctionsList internal constant SANCTIONS_LIST =
        ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

    IERC20Upgradeable public asset; // Any ERC20 token
    IERC20Upgradeable public other; // Usually a stablecoin

    // Vault of the target allocation coefficient, in basis point, to enforce consistent deposits
    // with the current vault's target allocation. The value of the target allocation can be set
    // during rebalancing.
    uint256 public invariant;

    uint256 private constant BASIS_POINT_MAX = 10_000;
    uint256 private constant INITIAL_SHARE = 1e18;
    uint256 public minDeposit;
    uint256 public maxDeposit;
    uint256 public entryFee;
    uint256 public exitFee;

    error InvariantError();
    error MaxFeeError();
    error SanctionedError();
    error MinDepositError();
    error MaxDepositError();
    error MaxRedeemError();
    error NonWrappedNativeError();
    error TransferError();
    error ZeroAddressError();
    error ZeroDepositError();
    error ZeroWithdrawError();

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Rebalance(bytes data, uint256 newInvariant, uint256 returnAmount);
    event Exit(address indexed sender, uint256 assets, uint256 stable, uint256 shares);
    event SetMinDeposit(uint256 indexed assets);
    event SetMaxDeposit(uint256 indexed assets);
    event SetEntryFee(uint256 indexed value);
    event SetExitFee(uint256 indexed value);

    constructor(address _delegatedPriceFeed, address _weth) {
        _disableInitializers();
        priceFeed = ILibertiPriceFeed(_delegatedPriceFeed);
        weth = IWeth9(_weth);
        maxDeposit = 0; // block deposit to implementation contract
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @notice Initialize the vault instance
    /// @dev Vault instance is an EIP-1167 minimal clone
    /// @dev The asset must be an ERC-20 supporting Metadata extension
    /// @dev The initialize function must not be callable on implementation contract
    /// @param _asset The underlying asset of the vault
    /// @param _name The name of the vault
    /// @param _symbol The symbol of the vault
    /// @param _other The other underlying asset of the vault
    /// @param _owner The wallet which can rebalance the vault
    /// @param _minDeposit The minimum amount of asset to deposit
    /// @param _maxDeposit The maximum amount of asset to deposit
    /// @param _entryFee The value in basis point of the entry fee
    /// @param _exitFee The value in basis point of the entry fee
    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _other,
        address _owner,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _entryFee,
        uint256 _exitFee
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Ownable_init(); //UNUSED: overriden by _transferOwnership below

        _transferOwnership(_owner);
        invariant = BASIS_POINT_MAX;
        if ((address(0) == _asset) || (address(0) == _other)) {
            revert ZeroAddressError();
        }
        asset = IERC20Upgradeable(_asset);
        other = IERC20Upgradeable(_other);
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
        if ((100 < _entryFee) || (100 < _exitFee)) {
            revert MaxFeeError(); // max fee: 100 bps (1 percent)
        }
        entryFee = _entryFee;
        exitFee = _exitFee;
    }

    /// @notice Rebalance the vault according to swap description from 1Inch API
    /// @param data The 1Inch calldata including the swap description
    /// @param newInvariant The target allocation of the vault in basis point of asset
    function rebalance(
        bytes calldata data,
        uint256 newInvariant
    ) external onlyOwner returns (uint256 returnAmount) {
        if (BASIS_POINT_MAX < newInvariant) {
            revert InvariantError();
        }
        invariant = newInvariant; // For subsequent deposits
        returnAmount = adminSwap(data, address(asset), address(other));
        emit Rebalance(data, newInvariant, returnAmount);
    }

    /// @notice A sanctioned address CANNOT deposit into the vault.
    function deposit(
        uint256 assets,
        address receiver,
        bytes calldata data
    ) external returns (uint256 shares) {
        uint256 nav = getNavInNumeraire(MathUpgradeable.Rounding.Up);
        SafeERC20Upgradeable.safeTransferFrom(asset, _msgSender(), address(this), assets);
        shares = _deposit(assets, receiver, data, nav);
        emit Deposit(_msgSender(), receiver, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner_,
        bytes calldata data
    ) external returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner_, data, false);
        emit Withdraw(_msgSender(), receiver, owner_, assets, shares);
    }

    /// @notice Transfer an amount of asset and an amount of stablecoin to the sender, relative to
    /// @notice their balance of shares and the total supply of the vault. Exit fees are captured
    /// @notice in the form of shares, and remaining shares are burned. The purpose of this function
    /// @notice is to let a shareholder to redeem their shares without relying on any external
    /// @notice service like 1inch.
    function exit() external returns (uint256 amountToken0, uint256 amountToken1) {
        uint256 shares = balanceOf(_msgSender());
        if (0 < shares) {
            if (_msgSender() != owner()) {
                uint256 exitFeeAmount = shares.mulDiv(
                    exitFee,
                    BASIS_POINT_MAX,
                    MathUpgradeable.Rounding.Down
                );
                _transfer(_msgSender(), owner(), exitFeeAmount);
                shares -= exitFeeAmount;
            }
            uint256 supply = totalSupply();
            _burn(_msgSender(), shares);
            uint256 totalToken0 = asset.balanceOf(address(this));
            if (0 < totalToken0) {
                amountToken0 = totalToken0.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
                SafeERC20Upgradeable.safeTransfer(asset, _msgSender(), amountToken0);
            }
            uint256 totalToken1 = other.balanceOf(address(this));
            if (0 < totalToken1) {
                amountToken1 = totalToken1.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
                SafeERC20Upgradeable.safeTransfer(other, _msgSender(), amountToken1);
            }
            emit Exit(_msgSender(), amountToken0, amountToken1, shares);
        }
    }

    /// @notice Given an amount of shares, returns the precise corresponding amount of stablecoin
    /// @notice after exit fee. The purpose of this function is to allow the dapp to get the
    /// @notice calldata from 1inch API that must be passed to the redeem() function.
    function sharesToToken1(uint256 shares) external view returns (uint256) {
        uint256 totalToken1 = other.balanceOf(address(this));
        uint256 supply = totalSupply();
        shares = MathUpgradeable.min(shares, supply);
        if (0 < totalToken1) {
            shares -= shares.mulDiv(exitFee, BASIS_POINT_MAX, MathUpgradeable.Rounding.Down);
            return totalToken1.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
        }
        return 0;
    }

    function convertToShares(uint256 assets) external view returns (uint256 shares) {
        if (0 == assets) {
            return 0;
        }
        uint256 supply = totalSupply();
        return
            (0 == supply)
                ? INITIAL_SHARE
                : assets.mulDiv(supply, totalAssets(), MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) external view returns (uint256 assets) {
        uint256 supply = totalSupply();
        if ((0 == shares) || (0 == supply)) {
            return 0;
        }
        return shares.mulDiv(totalAssets(), supply, MathUpgradeable.Rounding.Down);
    }

    /// @notice Configure the minimum amount of asset that can be deposited in a call to deposit()
    /// @notice function.
    function setMinDeposit(uint256 assets) external onlyOwner {
        minDeposit = assets;
        emit SetMinDeposit(assets);
    }

    /// @notice Configure the maximum amount of asset that can be deposited in a call to deposit()
    /// @notice function. This amount can be set to 0, effectively blocking any further deposit
    /// @notice into the vault.
    function setMaxDeposit(uint256 assets) external onlyOwner {
        maxDeposit = assets;
        emit SetMaxDeposit(assets);
    }

    function setEntryFee(uint256 value) external onlyOwner {
        if (100 < value) {
            revert MaxFeeError(); // max entry fee: 100 bps (1 percent)
        }
        entryFee = value;
        emit SetEntryFee(value);
    }

    function setExitFee(uint256 value) external onlyOwner {
        if (100 < value) {
            revert MaxFeeError(); // max exit fee: 100 bps (1 percent)
        }
        exitFee = value;
        emit SetExitFee(value);
    }

    /// @notice Allows the deposit of the blockchain's native currency into a vault. Wraps the
    /// @notice value of the deposit into the wrapped token before calling the base function.
    /// @notice A sanctioned address CANNOT deposit into the vault.
    /// @dev Calling the function on an non-native currency vault will revert. We use the same
    /// @dev factory for both native currency and ERC20 vaults to save ton deployment costs,
    /// @dev otherwise we would have to deploy a different factory to support the native currency
    /// @dev vaults.
    function depositEth(
        address receiver,
        bytes calldata data
    ) external payable returns (uint256 shares) {
        if (address(asset) != address(weth)) {
            revert NonWrappedNativeError();
        }
        uint256 nav = getNavInNumeraire(MathUpgradeable.Rounding.Up);
        weth.deposit{value: msg.value}();
        shares = _deposit(msg.value, receiver, data, nav);
        emit Deposit(_msgSender(), receiver, msg.value, shares);
    }

    /// @notice Allows the redeem of the blockchain's native currency from a vault. Unwraps the
    /// @notice wrapped token before transferring the value to the receiver.
    /// @dev Calling the function on an non-native currency vault will revert. We use the same
    /// @dev factory for both native currency and ERC20 vaults to save ton deployment costs,
    /// @dev otherwise we would have to deploy a different factory to support the native currency
    /// @dev vaults.
    function redeemEth(
        uint256 shares,
        address receiver,
        address _owner,
        bytes calldata data
    ) external returns (uint256 assets) {
        if (address(asset) != address(weth)) {
            revert NonWrappedNativeError();
        }
        assets = _redeem(shares, address(this), _owner, data, true);
        weth.withdraw(assets);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = payable(receiver).call{value: assets}("");
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        }
        emit Withdraw(_msgSender(), receiver, _owner, assets, shares);
    }

    function rescueEth() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert TransferError();
        }
    }

    /// @notice Returns the total value in USD of all asset and stablecoin owned by the vault.
    function getNavInNumeraire(MathUpgradeable.Rounding rounding) public view returns (uint256) {
        uint256 navToken0 = getValueInNumeraire(asset, asset.balanceOf(address(this)), rounding);
        uint256 navToken1 = getValueInNumeraire(other, other.balanceOf(address(this)), rounding);
        return navToken0 + navToken1;
    }

    /// @notice Given an amount of asset, returns the precise amount of asset that must be swapped
    /// @notice for stablecoin. The purpose of this function is to allow the dapp to get the
    /// @notice calldata from 1inch API that must be passed to the deposit() function.
    function assetsToToken1(uint256 assets) public view returns (uint256) {
        if (BASIS_POINT_MAX > invariant) {
            return assets - assets.mulDiv(invariant, BASIS_POINT_MAX);
        }
        return 0;
    }

    function totalAssets() public view returns (uint256) {
        uint256 navToken1 = getValueInNumeraire(
            other,
            other.balanceOf(address(this)),
            MathUpgradeable.Rounding.Down
        );
        return (asset.balanceOf(address(this)) +
            navToken1.mulDiv(
                10 ** IERC20Metadata(address(asset)).decimals(),
                priceFeed.getPrice(address(asset)),
                MathUpgradeable.Rounding.Down
            ));
    }

    /// @notice Sanctioned address CANNOT deposit or get shares of a vault when they
    /// @notice are in the OFAC sanctions list.
    function _beforeTokenTransfer(address, address to, uint256) internal view override {
        if (SANCTIONS_LIST.isSanctioned(to)) {
            revert SanctionedError();
        }
    }

    function _deposit(
        uint256 assets,
        address receiver,
        bytes calldata data,
        uint256 nav
    ) private returns (uint256 shares) {
        if (0 == assets) {
            revert ZeroDepositError();
        }
        if (SANCTIONS_LIST.isSanctioned(_msgSender())) {
            revert SanctionedError();
        }
        if (assets < minDeposit) {
            revert MinDepositError();
        }
        if (assets > maxDeposit) {
            revert MaxDepositError();
        }
        uint256 returnAmount = 0;
        uint256 swapAmount = 0;
        if (BASIS_POINT_MAX > invariant) {
            swapAmount = assetsToToken1(assets);
            returnAmount = userSwap(
                data,
                address(this),
                swapAmount,
                address(asset),
                address(other)
            );
        }
        uint256 supply = totalSupply();
        if (0 < supply) {
            uint256 valueToken0 = getValueInNumeraire(
                asset,
                assets - swapAmount,
                MathUpgradeable.Rounding.Down
            );
            uint256 valueToken1 = getValueInNumeraire(
                other,
                returnAmount,
                MathUpgradeable.Rounding.Down
            );
            shares = supply.mulDiv(
                valueToken0 + valueToken1, // Rounded down
                nav, // Rounded up
                MathUpgradeable.Rounding.Down
            );
        } else {
            shares = INITIAL_SHARE;
        }
        uint256 feeAmount = shares.mulDiv(entryFee, BASIS_POINT_MAX, MathUpgradeable.Rounding.Down);
        _mint(receiver, shares - feeAmount);
        _mint(owner(), feeAmount); // mint(feeTo)
    }

    function _redeem(
        uint256 shares,
        address receiver,
        address owner_,
        bytes calldata data,
        bool redeemEth_
    ) private returns (uint256 assets) {
        if (0 == shares) {
            revert ZeroWithdrawError();
        }
        if (shares > balanceOf(owner_)) {
            revert MaxRedeemError();
        }
        // This function will revert with MaxRedeemError() if supply == 0
        uint256 supply = totalSupply();
        if (_msgSender() != owner_) {
            _spendAllowance(owner_, _msgSender(), shares);
        }
        uint256 feeAmount = shares.mulDiv(exitFee, BASIS_POINT_MAX, MathUpgradeable.Rounding.Down);
        shares -= feeAmount;
        _transfer(owner_, owner(), feeAmount); // transfer(feeTo)
        _burn(owner_, shares);
        uint256 totalToken0 = asset.balanceOf(address(this));
        if (0 < totalToken0) {
            assets = totalToken0.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
            if (!redeemEth_) {
                SafeERC20Upgradeable.safeTransfer(asset, receiver, assets);
            }
        }
        uint256 totalToken1 = other.balanceOf(address(this));
        if (0 < totalToken1) {
            uint256 amount = totalToken1.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
            assets += userSwap(data, receiver, amount, address(other), address(asset));
        }
    }

    /// @notice Returns the value in USD for a given token and a given amount. The quote used in
    /// @notice the calculation of the value is fetched from a Chainlink price feed.
    function getValueInNumeraire(
        IERC20Upgradeable token,
        uint256 amount,
        MathUpgradeable.Rounding rounding
    ) private view returns (uint256) {
        uint256 tokenDecimals = 10 ** IERC20Metadata(address(token)).decimals();
        uint256 tokenPrice = priceFeed.getPrice(address(token));
        return tokenPrice.mulDiv(amount, tokenDecimals, rounding);
    }
}
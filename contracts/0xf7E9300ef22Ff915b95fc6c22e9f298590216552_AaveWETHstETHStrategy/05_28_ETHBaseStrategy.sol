// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "../oracle/IPriceOracleConsumer.sol";
import "../vault/IETHVault.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

import "./IETHStrategy.sol";

/// @title ETHBaseStrategy
/// @author Bank of Chain Protocol Inc
abstract contract ETHBaseStrategy is IETHStrategy, Initializable, AccessControlMixin, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StableMath for uint256;

    /// @param _outputCode The code of output,0:default path, Greater than 0:specify output path
    /// @param outputTokens The output tokens
    struct OutputInfo {
        uint256 outputCode;
        address[] outputTokens;
    }

    /// @inheritdoc IETHStrategy
    IETHVault public override vault;

    /// @notice The interface of PriceOracleConsumer contract
    IPriceOracleConsumer public priceOracleConsumer;

    /// @inheritdoc IETHStrategy
    uint16 public override protocol;

    /// @inheritdoc IETHStrategy
    string public override name;

    /// @notice The list of tokens wanted by this strategy
    address[] public wants;

    /// @inheritdoc IETHStrategy
    bool public override isWantRatioIgnorable;
    
    /// @dev Modifier that checks that msg.sender is the vault or not
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function _initialize(
        address _vault,
        uint16 _protocol,
        string memory _name,
        address[] memory _wants
    ) internal {
        protocol = _protocol;
        vault = IETHVault(_vault);

        priceOracleConsumer = IPriceOracleConsumer(vault.priceProvider());

        _initAccessControl(vault.accessControlProxy());

        name = _name;
        require(_wants.length > 0, "wants is required");
        wants = _wants;
    }

    /// @inheritdoc IETHStrategy
    function getVersion() external pure virtual override returns (string memory);


    /// @notice Sets the flag of `isWantRatioIgnorable` 
    /// @param _isWantRatioIgnorable "true" means that can ignore ratios given by wants info,
    ///    "false" is the opposite.
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external isVaultManager {
        bool _oldValue = isWantRatioIgnorable;
        isWantRatioIgnorable = _isWantRatioIgnorable;
        emit SetIsWantRatioIgnorable(_oldValue, _isWantRatioIgnorable);
    }

    /// @inheritdoc IETHStrategy
    function getWantsInfo()
        external
        view
        virtual
        override
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @inheritdoc IETHStrategy
    function getWants() external view override returns (address[] memory) {
        return wants;
    }

    // @notice Return the output path list of the strategy when withdraw.
    function getOutputsInfo() external view virtual returns (OutputInfo[] memory _outputsInfo);

    /// @inheritdoc IETHStrategy
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        );

    /// @inheritdoc IETHStrategy
    function estimatedTotalAssets() external view override returns (uint256 _assetsInETH) {
        (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        ) = getPositionDetail();
        if (_isETH) {
            _assetsInETH = _ethValue;
        } else {
            for (uint256 i = 0; i < _tokens.length; i++) {
                uint256 _amount = _amounts[i];
                if (_amount > 0) {
                    _assetsInETH += queryTokenValueInETH(_tokens[i], _amount);
                }
            }
        }
    }

    /// @inheritdoc IETHStrategy
    function get3rdPoolAssets() external view virtual override returns (uint256);

    /// @inheritdoc IETHStrategy
    function harvest() external virtual override returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts){
        vault.report(_rewardsTokens,_claimAmounts);
    }

    /// @inheritdoc IETHStrategy
    function borrow(address[] memory _assets, uint256[] memory _amounts)
        external
        payable
        override
        onlyVault
    {
        depositTo3rdPool(_assets, _amounts);

        emit Borrow(_assets, _amounts);
    }

    /// @inheritdoc IETHStrategy
    function repay(
        uint256 _repayShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) public virtual override onlyVault nonReentrant returns (address[] memory _assets, uint256[] memory _amounts) {
        require(_repayShares > 0 && _totalShares >= _repayShares, "cannot repay 0 shares");
        _assets = wants;
        uint256[] memory _balancesBefore = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _balancesBefore[i] = balanceOfToken(_assets[i]);
        }

        withdrawFrom3rdPool(_repayShares, _totalShares,_outputCode);
        _amounts = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _balanceAfter = balanceOfToken(_assets[i]);
            _amounts[i] =
                _balanceAfter -
                _balancesBefore[i] +
                (_balancesBefore[i] * _repayShares) /
                _totalShares;
        }

        transferTokensToTarget(address(vault), _assets, _amounts);

        emit Repay(_repayShares, _totalShares, _assets, _amounts);
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual;

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal virtual;

    /// @notice Return the token's balance Of this contract
    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        if (_tokenAddress == NativeToken.NATIVE_TOKEN) {
            return address(this).balance;
        }
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    /// @notice Return the investable amount of strategy in ETH
    function poolQuota() public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Return the value of token in ETH
    function queryTokenValueInETH(address _token, uint256 _amount)
        internal
        view
        returns (uint256 _valueInETH)
    {
        if (_token == NativeToken.NATIVE_TOKEN) {
            _valueInETH = _amount;
        } else {
            _valueInETH = priceOracleConsumer.valueInEth(_token, _amount);
        }
    }

    /// @notice Return the uint with decimal of one token
    function decimalUnitOfToken(address _token) internal view returns (uint256) {
        if (_token == NativeToken.NATIVE_TOKEN) {
            return 1e18;
        }
        return 10**IERC20MetadataUpgradeable(_token).decimals();
    }

    /// @notice Transfer `_assets` token from this contract to target address.
    /// @param _target The target address to receive token
    /// @param _assets the address list of token to transfer
    /// @param _amounts the amount list of token to transfer
    function transferTokensToTarget(
        address _target,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount > 0) {
                if (_assets[i] == NativeToken.NATIVE_TOKEN) {
                    payable(_target).transfer(_amount);
                } else {
                    IERC20Upgradeable(_assets[i]).safeTransfer(address(_target), _amount);
                }
            }
        }
    }
    
}
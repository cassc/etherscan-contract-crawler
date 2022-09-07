// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IHarvester.sol";
import "./../access-control/AccessControlMixin.sol";
import "./../library/BocRoles.sol";
import "../vault/IVault.sol";
import "./../strategy/IStrategy.sol";

contract Harvester is IHarvester, AccessControlMixin, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public profitReceiver;
    address public exchangeManager;
    /// rewards sell to token.
    address public sellTo;
    address public vaultAddress;

    function initialize(
        address _accessControlProxy,
        address _receiver,
        address _sellTo,
        address _vault
    ) external initializer {
        require(_receiver != address(0), "Must be a non-zero address");
        require(_vault != address(0), "Must be a non-zero address");
        require(_sellTo != address(0), "Must be a non-zero address");
        profitReceiver = _receiver;
        sellTo = _sellTo;
        vaultAddress = _vault;
        exchangeManager = IVault(_vault).exchangeManager();
        _initAccessControl(_accessControlProxy);
    }

    /// @notice Setting profit receive address. Only governance role can call.
    function setProfitReceiver(address _receiver) external override onlyRole(BocRoles.GOV_ROLE) {
        require(_receiver != address(0), "Must be a non-zero address");
        profitReceiver = _receiver;

        emit ReceiverChanged(profitReceiver);
    }
    
    function setSellTo(address _sellTo) external override isVaultManager {
        require(_sellTo != address(0), "Must be a non-zero address");
        sellTo = _sellTo;

        emit SellToChanged(sellTo);
    }

    /**
     * @dev Transfer token to governor. Intended for recovering tokens stuck in
     *      contract, i.e. mistaken sends.
     * @param _asset Address of the asset
     * @param _amount Amount of the asset to transfer
     */
    function transferToken(address _asset, uint256 _amount)
        external
        override
        onlyRole(BocRoles.GOV_ROLE)
    {
        IERC20Upgradeable(_asset).safeTransfer(IVault(vaultAddress).treasury(), _amount);
    }

    /**
     * @dev Multi strategies harvest and collect all rewards to this contarct
     * @param _strategies The strategy array in which each strategy will harvest
     * Requirements: only Keeper can call
     */
    function collect(address[] calldata _strategies) external override isKeeper {
        for (uint256 i = 0; i < _strategies.length; i++) {
            address _strategy = _strategies[i];
            IVault(vaultAddress).checkActiveStrategy(_strategy);
            IStrategy(_strategy).harvest();
        }
    }

    /**
     * @dev After collect all rewards,exchange from all reward tokens to 'sellTo' token(one stablecoin),
     * finally send stablecoin to receiver
     * @param _exchangeTokens The all info of exchange will be used when exchange
     * Requirements: only Keeper can call
     */
    function exchangeAndSend(IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens)
        external
        override
        isKeeper
    {
        address _sellToCopy = sellTo;
        for (uint256 i = 0; i < _exchangeTokens.length; i++) {
            IExchangeAggregator.ExchangeToken memory _exchangeToken = _exchangeTokens[i];
            require(_exchangeToken.toToken == _sellToCopy, "Rewards can only be sold as sellTo");
            _exchange(
                _exchangeToken.fromToken,
                _exchangeToken.toToken,
                _exchangeToken.fromAmount,
                _exchangeToken.exchangeParam
            );
        }
    }

    /**
     * @dev Exchange from all reward tokens to 'sellTo' token(one stablecoin)
     * @param _fromToken The token swap from
     * @param _toToken The token swap to
     * @param _amount The amount to swap
     * @param _exchangeParam The struct of ExchangeParam, see {ExchangeParam} struct
     * @return _exchangeAmount The real amount to exchange
     * Emits a {Exchange} event.
     */
    function _exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) internal returns (uint256 _exchangeAmount) {
        IExchangeAdapter.SwapDescription memory _swapDescription = IExchangeAdapter.SwapDescription({
            amount: _amount,
            srcToken: _fromToken,
            dstToken: _toToken,
            receiver: profitReceiver
        });
        IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, 0);
        IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, _amount);
        _exchangeAmount = IExchangeAggregator(exchangeManager).swap(
            _exchangeParam.platform,
            _exchangeParam.method,
            _exchangeParam.encodeExchangeArgs,
            _swapDescription
        );
        emit Exchange(_exchangeParam.platform, _fromToken, _amount, _toToken, _exchangeAmount);
    }
}
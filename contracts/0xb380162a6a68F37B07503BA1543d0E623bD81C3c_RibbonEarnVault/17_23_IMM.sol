// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMM {
    function ORACLE_DIFF_THRESH_PCT() external view returns (uint256);

    function USDC() external view returns (address);

    function RIBBON_EARN_USDC_VAULT() external view returns (address);

    function minProviderSwap() external view returns (uint256);

    function products(address _product)
        external
        view
        returns (
            uint32,
            uint32,
            address,
            address,
            address,
            bool
        );

    function pendingSettledAssetAmount(address _product)
        external
        view
        returns (uint256);

    function convertToUSDCAmount(address _product, uint256 _amount)
        external
        view
        returns (uint256);

    function convertToProductAmount(address _product, uint256 _amount)
        external
        view
        returns (uint256);

    function setMinProviderSwap(uint256 _minProviderSwap) external;

    function setProduct(
        address _product,
        uint32 _mmSpread,
        uint32 _providerSpread,
        address _issueAddress,
        address _redeemAddress,
        address _oracle,
        bool _isWhitelisted
    ) external;

    function swap(
        address _fromAsset,
        address _toAsset,
        uint256 _amount
    ) external;

    function settleTPlus0Transfer(address _asset) external;
}
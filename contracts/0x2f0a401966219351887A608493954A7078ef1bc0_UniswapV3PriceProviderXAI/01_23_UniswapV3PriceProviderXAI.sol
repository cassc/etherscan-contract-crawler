// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "../IERC20LikeV3.sol";
import "./UniswapV3PriceProviderV3.sol";

contract UniswapV3PriceProviderXAI is UniswapV3PriceProviderV3 {
    uint256 public constant VERSION = 0x584149; // XAI in hex

    address public immutable XAI_ADDRESS; // solhint-disable-line var-name-mixedcase

    /// @dev asset address that will be used to provide XAI price
    address public immutable XAI_VIRTUAL_ADDRESS; // solhint-disable-line var-name-mixedcase

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    /// @param _factory UniswapV3 factory contract
    /// @param _priceCalculationData see UniswapV3PriceProviderV3 constructor
    /// @param _xaiAddress address of XAI token
    /// @param _xaiVirtualAddress address of token that will be used instead of XAI, to provide a price
    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        IUniswapV3Factory _factory,
        PriceCalculationData memory _priceCalculationData,
        address _xaiAddress,
        address _xaiVirtualAddress
    ) UniswapV3PriceProviderV3(_priceProvidersRepository, _factory, _priceCalculationData) {
        bytes32 symbolHash = keccak256(abi.encodePacked(IERC20LikeV3(_xaiAddress).symbol()));

        if (symbolHash != keccak256(abi.encodePacked("XAI")) && symbolHash != keccak256(abi.encodePacked("X"))) {
            revert("Not a XAI");
        }

        // sanity check
        IERC20LikeV3(_xaiVirtualAddress).symbol();

        XAI_ADDRESS = _xaiAddress;
        XAI_VIRTUAL_ADDRESS = _xaiVirtualAddress;
    }

    /// @inheritdoc IPriceProvider
    /// @notice for XAI it requires also setup for virtual token (XAI_VIRTUAL_ADDRESS)
    function assetSupported(address _asset) external view override returns (bool) {
        if (_asset == XAI_ADDRESS) {
            return _assetPath[XAI_ADDRESS].length != 0 && _assetPath[XAI_VIRTUAL_ADDRESS].length != 0;
        } else {
            return _assetPath[_asset].length != 0 || _asset == quoteToken;
        }
    }

    /// @inheritdoc UniswapV3PriceProviderV3
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    /// in case `_asset` is XAI, it returns price for XAI_VIRTUAL_ADDRESS token
    function getPrice(address _asset) public view override returns (uint256 price) {
        if (_asset == XAI_ADDRESS) {
            return super.getPrice(XAI_VIRTUAL_ADDRESS);
        }

        return super.getPrice(_asset);
    }
}
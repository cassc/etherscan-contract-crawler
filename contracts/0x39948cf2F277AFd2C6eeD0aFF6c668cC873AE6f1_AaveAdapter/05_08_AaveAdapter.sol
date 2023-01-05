// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/external/IWETH.sol";
import "../interfaces/IAaveAdapter.sol";
import "../interfaces/external/aave/IAave.sol";

contract AaveAdapter is IAaveAdapter {
    using SafeERC20 for IERC20;

    PoolAddressesProvider internal immutable poolAddressesProvider;
    IWETH public immutable nativeToken;

    constructor(IWETH nativeToken_, PoolAddressesProvider poolAddressesProvider_) {
        nativeToken = nativeToken_;
        poolAddressesProvider = poolAddressesProvider_;
    }

    function doFlashLoan(address _token, uint256 amount_, bytes memory _data) external {
        AaveLendingPool _aaveLendingPool = AaveLendingPool(poolAddressesProvider.getLendingPool());
        IERC20(_token).approve(address(_aaveLendingPool), type(uint256).max);

        address[] memory _assets = new address[](1);
        _assets[0] = _token;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount_;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory _interestRateModes = new uint256[](1);
        _interestRateModes[0] = 0;

        _aaveLendingPool.flashLoan({
            receiverAddress: address(this),
            assets: _assets,
            amounts: _amounts,
            interestRateModes: _interestRateModes,
            onBehalfOf: address(this),
            params: _data,
            referralCode: 0
        });
    }

    receive() external payable {}
}
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "../../interfaces/IATokenV2.sol";
import "../../interfaces/IAaveLendingPoolV2.sol";

contract ATokenV2 is IATokenV2 {
    address public UNDERLYING_ASSET_ADDRESS;
}

contract LendingLogicAaveV2 is ILendingLogic {
    using SafeMath for uint128;

    IAaveLendingPoolV2 public lendingPool;
    uint16 public referralCode;
    address public tokenHolder;

    constructor(address _lendingPool, uint16 _referralCode, address _tokenHolder) {
        require(_lendingPool != address(0), "LENDING_POOL_INVALID");
        lendingPool = IAaveLendingPoolV2(_lendingPool);
        referralCode = _referralCode;
        tokenHolder = _tokenHolder;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        address underlying = ATokenV2(_token).UNDERLYING_ASSET_ADDRESS();
        return getAPRFromUnderlying(underlying);
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(_token);
        return reserveData.currentLiquidityRate.div(1000000000);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), _amount);

        // Deposit into Aave
        targets[2] = address(lendingPool);
        data[2] =  abi.encodeWithSelector(lendingPool.deposit.selector, _underlying, _amount, tokenHolder, referralCode);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        ATokenV2 wrapped = ATokenV2(_wrapped);

        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = address(lendingPool);
        data[0] = abi.encodeWithSelector(
            lendingPool.withdraw.selector,
            wrapped.UNDERLYING_ASSET_ADDRESS(),
            _amount,
            tokenHolder
        );

        return(targets, data);
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }

}
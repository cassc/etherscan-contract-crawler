// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract FeeComp is Initializable {
    address public FEE_RECEIVER;
    uint256 public FEE_FRACTION;

    function __FeeComp_init(
        address feeReceiver,
        uint256 feeFraction
    ) public initializer {
        _setFee(feeReceiver, feeFraction);
    }

    function _setFee(address feeReceiver, uint256 feeFraction) internal {
        FEE_RECEIVER = feeReceiver;
        FEE_FRACTION = feeFraction;
    }

    function _getFeeAmount(uint256 _salePrice) internal view returns( uint256) {
        uint256 feeAmount = (_salePrice * FEE_FRACTION) / _feeDenominator();

        return feeAmount;
    }

    function _payFee(address currency, uint256 salePrice) internal returns(uint256) {
        uint256 feeAmount = _getFeeAmount(salePrice);

        if (currency == address(0)){
            payable(FEE_RECEIVER).transfer(feeAmount);
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(currency);
            require(erc20.transfer(FEE_RECEIVER, feeAmount), "BidComp: Bid with ERC20 token failed");
        }

        return feeAmount;
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}
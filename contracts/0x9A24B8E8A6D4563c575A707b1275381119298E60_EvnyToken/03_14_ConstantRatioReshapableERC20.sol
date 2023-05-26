pragma solidity >=0.6.0 <0.8.0;

import "./ReshapableERC20.sol";

abstract contract ConstantRatioReshapableERC20 is ReshapableERC20 {
    function setRatio(address token, uint256 paddedRatio)
    external virtual override onlyOwner() returns (bool) {
        require(_ratios[token] == 0, "ConstantRatioReshapableERC20: Ratio already set");
        _setRatio(token, paddedRatio);
        return true;
    }

    function setOneToOneRatio(address token)
    external virtual onlyOwner() returns (bool) {
        require(_ratios[token] == 0, "ConstantRatioReshapableERC20: Ratio already set");
        _setRatio(token, RATIO_PADDING.div(DECIMALS));
        return true;
    }
}
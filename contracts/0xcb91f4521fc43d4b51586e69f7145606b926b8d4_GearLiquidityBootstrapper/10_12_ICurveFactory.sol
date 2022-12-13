pragma solidity ^0.8.10;

interface ICurveFactory {
    function deploy_pool(
        string calldata _name,
        string calldata _symbol,
        address[2] calldata _coins,
        uint256 A,
        uint256 gamma,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 allowed_extra_profit,
        uint256 fee_gamma,
        uint256 adjustment_step,
        uint256 admin_fee,
        uint256 ma_half_time,
        uint256 initial_price
    ) external returns (address);
}
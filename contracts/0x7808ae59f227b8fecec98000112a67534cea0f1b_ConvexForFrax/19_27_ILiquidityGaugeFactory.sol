// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface ILiquidityGaugeFactory {
    function get_gauge_from_lp_token(address lp_token) external view returns (address);

    function is_valid_gauge(address _gauge) external view returns (bool);

    function mint(address gauge_addr) external;
}
/* solhint-enable */
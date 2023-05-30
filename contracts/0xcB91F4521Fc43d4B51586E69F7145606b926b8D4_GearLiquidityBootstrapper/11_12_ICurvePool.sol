pragma solidity ^0.8.10;

interface ICurvePool {
    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external payable returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function token() external view returns (address);

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function fee() external view returns (uint256);
}
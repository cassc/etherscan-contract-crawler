pragma solidity >0.8.0;

import "IERC20.sol";

interface IBridgeAdapter {
    function sendAssets(
        uint256 value,
        address asset,
        address to
    ) external returns (bytes32 transferId);
}
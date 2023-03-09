// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BurnBot is AccessControlEnumerable, KeeperCompatible {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 public router;
    address public immutable FLOKI;

    EnumerableSet.AddressSet private _whitelistedTokens;

    constructor(address _router, address _floki) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        router = IUniswapV2Router02(_router);
        FLOKI = _floki;
    }

    function addWhitelistedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistedTokens.add(token);
    }

    function removeWhitelistedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistedTokens.remove(token);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 length = _whitelistedTokens.length();
        for (uint256 i = 0; i < length; i++) {
            address token = _whitelistedTokens.at(i);
            if (IERC20(token).balanceOf(address(this)) > 0) {
                return (true, abi.encode(""));
            }
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 length = _whitelistedTokens.length();
        for (uint256 i = 0; i < length; i++) {
            address token = _whitelistedTokens.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeApprove(address(router), balance);

                address WETH = router.WETH();

                address[] memory path;
                if (token == WETH) {
                    path = new address[](2);
                    path[0] = token;
                    path[1] = FLOKI;
                } else {
                    path = new address[](3);
                    path[0] = token;
                    path[1] = WETH;
                    path[2] = FLOKI;
                }
                router.swapExactTokensForTokens(balance, 0, path, BURN_ADDRESS, block.timestamp);
            }
        }
    }

    receive() external payable {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = FLOKI;
        router.swapExactETHForTokens{ value: msg.value }(0, path, BURN_ADDRESS, block.timestamp);
    }
}
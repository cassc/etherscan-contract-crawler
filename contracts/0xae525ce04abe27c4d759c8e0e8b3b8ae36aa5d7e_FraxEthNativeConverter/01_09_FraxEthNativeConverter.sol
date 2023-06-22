//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../utils/Constants.sol';
import '../../../strategies/interfaces/ICurvePool2Native.sol';
import "../../../interfaces/INativeConverter.sol";

contract FraxEthNativeConverter is INativeConverter {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant SLIPPAGE_DENOMINATOR = 10_000;
    IERC20Metadata public constant frxETH = IERC20Metadata(Constants.FRX_ETH_ADDRESS);

    int128 public constant ETH_frxETH_POOL_ETH_ID = 0;
    int128 public constant ETH_frxETH_POOL_frxETH_ID = 1;

    ICurvePool2Native public immutable fraxEthPool;

    uint256 public constant defaultSlippage = 30; // 0.3%

    constructor() {
        fraxEthPool = ICurvePool2Native(Constants.ETH_frxETH_ADDRESS);
    }

    receive() external payable {
        // receive ETH on conversion
    }

    function handle(
        bool buyToken,
        uint256 amount,
        uint256 slippage
    ) public payable returns(uint256 tokenAmount){
        if (amount == 0) return 0;

        if(buyToken) {
            tokenAmount = fraxEthPool.exchange{value: amount}(
                ETH_frxETH_POOL_ETH_ID,
                ETH_frxETH_POOL_frxETH_ID,
                amount,
                applySlippage(
                    amount,
                    slippage
                )
            );

            frxETH.safeTransfer(address(msg.sender), tokenAmount);
        } else {
            frxETH.safeIncreaseAllowance(address(fraxEthPool), amount);

            tokenAmount = fraxEthPool.exchange(
                ETH_frxETH_POOL_frxETH_ID,
                ETH_frxETH_POOL_ETH_ID,
                amount,
                applySlippage(
                    amount,
                    slippage
                )
            );

            (bool sent, ) = address(msg.sender).call{ value: tokenAmount }('');
            require(sent, 'Failed to send Ether');
        }
    }

    function valuate(
        bool buyToken,
        uint256 amount
    ) public view returns (uint256) {
        if (amount == 0) return 0;
        int128 i = buyToken ? ETH_frxETH_POOL_ETH_ID : ETH_frxETH_POOL_frxETH_ID;
        int128 j = buyToken ? ETH_frxETH_POOL_frxETH_ID : ETH_frxETH_POOL_ETH_ID;
        return
            fraxEthPool.get_dy(i, j, amount);
    }

    function applySlippage(
        uint256 amount,
        uint256 slippage
    ) internal pure returns (uint256) {
        require(slippage <= SLIPPAGE_DENOMINATOR, 'Wrong slippage');
        if (slippage == 0) slippage = defaultSlippage;
        uint256 value = (amount * (SLIPPAGE_DENOMINATOR - slippage)) / SLIPPAGE_DENOMINATOR;
        return value;
    }
}
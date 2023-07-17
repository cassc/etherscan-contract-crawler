// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IStargateRouter.sol";
import "../interfaces/IPancakeRouter.sol";

contract CrossDepositor is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct CAdapterInfo {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 dstGasForCall;
        address stRouter;
        uint16 dstChainId;
        address srcToken;
        address srcSwapRouter;
        address dstSwapRouter;
    }

    // cross chain adapter information
    CAdapterInfo public cAdapterInfo;

    // WETH address
    address public WETH;

    /**
     * @notice initialize
     */
    function initialize(address weth_, CAdapterInfo memory cAdapterInfo_) external initializer {
        __Ownable_init();

        cAdapterInfo = cAdapterInfo_;
        WETH = weth_;
    }

    function crossDeposit(uint256 _tokenId, address _dst, uint256 _amountIn, uint256 _stAmount) external payable {
        require(msg.sender == tx.origin, "Error: only EOA can interact");
        require(msg.value == _amountIn + _stAmount, "Error: Insufficient ETH");

        // Swap bnb to source token
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = cAdapterInfo.srcToken;

        uint256 balance = IERC20(cAdapterInfo.srcToken).balanceOf(address(this));
        IPancakeRouter(cAdapterInfo.srcSwapRouter).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(
            0,
            path,
            address(this),
            block.timestamp
        );

        {
            balance = IERC20(cAdapterInfo.srcToken).balanceOf(address(this)) - balance;
            bytes memory bytesAddress = abi.encodePacked(_dst);
            bytes memory payload = abi.encodeWithSelector(
                bytes4(keccak256("depositOnBehalf(uint256,address)")),
                _tokenId,
                msg.sender,
                cAdapterInfo.dstSwapRouter
            );

            // Approve token to stRouter
            IERC20(cAdapterInfo.srcToken).approve(cAdapterInfo.stRouter, 0);
            IERC20(cAdapterInfo.srcToken).approve(cAdapterInfo.stRouter, balance);
            {
                IStargateRouter(cAdapterInfo.stRouter).swap{value: _stAmount}(
                    cAdapterInfo.dstChainId,
                    cAdapterInfo.srcPoolId,
                    cAdapterInfo.dstPoolId,
                    payable(msg.sender),
                    balance,
                    0,
                    IStargateRouter.lzTxObj(cAdapterInfo.dstGasForCall, 0, bytesAddress),
                    bytesAddress,
                    payload
                );
            }
        }
    }

    function setCAdapterInfo(CAdapterInfo memory _cAdapterInfo) external onlyOwner {
        cAdapterInfo = _cAdapterInfo;
    }

    receive() external payable {}
}
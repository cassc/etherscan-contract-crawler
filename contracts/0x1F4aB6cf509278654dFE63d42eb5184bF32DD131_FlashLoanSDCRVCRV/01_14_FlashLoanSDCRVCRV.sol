pragma solidity ^0.8.9;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "./ICurvePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashLoanSDCRVCRV is IFlashLoanRecipient, Ownable {
    address private constant BALANCER_VAULT_ADDRESS = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IVault private constant vault = IVault(BALANCER_VAULT_ADDRESS);
    address private constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address private constant SD_CRV = address(0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5);
    address private constant CVX_CRV = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);

    address private constant SDCRV_VAULT_ADDRESS = address(0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717);
    address private constant SDCRV_VAULT_BOOSTER_ADDRESS = address(0xAf25fFe6bA5A8a29665adCfA6D30C5Ae56CA0Cd3);
    address private constant CVXCRV_VAULT = address(0x9D0464996170c6B9e75eED71c68B99dDEDf279e8);
    ICurvePool private constant SDCRV_VAULT = ICurvePool(SDCRV_VAULT_ADDRESS);
    ICurvePool private constant SDCRV_VAULT_BOOSTER = ICurvePool(SDCRV_VAULT_BOOSTER_ADDRESS);

    uint256 public denominator = 10000;
    uint256 public maxSlippage = 10;

    struct Node {
        address pool;
        int128 i;
        int128 j;
        address receiveTokenAddress;
    }

    constructor() {
        IERC20(CRV).approve(SDCRV_VAULT_ADDRESS, type(uint256).max);
        IERC20(CRV).approve(SDCRV_VAULT_BOOSTER_ADDRESS, type(uint256).max);
        IERC20(CRV).approve(BALANCER_VAULT_ADDRESS, type(uint256).max);
        IERC20(CRV).approve(CVXCRV_VAULT, type(uint256).max);

        IERC20(SD_CRV).approve(SDCRV_VAULT_ADDRESS, type(uint256).max);
        IERC20(SD_CRV).approve(SDCRV_VAULT_BOOSTER_ADDRESS, type(uint256).max);
        IERC20(SD_CRV).approve(CVXCRV_VAULT, type(uint256).max);

        IERC20(CVX_CRV).approve(SDCRV_VAULT_ADDRESS, type(uint256).max);
        IERC20(CVX_CRV).approve(SDCRV_VAULT_BOOSTER_ADDRESS, type(uint256).max);
        IERC20(CVX_CRV).approve(CVXCRV_VAULT, type(uint256).max);
    }

    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        vault.flashLoan(this, tokens, amounts, userData);
    }

    function withdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == BALANCER_VAULT_ADDRESS, "!auth");
        Node[] memory nodes = abi.decode(userData, (Node[]));

        uint256 length = nodes.length;
        uint256 _amount = amounts[0];
        uint8 i = 0;
        for(; i < length;) {
            Node memory node = nodes[i];
            
            _swap(_amount, node);

            if(i < length - 1) {
                _amount = IERC20(node.receiveTokenAddress).balanceOf(address(this));
            }
            
            unchecked {
                i++;
            }
        }

        uint256 crvBalance = IERC20(CRV).balanceOf(address(this));
        uint256 gain = crvBalance - amounts[0] - feeAmounts[0];
        IERC20(CRV).transfer(owner(), gain);
    }

    function _swap(uint256 _amount, Node memory node)
        internal
    {
        // calculate amount received
        uint256 amount = ICurvePool(node.pool).get_dy(node.i, node.j, _amount);

        // calculate minimum amount received
        uint256 minAmount = (amount * (denominator - maxSlippage)) / denominator;

        // swap
        ICurvePool(node.pool).exchange(
            node.i,
            node.j,
            _amount,
            minAmount,
            address(this)
        );
    }
}
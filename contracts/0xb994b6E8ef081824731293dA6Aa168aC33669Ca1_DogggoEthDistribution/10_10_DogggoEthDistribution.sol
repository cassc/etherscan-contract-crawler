// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/// @custom:security-contact [email protected]
contract DogggoEthDistribution is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant LIQUIDITY_PERC = 650;
    uint256 public distributeMinBalance = 10 ** 22;
    address public marketingAddress;
    IUniswapV2Router02 public router;
    IERC20 public immutable dogggo;

    event DistributeMinBalanceUpdated(uint256 minBalance);
    event MarketingAddressUpdated(address marketingAddress);
    event TaxDistributed(uint256 marketingTax, uint256 liquidityTax);
    event Received(address, uint);

    constructor(address _marketingAddress, address _dogggo, address _router) {
        require(_marketingAddress != address(0), "Address invalid");
        require(_dogggo != address(0), "Address invalid");
        require(_router != address(0), "Address invalid");

        marketingAddress = _marketingAddress;
        dogggo = IERC20(_dogggo);
        router = IUniswapV2Router02(_router);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setDistributeMinBalance(uint256 _minBalance) external onlyOwner {
        distributeMinBalance = _minBalance;

        emit DistributeMinBalanceUpdated(_minBalance);
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;

        emit MarketingAddressUpdated(_marketingAddress);
    }

    function distributeTax() external payable {
        uint256 contractBalance = dogggo.balanceOf(address(this));
        require(
            contractBalance >= distributeMinBalance,
            "Min balance not reached"
        );

        uint256 liquidityTax = (contractBalance * LIQUIDITY_PERC) / 1000;
        uint256 marketingTax = contractBalance - liquidityTax;

        dogggo.approve(address(router), contractBalance);
        address[] memory path = new address[](2);
        path[0] = address(dogggo);
        path[1] = router.WETH();

        addToLiquidity(liquidityTax, path);
        marketingTransfer(marketingTax, path);

        emit TaxDistributed(marketingTax, liquidityTax);
    }

    function marketingTransfer(
        uint256 _marketingTax,
        address[] memory _path
    ) internal {
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _marketingTax,
            0,
            _path,
            address(this),
            block.timestamp
        );
        uint256 ethBalance = address(this).balance;
        (bool sent, ) = marketingAddress.call{value: ethBalance}("");
        require(sent, "Failed to send Ether");
    }

    function addToLiquidity(
        uint256 _liquidityTax,
        address[] memory _path
    ) internal {
        uint256 half = _liquidityTax / 2;
        uint256 otherHalf = _liquidityTax - half;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            _path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;

        router.addLiquidityETH{value: ethBalance}(
            address(dogggo),
            otherHalf,
            0,
            0,
            marketingAddress,
            block.timestamp
        );
    }
}
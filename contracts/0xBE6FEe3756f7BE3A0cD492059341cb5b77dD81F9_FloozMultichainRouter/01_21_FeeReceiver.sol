pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IWETH.sol";

contract FeeReceiver is Pausable, Ownable {
    using SafeMath for uint256;

    event BuybackRateUpdated(uint256 newBuybackRate);
    event RevenueReceiverUpdated(address newRevenueReceiver);
    event RouterWhitelistUpdated(address router, bool status);
    event BuybackExecuted(uint256 amountBuyback, uint256 amountRevenue);

    address internal constant ZERO_ADDRESS = address(0);
    uint256 public constant FEE_DENOMINATOR = 10000;
    IPancakeRouter02 public pancakeRouter;
    address payable public revenueReceiver;
    uint256 public buybackRate;
    address public SYA;
    address public WETH;

    mapping(address => bool) public routerWhitelist;

    constructor(
        IPancakeRouter02 _pancakeRouterV2,
        address _SYA,
        address _WETH,
        address payable _revenueReceiver,
        uint256 _buybackRate
    ) public {
        pancakeRouter = _pancakeRouterV2;
        SYA = _SYA;
        WETH = _WETH;
        revenueReceiver = _revenueReceiver;
        buybackRate = _buybackRate;
        routerWhitelist[address(pancakeRouter)] = true;
    }

    /// @dev executes the buyback, buys SYA on pancake & sends revenue to the revenueReceiver by the defined rate.
    function executeBuyback() external whenNotPaused {
        require(address(this).balance > 0, "FeeReceiver: No balance for buyback");
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = SYA;

        uint256 balance = address(this).balance;
        uint256 amountBuyback = balance.mul(buybackRate).div(FEE_DENOMINATOR);
        uint256 amountRevenue = balance.sub(amountBuyback);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBuyback}(
            0,
            path,
            ZERO_ADDRESS,
            block.timestamp
        );
        TransferHelper.safeTransferETH(revenueReceiver, amountRevenue);
        emit BuybackExecuted(amountBuyback, amountRevenue);
    }

    /// @dev converts collected tokens from fees to ETH for executing buybacks
    function convertToETH(
        address _router,
        IERC20 _token,
        bool _fee
    ) public whenNotPaused {
        require(routerWhitelist[_router], "FeeReceiver: Router not whitelisted");
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = WETH;

        uint256 balance = _token.balanceOf(address(this));
        TransferHelper.safeApprove(address(_token), address(pancakeRouter), balance);
        if (_fee) {
            IPancakeRouter02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            IPancakeRouter02(_router).swapExactTokensForETH(balance, 0, path, address(this), block.timestamp);
        }
    }

    /// @dev converts WETH to ETH
    function unwrapWETH() public whenNotPaused {
        uint256 balance = IWETH(WETH).balanceOf(address(this));
        require(balance > 0, "FeeReceiver: Nothing to unwrap");
        IWETH(WETH).withdraw(balance);
    }

    /// @dev lets the owner update update the router whitelist
    function updateRouterWhiteliste(address _router, bool _status) external onlyOwner {
        routerWhitelist[_router] = _status;
        emit RouterWhitelistUpdated(_router, _status);
    }

    /// @dev lets the owner update the buyback rate
    function updateBuybackRate(uint256 _newBuybackRate) external onlyOwner {
        buybackRate = _newBuybackRate;
        emit BuybackRateUpdated(_newBuybackRate);
    }

    /// @dev lets the owner update the revenue receiver address
    function updateRevenueReceiver(address payable _newRevenueReceiver) external onlyOwner {
        revenueReceiver = _newRevenueReceiver;
        emit RevenueReceiverUpdated(_newRevenueReceiver);
    }

    /// @dev lets the owner withdraw ETH from the contract
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @dev lets the owner withdraw any ERC20 Token from the contract
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @dev allows to receive ETH on this contract
    receive() external payable {}

    /// @dev lets the owner pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev lets the owner unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
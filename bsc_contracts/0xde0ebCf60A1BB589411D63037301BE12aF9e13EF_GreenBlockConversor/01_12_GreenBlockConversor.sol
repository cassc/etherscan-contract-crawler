// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IGreenBlockPool.sol";
import "./interfaces/IRouterV2.sol";

contract GreenBlockConversor is Ownable, ReentrancyGuard, Pausable {
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //---------- Contracts ----------//
    IRouterV2 public immutable SWAP_ROUTER;
    IGreenBlockPool public immutable POOL;
    IERC20 public immutable WBTC;

    //---------- Variables ----------//
    uint256 public constant POINTS_DIVISOR = 10000;
    address public immutable WETH;
    uint256 public minDistribution;
    uint256 public treasuryFee;
    address public treasury;

    //---------- Events -----------//
    event Distributed(uint256 treasury, uint256 pool);

    //---------- Constructor ----------//
    constructor(
        IGreenBlockPool pool,
        IERC20 wbtc,
        IRouterV2 swapRouter
    ) {
        WETH = swapRouter.WETH();
        POOL = pool;
        WBTC = wbtc;
        SWAP_ROUTER = swapRouter;
        minDistribution = 0.1 ether;
        treasuryFee = 2500; // 25%
        treasury = msg.sender;
    }

    //----------- Internal Functions -----------//
    function _swap(uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(WBTC);

        // Executes the swap.
        SWAP_ROUTER.swapExactETHForTokens{value: amountIn}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _performDistribution(uint256 amount) internal {
        uint256 toTreasury = amount.mul(treasuryFee).div(POINTS_DIVISOR);
        uint256 toPool = amount.sub(toTreasury);
        WBTC.safeTransfer(treasury, toTreasury);
        if (WBTC.allowance(address(this), address(POOL)) < toPool) {
            WBTC.approve(address(POOL), type(uint256).max);
        }
        POOL.deposit(toPool);
        emit Distributed(toTreasury, toPool);
    }

    //----------- External Functions -----------//
    receive() external payable {}

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function btcBalance() public view returns (uint256) {
        return WBTC.balanceOf(address(this));
    }

    function canDistribute() public view returns (bool) {
        uint256 amount = balance();
        return amount >= minDistribution;
    }

    function swap() external nonReentrant {
        uint256 amount = balance();
        require(amount >= minDistribution, "Balance too low");
        _swap(amount);
    }

    function distribute() external nonReentrant {
        uint256 amount = balance();
        require(amount >= minDistribution, "Balance too low");
        _swap(amount);
        uint256 btcAmount = btcBalance();
        _performDistribution(btcAmount);
    }

    function distributeBTC() external nonReentrant {
        uint256 btcAmount = btcBalance();
        require(btcAmount >= 100, "Btc too low");
        _performDistribution(btcAmount);
    }

    function setMinDistribution(uint256 _min) external onlyOwner {
        require(_min >= 1 gwei);
        minDistribution = _min;
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0));
        treasury = _newTreasury;
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        require(_fee > 0 && _fee < POINTS_DIVISOR);
        treasuryFee = _fee;
    }

    function withdrawnEther(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Zero amount");
        address payable to = payable(_msgSender());
        (bool success, ) = to.call{value: _amount}("");
        require(success);
    }

    function withdrawnToken(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount > 0, "Zero amount");
        require(_token != address(0), "Invalid token");
        IERC20(_token).safeTransfer(_msgSender(), _amount);
    }

    /**
     * @notice Function for pause and unpause the contract.
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILeechSwapper.sol";
import "./interfaces/IStrategyVenus.sol";
import "./interfaces/IVenusPool.sol";
import "./interfaces/IUnitroller.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyVenusSupply is Ownable, Pausable, IStrategyVenus {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    address public unitroller;

    ///@notice Address of stake token.
    address public want;

    ///@notice Address LeechRouter's base token.
    address public constant BASE_TOKEN =
        0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    ///@notice Reward token.
    address public constant XVS = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;

    ///@notice Venus pool
    address public venusPool;

    ///@notice Address of the Uniswap Router
    IUniswapV2Router02 public uniV2Router;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%.
    uint256 public constant MAX_FEE = 1200;

    ///@notice Token swap path
    address[] public pathVenusToWant;

    address[] public pathWantToBase;

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller)
            revert("Unauthorized Caller");
        _;
    }

    constructor(
        address _controller,
        address _router,
        address _treasury,
        address _unitroller,
        address _want,
        address _venusPool,
        address _uniV2Router,
        address[] memory _pathVenusToWant,
        address[] memory _pathWantToBase,
        uint256 _fee
    ) {
        controller = _controller;
        router = _router;
        treasury = _treasury;
        unitroller = _unitroller;
        want = _want;
        venusPool = _venusPool;
        uniV2Router = IUniswapV2Router02(_uniV2Router);
        pathVenusToWant = _pathVenusToWant;
        _pathWantToBase = _pathWantToBase;
        protocolFee = _fee;
        IERC20(want).safeApprove(venusPool, type(uint256).max);
        IERC20(XVS).safeApprove(address(uniV2Router), type(uint256).max);
        IERC20(want).safeApprove(address(uniV2Router), type(uint256).max);
    }

    /**
     * @notice Supplying tokens into Venus farm.
     */
    function deposit(
        address[] memory pathTokenInToWant
    ) external whenNotPaused returns (uint256 wantBal) {
        if (msg.sender != router) revert("Unauthorized Caller");
        if (pathTokenInToWant[0] != want) {
            uint256 received = IERC20(pathTokenInToWant[0]).balanceOf(
                address(this)
            );
            _approveTokenIfNeeded(pathTokenInToWant[0], address(uniV2Router));
            uniV2Router.swapExactTokensForTokens(
                received,
                0,
                pathTokenInToWant,
                address(this),
                block.timestamp
            );
            wantBal = IERC20(want).balanceOf(address(this));
        } else {
            wantBal = IERC20(want).balanceOf(address(this));
        }
        if (wantBal > 0) {
            uint256 amountMinted = IVenusPool(venusPool).mint(wantBal);
            emit Deposited(wantBal, amountMinted);
        } else {
            revert("Nothing to deposit");
        }
    }

    /**
     * @notice Redeems the requested amount of vUSDC. Received USDC is sent back to LeechRouter.
     * @param _amountVUSDC Amount of vUSDC to be redeemed.
     */
    function withdraw(
        uint256 _amountVUSDC,
        address[] memory _pathWantToTokenOut
    ) public whenNotPaused returns (uint256 tokenOutAmount) {
        if (msg.sender != router) revert("Unauthorized Caller");
        IVenusPool(venusPool).redeem(_amountVUSDC);

        address tokenOut = _pathWantToTokenOut[_pathWantToTokenOut.length - 1];
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (tokenOut != want) {
            uniV2Router.swapExactTokensForTokens(
                wantBal,
                0,
                _pathWantToTokenOut,
                address(this),
                block.timestamp
            );
        }

        tokenOutAmount = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).safeTransfer(router, tokenOutAmount);
        emit Withdrawn(tokenOutAmount);
    }

    function withdrawAll() external {
        uint256 amountAll = IERC20(venusPool).balanceOf(address(this));
        withdraw(amountAll, pathWantToBase);
    }

    /**
     * @notice Claims rewards and re-invests them.
     */
    function autocompound() external whenNotPaused {
        IUnitroller(unitroller).claimVenus(address(this));
        uint256 amountXVS = IERC20(XVS).balanceOf(address(this));
        if (amountXVS > 0) {
            uniV2Router.swapExactTokensForTokens(
                amountXVS,
                0,
                pathVenusToWant,
                address(this),
                block.timestamp
            );
        }
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        uint256 fee = wantBal.mul(protocolFee).div(10000);
        IERC20(want).safeTransfer(treasury, fee);
        uint256 amountMinted = IVenusPool(venusPool).mint(wantBal - fee);
        emit Compounded(amountXVS, amountMinted, fee, block.timestamp);
    }

    /**
     * @notice Pause the contract's activity
     * @dev Only the owner or the controller can pause the contract's activity.
     */
    function pause() external onlyOwnerOrController {
        _pause();
    }

    /**
     * @notice Unpause the contract's activity
     * @dev Only the owner can unpause the contract's activity.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets fee taken by the Leech protocol.
     * @dev Only owner can set the protocol fee.
     * @param _fee Fee value.
     */
    function setFee(uint256 _fee) external onlyOwner {
        if (_fee > MAX_FEE) revert("Wrong Amount");
        protocolFee = _fee;
    }

    /**
     * @notice Sets the tresury address
     * @dev Only owner can set the treasury address
     * @param _treasury Address to be set.
     */
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert("ZeroAddressAsInput");
        treasury = _treasury;
    }

    /**
     * @notice Sets the controller address
     * @dev Only owner can set the controller address
     * @param _controller Address to be set.
     */
    function setController(address _controller) external onlyOwner {
        if (_controller == address(0)) revert("ZeroAddressAsInput");
        controller = _controller;
    }

    /**
     * @notice Allows the owner to withdraw stuck tokens from the contract's balance.
     * @dev Only owner can withdraw tokens.
     * @param _token Address of the token to be withdrawn.
     * @param _amount Amount to be withdrawn.
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Amount of USDC staked in the Venus pool
     */
    function balance() public view returns (uint256 amountWant) {
        uint256 rate = IVenusPool(venusPool).exchangeRateStored();
        amountWant = IERC20(venusPool).balanceOf(address(this)).mul(rate).div(
            1e18
        );
    }

    /**
     * @notice Amount of pending XVS rewards
     */
    function claimable() public view returns (uint256 pendingVenus) {
        pendingVenus = IUnitroller(unitroller).venusAccrued(address(this));
    }

    /**
     * @notice Returns total supply of the vToken, its exchange rate and vToken balance of this strategy. 
     */

    function getVtokenInfo() external view returns (uint256 totalSupply, uint256 exchangeRate, uint256 strBalance){
        totalSupply = IERC20(venusPool).totalSupply(); 
        exchangeRate = IVenusPool(venusPool).exchangeRateStored();
        strBalance = IERC20(venusPool).balanceOf(address(this));
    }

    /**
     *@dev Approves spender to spend tokens on behalf of the contract.
     *If the contract doesn't have enough allowance, this function approves spender.
     *@param token The address of the token to be approved
     *@param spender The address of the spender to be approved
     */
    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILeechSwapper.sol";
import "./interfaces/IStrategyVUSDCsupl.sol";
import "./interfaces/IVUSDC.sol";
import "./interfaces/IUnitroller.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyVUSDCsupl is Ownable, Pausable, IStrategyVUSDCsupl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leechswapper.
    address public swapper;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    address constant public UNITROLLER = 0xfD36E2c2a6789Db23113685031d7F16329158384;

    ///@notice Address LeechRouter's base token.
    address public constant WANT = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    ///@notice Reward token.
    address public constant XVS = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;

    ///@notice Venus pool
    address public constant VUSDC = 0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8;

    ///@notice WBNB address.
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    ///@notice Address of the Uniswap Router
    IUniswapV2Router02 public uniV2Router;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%.
    uint256 public constant MAX_FEE = 1200;

    ///@notice Token swap path
    address[] public pathVenusToWant = [XVS, WBNB, WANT];

    address[] public pathWantToBase = [WANT];

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller)
            revert("Unauthorized Caller");
        _;
    }

    constructor(
        address _controller,
        address _router,
        uint256 _fee,
        address _uniV2Router
    ) {
        controller = _controller;
        router = _router;
        protocolFee = _fee;
        uniV2Router = IUniswapV2Router02(_uniV2Router);
        IERC20(WANT).safeApprove(VUSDC, type(uint256).max);
        IERC20(XVS).safeApprove(address(uniV2Router), type(uint256).max);
        IERC20(WANT).safeApprove(address(uniV2Router), type(uint256).max);
    }

    /**
     * @notice Supplying tokens into Venus farm.
     */
    function deposit(
        address[] memory pathTokenInToWant
    ) external whenNotPaused returns (uint256 wantBal) {
        if (msg.sender != router) revert("Unauthorized Caller");
        if (pathTokenInToWant[0] != WANT) {
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
            wantBal = IERC20(WANT).balanceOf(address(this));
        } else {
            wantBal = IERC20(WANT).balanceOf(address(this));
        }
        if (wantBal > 0) {
            uint256 amountMinted = IVUSDC(VUSDC).mint(wantBal);
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
        address[] memory _pathWantToTokenOut,
        address[] memory _pathVenusToTokenOut
    ) public whenNotPaused returns (uint256 tokenOutAmount) {
        if (msg.sender != router) revert("Unauthorized Caller");
        IVUSDC(VUSDC).redeem(_amountVUSDC);
        uint256 amountXVS = IERC20(XVS).balanceOf(address(this));
        if (amountXVS > 0) {
            uint256 fee = amountXVS.mul(protocolFee).div(10000);
            IERC20(XVS).safeTransfer(treasury, fee);
            uniV2Router.swapExactTokensForTokens(
                amountXVS - fee,
                0,
                _pathVenusToTokenOut,
                address(this),
                block.timestamp
            );
        }

        address tokenOut = _pathWantToTokenOut[_pathWantToTokenOut.length - 1];
        uint256 wantBal = IERC20(WANT).balanceOf(address(this));

        if (tokenOut != WANT) {
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
        uint256 amountAll = IERC20(VUSDC).balanceOf(address(this));
        withdraw(amountAll, pathWantToBase, pathVenusToWant);
    }

    /**
     * @notice Claims rewards and re-invests them.
     */
    function autocompound() external whenNotPaused {
        IUnitroller(UNITROLLER).claimVenus(address(this));
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
        uint256 wantBal = IERC20(WANT).balanceOf(address(this));
        uint256 fee = wantBal.mul(protocolFee).div(10000);
        IERC20(WANT).safeTransfer(treasury, fee);
        uint256 amountMinted = IVUSDC(VUSDC).mint(wantBal-fee);
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
     * @notice Shows the amount of minted vUSDC.
     */
    function getBalance() external view returns (uint256) {
        uint256 bal = IERC20(VUSDC).balanceOf(address(this));
        return bal;
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
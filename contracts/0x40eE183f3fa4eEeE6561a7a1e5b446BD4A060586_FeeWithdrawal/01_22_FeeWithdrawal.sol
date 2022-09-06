// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {UUPSProxiable} from "../upgradability/UUPSProxiable.sol";
import "../interfaces/IBSLendingPair.sol";

contract FeeWithdrawal is UUPSProxiable {
    using SafeERC20 for IERC20;

    event LogUpdateAdmin(address newAdmin, uint256 timestamp);
    event LogRescueFunds(address token, uint256 amount, uint256 timestamp);
    event LogTransferToReceiver(address receiver, uint256 amount, uint256 timestamp);
    event LogWithdrawFees(uint256 totalWithdrawnFees, uint256 timestamp);
    event LogWithSwap(uint256 totalWarpReceived, uint256 timestamp);
    event LogUpdateWarpToken(address newToken, uint256 timestamp);

    uint256 public constant VERSION = 0x1;

    /// @notice The address to transfer the swapped WARP to
    address public immutable receiver;

    /// @notice vault address
    IBSVault public immutable vault;

    /// @notice the token's address that is swapped against any other fee token
    address public  warpToken;

    /// @notice WETH address
    address public immutable WETH;

    /// @notice The admin
    address public admin;

    /// @notice IUniswapRouter used to swap erc20 fee token into warpToken
    IUniswapV2Router02 public uniswapRouter;

    modifier onlyAdmin() {
        require(msg.sender == admin, "ONLY_ADMIN");
        _;
    }

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally-owned addresses.
        require(msg.sender == tx.origin, "MUST_BE_EOA");
        _;
    }

    /**
     * @notice Create a new FeeWithdrawal contract
     * @param _vault vault address
     * @param _receiver address of the contract to transfer Warp to
     * @param _warpToken address of warp token
     * @param _wethAddress WETH address
     */
    constructor(
        IBSVault _vault,
        address _receiver,
        address _warpToken,
        address _wethAddress
    ) {
        require(address(_vault) != address(0), "INVALID_VAULT");
        require(_receiver != address(0), "INVALID_RECEIVER");

        require(_warpToken != address(0), "FeeWithdrawal: invalid token address");

        require(_wethAddress != address(0), "FeeWithdrawal: invalid weth address");

        warpToken = _warpToken;
        WETH = _wethAddress;
        vault = _vault;
        receiver = _receiver;
    }

    /// @dev to avoid gas costs we are gonna send the underlying pair's asset as param & compute the amount off-chain
    /// @param _lendingPairs lending pair addresses
    function withdrawFees(IBSLendingPair[] calldata _lendingPairs) external onlyEOA {
        require(_lendingPairs.length > 0, "lendingPairs.length");

        uint256 totalWithdrawnFees = 0;

        for (uint256 i = 0; i < _lendingPairs.length; i++) {
            IBSLendingPair pair = _lendingPairs[i];

            IERC20 asset = pair.asset();
            uint256 amountToWithdraw = pair.totalReserves();

            // withdraw to vault
            pair.withdrawFees(amountToWithdraw);

            // withdraw underlying
            vault.withdraw(asset, address(this), address(this), amountToWithdraw);

            totalWithdrawnFees += amountToWithdraw;
        }

        emit LogWithdrawFees(totalWithdrawnFees, block.timestamp);
    }

    /// @dev swap Fees with warpToken
    /// @param _assets assets to be swaped
    /// @param amountOuts Minimum expected amountOut of the lending pair reserve swap
    function swapFees(IERC20[] calldata _assets, uint256[] calldata amountOuts) external onlyAdmin {
        require(_assets.length > 0, "assets.length");

        uint256 totalWarpReceived = 0;

        for (uint256 i = 0; i < _assets.length; i++) {
            IERC20 asset = _assets[i];

            uint256 amountToTrade = asset.balanceOf(address(this));

            if (address(asset) != warpToken) {
                totalWarpReceived += _convertToWarp(address(asset), amountToTrade, amountOuts[i]);
            } else {
                totalWarpReceived += amountToTrade;
            }
        }

        emit LogWithSwap(totalWarpReceived, block.timestamp);
    }

    function transferToReceiver() external {
        uint256 amount = IERC20(warpToken).balanceOf(address(this));
        IERC20(warpToken).transfer(receiver, amount);

        emit LogTransferToReceiver(receiver, amount, block.timestamp);
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "INVALID_ADMIN");
        admin = _newAdmin;
        emit LogUpdateAdmin(_newAdmin, block.timestamp);
    }

    function rescueFunds(address _token) external onlyAdmin {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(admin, balance);
        emit LogRescueFunds(_token, balance, block.timestamp);
    }

    function getPath(address from) internal view returns (address[] memory path) {
        if (from == WETH) {
            path = new address[](2);
            path[0] = WETH;
            path[1] = warpToken;
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = WETH;
            path[2] = warpToken;
        }
    }

    function _convertToWarp(
        address from,
        uint256 amount,
        uint256 amountOut
    ) private returns (uint256) {
        address[] memory path = getPath(from);

        IERC20(from).safeIncreaseAllowance(address(uniswapRouter), amount);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            amountOut,
            path,
            address(this),
            10**64
        );

        return amounts[amounts.length - 1];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // UUPSProxiable
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function initialize(address _admin, address _uniswapV2Router) external initializer {
        require(_admin != address(0), "INVALID_ADMIN");
        admin = _admin;

        require(_uniswapV2Router != address(0), "FeeWithdrawal: invalid router address");
        uniswapRouter = IUniswapV2Router02(_uniswapV2Router);
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.warp.contracts.warphelper.feewithdrawal");
    }

    function updateCode(address newAddress) external override onlyAdmin {
        _updateCodeAddress(newAddress);
    }

    function updateWarpToken(address _newToken) external onlyAdmin {
        require(_newToken != address(0), "INVALID_TOKEN");
        warpToken = _newToken;
        emit LogUpdateWarpToken(_newToken, block.timestamp);
    }
}
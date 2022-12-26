// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IWombatRouter.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IWombatLP.sol";
import "../interfaces/IZaynVault.sol";

contract ZaynDAIZap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IZaynVault;
    using SafeMath for uint256;

    mapping(address => bool) public allowedTokens;
    IWombatRouter public wombatRouter;
    IPool public wombatPool;

    mapping(address => address[]) public paths;


    // The minimum time it has to pass before a strat candidate can be approved.
    // uint256 public immutable approvalDelay;

   
    constructor(
        IWombatRouter _wombatRouter,
        IPool _wombatPool
    ) public {
        wombatRouter = _wombatRouter;
        wombatPool = _wombatPool;
    }


    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function recoverTokens(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function allowToken(address _token, bool _allow) external onlyOwner {
        allowedTokens[_token] = _allow;
    }

    function setPath(address _token, address[] calldata _paths) external onlyOwner {
        paths[_token] = _paths;
    }

    function zapIn(address _token, address vault, uint256 _amount) external {
        require(allowedTokens[_token], "Token is not allowed to deposit");
        require(_amount > 0, "Deposit amount should be greater than 0");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to deposit");

        address _lpAddress = IZaynVault(vault).want();
        address _underlyingToken = IWombatLP(_lpAddress).underlyingToken();
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        
        address token;
        uint256 minAmount;
        if (_underlyingToken == _token) {
            token = _token;
            minAmount = _amount;
        } else {
            token = paths[_token][paths[_token].length - 1];
            address[] memory _poolPathArr = new address[](1);
            _poolPathArr[0] = address(wombatPool);
            (minAmount,) = getAmountOut(_token, int256(_amount));
            
            _approveTokenIfNeeded(_token, address(wombatRouter));
            wombatRouter.swapExactTokensForTokens(paths[_token], _poolPathArr, _amount, minAmount, address(this), block.timestamp);
        }
        
        (uint256 minLiq,) = wombatPool.quotePotentialDeposit(token, minAmount);
        
        _approveTokenIfNeeded(token, address(wombatPool));
        uint256 liquidity = wombatPool.deposit(token, minAmount, minLiq, address(this), block.timestamp, false);

        _approveTokenIfNeeded(_lpAddress, vault);
        IZaynVault(vault).deposit(liquidity);

        IZaynVault(vault).safeTransfer(msg.sender, IZaynVault(vault).balanceOf(address(this)));
    }

    function zapOut(address vault, uint256 _amount, address _desiredToken) external {
        require(_amount > 0, "Amount should be greater than 0");
        IZaynVault vaultObj = IZaynVault(vault);
        require(vaultObj.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to deposit");

        vaultObj.safeTransferFrom(msg.sender, address(this), _amount);
        address[] memory poolTokens = wombatPool.getTokens();
        bool tokenFound = false;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            if (_desiredToken == poolTokens[i]) {
                tokenFound = true;
            }
        }
        require(tokenFound, "Pool does not support desiredToken");
        vaultObj.withdraw(_amount);

        address _lpAddress = IZaynVault(vault).want();
        address _underlyingToken = IWombatLP(_lpAddress).underlyingToken();
        uint256 wantBal = IERC20(_lpAddress).balanceOf(address(this));
        _approveTokenIfNeeded(_lpAddress, address(wombatPool));
        if (_underlyingToken == _desiredToken) {
            wombatPool.withdraw(_desiredToken, wantBal, 0, msg.sender, block.timestamp);
        } else {
            wombatPool.withdrawFromOtherAsset(_underlyingToken, _desiredToken, wantBal, 0, msg.sender, block.timestamp);
        }
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    function getAmountOut(address _token, int256 _amount) public view 
    returns (uint256 amountOut, uint256[] memory haircuts) {
        address[] memory _poolPathArr = new address[](1);
        _poolPathArr[0] = address(wombatPool);
        return wombatRouter.getAmountOut(paths[_token], _poolPathArr, _amount);
    }
}
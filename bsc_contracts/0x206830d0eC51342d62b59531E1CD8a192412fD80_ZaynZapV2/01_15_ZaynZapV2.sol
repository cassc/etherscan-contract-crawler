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
import "../interfaces/IZaynVaultV2.sol";

contract ZaynZapV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public allowedTokens;
    IWombatRouter public wombatRouter;
    IPool public wombatPool;
    address public poolPath;

    constructor(
        IWombatRouter _wombatRouter,
        IPool _wombatPool,
        address _poolPath
    ) public {
        wombatRouter = _wombatRouter;
        wombatPool = _wombatPool;
        poolPath = _poolPath;
    }


    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0)) {
            (bool sent, ) = msg.sender.call{value: address(this).balance}("");
            require(sent, "failed to send");
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    function allowToken(address _token, bool _allow) external onlyOwner {
        allowedTokens[_token] = _allow;
    }

    function zapIn(address _token, address vault, uint256 _amount, address _referrer) external {
        require(allowedTokens[_token], "Token is not allowed to deposit");
        require(_amount > 0, "Deposit amount should be greater than 0");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to deposit");

        address _lpAddress = IZaynVaultV2(vault).want();
        address _underlyingToken = IWombatLP(_lpAddress).underlyingToken();
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 depositAmount;
        if (_underlyingToken == _token) {
            depositAmount = _amount;
        } else {
            depositAmount = swapToUnderlying(_token, _underlyingToken, _amount);
        }
        
       
        uint256 liquidity = addLiquidity(_underlyingToken, depositAmount);
        _approveTokenIfNeeded(_lpAddress, vault);
        IZaynVaultV2(vault).depositZap(liquidity, msg.sender, _referrer);
    }

    function swapToUnderlying(address _token, address _underlyingToken, uint256 _amount) internal returns (uint256 swappedAmount){
        address[] memory _path = new address[](2);
        _path[0] = address(_token);
        _path[1] = address(_underlyingToken);

        address[] memory _poolPathArr = new address[](1);
        _poolPathArr[0] = address(poolPath);
        (uint256 minDepositOut,) = getAmountOut(_path, _poolPathArr, int256(_amount));

        _approveTokenIfNeeded(_token, address(wombatRouter));
        uint256 _before = IERC20(_underlyingToken).balanceOf(address(this));
        wombatRouter.swapExactTokensForTokens(
            _path,
            _poolPathArr,
            _amount,
            minDepositOut,
            address(this),
            block.timestamp
        );
        uint256 _after = IERC20(_underlyingToken).balanceOf(address(this));
        swappedAmount = _after.sub(_before);
    }

    function addLiquidity(address _underlyingToken, uint256 depositAmount) internal returns (uint256 liquidity) {
         (uint256 minLiq,) = wombatPool.quotePotentialDeposit(_underlyingToken, depositAmount);
        
        _approveTokenIfNeeded(_underlyingToken, address(wombatPool));
        liquidity = wombatPool.deposit(
            _underlyingToken,
            depositAmount,
            minLiq,
            address(this),
            block.timestamp,
            false
        );
    }

    function zapOut(address vault, uint256 _shares, address _desiredToken) external {
        require(_shares > 0, "Amount should be greater than 0");
        IZaynVaultV2 vaultObj = IZaynVaultV2(vault);
        vaultObj.withdrawZap(_shares, msg.sender);

        address _lpAddress = IZaynVaultV2(vault).want();
        address _underlyingToken = IWombatLP(_lpAddress).underlyingToken();
        uint256 wantBal = IERC20(_lpAddress).balanceOf(address(this));
        _approveTokenIfNeeded(_lpAddress, address(wombatPool));
        if (_underlyingToken == _desiredToken) {
            wombatPool.withdraw(_desiredToken, wantBal, 0, msg.sender, block.timestamp);
        } else {
            address[] memory _poolPathArr = new address[](1);
            _poolPathArr[0] = address(poolPath);

            address[] memory _path = new address[](2);
            _path[0] = address(_underlyingToken);
            _path[1] = address(_desiredToken);

            uint256 withdrawnAmount = wombatPool.withdraw(_underlyingToken, wantBal, 0, address(this), block.timestamp);
            _approveTokenIfNeeded(_underlyingToken, address(wombatRouter));
            wombatRouter.swapExactTokensForTokens(_path, _poolPathArr, withdrawnAmount, 0, msg.sender, block.timestamp);
        }
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    function getAmountOut(address[] memory _path, address[] memory _poolPathArr, int256 _amount) public view 
    returns (uint256 amountOut, uint256[] memory haircuts) {
        return wombatRouter.getAmountOut(_path, _poolPathArr, _amount);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITokenPreTimelock } from "./interfaces/ITokenPreTimelock.sol";

/**
 * @title TokenSale Contract
 */

contract TokenSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Sold(address buyer, uint256 amount);

    enum SaleStatus {
        Pause,
        Start
    }

    IERC20 public immutable USDC;

    ITokenPreTimelock public tokenPreTimelock;

    IERC20 public token; // the token being sold

    uint256 public coinsSold;

    uint256 public exchangePriceUSDC = 100000; // 0.1

    SaleStatus public saleStatus;

    constructor(IERC20 _token, IERC20 _usdc) {
        token = _token;
        USDC = _usdc;
    }

    modifier onSale() {
        require(saleStatus == SaleStatus.Start, "1");
        _;
    }

    function setTokenPreTimelock(ITokenPreTimelock _tokenPreTimelock) external onlyOwner {
        tokenPreTimelock = _tokenPreTimelock;
    }

    function setExchangePriceUSDC(uint256 _usdcPrice) external onlyOwner {
        exchangePriceUSDC = _usdcPrice;
    }

    function setSaleStatus(SaleStatus _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function buyTokensUsingUSDC(uint256 _usdcAmount) external onSale {
        uint256 _balanceBefore = USDC.balanceOf(address(this));
        USDC.safeTransferFrom(msg.sender, address(this), _usdcAmount);
        uint256 _balanceAfter = USDC.balanceOf(address(this));
        uint256 _actualUSDCAmount = _balanceAfter.sub(_balanceBefore);
        uint256 _numberOfTokens = computeTokensForUSDC(_actualUSDCAmount);
        require(token.allowance(owner(), address(this)) >= _numberOfTokens, "4");
        emit Sold(msg.sender, _numberOfTokens);
        coinsSold += _numberOfTokens;
        token.safeTransferFrom(owner(), address(tokenPreTimelock), _numberOfTokens);
        tokenPreTimelock.depositTokens(msg.sender, _numberOfTokens);
    }

    function buyTokensUsingUSDCPermit(uint256 _usdcAmount, bytes calldata _permitParams) external onSale {
        uint256 _balanceBefore = USDC.balanceOf(address(this));
        _permit(_permitParams);
        USDC.safeTransferFrom(msg.sender, address(this), _usdcAmount);
        uint256 _balanceAfter = USDC.balanceOf(address(this));
        uint256 _actualUSDCAmount = _balanceAfter.sub(_balanceBefore);
        uint256 _numberOfTokens = computeTokensForUSDC(_actualUSDCAmount);
        require(token.allowance(owner(), address(this)) >= _numberOfTokens, "4");
        emit Sold(msg.sender, _numberOfTokens);
        coinsSold += _numberOfTokens;
        token.safeTransferFrom(owner(), address(tokenPreTimelock), _numberOfTokens);
        tokenPreTimelock.depositTokens(msg.sender, _numberOfTokens);
    }

    function computeTokensForUSDC(uint256 _usdcAmount) public view returns (uint256) {
        uint256 _tokenDecimals = ERC20(address(token)).decimals();
        return (_usdcAmount * 10 ** _tokenDecimals) / exchangePriceUSDC;
    }

    function withdrawUSDC() public onlyOwner {
        uint256 _usdcBalance = IERC20(USDC).balanceOf(address(this));
        if (_usdcBalance > 0) {
            IERC20(USDC).safeTransfer(owner(), _usdcBalance);
        }
    }

    function endSale() external onlyOwner {
        saleStatus = SaleStatus.Pause;
        withdrawUSDC();
    }

    function _permit(bytes calldata _permitParams) internal {
        (bool success, ) = address(USDC).call(abi.encodePacked(IERC20Permit.permit.selector, _permitParams));
        require(success, "Permit Failed");
    }
}
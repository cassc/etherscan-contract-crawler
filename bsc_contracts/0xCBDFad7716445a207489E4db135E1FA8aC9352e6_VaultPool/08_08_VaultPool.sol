// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IWETH.sol";
import "./Ownable.sol";

contract VaultPool is Ownable {

    using SafeERC20 for IERC20;

    address constant BNB = address(0);

    address public WBNB;
    address internal _dex;

    event VaultAdded(address indexed token, uint256 amount);
    event VaultRemoved(address indexed token, uint256 amount);
    event DexAddressAccepted(address indexed dex);

    constructor(address WBNB_) {
        WBNB = WBNB_;
        _owner = msg.sender;
    }

    modifier onlyDex() {
        require(_dex == msg.sender, "VaultPool: caller is not the dex");
        _;
    }

    receive() external payable {
    }

    function dex() external view returns (address) {
        return _dex;
    }

    function setDex(address dex) external onlyOwner {
        require(dex != address(0), "VaultPool: dex is the zero address");
        _dex = dex;
        emit DexAddressAccepted(_dex);
    }

   function query(address token) external view returns (uint256 amount) {
        if (token == BNB) {
            return IWETH(WBNB).balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function addVault(address token_, uint256 amount_) external payable nonReentrant onlyDex {
        require(amount_ > 0, "VaultPool: vault value should above zero");
        if (token_ == BNB) {
            require(msg.value == amount_, "VaultPool: msg value is not equal to amount");
            _convertToWETH(amount_);
            emit VaultAdded(WBNB, amount_);
        } else {
            IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
            emit VaultAdded(token_, amount_);
        }
    }

    function removeVault(address token_, uint256 amount_) external nonReentrant onlyDex {
        if (token_ == BNB) {
            require(amount_ <= IWETH(WBNB).balanceOf(address(this)), "VaultPool: exceed vault amount");
            _convertFromWETH(amount_);
            _safeTransferETH(msg.sender, amount_);
            emit VaultRemoved(WBNB, amount_);
        } else {
            require(amount_ <= IERC20(token_).balanceOf(address(this)), "VaultPool: exceed vault amount");
            IERC20(token_).safeTransfer(msg.sender, amount_);
            emit VaultRemoved(token_, amount_);
        }
    }

    function _convertToWETH(uint amountETH) internal {
        require(amountETH > 0, "VaultPool: ZERO_AMOUNT");
        address self = address(this);
        uint256 assetBalance = self.balance;
        if (assetBalance >= amountETH) {
            IWETH(WBNB).deposit{value: amountETH}();
        }
    }

    function _convertFromWETH(uint amountWETH) internal {
        require(amountWETH > 0, "VaultPool: ZERO_AMOUNT");
        uint256 assetBalance = IWETH(WBNB).balanceOf(address(this));
        if (assetBalance >= amountWETH) {
            IWETH(WBNB).withdraw(amountWETH);
        }
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "VaultPool: transfer bnb failed");
    }

}
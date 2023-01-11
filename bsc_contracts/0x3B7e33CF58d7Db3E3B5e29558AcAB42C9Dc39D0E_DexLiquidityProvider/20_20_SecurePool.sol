// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Ownable.sol";

contract SecurePool is Ownable {

    using SafeERC20 for IERC20;

    address constant BNB = address(0);

    address public compensateToken;
    uint256 public totalCompensate;

    mapping(address => uint) internal dexMap;                      

    mapping(address => uint256) internal liquidityProviderSecure;     // out address => credit
    mapping(address => uint256) internal liquidityProviderPending;    // out address => pending number

    event SecureFundAdded(address indexed lpOut, address token, uint256 amount);
    event SecureFundRemoved(address indexed lpOut, address token, uint256 amount);
    event CompensateDone(address indexed lpOut, uint256 pendingSecure, uint256 totalSecure);

    event DexAddressAccepted(address indexed dex);
    event DexAddressRemoved(address indexed dex);

    constructor(address compensateToken_) {
        compensateToken = compensateToken_;
        _owner = msg.sender;
    }

    modifier onlyDex() {
        require(dexMap[msg.sender] > 0, "SecurePool: caller is not the dex");
        _;
    }

    receive() external payable {
    }

    function addDex(address[] calldata dexs) external onlyOwner {
        for (uint i = 0; i < dexs.length; i++) {
            address dex = dexs[i];
            require(dex != address(0), "SecurePool: dex is the zero address");
            dexMap[dex] = 1;
            emit DexAddressAccepted(dex);
        }
    }

    function removeDex(address[] calldata dexs) external onlyOwner {
        for (uint i = 0; i < dexs.length; i++) {
            address dex = dexs[i];
            require(dex != address(0), "SecurePool: dex is the zero address");
            delete dexMap[dex];
            emit DexAddressRemoved(dex);
        }
    }

    function queryDex(address dex) external view returns (uint) {
        return dexMap[dex];
    }

    function queryPending(address lpOut) external view returns (uint256 amount) {
        return liquidityProviderPending[lpOut];
    }

    function querySecure(address lpOut) external view returns (uint256 amount) {
        return liquidityProviderSecure[lpOut];
    }

    function addSecureFund(address lpOut, address token_, uint256 amount_) external payable nonReentrant onlyDex {
        require(amount_ > 0, "SecurePool: secure fund should above zero");
        require(token_ == compensateToken, "SecurePool: not same compensation token");

        if (token_ == BNB) {
            require(amount_ == msg.value, "DexLiquidityProvider: msg value is not equal to amount");
        } else {
            IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        }
        liquidityProviderSecure[lpOut] = liquidityProviderSecure[lpOut] + amount_;
        totalCompensate += amount_;
        emit SecureFundAdded(lpOut, token_, amount_);
    }

    function removeSecureFund(address lpOut, address token_, uint256 amount_) external nonReentrant onlyDex {
        uint256 freeSecure = liquidityProviderSecure[lpOut] - liquidityProviderPending[lpOut];
        require(amount_ <= freeSecure, "SecurePool: not enough free security fund");
        require(token_ == compensateToken, "SecurePool: not same compensation token");

        _safeTransferAsset(token_, msg.sender, amount_);
        liquidityProviderSecure[lpOut] = liquidityProviderSecure[lpOut] - amount_;
        totalCompensate -= amount_;
        emit SecureFundRemoved(lpOut, token_, amount_);
    }

    function compensateChange(address lpOut, uint256 amount_) external nonReentrant onlyDex {
        require(amount_ <= liquidityProviderPending[lpOut], "SecurePool: not enough pending fund");
        require(amount_ <= liquidityProviderSecure[lpOut], "SecurePool: not enough security fund");
        
        _safeTransferAsset(compensateToken, msg.sender, amount_);
        liquidityProviderPending[lpOut] = liquidityProviderPending[lpOut] - amount_;
        liquidityProviderSecure[lpOut] = liquidityProviderSecure[lpOut] - amount_;
        totalCompensate -= amount_;
        emit CompensateDone(lpOut, liquidityProviderPending[lpOut], liquidityProviderSecure[lpOut]);
    }

    function freePending(address lpOut, uint256 amount_) external nonReentrant onlyDex {
        require(amount_ <= liquidityProviderPending[lpOut], "SecurePool: not enough pending fund");
        liquidityProviderPending[lpOut] = liquidityProviderPending[lpOut] - amount_;
    }

    function frozePending(address lpOut, uint256 amount_) external nonReentrant onlyDex {
        uint256 targetSecure = liquidityProviderPending[lpOut] + amount_;
        require(targetSecure <= liquidityProviderSecure[lpOut], "SecurePool: liquidity provider has not enough security fund");
        liquidityProviderPending[lpOut] = targetSecure;
    }

    function recover(address asset, uint256 amount) external onlyOwner {
        if (asset == compensateToken) {
            uint256 balance;
            if (asset  == BNB) {
                balance = address(this).balance;
            } else {
                balance = IERC20(asset).balanceOf(address(this));
            }
            require((balance - totalCompensate) >= amount, "too much");
        }
        _safeTransferAsset(asset, _owner, amount);
    }

    function _safeTransferAsset(address asset, address to, uint256 amount) internal {
        if (asset  == BNB) {
            _safeTransferETH(to, amount);
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "DexBase: transfer bnb failed");
    }

}
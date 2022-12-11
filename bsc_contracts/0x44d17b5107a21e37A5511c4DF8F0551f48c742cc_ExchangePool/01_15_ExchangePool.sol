// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface IMai {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface ILendingPool {
    function deposit(uint256 amount) external;
}

contract ExchangePool is AccessControlEnumerableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function initialize() external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    uint256 public lastPrice;
    uint256 public totalUAmount;
    address public mai;

    mapping(address => mapping(uint8 => uint256)) public scales;

    EnumerableSetUpgradeable.AddressSet private tokenSet;

    function setScale(
        address addr,
        uint8 method,
        uint256 scale
    ) external onlyRole(OPERATOR_ROLE) {
        require(scale <= 6e17, "ExchangePool: Scale exceed.");
        scales[addr][method] = scale;
    }

    function setMai(address newMai) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMai != address(0), "ExchangePool: Address illegal.");
        mai = newMai;
    }

    function tokenAdd(address addr) external onlyRole(OPERATOR_ROLE) {
        tokenSet.add(addr);
    }

    function tokenRemove(address addr) external onlyRole(OPERATOR_ROLE) {
        tokenSet.remove(addr);
    }

    function tokenList() external view returns (address[] memory) {
        return tokenSet.values();
    }

    function initSupply(address token, uint256 amount) external {
        require(msg.sender == 0x1217748e9456EF6c471bC7E99a0D4a6Afa588F01, "ExchangePool: Forbidden.");
        require(amount <= 33_9330e18, "ExchangePool: Amount exceed.");
        if (lastPrice != 0) {
            revert("ExchangePool: Repeat initSupply.");
        } else {
            uint256 back = (amount * 1e18) / 1e17;
            _mint(token, amount, back);
        }
    }

    function deposit(
        address token,
        uint8 method,
        uint256 amount
    ) external returns (uint256 back) {
        require(scales[msg.sender][method] != 0, "ExchangePool: Forbidden.");
        require(tokenSet.contains(token), "ExchangePool: Nonsupport token.");

        back = ((amount * scales[msg.sender][method]) / lastPrice);
        _mint(token, amount, back);
    }

    function _mint(
        address token,
        uint256 amount,
        uint256 back
    ) private {
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        IMai(mai).mint(msg.sender, back);
        totalUAmount += amount;
        lastPrice = (totalUAmount * 1e18) / IERC20Upgradeable(mai).totalSupply();
    }

    function withdraw(address token, uint256 amount) external {
        require(tokenSet.contains(token), "ExchangePool: Nonsupport token.");
        uint256 exchangeAmount = (amount * totalUAmount) / IERC20Upgradeable(mai).totalSupply();
        totalUAmount -= exchangeAmount;
        IERC20Upgradeable(token).safeTransfer(msg.sender, exchangeAmount);
        IMai(mai).burnFrom(msg.sender, amount);
    }

    function transform2(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        address usdt = 0x55d398326f99059fF775485246999027B3197955;
        address lendingPool = 0xa6433855524027709FDfCA15937d9443d7989928;
        IERC20Upgradeable(usdt).safeApprove(lendingPool, amount);
        ILendingPool(lendingPool).deposit(amount);
    }
}
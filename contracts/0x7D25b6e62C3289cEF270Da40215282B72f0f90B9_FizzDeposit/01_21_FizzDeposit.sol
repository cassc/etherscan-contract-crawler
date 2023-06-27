// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract FizzDeposit is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public minDepositAmount;
    address public receiver;
    EnumerableSetUpgradeable.AddressSet tokens;

    event Deposit(address indexed addr, address indexed token, uint256 indexed amount);

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        tokens.add(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    function addToken(address token, bool flag) external onlyRole(OPERATOR_ROLE) {
        if (flag) tokens.add(token);
        else tokens.remove(token);
    }

    function setReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        receiver = _receiver;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyRole(OPERATOR_ROLE) {
        minDepositAmount = _minDepositAmount;
    }

    function getTokens() public view returns (address[] memory) {
        return tokens.values();
    }

    function withdraw(address token, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        require(receiver != address(0), "zero receiver limited");
        if (token == address(0)) {
            (bool sent, ) = receiver.call{value: amount}("");
            require(sent, "failed to send bnb");
        } else {
            IERC20Upgradeable(token).safeTransfer(receiver, amount);
        }
    }

    function depositToken(address token, uint256 amount) external {
        require(tokens.contains(token), "unsupported token");
        require(amount >= minDepositAmount, "min amount limited");
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    function deposit() external payable {
        require(msg.value > 0, "min amount limited");
        emit Deposit(msg.sender, address(0), msg.value);
    }
}
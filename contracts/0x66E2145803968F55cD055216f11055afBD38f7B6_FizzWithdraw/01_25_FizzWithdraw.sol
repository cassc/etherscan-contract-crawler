// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FizzWithdraw is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    EnumerableSetUpgradeable.AddressSet tokens;
    EnumerableSetUpgradeable.AddressSet signers;
    mapping(uint256 => bool) public orderIds;

    event Withdraw(address sender, address token, address to, uint256 amount, uint256 orderId);

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        tokens.add(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        signers.add(0x6400D8f0d547251451CeBA39C859c96f64BFc018);
    }

    function addToken(address token, bool flag) external onlyRole(OPERATOR_ROLE) {
        if (flag) tokens.add(token);
        else tokens.remove(token);
    }

    function addSigner(address signer, bool flag) external onlyRole(OPERATOR_ROLE) {
        if (flag) signers.add(signer);
        else signers.remove(signer);
    }

    function getTokens() public view returns (address[] memory) {
        return tokens.values();
    }

    function getSigners() public view returns (address[] memory) {
        return signers.values();
    }

    function withdraw(bytes calldata signature, address token, address to, uint256 amount, uint256 orderId, uint256 deadline) external {
        require(tokens.contains(token), "unsupported token");
        require(!orderIds[orderId], "duplicate withdraw");
        orderIds[orderId] = true;
        // require(block.timestamp < deadline, "deadline limited");
        bytes32 hash = keccak256(abi.encodePacked(token, to, amount, orderId, deadline));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        require(signers.contains(signer), "invalid signature");
        IERC20Upgradeable(token).safeTransfer(to, amount);
        emit Withdraw(msg.sender, token, to, amount, orderId);
    }
}
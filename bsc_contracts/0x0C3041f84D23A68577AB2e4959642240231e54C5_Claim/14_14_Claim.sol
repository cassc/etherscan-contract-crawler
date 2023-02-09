// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract Claim is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public admin;
    address public token;
    address public operator;

    mapping(uint256 => bool) usedNonces;
    event Claimed(address indexed addr, uint256 amount);
    event EmergencyWithdraw(address token, address to, uint256 amount);
    event OperatorChanged(address indexed operator);
    event ClaimAdminChanged(address indexed admin);
    event TokenChanged(address indexed token);

    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Caller is not operator");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    function initialize(address _token, address _admin, address _operator) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_admin != address(0), "Admin address must not be zero");
        require(_operator != address(0), "Operator address must not be zero");

        token = _token;
        admin = _admin;
        operator = _operator;
    }

    receive() external payable {}

    function changeToken(address _token) external onlyAdmin nonReentrant {
        token = _token;
        emit TokenChanged(token);
    }

    function emergencyWithdraw(address _token, address _to, uint256 _amount) external onlyAdmin nonReentrant {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        }
        emit EmergencyWithdraw(_token, _to, _amount);
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function changeOperator(address _newOperator) external onlyAdmin {
        require(_newOperator != address(0), "Operator address must not be zero");
        operator = _newOperator;
        emit OperatorChanged(_newOperator);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Admin address must not be zero");
        admin = _newAdmin;
        emit ClaimAdminChanged(_newAdmin);
    }

    function claimPayment(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        require(!usedNonces[_nonce], "Nonce already used");
        usedNonces[_nonce] = true;

        // this recreates the message that was signed on the client
        bytes32 _message = prefixed(keccak256(abi.encodePacked(msg.sender, _amount, _nonce, this)));

        require(recoverSigner(_message, _signature) == operator, "Failed to verify signature");

        if (token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(msg.sender, _amount);
        }
        emit Claimed(msg.sender, _amount);
    }

    /// signature methods.
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
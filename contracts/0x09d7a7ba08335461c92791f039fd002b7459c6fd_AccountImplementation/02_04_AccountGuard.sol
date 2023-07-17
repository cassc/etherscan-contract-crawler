// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccountGuard is Ownable {
    address factory;
    uint8 constant WHITELISTED_EXECUTE_MASK = 1;
    uint8 constant WHITELISTED_SEND_MASK = 2;
    mapping(address => mapping(address => bool)) private allowed;
    mapping(address => uint8) private whitelisted;
    mapping(address => address) public owners;

    function isWhitelisted(address target) public view returns (bool) {
        return (whitelisted[target] & WHITELISTED_EXECUTE_MASK) > 0;
    }

    function setWhitelist(address target, bool status) external onlyOwner {
        whitelisted[target] = status
            ? whitelisted[target] | WHITELISTED_EXECUTE_MASK
            : whitelisted[target] & ~WHITELISTED_EXECUTE_MASK;
    }

    function isWhitelistedSend(address target) public view returns (bool) {
        return (whitelisted[target] & WHITELISTED_SEND_MASK) > 0;
    }

    function setWhitelistSend(address target, bool status) external onlyOwner {
        whitelisted[target] = status
            ? whitelisted[target] | WHITELISTED_SEND_MASK
            : whitelisted[target] & ~WHITELISTED_SEND_MASK;
    }

    function canCallAndWhitelisted(
        address proxy,
        address operator,
        address callTarget,
        bool asDelegateCall
    ) external view returns (bool, bool) {
        return (
            allowed[operator][proxy],
            asDelegateCall
                ? isWhitelisted(callTarget)
                : isWhitelistedSend(callTarget)
        );
    }

    function canCall(address target, address operator)
        external
        view
        returns (bool)
    {
        return owners[target] == operator || allowed[operator][target];
    }

    function initializeFactory() external {
        require(factory == address(0), "account-guard/factory-set");
        factory = msg.sender;
    }

    function permit(
        address caller,
        address target,
        bool allowance
    ) external {
        require(
            allowed[msg.sender][target] || msg.sender == factory,
            "account-guard/no-permit"
        );
        if (msg.sender == factory) {
            owners[target] = caller;
            allowed[target][target] = true;
        } else {
            require(owners[target] != caller, "account-guard/cant-deny-owner");
        }
        allowed[caller][target] = allowance;

        if (allowance) {
            emit PermissionGranted(caller, target);
        } else {
            emit PermissionRevoked(caller, target);
        }
    }

    function changeOwner(address newOwner, address target) external {
        require(newOwner != address(0), "account-guard/zero-address");
        require(owners[target] == msg.sender, "account-guard/only-proxy-owner");
        owners[target] = newOwner;
        allowed[msg.sender][target] = false;
        allowed[newOwner][target] = true;
        emit ProxyOwnershipTransferred(newOwner, msg.sender, target);
    }

    event ProxyOwnershipTransferred(
        address indexed newOwner,
        address indexed oldAddress,
        address indexed proxy
    );
    event PermissionGranted(address indexed caller, address indexed proxy);
    event PermissionRevoked(address indexed caller, address indexed proxy);
}
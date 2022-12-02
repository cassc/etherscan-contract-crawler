// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {AccountGuard} from "./AccountGuard.sol";
import {AccountImplementation} from "./AccountImplementation.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract AccountFactory {
    address public immutable proxyTemplate;
    AccountGuard public immutable guard;
    uint256 public accountsGlobalCounter;

    //mapping(uint256 => address) public accounts;

    constructor(address _guard) {
        guard = AccountGuard(_guard);
        guard.initializeFactory();
        address adr = address(new AccountImplementation(guard));
        proxyTemplate = adr;
    }

    function createAccount() external returns (address clone) {
        clone = this.createAccount(msg.sender);
        return clone;
    }

    function createAccount(address user) external returns (address) {
        require(user != address(0), "account-factory/zero-address");
        uint globalCounter = ++accountsGlobalCounter;
        address clone = Clones.clone(proxyTemplate);
        guard.permit(user, clone, true);
        emit AccountCreated(clone, user, globalCounter);
        return clone;
    }

    event AccountCreated(
        address indexed proxy,
        address indexed user,
        uint256 indexed vaultId
    );
}
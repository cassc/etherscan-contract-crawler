// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@parallelmarkets/token/contracts/IParallelID.sol";

/*
 * @title The Know Your Customer Eth Token (KYCETH)
 * @author Parallel Markets Engineering Team
 * @dev See https://developer.parallelmarkets.com/docs/token for detailed documentation
 */
contract KnowYourCustomerEth is ERC20Upgradeable {
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    address public pidContract;

    function initialize(address _pidContract) public initializer {
        pidContract = _pidContract;
        __ERC20_init("Know Your Customer Eth", "KYCETH");
    }

    function deposit() public payable virtual sanctionsClear(msg.sender) {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override sanctionsClear(from) sanctionsClear(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public virtual override sanctionsClear(to) sanctionsClear(msg.sender) returns (bool) {
        return super.transfer(to, amount);
    }

    modifier sanctionsClear(address subject) {
        // Get a handle for the Parallel Identity Token contract
        IParallelID pid = IParallelID(pidContract);
        bool safe = false;

        // It's possible a subject could have multiple tokens issued over time - check
        // to see if any are currently monitored and safe from sanctions
        for (uint256 i = 0; i < pid.balanceOf(subject); i++) {
            uint256 tokenId = pid.tokenOfOwnerByIndex(subject, i);
            if (pid.isSanctionsSafe(tokenId)) safe = true;
        }

        require(safe, "Need monitored/unsanctioned PID");

        _;
    }
}
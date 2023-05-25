// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./interfaces/ITokenLockup.sol";

contract BlurToken is ERC20Votes, Ownable {

    uint256 private constant INITIAL_SUPPLY = 3_000_000_000;

    address[] public lockups;

    constructor() ERC20Permit("Blur") ERC20("Blur", "BLUR") {
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** 18);
    }

    /**
     * @notice Adds token lockup addresses
     * @param _lockups Lockup addresses to add
     */
    function addLockups(address[] calldata _lockups) external onlyOwner {
        require(lockups.length == 0);
        uint256 lockupsLength = _lockups.length;
        for (uint256 i = 0; i < lockupsLength; i++) {
            require(ITokenLockup(_lockups[i]).token() == address(this));
            lockups.push(_lockups[i]);
        }
    }

    /**
     * @notice Adds token lockup balance to ERC20Votes.getVotes value
     * @param account Address to get vote total of
     */
    function getVotes(address account) public view override returns (uint256) {
        return ERC20Votes.getVotes(account) + _getTokenLockupBalance(account);
    }

    /**
     * @notice Adds token lockup balance to ERC20Votes.getPastVotes value
     * @param account Address to get past vote total of
     */
    function getPastVotes(address account, uint256 blockNumber) public view override returns (uint256) {
        return ERC20Votes.getPastVotes(account, blockNumber) + _getTokenLockupBalance(account);
    }

    /**
     * @notice Calculates the balance that is allocated to the account across the token lockups
     * @param account Address to get locked balance of
     */
    function _getTokenLockupBalance(address account) internal view returns (uint256) {
        uint256 balance;
        uint256 lockupsLength = lockups.length;
        for (uint256 i; i < lockupsLength; i++) {
            balance += ITokenLockup(lockups[i]).balanceOf(account);
        }
        return balance;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721Reservable is Ownable {
    mapping(address => uint256) public reservedFor;
    uint256 public immutable maxReserved;
    uint256 internal reservedTotal;
    uint256 internal reservedOpen;

    constructor(uint256 _maxReserved) {
        maxReserved = _maxReserved;
    }

    /**
     * @notice Reserve `amount` tokens to be minted by `to`. Only callable by onwer.
     */
    function reserve(address to, uint256 amount) external onlyOwner {
        reservedFor[to] += amount;
        reservedOpen += amount;
        reservedTotal += amount;
        require(reservedTotal <= maxReserved, "Exceeds maxReserved");
    }

    /**
     * @notice Mint `amount` reserved tokens for `user`. Only callable by onwer.
     * @dev This method is meant to only be used to make sure all reserved mints are beeing used.
     */
    function mintReservedFor(address user, uint256 amount) external onlyOwner {
        require(amount <= reservedFor[user], "Exceeds reserved amount");

        reservedFor[user] -= amount;
        reservedOpen -= amount;
        _mintTo(user, amount);
    }

    /**
     * @notice Mint `amount` reserved tokens of sender to `to`.
     */
    function mintReserved(address to, uint256 amount) external {
        require(amount <= reservedFor[msg.sender], "Exceeds reserved amount");

        reservedFor[msg.sender] -= amount;
        reservedOpen -= amount;
        _mintTo(to, amount);
    }

    /**
     * @notice Mint reserved tokens of sender to `to`, one token each.
     */
    function mintReservedTo(address[] memory to) external {
        uint256 amount = to.length;
        require(amount <= reservedFor[msg.sender], "Exceeds reserved amount");

        reservedFor[msg.sender] -= amount;
        reservedOpen -= amount;
        for (uint256 i = 0; i < amount; ++i) {
            _mintTo(to[i], 1);
        }
    }

    function _mintTo(address _to, uint256 _amount) internal virtual;
}
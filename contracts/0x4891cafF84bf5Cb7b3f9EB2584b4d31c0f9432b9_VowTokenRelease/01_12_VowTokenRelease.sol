// contracts/VowTokenRelease.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VowTokenRelease is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    mapping(uint256 => bool) private _fulfilments;

    event Released(address indexed to, uint256 amount, address indexed token, uint256 fulfilmentId);

    constructor(address governance, address vowTokenReleaseAlgorithm) {
        _grantRole(GOVERNOR_ROLE, governance);
        _grantRole(VOW_TOKEN_RELEASE_ALGORITHM, vowTokenReleaseAlgorithm);
    }

    /**
     * @notice Function to release token
     * Caller is assumed to be governance
     * @param to Address of reciever
     * @param amount Amount of tokens
     * @param token Address of token
     * @param fulfilmentId Id of fulfilment
     */
    function release(address to, uint256 amount, IERC20 token, uint256 fulfilmentId) public onlyRole(GOVERNOR_ROLE) {
        require (amount > 0, "!amount");
        require (!_fulfilments[fulfilmentId], "fulfilled");
        token.safeTransfer(to, amount);
        _fulfilments[fulfilmentId] = true;
        emit Released(to, amount, address(token), fulfilmentId);
    }

    function isFulfilled(uint256 fulfilmentId) public view returns(bool fulfilmentStatus) {
        return _fulfilments[fulfilmentId];
    }
}
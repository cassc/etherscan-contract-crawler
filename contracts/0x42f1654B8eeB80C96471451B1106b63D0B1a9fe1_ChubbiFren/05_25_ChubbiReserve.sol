// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiBase.sol";

/**
 * @title ChubbiReserve
 * ChubbiReserve - A contract that allows token reservations and claiming.
 */
contract ChubbiReserve is ChubbiBase {
    using SafeMath for uint256;

    // Events
    event Claimed(address indexed owner, uint256 amount);

    uint256 public claimed;

    // A mapping from addresses to the amount of allocations
    mapping(address => uint256) internal reservations;

    bool internal _isClaimingActive;
    bool private isReserveActive;

    uint256 public maxTokensPerClaim;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ChubbiBase(_name, _symbol, _proxyRegistryAddress, _maxSupply) {
        _isClaimingActive = false;
        isReserveActive = true;
        maxTokensPerClaim = 50;
    }

    /**
     * @dev Get the reservations for a given address.
     * @param _for address of the owner of the tokens.
     */
    function getReservations(address _for) external view returns (uint256) {
        return isReserveActive ? reservations[_for] : 0;
    }

    /**
     * @dev Check if claiming is active.
     */
    function isClaimingActive() external view returns (bool) {
        return _isClaimingActive && isReserveActive;
    }

    function setMaxTokensPerClaim(uint256 _amount) external onlyOwner {
        maxTokensPerClaim = _amount;
    }

    /**
     * @dev Claim all reserved tokens.
     */
    function claim() external whenNotPaused {
        require(_isClaimingActive, "Claiming is not active");
        require(isReserveActive, "Reserve is not active");
        require(reservations[msg.sender] > 0, "No tokens to claim");

        uint256 numberOfTokens = reservations[msg.sender];
        uint256 numberToClaim = Math.min(numberOfTokens, maxTokensPerClaim);
        reservations[msg.sender] = numberOfTokens.sub(numberToClaim);
        claimed = claimed.add(numberToClaim);

        for (uint256 i = 0; i < numberToClaim; i++) {
            _mintTo(msg.sender);
        }

        emit Claimed(msg.sender, numberToClaim);
    }

    // Pause and unpause

    function pauseClaiming() external onlyOwner {
        require(_isClaimingActive, "Claiming is already paused");
        _isClaimingActive = false;
    }

    function unpauseClaiming() external onlyOwner {
        require(!_isClaimingActive, "Claiming is active");
        _isClaimingActive = true;
    }

    /**
     * @dev Stop all reservations permanently
     */
    function stopReservations() public onlyOwner whenNotPaused {
        _isClaimingActive = false;
        isReserveActive = false;
    }
}
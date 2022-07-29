// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error SalesActivation__ClaimNotStarted();
error SalesActivation__PublicSalesNotStarted();
error SalesActivation__PrivateSalesNotStarted();

contract SalesActivation is Ownable {
    /* State Variable */
    // Claim Start time
    uint256 private s_claimStartTime;
    // Public sales start time
    uint256 private s_publicSalesStartTime;
    // presales start time
    uint256 private s_preSalesStartTime;
    // presales end time
    uint256 private s_preSalesEndTime;

    /* Modifier */
    modifier isClaimActive() {
        if (!isClaimActivated()) {
            revert SalesActivation__ClaimNotStarted();
        }
        _;
    }
    modifier isPublicSalesActive() {
        if (!isPublicSalesActivated()) {
            revert SalesActivation__PublicSalesNotStarted();
        }
        _;
    }

    modifier isPreSalesActive() {
        if (!isPreSalesActivated()) {
            revert SalesActivation__PrivateSalesNotStarted();
        }
        _;
    }

    /* Functions */
    constructor(
        uint256 _publicSalesStartTime,
        uint256 _preSalesStartTime,
        uint256 _preSalesEndTime,
        uint256 _claimStartTime
    ) {
        s_claimStartTime = _claimStartTime;
        s_publicSalesStartTime = _publicSalesStartTime;
        s_preSalesStartTime = _preSalesStartTime;
        s_preSalesEndTime = _preSalesEndTime;
    }

    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        s_publicSalesStartTime = _startTime;
    }

    function setClaimStartTime(uint256 _startTime) external onlyOwner {
        s_claimStartTime = _startTime;
    }

    function setPreSalesTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_endTime >= _startTime, "PreSalesActivation: End time should be later than start time");
        s_preSalesStartTime = _startTime;
        s_preSalesEndTime = _endTime;
    }

    /* View / Pure Functions */
    function getClaimStartTime() public view returns (uint256) {
        return s_claimStartTime;
    }

    function getPublicSalesStartTime() public view returns (uint256) {
        return s_publicSalesStartTime;
    }

    function getPrivateSalesStartTime() public view returns (uint256) {
        return s_preSalesStartTime;
    }

    function getPreSalesEndTime() public view returns (uint256) {
        return s_preSalesEndTime;
    }

    function isClaimActivated() public view returns (bool) {
        return s_claimStartTime > 0 && block.timestamp >= s_claimStartTime;
    }

    function isPublicSalesActivated() public view returns (bool) {
        return s_publicSalesStartTime > 0 && block.timestamp >= s_publicSalesStartTime;
    }

    function isPreSalesActivated() public view returns (bool) {
        return
            s_preSalesStartTime > 0 &&
            s_preSalesEndTime > 0 &&
            block.timestamp >= s_preSalesStartTime &&
            block.timestamp <= s_preSalesEndTime;
    }
}
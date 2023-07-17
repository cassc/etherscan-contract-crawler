// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract FeesV2 is Ownable {
    using SafeERC20 for IERC20;
    bool public paused = false;

    // If true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    uint256 public affiliateSplit;

    // Mapping from {affiliate} to {status}
    mapping(address => bool) public affiliates;
    // Mapping from {swapTarget} to {status}
    mapping(address => bool) public approvedTargets;
    // Mapping from {token} to {status}
    mapping(address => bool) public shouldResetAllowance;

    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ContractPauseStatusChanged(bool status);
    event FeeWhitelistUpdate(address _address, bool status);
    event GoodwillChange(uint256 newGoodwill);
    event AffiliateSplitChange(uint256 newAffiliateSplit);

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is temporary paused");
        _;
    }

    /// @notice Returns address token balance
    /// @param token address
    /// @return balance
    function _getBalance(address token) internal view returns (uint256 balance) {
        if (token == address(ETH_ADDRESS)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    /// @dev Gives MAX allowance to token spender
    /// @param token address to apporve
    /// @param spender address
    function _approveToken(address token, address spender, uint256 amount) internal {
        IERC20 _token = IERC20(token);

        if (shouldResetAllowance[token]) {
            _token.safeApprove(spender, 0);
            _token.safeApprove(spender, type(uint256).max);
        } else if (_token.allowance(address(this), spender) > amount) return;
        else {
            _token.safeApprove(spender, 0);
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice To pause/unpause contract
    function toggleContractActive() public onlyOwner {
        paused = !paused;

        emit ContractPauseStatusChanged(paused);
    }

    /// @notice Whitelists addresses from paying goodwill
    function setFeeWhitelist(address _address, bool status) external onlyOwner {
        feeWhitelist[_address] = status;

        emit FeeWhitelistUpdate(_address, status);
    }

    /// @notice Changes goodwill %
    function setNewGoodwill(uint256 _newGoodwill) public onlyOwner {
        require(_newGoodwill <= 100, "Invalid goodwill value");
        goodwill = _newGoodwill;

        emit GoodwillChange(_newGoodwill);
    }

    /// @notice Changes affiliate split %
    function setNewAffiliateSplit(uint256 _newAffiliateSplit) external onlyOwner {
        require(_newAffiliateSplit <= 100, "Invalid affilatesplit percent");
        affiliateSplit = _newAffiliateSplit;

        emit AffiliateSplitChange(_newAffiliateSplit);
    }

    /// @notice Sets affiliate status
    function setAffiliates(address[] calldata _affiliates, bool[] calldata _status) external onlyOwner {
        require(_affiliates.length == _status.length, "Affiliate: Invalid input length");

        for (uint256 i = 0; i < _affiliates.length; i++) {
            affiliates[_affiliates[i]] = _status[i];
        }
    }

    ///@notice Sets approved targets
    function setApprovedTargets(address[] calldata targets, bool[] calldata isApproved) external onlyOwner {
        require(targets.length == isApproved.length, "SetApprovedTargets: Invalid input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    ///@notice Sets address allowance that should be reset first
    function setShouldResetAllowance(address[] calldata tokens, bool[] calldata statuses) external onlyOwner {
        require(tokens.length == statuses.length, "SetShouldResetAllowance: Invalid input length");

        for (uint256 i = 0; i < tokens.length; i++) {
            shouldResetAllowance[tokens[i]] = statuses[i];
        }
    }

    receive() external payable {
        // solhint-disable-next-line
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract UnboundToken is ERC20, ERC20Permit, ERC20Votes {
    address public governance;
    address public pendingGovernance;

    struct MintParams {
        address dest;
        uint256 amount;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "not allowed :(");
        _;
    }

    constructor(address _governance)
        ERC20("Unbound", "UNB")
        ERC20Permit("Unbound")
    {
        governance = _governance;
    }

    /// @notice Mint tokens
    function mint(MintParams[] memory params) external onlyGovernance {
        for (uint256 i = 0; i < params.length; i++) {
            _mint(params[i].dest, params[i].amount);
        }
    }

    /// @notice Burn tokens, only tokens from address(0) can be burned
    /// @param _amount  Amount of tokens to burn
    function burn(uint256 _amount) external onlyGovernance {
        _burn(0x000000000000000000000000000000000000dEaD, _amount);
    }

    /// @notice Remove stuck ERC20's from the contract
    /// @param _token Address of the token to remove
    /// @param _to Address to send removed token
    /// @param _amount Amount of the token
    function remove(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyGovernance {
        IERC20(_token).transfer(_to, _amount);
    }

    /// @notice Change governance
    /// @param _governance new governance
    function changeGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /// @notice Accept governance via 2 step process
    function acceptGovernance() external {
        require(pendingGovernance == msg.sender);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    /// @notice Renounces the ownership of the token contract
    function renounceOwnership() external onlyGovernance {
        governance = address(0);
    }

    // INTERNAL FUNCTIONS
    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
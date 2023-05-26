// SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// Interface to the RHAT ERC20 contract
interface IRibbonHatToken {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external;
}

contract RibbonHat is ERC1155, Ownable {
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Existing members who lost their ERC20 token.
    mapping(address => bool) public whitelist;
    // RHAT ERC20 address
    IRibbonHatToken public erc20Address;
    // This is the real contract owner, Ownable's owner has
    // no access in this house but kept just to please OpenSea.
    address public governor;

    /// @dev Event emitted when the contract governance is updated.
    event GovernanceTransferred(address indexed previousGovernor, address indexed newGovernor);

    constructor(
        address _erc20Address,
        address _governor,
        string memory uri,
        address[] memory whitelistedAddresses
    ) ERC1155(uri) {
        name = "Ribbon Hat";
        symbol = "RHAT";
        erc20Address = IRibbonHatToken(_erc20Address);
        governor = _governor;
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            whitelist[whitelistedAddresses[i]] = true;
        }
    }

    /// @dev A modifier which checks that the caller is eligible to mint RHAT.
    modifier onlyRhatHolder() {
        // Check whether sender has a RHAT ERC20 token,
        // or is part of the whitelist.
        require(erc20Address.balanceOf(msg.sender) > 0 || whitelist[msg.sender], "not eligible for rhat");
        _;
    }

    /// @dev A modifier which checks that the caller is the contract governor.
    modifier onlyGovernor() {
        require(governor == msg.sender, "not the governor");
        _;
    }

    /// @dev mint ensures that only RHAT ERC20 holders or whitelisted addresses
    /// can mint RHAT NFTs. For ERC20 holders, their token is transferred
    /// to this contract, then the mint is executed.
    /// Note that for RHAT ERC20 holders, first the current contract allowance
    /// needs to be increased in the RHAT ERC20 contract.
    function mint() external onlyRhatHolder {
        if (erc20Address.balanceOf(msg.sender) > 0) {
            erc20Address.transferFrom(msg.sender, address(this), 1);
        } else if (whitelist[msg.sender]) {
            // Remove from whitelist to ensure only once semantics
            whitelist[msg.sender] = false;
        }
        // mint RHAT NFT for the RHAT holder
        _mint(msg.sender, 0, 1, "");
    }

    /// @dev Transfer contract governance to newGovernor. Only callable by
    /// the existing governor.
    function transferGovernance(address newGovernor) external onlyGovernor {
        require(newGovernor != address(0), "new governor is the zero address");
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernanceTransferred(oldGovernor, newGovernor);
    }
}
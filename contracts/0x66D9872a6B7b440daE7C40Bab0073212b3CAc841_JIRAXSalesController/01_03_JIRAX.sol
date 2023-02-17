// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title JIRAX Sales Controller
/// @author @whiteoakkong
/// @notice This contract is designed to control the sale of JIRAX - the off-chain token for PG and associated projects.

import "@openzeppelin/contracts/access/Ownable.sol";

contract JIRAXSalesController is Ownable {
    event Deposit(address indexed sender, uint256 amount, address partner);

    mapping(address => uint256) public PartnerRegistry;

    address public JIRA;
    address public INFINIT3;

    uint256 private developerSplit;

    constructor(address _JIRA, address _INFINIT3, uint256 _developerSplit) {
        JIRA = _JIRA;
        INFINIT3 = _INFINIT3;
        developerSplit = _developerSplit;
    }

    function deposit(address partner) external payable {
        uint256 affiliateSplit = (msg.value * PartnerRegistry[partner]) / 100;
        if (affiliateSplit > 0) {
            (bool success, ) = payable(partner).call{value: affiliateSplit}("");
            require(success, "Transfer failed.");
        }
        emit Deposit(msg.sender, msg.value, partner);
    }

    function setPartner(address partner, uint256 split) external onlyOwner {
        PartnerRegistry[partner] = split;
    }

    function withdraw() external {
        require(msg.sender == INFINIT3 || msg.sender == JIRA || msg.sender == owner(), "Not authorized");
        uint256 fee = (address(this).balance * developerSplit) / 100;
        (bool success, ) = payable(INFINIT3).call{value: fee}("");
        require(success, "Transfer failed.");
        (success, ) = payable(JIRA).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setDeveloperSplit(uint256 _developerSplit) external onlyOwner {
        developerSplit = _developerSplit;
    }

    function changeWallets(address _address, uint256 selector) external onlyOwner {
        if (selector == 0) JIRA = _address;
        else if (selector == 1) INFINIT3 == _address;
        else revert("Incorrect selector");
    }

}
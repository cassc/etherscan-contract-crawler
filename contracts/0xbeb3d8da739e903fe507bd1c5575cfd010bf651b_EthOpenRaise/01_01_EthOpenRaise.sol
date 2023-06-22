// SPDX-License-Identifier: MIT
//-------------------------------------------------------------------------
//    Pragma
//-------------------------------------------------------------------------

pragma solidity 0.8.20;

//-------------------------------------------------------------------------
//    Errors
//-------------------------------------------------------------------------

error MV_OpenRaise_MinNotMet();
error MV_OpenRaise_MaxMet();
error MV_OpenRaise_onlyOwner();
error MV_OpenRaise_InvalidEdit();
error MV_OpenRaise_CantWithdraw();

/**
 * @title EthOpenRaise
 * @author Semi Invader
 * @notice This contract is meant only to receive ETH type contributions
 */

contract EthOpenRaise {
    //-------------------------------------------------------------------------
    //    State Variables
    //-------------------------------------------------------------------------
    mapping(address => uint256) public contributions;
    mapping(address => uint256) private contributorIndex;
    address[] private contributors;
    address public owner;
    string public name;
    uint public min;
    uint public max;
    uint public totalContributions;

    //-------------------------------------------------------------------------
    //    Events
    //-------------------------------------------------------------------------
    event Contributed(address indexed contributor, uint256 amount);
    event Edit(string indexed name, uint256 prevAmount, uint256 newAmount);
    event Withdraw(address indexed to, uint256 amount);
    //-------------------------------------------------------------------------
    //    Modifiers
    //-------------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert MV_OpenRaise_onlyOwner();
        _;
    }

    //-------------------------------------------------------------------------
    //    Constructor
    //-------------------------------------------------------------------------

    constructor(string memory _raiseName, uint _min, uint _max) {
        name = _raiseName;
        min = _min;
        max = _max;
        owner = msg.sender;
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL Functions
    //-------------------------------------------------------------------------

    function contribute() external payable {
        uint contributed = contributions[msg.sender];
        if (contributed == 0) {
            if (msg.value < min) revert MV_OpenRaise_MinNotMet();

            contributorIndex[msg.sender] = contributors.length;
            contributors.push(msg.sender);
        }
        contributed += msg.value;
        if (contributed > max) revert MV_OpenRaise_MaxMet();
        totalContributions += msg.value;
        contributions[msg.sender] = contributed;

        emit Contributed(msg.sender, msg.value);
    }

    function editMin(uint _newMin) external onlyOwner {
        if (_newMin > max) revert MV_OpenRaise_InvalidEdit();
        emit Edit("min", min, _newMin);
        min = _newMin;
    }

    function editMax(uint _newMax) external onlyOwner {
        if (_newMax < min) revert MV_OpenRaise_InvalidEdit();
        emit Edit("max", max, _newMax);
        max = _newMax;
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert MV_OpenRaise_CantWithdraw();
        (bool succ, ) = payable(_to).call{value: balance}("");
        if (!succ) revert MV_OpenRaise_CantWithdraw();
        emit Withdraw(_to, balance);
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL Functions (VIEW)
    //-------------------------------------------------------------------------

    function getAllContributorsAndContributions()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory _contributions = new uint256[](contributors.length);
        for (uint256 i = 0; i < contributors.length; i++) {
            _contributions[i] = contributions[contributors[i]];
        }
        return (contributors, _contributions);
    }

    function totalContributors() external view returns (uint256) {
        return contributors.length;
    }
}
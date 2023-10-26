/**
 *Submitted for verification at Etherscan.io on 2023-09-01
*/

pragma solidity 0.8.18;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ClaimContract {
    IERC20 public TOKEN;

    address public owner;
    uint256 public totalTokenClaimed;
    bool public enableClaim;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    constructor(address _owner, address _TOKEN) {
        owner = _owner;
        TOKEN = IERC20(_TOKEN);
    }

    function addData(
        address[] memory wallet,
        uint256[] memory amount
    ) public onlyOwner {
        for (uint256 i = 0; i < wallet.length; i++) {
            wallets[wallet[i]] += amount[i];
        }
    }

    function Claim() public {
        require(enableClaim == true, "wait for owner to start claim");
        require(wallets[msg.sender] > 0, "already claimed");
        TOKEN.transfer(msg.sender, wallets[msg.sender] * 1e18);
        wallets[msg.sender] = 0;
    }

    // transfer ownership
    function EnableClaim(bool _state) external onlyOwner {
        enableClaim = _state;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        TOKEN = IERC20(_token);
    }

    // to draw out tokens
    function transferStuckTokens(
        IERC20 token,
        uint256 _value
    ) external onlyOwner {
        token.transfer(msg.sender, _value);
    }
 
}
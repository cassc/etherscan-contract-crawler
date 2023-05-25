/**
 *Submitted for verification at Etherscan.io on 2023-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBEP20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),
            'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claim is Ownable {

    address public tokenAddress;

    mapping (address => uint256) public claimableAmount;
    mapping (address => uint256) public claimedAmount;

    event Claimed(address indexed user, uint256 amount);

    constructor() {
        tokenAddress = 0x95ac4ffA46C25dBCe18C53F5EdAf088b53c160D1;
    }

    // only owner functions here

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setClaimableAmount(address[] memory _users, uint256[] memory _amounts) public onlyOwner {
        require(_users.length == _amounts.length, 'Invalid input');
        for (uint256 i = 0; i < _users.length; i++) {
            claimableAmount[_users[i]] = _amounts[i];
        }
    }


    // public functions here

    function claim () public {
        require(claimableAmount[msg.sender] > 0, 'No claimable amount');
        uint256 amount = claimableAmount[msg.sender];
        claimedAmount[msg.sender] += amount;
        claimableAmount[msg.sender] = 0;
        IBEP20(tokenAddress).transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth(uint256 amount) external onlyOwner returns (bool) {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        return success;
    }

    // this function is to withdraw BEP20 tokens sent to this address by mistake
    function withdrawBEP20(
        address _tokenAddress,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IBEP20 token = IBEP20(_tokenAddress);
        bool success = token.transfer(msg.sender, amount);
        return success;
    }

    receive() external payable {}

}
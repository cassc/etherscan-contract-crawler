/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

abstract contract IERC20 {
    function transfer(address _to, uint256 _value) external virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
}

contract TokenStaking {

    address public tokenContract;
    uint256 public interest;  // e.g. 3.5% ==> 1035
    uint256 public spotsLeft;
    uint256 public minimumAmount;
    uint256 public maximumAmount;

    mapping(address => uint256) public ownerToStakedValue;
    mapping(address => uint256) public ownerToReleaseTime;
    mapping(address => uint256) public ownerToReleaseValue;

    bool public paused = false;
    address public owner;
    address public newContractOwner;

    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (uint256 _spotsLeft, uint256 _minimumAmount, uint256 _maximumAmount, uint256 _interest, address _tokenContract) {
        spotsLeft = _spotsLeft;
        minimumAmount = _minimumAmount;
        maximumAmount = _maximumAmount;
        interest = _interest;
        tokenContract = _tokenContract;
        owner = msg.sender;
    }

    modifier ifNotPaused {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier onlyContractOwner {
        require(msg.sender == owner, "Not authorized.");
        _;
    }

    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0), "Invalid address.");
        newContractOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newContractOwner, "Not authorized to accept ownership.");
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }

    function setPause(bool _paused) external onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }

    function setInterest(uint256 _interest) external onlyContractOwner {
        interest = _interest;
    }

    function setTokenContract(address _tokenContract) external onlyContractOwner {
        tokenContract = _tokenContract;
    }

    function stake(uint256 _value) external payable ifNotPaused {
        require(_value >= minimumAmount, "Insufficient amount for staking!");
        require(_value <= maximumAmount, "Amount too big for staking!");
        require(spotsLeft > 0, "No more staking spots left!");
        require(ownerToStakedValue[msg.sender] == 0, "This address is already staking!");
        IERC20 token = IERC20(tokenContract);
        token.transferFrom(msg.sender, address(this), _value);

        ownerToStakedValue[msg.sender] = _value;
        ownerToReleaseTime[msg.sender] = block.timestamp + (6 * 2628000);  // one month equals 2628000 secs
        ownerToReleaseValue[msg.sender] = (_value * interest) / 1000;

        spotsLeft -= 1;
    }

    function claim() external payable ifNotPaused {
        require(block.timestamp >= ownerToReleaseTime[msg.sender], "Your staking has not ended yet.");
        require(ownerToReleaseValue[msg.sender] > 0, "Release value is zero.");

        delete ownerToReleaseTime[msg.sender];
        delete ownerToStakedValue[msg.sender];
        delete ownerToReleaseValue[msg.sender];

        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, ownerToReleaseValue[msg.sender]);
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }

    function withdrawTokenBalance(address _address, uint256 _amount) external onlyContractOwner {
        IERC20 token = IERC20(_address);
        token.transfer(msg.sender, _amount);
    }

}
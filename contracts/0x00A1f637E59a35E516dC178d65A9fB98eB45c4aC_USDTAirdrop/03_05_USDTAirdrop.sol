//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IRDS.sol";
import "../interface/IERC20TokenBank.sol";

contract USDTAirdrop is Ownable {
    IRDS public rds;
    IERC20TokenBank public usdtBank;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalAward;
    uint256 public creationBlock;
    mapping(address => bool) public claimed;

    constructor(
        address _rdsAddr,
        address _usdtBank,
        uint256 _totalAward,
        uint256 _startAt,
        uint256 _endAt
    ) {
        rds = IRDS(_rdsAddr);
        usdtBank = IERC20TokenBank(_usdtBank);
        totalAward = _totalAward * 10**6;
        startTime = _startAt;
        endTime = _endAt;
        require(startTime < endTime, "invalid input!");
        creationBlock = _startAt;
    }

    event Claim(address indexed addr, uint256 amount);

    modifier isDuringAirdrop(bool _is) {
        if (_is) {
            require(
                block.number > startTime && block.number < endTime,
                "not started or already ended"
            );
        } else {
            require(
                block.number < startTime || block.number > endTime,
                "during airdrop"
            );
        }
        _;
    }

    function claim() external isDuringAirdrop(true) {
        uint256 amount = (rds.balanceOfAt(msg.sender, creationBlock) *
            totalAward) / rds.totalSupplyAt(creationBlock);
        require(amount > 0, "no airdrop");
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;
        bool success = usdtBank.issue(msg.sender, amount);
        require(success);

        emit Claim(msg.sender, amount);
    }

    function changeParams(uint256 _creationBlock, uint256 _totalAward)
        external
        isDuringAirdrop(false)
        onlyOwner
    {
        creationBlock = _creationBlock;
        totalAward = _totalAward;
    }

    function changePeriod(uint256 _startAt, uint256 _endAt) external onlyOwner {
        startTime = _startAt;
        endTime = _endAt;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeDao is Ownable, ReentrancyGuard, ERC20("DeHorizon DAO", "DD") {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    ERC20 public immutable devt;
    uint256 public immutable startTime;

    //no tranfer flag
    bool public noTransfer = true;

    /// @notice From the start time, calculate the minimum stake amount
    function checkAmount() public view returns (uint256) {
        uint256 day = (block.timestamp - startTime) / 86400;
        int128 logVariable = ABDKMath64x64.log_2(
            ABDKMath64x64.fromUInt(day * 3 + 2)
        )*150;
      
        uint256 currentAmount = uint256(ABDKMath64x64.toUInt(logVariable));
        return currentAmount;
    }

    constructor(address _devt) public {
        require(_devt != address(0), "DeHorizon DAO: set address is zero");
        devt = ERC20(_devt);
        startTime = block.timestamp;
    }

    /// @notice Determine whether to allow the transaction when trading
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20) {
        require(!noTransfer, "DeHorizon DAO: no transfer");
        ERC20._transfer(sender, recipient, amount);
    }

     /// @notice Set whether to allow transactions
    function setTransferFlag() external onlyOwner {
        noTransfer = !noTransfer;
    }

    /// @notice staking DEVT, get DD
    /// @param _samount is staking devt nums
    
    function stake(uint256 _samount ) external nonReentrant {
        require(_samount >= checkAmount(), "DeHorizon DAO: not enough amount");
        devt.transferFrom(msg.sender, address(this), _samount * 10**18);
        _mint(msg.sender, _samount * 10**18);

        emit Staked(msg.sender, _samount * 10**18);
    }

    /// @notice withdraw DEVT, burn DD
    function withdraw() external nonReentrant {
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "DeHorizon DAO: no stake");
        _burn(msg.sender, amount);
        devt.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IVBabyToken.sol';
import '../interfaces/IBabyToken.sol';

contract VBabyOwner is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IBabyToken;

    event Borrow(address user, uint amount, uint userBorrowed, uint totalBorrowed, uint currentBalance);
    event Repay(address user, uint repayAmount, uint donateAmount, uint userBorrowed, uint totalBorrowed, uint currentBalance);

    uint constant public PERCENT_BASE = 1e6;
    uint constant public MAX_BORROW_PERCENT = 8e5;

    IBabyToken immutable public babyToken;
    IVBabyToken immutable public vBabyToken;
    mapping(address => uint) public farmers;
    mapping(address => bool) public isFarmer;
    uint public totalPercent;
    mapping(address => uint) public farmerBorrow;
    uint public totalBorrow;
    uint public totalDonate;

    constructor(IVBabyToken _vBabyToken) {
        vBabyToken = _vBabyToken;
        babyToken = IBabyToken(_vBabyToken._babyToken());
    }

    modifier onlyFarmer() {
        require(isFarmer[msg.sender], "only farmer can do this");
        _;
    }

    function vBabySetCanTransfer(bool allowed) external onlyOwner {
        vBabyToken.setCanTransfer(allowed);
    }

    function vBabyChangePerReward(uint256 babyPerBlock) external onlyOwner {
        vBabyToken.changePerReward(babyPerBlock);
    }

    function vBabyUpdateBABYFeeBurnRatio(uint256 babyFeeBurnRatio) external onlyOwner {
        vBabyToken.updateBABYFeeBurnRatio(babyFeeBurnRatio);
    }

    function vBabyUpdateBABYFeeReserveRatio(uint256 babyFeeReserve) external onlyOwner {
        vBabyToken.updateBABYFeeReserveRatio(babyFeeReserve);
    }

    function vBabyUpdateTeamAddress(address team) external onlyOwner {
        vBabyToken.updateTeamAddress(team);
    }

    function vBabyUpdateTreasuryAddress(address treasury) external onlyOwner {
        vBabyToken.updateTreasuryAddress(treasury);
    }

    function vBabyUpdateReserveAddress(address newAddress) external onlyOwner {
        vBabyToken.updateReserveAddress(newAddress);
    }

    function vBabySetSuperiorMinBABY(uint256 val) external onlyOwner {
        vBabyToken.setSuperiorMinBABY(val);
    }

    function vBabySetRatioValue(uint256 ratioFee) external onlyOwner {
        vBabyToken.setRatioValue(ratioFee);
    }

    function vBabyEmergencyWithdraw() external onlyOwner {
        vBabyToken.emergencyWithdraw();
        uint currentBalance = babyToken.balanceOf(address(this));
        if (currentBalance > 0) {
            babyToken.safeTransfer(owner(), currentBalance);
        }
    }

    function vBabyTransferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "illegal newOwner");
        vBabyToken.transferOwnership(_newOwner);
    }

    function contractCall(address _contract, bytes memory _data) public onlyOwner {
        (bool success, ) = _contract.call(_data);
        require(success, "response error");
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    function babyTokenCall(bytes memory _data) external onlyOwner {
        contractCall(address(babyToken), _data);
    }

    function vBabyTokenCall(bytes memory _data) external onlyOwner {
        contractCall(address(vBabyToken), _data);
    }

    function setFarmer(address _farmer, uint _percent) external onlyOwner {
        require(_farmer != address(0), "illegal farmer");
        require(_percent <= PERCENT_BASE, "illegal percent");
        totalPercent = totalPercent.sub(farmers[_farmer]).add(_percent);
        farmers[_farmer] = _percent;
        require(totalPercent <= MAX_BORROW_PERCENT, "illegal percent value");
    }

    function addFarmer(address _farmer) external onlyOwner {
        isFarmer[_farmer] = true;
    }

    function delFarmer(address _farmer) external onlyOwner {
        isFarmer[_farmer] = false;
    }

    function borrow() external onlyFarmer returns (uint) {
        uint totalBaby = babyToken.balanceOf(address(vBabyToken)).add(totalBorrow);
        uint maxBorrow = totalBaby.mul(farmers[msg.sender]).div(PERCENT_BASE);
        if (maxBorrow > farmerBorrow[msg.sender]) {
            maxBorrow = maxBorrow.sub(farmerBorrow[msg.sender]);
        } else {
            maxBorrow = 0;
        }
        if (maxBorrow > 0) {
            farmerBorrow[msg.sender] = farmerBorrow[msg.sender].add(maxBorrow);
            vBabyToken.emergencyWithdraw();
            uint currentBalance = babyToken.balanceOf(address(this));
            require(currentBalance >= maxBorrow, "illegal baby balance");
            totalBorrow = totalBorrow.add(maxBorrow);
            babyToken.safeTransfer(msg.sender, maxBorrow);
            babyToken.safeTransfer(address(vBabyToken), currentBalance.sub(maxBorrow));
        }
        emit Borrow(msg.sender, maxBorrow, farmerBorrow[msg.sender], totalBorrow, babyToken.balanceOf(address(vBabyToken)));
        return maxBorrow;
    }

    function repay(uint _amount) external onlyFarmer returns (uint, uint) {
        babyToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint repayAmount; 
        uint donateAmount;
        if (_amount > farmerBorrow[msg.sender]) {
            repayAmount = farmerBorrow[msg.sender];
            donateAmount = _amount.sub(repayAmount);
        } else {
            repayAmount = _amount;
        }
        require(_amount == repayAmount.add(donateAmount), "repay error");
        if (repayAmount > 0) {
            totalBorrow = totalBorrow.sub(repayAmount);
            farmerBorrow[msg.sender] = farmerBorrow[msg.sender].sub(repayAmount);
            babyToken.safeTransfer(address(vBabyToken), repayAmount);
        }
        if (donateAmount > 0) {
            babyToken.approve(address(vBabyToken), donateAmount);            
            totalDonate = totalDonate.add(donateAmount);
            vBabyToken.donate(donateAmount);
        }
        emit Repay(msg.sender, repayAmount, donateAmount, farmerBorrow[msg.sender], totalBorrow, babyToken.balanceOf(address(vBabyToken)));
        return (repayAmount, donateAmount);
    }
}
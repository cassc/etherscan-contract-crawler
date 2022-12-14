// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../vouchers/IVouchers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeForVoucher is Ownable {
    event Staked(address indexed staker, uint256 indexed configIndex);
    event Unstaked(address indexed staker, uint256 indexed configIndex);

    struct StakeConfig{
        address tokenAddress;
        bool isEnabled;
        uint256 requiredAmount;
        uint256 duration;
        uint256 slotsAvailable;
        uint256 slotsMax;
        uint256 voucherTypeId;
        uint256 vouchersAmount;
    }
    mapping(uint256 => StakeConfig) public stakeConfig;
    mapping(uint256 => mapping(address => uint256)) public stakeDate;
    mapping(uint256 => mapping(address => bool)) public unstaked;
    uint256 public stakeConfigIndex;
    IVouchers public vouchers;

    function stakeDates(address adr, uint256 from, uint256 to) external view returns (uint256[] memory){
        require(to >= from, "StakeForVoucher: Sort error");
        require(to <= stakeConfigIndex, "StakeForVoucher: Not existing element");
        uint256[] memory dates = new uint256[](to-from+1);
        for(uint256 i=from; i<=to; i++){
            bool isUnstaked = unstaked[i][adr];
            dates[i-from]= isUnstaked ? 1 : stakeDate[i][adr];
        }
        return dates;
    }

    function stakeConfigs(uint256 from, uint256 to) external view returns (StakeConfig[] memory){
        require(to >= from, "StakeForVoucher: Sort error");
        require(to <= stakeConfigIndex, "StakeForVoucher: Not existing element");
        StakeConfig[] memory sc = new StakeConfig[](to-from+1);
        for(uint256 i=from; i<=to; i++){
            sc[i-from]= stakeConfig[i];
        }
        return sc;
    }

    function addStakeConfig(       
        address tokenAddress,
        bool isEnabled,
        uint256 requiredAmount,
        uint256 duration,
        uint256 slotsAvailable,
        uint256 voucherTypeId,
        uint256 vouchersAmount
    ) external onlyOwner {
        StakeConfig memory newConfig = StakeConfig(tokenAddress, isEnabled, requiredAmount, duration, slotsAvailable, slotsAvailable, voucherTypeId, vouchersAmount);
        stakeConfig[stakeConfigIndex] = newConfig;
        stakeConfigIndex++;
    }

    function editStakeConfig(
        uint256 configIndex,
        bool isEnabled,
        uint256 slotsAvailable
    )  external onlyOwner{
        require(stakeConfig[configIndex].slotsMax >= slotsAvailable, "StakeForVoucher: slotsMax limit");
        stakeConfig[configIndex].isEnabled = isEnabled;
        stakeConfig[configIndex].slotsAvailable = slotsAvailable;
    }

    function stake(uint256 configIndex) external {
        require(stakeDate[configIndex][msg.sender] == 0 && !unstaked[configIndex][msg.sender], "StakeForVoucher: Only one stake per address");
        StakeConfig memory sc = stakeConfig[configIndex];
        require(sc.isEnabled, "StakeForVoucher: Staking is disabled");
        require(sc.slotsAvailable > 0, "StakeForVoucher: No available slots");
        IERC20(sc.tokenAddress).transferFrom(msg.sender, address(this), sc.requiredAmount);
        stakeDate[configIndex][msg.sender] = block.timestamp;
        stakeConfig[configIndex].slotsAvailable--;
        bytes memory data;
        vouchers.mint(msg.sender, sc.voucherTypeId, sc.vouchersAmount, data);
        emit Staked(msg.sender, configIndex);
    }

    function unstake(uint256 configIndex) external {
        uint256 userStakeDate = stakeDate[configIndex][msg.sender];
        require(userStakeDate != 0 && !unstaked[configIndex][msg.sender], "StakeForVoucher: Stake not found");
        StakeConfig memory sc = stakeConfig[configIndex];
        require(userStakeDate + sc.duration * 1 minutes < block.timestamp, "StakeForVoucher: Withdraw before end of stake period");
        unstaked[configIndex][msg.sender]=true;
        IERC20(sc.tokenAddress).transfer(msg.sender, sc.requiredAmount);
        emit Unstaked(msg.sender, configIndex);
    }

    constructor(IVouchers vouchersAddress){
        vouchers = vouchersAddress;
    }
}
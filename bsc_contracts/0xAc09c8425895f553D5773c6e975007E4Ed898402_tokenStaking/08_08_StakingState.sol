// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingState {
    address public devAddress;
    mapping(uint => mapping(uint => address)) public investors;
    uint internal constant TIME_STEP = 1 days;
    uint internal constant HARVEST_DELAY = 1 days;
    uint internal constant BLOCK_TIME_STEP = 30 days;
    uint internal constant PERCENT_DIVIDER = 1000;
    uint internal constant REFERRER_PERCENTS = 50;

    uint public initDate;

    uint internal totalUsers;
    mapping(uint => uint) internal totalInvested;
    mapping(uint => uint) internal totalWithdrawn;
    mapping(uint => uint) internal totalReinvested;
    mapping(uint => uint) internal totalDeposits;
    mapping(uint => uint) internal totalReinvestCount;
    uint public stopProductionDate;
    bool public stopProductionVar;
    bool public referrer_is_allowed = true;

    event Paused(address account);
    event Unpaused(address account);

    modifier hasStoppedProduction() {
        require(hasStoppedProductionView(), "Production is not stopped");
        _;
    }

    modifier hasNotStoppedProduction() {
        require(!hasStoppedProductionView(), "Production is stopped");
        _;
    }

    function hasStoppedProductionView() public view returns (bool) {
        return stopProductionVar;
    }

    modifier onlyOwner() {
        require(devAddress == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(initDate > 0, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(initDate == 0, "Pausable: not paused");
        _;
    }

    function stopProduction() external onlyOwner {
        stopProductionVar = true;
        stopProductionDate = block.timestamp;
    }

    function unpause() external whenPaused onlyOwner {
        initDate = block.timestamp;
        emit Unpaused(msg.sender);
    }

    function isPaused() public view returns (bool) {
        return initDate == 0;
    }

    function getDAte() external view returns (uint) {
        return block.timestamp;
    }

    function getPublicData(uint _pool)
        external
        view
        returns (
            uint totalUsers_,
            uint totalInvested_,
            uint totalDeposits_,
            uint totalReinvested_,
            uint totalReinvestCount_,
            uint totalWithdrawn_,
            bool isPaused_
        )
    {
        totalUsers_ = totalUsers;
        totalInvested_ = totalInvested[_pool];
        totalDeposits_ = totalDeposits[_pool];
        totalReinvested_ = totalReinvested[_pool];
        totalReinvestCount_ = totalReinvestCount[_pool];
        totalWithdrawn_ = totalWithdrawn[_pool];
        isPaused_ = isPaused();
    }

    function getAllInvestors(
        uint _pool
    ) external view returns (address[] memory) {
        address[] memory investorsList = new address[](totalUsers);
        for (uint i = 0; i < totalUsers; i++) {
            investorsList[i] = investors[_pool][i];
        }
        return investorsList;
    }

    function getInvestorByIndex(
        uint _pool,
        uint index
    ) external view returns (address) {
        require(index < totalUsers, "Index out of range");
        return investors[_pool][index];
    }

    function setReferrerIsAllowed(
        bool _referrer_is_allowed
    ) external onlyOwner {
        referrer_is_allowed = _referrer_is_allowed;
    }
}
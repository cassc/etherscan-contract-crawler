// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/access/Ownable.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/Address.sol";
import "./interfaces/IPool.sol";

contract SellTaxDistributor is Ownable, ReentrancyGuard {
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using Address for address payable;

    //---------- Variables ----------//
    IPool public pool;
    uint256 public minDistribution;
    address payable public team;

    //---------- Storage -----------//
    struct Fees {
        uint256 Stake;
        uint256 Team;
    }

    Fees public beneficiariesFees;

    //---------- Events -----------//
    event ProfitsDestributed(uint256 Stake, uint256 Team);

    //---------- Constructor ----------//
    constructor(address _pool) public {
        pool = IPool(_pool);
        team = msg.sender;
        minDistribution = 1 ether;
        beneficiariesFees.Stake = 2000; // 20%
        beneficiariesFees.Team = 8000; // 80%
    }

    //----------- Internal Functions -----------//
    function _distributeProfits() internal {
        uint256 amount = balanceBNB();
        uint256 toStake = (amount * beneficiariesFees.Stake) / 10000;
        uint256 toTeam = amount.sub(toStake);
        pool.deposit{value: toStake}();
        team.sendValue(toTeam);
        emit ProfitsDestributed(toStake, toTeam);
    }

    //----------- External Functions -----------//
    fallback() external {}

    receive() external payable {}

    function balanceBNB() public view returns (uint256) {
        return address(this).balance;
    }

    function canDistribute() public view returns (bool) {
        uint256 amount = balanceBNB();
        uint256 staked = pool.totalStaked();
        return amount >= minDistribution && staked > 0;
    }

    function distribute() external nonReentrant {
        require(canDistribute(), "Balance too low");
        _distributeProfits();
    }

    function setBeneficiaries(address _Stake, address _Team)
        external
        onlyOwner
    {
        require(_Stake != address(0) && _Team != address(0), "Invalid address");
        pool = IPool(_Stake);
        team = payable(_Team);
    }

    function setBeneficiariesFee(uint256 _Stake, uint256 _Team)
        external
        onlyOwner
    {
        require(_Stake != 0 && _Team != 0, "Invalid amounts");
        require(_Stake + _Team == 10000, "Fees out of bounds");
        beneficiariesFees.Stake = _Stake;
        beneficiariesFees.Team = _Team;
    }

    function setMinDistribution(uint256 _min) external onlyOwner {
        require(_min >= 1 gwei);
        minDistribution = _min;
    }
}
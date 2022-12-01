// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBEP20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IDinostaking.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Context.sol";
import "./libraries/Auth.sol";
contract RouterDinoStaking is Context, Auth {
    using SafeMath for uint256;

    address public wbnbAddress;

    address public manualStakingAddress;
    address public autoStakingAddress;
    address public tokenAddress;

    uint256 public percentDenominator = 10000;
    uint256 public percentAutoStaking = 5000;
    uint256 public percentManualStaking = 5000;

    event Deposit(address account, uint256 amount);
    event Stake(address account, uint256 amount);
    event UnStake(address account, uint256 amount);

    constructor(address _tokenAddress,address _wbnbAddress) Auth(msg.sender) {
        tokenAddress = _tokenAddress;
        wbnbAddress = _wbnbAddress;
    }

    receive() external payable {}

    function deposit(uint256 loop) public payable {
        if(autoStakingAddress != address(0) && manualStakingAddress != address(0)){
            uint256 supplyAuto = IBEP20(autoStakingAddress).totalSupply();
            uint256 supplyManual = IBEP20(manualStakingAddress).totalSupply();
            uint256 amountDeposit = msg.value;
            if(supplyAuto > 0) {   
                // uint256 amountAuto = (supplyAuto.mul(percentDenominator).div(supplyAuto.add(supplyManual))).mul(msg.value).div(percentDenominator);
                uint256 amountAuto = amountDeposit.mul(percentAutoStaking).div(percentDenominator);
                IDinostaking(autoStakingAddress).deposit{value:amountAuto}(loop);
            }
            if(supplyManual > 0){
                // uint256 amountManual = (supplyManual.mul(percentDenominator).div(supplyAuto.add(supplyManual))).mul(msg.value).div(percentDenominator);
                uint256 amountManual = amountDeposit.mul(percentManualStaking).div(percentDenominator);
                IDinostaking(manualStakingAddress).deposit{value:amountManual}(loop);
            }
        }
    }

    function setPercentDistribution(uint256 percentAuto, uint256 percentManual) public onlyOwner{
        percentAutoStaking = percentAuto;
        percentManual = percentManual;
        require(percentManual+percentAuto == percentDenominator,"Should be 10000");
    }

    function depositWithOther(address token, uint256 amount) external {

    }

    function stake(address stakingAddress, address account, uint256 amount) external {
        IBEP20(tokenAddress).transferFrom(_msgSender(),address(this),amount);
        IBEP20(tokenAddress).approve(stakingAddress,amount);
        IDinostaking(stakingAddress).stake(account,amount);
    }

    function unstake(address stakingAddress, address account,uint256 amount) external {
        IBEP20(stakingAddress).transferFrom(_msgSender(),address(this),amount);
        IDinostaking(stakingAddress).unstake(account,amount);
    }


    function claimToEth(address stakingAddress, address account) external {
        IDinostaking(stakingAddress).claimToEth(account);
    }

    function claimToOther(address stakingAddress, address account, address targetToken) external {
        // tobe update
        IDinostaking(stakingAddress).claimToOther(account,targetToken);
    }

    function setWbnbAddress(address _wbnbAddress) external onlyOwner {
        wbnbAddress = _wbnbAddress;
    }

    function setStakingAddress(address _manual, address _auto) external onlyOwner {
        manualStakingAddress = _manual;
        autoStakingAddress = _auto;
    }

    function claimWeth(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function claimFromContract(address _tokenAddress, address to, uint256 amount) external onlyOwner {
        IBEP20(_tokenAddress).transfer(to, amount);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFraxFarmERC20.sol";
import "./interfaces/IConvexWrapper.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


    
contract GaugeExtraRewardDistributor {
    using SafeERC20 for IERC20;

    address public farm;
    address public wrapper;

    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    event Recovered(address _token, uint256 _amount);
    event Distributed(address _token, uint256 _rate);

    constructor(){}

    function initialize(address _farm, address _wrapper) external {
        require(farm == address(0),"init fail");

        farm = _farm;
        wrapper = _wrapper;
    }

    //owner is farm owner
    modifier onlyOwner() {
        require(msg.sender == IFraxFarmERC20(farm).owner(), "!owner");
        _;
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != crv && _tokenAddress != cvx, "invalid");
        IERC20(_tokenAddress).safeTransfer(IFraxFarmERC20(farm).owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    // Add a new reward token to be distributed to stakers
    function distributeReward(address _farm) external{
        //only allow farm to call
        require(msg.sender == farm);
        
        //get rewards
        IConvexWrapper(wrapper).getReward(_farm);

        //get last period update from farm and figure out period
        uint256 duration = IFraxFarmERC20(_farm).rewardsDuration();
        uint256 periodLength = ((block.timestamp + duration) / duration) - IFraxFarmERC20(_farm).periodFinish();

        //reward tokens on farms are constant so dont need to loop, just distribute crv and cvx
        uint256 balance = IERC20(crv).balanceOf(address(this));
        uint256 rewardRate = IERC20(crv).balanceOf(address(this)) / periodLength;
        if(balance > 0){
            IERC20(crv).transfer(farm, balance);
        }
        //if balance is 0, still need to call so reward rate is set to 0
        IFraxFarmERC20(_farm).setRewardVars(crv, rewardRate, address(0), address(this));
        emit Distributed(crv, rewardRate);

        balance = IERC20(cvx).balanceOf(address(this));
        rewardRate = IERC20(cvx).balanceOf(address(this)) / periodLength;
        if(balance > 0){
            IERC20(cvx).transfer(farm, balance);
        }
        IFraxFarmERC20(_farm).setRewardVars(cvx, rewardRate, address(0), address(0)); //keep distributor 0 since its shared
        emit Distributed(cvx, rewardRate);
    }
}
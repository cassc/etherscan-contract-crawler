// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Staker.sol";
//import "hardhat/console.sol";

contract StakeFactory
{
    using SafeERC20 for IERC20;
    address public main;
    IERC20 public token;
    mapping(address => address[]) stakers;
    uint fee;
    error InvalidOffsetLimit(uint offset, uint limit);
    constructor(address _main){
        main = _main;
        fee = IMain(main).fee();
        token = IERC20(main);
        token.totalSupply();
    }
    function stakeFactory(uint amount, uint term) external payable {
        Staker staker = new Staker(msg.sender, main);
        stakers[msg.sender].push(address(staker));
        token.safeTransferFrom(msg.sender, address(staker), amount);
        staker.stake{value : fee}(amount, term);
    }

    function getUserStakes(address user) public view returns (address[] memory){
        return stakers[user];
    }

    function getUserStakeInfo(address user, uint offset, uint limit) public view returns (IMain.StakeInfo[] memory){
        IMain.StakeInfo[] memory stakerInfo = new IMain.StakeInfo[](limit);
        for( uint i = offset ; i < limit ; ++ i ){
            Staker staker = Staker(stakers[user][i]);
            stakerInfo[i] = staker.getUserStakeInfo();
        }
        return stakerInfo;
    }

    function stake(uint256 i, uint256 amount, uint256 term) external payable{
        Staker staker = Staker(stakers[msg.sender][i]);
        IMain.StakeInfo memory stakerInfo = staker.getUserStakeInfo();
        IERC20(main).safeTransferFrom(msg.sender, address(staker), amount);
        staker.stake{value : fee}(amount, term);
    }

    function withdraw(uint offset, uint limit) external payable{
        if( offset >= limit || limit == 0 )
            revert InvalidOffsetLimit(offset, limit);
        for( uint i = offset ; i < limit ; ++ i ){
            Staker staker = Staker(stakers[msg.sender][i]);
            IMain.StakeInfo memory stakerInfo = staker.getUserStakeInfo();
            if( stakerInfo.amount == 0 )
                continue;
            staker.withdraw{value : fee}();
        }
    }
}
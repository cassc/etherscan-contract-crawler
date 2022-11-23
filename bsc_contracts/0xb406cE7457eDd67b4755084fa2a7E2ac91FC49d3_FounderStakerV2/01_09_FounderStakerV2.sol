pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPigPen.sol";

contract FounderStakerV2 is Ownable {
    using SafeERC20 for IERC20;

    IERC20  public pigsV2Token = IERC20(0x9a3321E1aCD3B9F6debEE5e042dD2411A1742002);
    IPigPen public PigPen = IPigPen(0x1f8a98bE5C102D145aC672ded99C5bE0330d7e4F);
    bool public shouldAutoCompound = true;
    uint256 public depositThreshold = 1e18;

    event FounderDeposit(address indexed user, uint256 amount);
    event FounderHarvest();
    event FounderWithdraw(address indexed user);
    event FounderEmergencyWithdraw(address indexed user);

    constructor(){
        pigsV2Token.approve(address(PigPen), type(uint256).max);
    }

    function depositFounderPigs() external  {
        uint256 balance = pigsV2Token.balanceOf(address(this));
        if (balance > depositThreshold){
        PigPen.claimRewards(shouldAutoCompound);
        PigPen.deposit(balance);
            emit FounderDeposit(address(this), balance);    
        }
    }

    function claimRewards(bool _shouldCompound) external onlyOwner {
        PigPen.claimRewards(_shouldCompound);
        emit FounderHarvest();
    }

    function withdrawTokens(address _token, uint256 _amount, address _to) external onlyOwner {
        require(_token != address(pigsV2Token), "cant withdraw pigs");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function burnTokens(uint256 _amount) external onlyOwner {
        IERC20(pigsV2Token).safeTransfer(0x000000000000000000000000000000000000dEaD, _amount);
    }

    function withdrawFromPigsPen() external onlyOwner{
        PigPen.withdraw();
    }

    // ADMIN FUNCTIONS
    function setPigPenAddress(IPigPen _pigpen) external onlyOwner {
        require(address(_pigpen) != address(0), 'zero address');
        PigPen = _pigpen;
        pigsV2Token.approve(address(_pigpen), type(uint256).max);
    }

    function setPigsToken(IERC20 _pigsToken) external onlyOwner {
        require(address(_pigsToken) != address(0), 'zero address');
        require(address(pigsV2Token) == address(0),"pigs token already set");
        pigsV2Token = _pigsToken;
        pigsV2Token.approve(address(PigPen), type(uint256).max);
    }

    function updateDepositThreshold(uint256 _depositThreshold) external onlyOwner {
        depositThreshold = _depositThreshold;
    }

    function updateShouldCompound(bool _shouldAutoCompound) external onlyOwner {
        shouldAutoCompound = _shouldAutoCompound;
    }

}
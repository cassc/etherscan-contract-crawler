// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFeeReceiver.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IBooster.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';



contract FeeDepositV2 {
    using SafeERC20 for IERC20;

    //tokens
    address public constant fpis = address(0xc2544A32872A91F4A553b404C6950e89De901fdb);
    address public immutable vefpisProxy;
    address public immutable cvxFpis;
    
    address public constant owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);

    uint256 public constant denominator = 10000;
    uint256 public platformIncentive = 1000;
    address public platformReceiver;
    address public cvxfpisReceiver;

    mapping(address => bool) public requireProcessing;

    event SetPlatformIncentive(uint256 _amount);
    event SetPlatformReceiver(address _account);
    event SetCvxFpisReceiver(address _account);
    event AddDistributor(address indexed _distro, bool _valid);
    event PlatformFeesDistributed(address indexed token, uint256 amount);
    event RewardsDistributed(address indexed token, uint256 amount);

    constructor(address _proxy, address _cvxfpis, address _initialReceiver) {
        vefpisProxy = _proxy;
        cvxFpis = _cvxfpis;
        platformReceiver = address(0x1389388d01708118b497f59521f6943Be2541bb7);
        cvxfpisReceiver = _initialReceiver;
        requireProcessing[_initialReceiver] = true;
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(vefpisProxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setPlatformIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 5000, "too high");
        platformIncentive = _incentive;
        emit SetPlatformIncentive(_incentive);
    }

    function cvxfpisIncentive() external view returns(uint256){
        return denominator - platformIncentive;
    }

    function setPlatformReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        platformReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetPlatformReceiver(_receiver);
    }

    function setCvxFpisReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        cvxfpisReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetCvxFpisReceiver(_receiver);
    }

    function rescueToken(address _token, address _to) external onlyOwner{
        require(_token != fpis, "not allowed");

        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, bal);
    }

    function processFees() external {
        require(msg.sender == IVoterProxy(vefpisProxy).operator(), "!auth");

        //get reward amounts
        uint256 platformAmount = IERC20(fpis).balanceOf(address(this)) * platformIncentive / denominator;

        //process other incentives
        if(platformAmount > 0){
            IERC20(fpis).safeTransfer(platformReceiver, platformAmount);
            if(requireProcessing[platformReceiver]){
                IFeeReceiver(platformReceiver).processFees();
            }
            emit PlatformFeesDistributed(fpis,platformAmount);
        }

        //send rest to cvxfpis incentives
        uint256 fpisbalance = IERC20(fpis).balanceOf(address(this));
        IERC20(fpis).safeTransfer(cvxfpisReceiver, fpisbalance);
        if(requireProcessing[cvxfpisReceiver]){
            IFeeReceiver(cvxfpisReceiver).processFees();
        }

        emit RewardsDistributed(fpis, fpisbalance);
    }

}
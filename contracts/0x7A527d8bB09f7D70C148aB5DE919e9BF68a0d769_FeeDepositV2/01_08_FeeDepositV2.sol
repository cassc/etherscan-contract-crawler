// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFxsDepositor.sol";
import "./interfaces/IFeeRegistry.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/IFeeReceiver.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';



contract FeeDepositV2 {
    using SafeERC20 for IERC20;

    //tokens
    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant cvxFxs = address(0xFEEf77d3f69374f66429C91d732A244f074bdf74);

    //convex addresses
    address public constant cvxFxsPoolStash = address(0x4f3AD55D7b884CDC48ADD1e2451A13af17887F26);
    address public constant fxsDeposit = address(0x8f55d7c21bDFf1A51AFAa60f3De7590222A3181e);
    address public constant feeRegistry = address(0xC9aCB83ADa68413a6Aa57007BC720EE2E2b3C46D);
    address public constant vlcvx = address(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);
    
    address public constant owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);

    uint256 public constant denominator = 10000;
    uint256 public callIncentive = 100;
    address public platformReceiver;
    address public vlcvxReceiver;
    bool public convertVlcvxRewards;
    address public cvxfxsReceiver;

    mapping(address => bool) public distributors;
    mapping(address => bool) public requireProcessing;
    bool public UseDistributors = true;

    event SetCallIncentive(uint256 _amount);
    event SetPlatformReceiver(address _account);
    event SetVlcvxReceiver(address _account);
    event SetCvxFxsReceiver(address _account);
    event AddDistributor(address indexed _distro, bool _valid);
    event RewardsDistributed(address indexed token, uint256 amount);

    constructor() {
        distributors[msg.sender] = true;
        IERC20(fxs).approve(fxsDeposit, type(uint256).max);
        IERC20(cvxFxs).approve(vlcvx, type(uint256).max);
    }

    function setCallIncentive(uint256 _incentive) external {
        require(msg.sender == owner, "!auth");
        require(_incentive <= 100, "too high");
        callIncentive = _incentive;
        emit SetCallIncentive(_incentive);
    }

    function setPlatformReceiver(address _receiver, bool _requireProcess) external {
        require(msg.sender == owner, "!auth");
        platformReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetPlatformReceiver(_receiver);
    }

    function setVlcvxReceiver(address _receiver, bool _requireProcess, bool _convert) external {
        require(msg.sender == owner, "!auth");
        vlcvxReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        convertVlcvxRewards = _convert;
        emit SetVlcvxReceiver(_receiver);
    }

    function setCvxFxsReceiver(address _receiver, bool _requireProcess) external {
        require(msg.sender == owner, "!auth");
        cvxfxsReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetCvxFxsReceiver(_receiver);
    }

    function setDistributor(address _distro, bool _valid) external {
        require(msg.sender == owner, "!auth");
        distributors[_distro] = _valid;
        emit AddDistributor(_distro, _valid);
    }

    function setUseDistributorList(bool _use) external {
        require(msg.sender == owner, "!auth");
        UseDistributors = _use;
    }

    function rescueToken(address _token, address _to) external {
        require(msg.sender == owner, "!auth");
        require(_token != fxs && _token != cvxFxs, "not allowed");

        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, bal);
    }

    function distribute() external {
        if(UseDistributors){
            require(distributors[msg.sender], "!auth");
        }

        uint256 fxsbalance = IERC20(fxs).balanceOf(address(this));
        uint256 incentiveAmount = fxsbalance * callIncentive / denominator;

        //remove call incentive first
        fxsbalance -= incentiveAmount;

        //get reward amounts
        uint256 totalFees = IFeeRegistry(feeRegistry).totalFees();
        uint256 cvxRewards = fxsbalance * IFeeRegistry(feeRegistry).cvxIncentive() / totalFees;
        uint256 platformRewards = fxsbalance * IFeeRegistry(feeRegistry).platformIncentive() / totalFees;
        

        //process distro fees
        if(incentiveAmount > 0){
            IERC20(fxs).safeTransfer(msg.sender, incentiveAmount);
        }

        //process vlcvx rewards
        if(cvxRewards > 0 && convertVlcvxRewards){
            //convert to cvxfxs
            IFxsDepositor(fxsDeposit).deposit(cvxRewards, true);
            //send to vlcvx
            IRewards(vlcvx).notifyRewardAmount(cvxFxs, cvxRewards);
        }else if(cvxRewards > 0){
            //vanilla transfer
            IERC20(fxs).safeTransfer(vlcvxReceiver, cvxRewards);
            if(requireProcessing[vlcvxReceiver]){
                IFeeReceiver(vlcvxReceiver).processFees();
            }
        }

        //process platform rewards
        if(platformRewards > 0){
            IERC20(fxs).safeTransfer(platformReceiver, platformRewards);
            if(requireProcessing[platformReceiver]){
                IFeeReceiver(platformReceiver).processFees();
            }
        }

        //send rest to cvxfxs incentives
        IERC20(fxs).safeTransfer(cvxfxsReceiver, IERC20(fxs).balanceOf(address(this)));
        if(requireProcessing[cvxfxsReceiver]){
            IFeeReceiver(cvxfxsReceiver).processFees();
        }

        emit RewardsDistributed(fxs, fxsbalance);
    }

}
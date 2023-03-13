pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable-v6/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v6/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v6/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v6/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable-v6/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v6/utils/AddressUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


import "../interfaces/IController.sol";
import "../interfaces/Token.sol";
import "../interfaces/MasterChef.sol";



contract StrategySishiTokenToken is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;


    address public rewardToken;
    address public masterChef;
    address public uniswapRouter;

    address public want;
    address public tokenA;
    address public tokenB;
    uint256 public masterChefPid;
    address[] public rewardToTokenAPath;

    address public governance;
    address public controller;
    address public strategist;

    uint256 public performanceFee;
    uint256 public strategistReward;
    uint256 public withdrawalFee;
    uint256 public harvesterReward;
    uint256 public buyBackAndBurnFee;
    address[] public buyBackAndBurnPath;


    uint256 public constant FEE_DENOMINATOR = 10000;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bool public paused;

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _rewardToken,
        address _masterChef,
        address _want,
        address _tokenA,
        address _tokenB,
        uint256 _masterChefPid,
        address _uniswapRouter,
        address[] memory _rewardToTokenAPath,
        address[] memory _buyBackAndBurnPath
    ) public initializer {
        performanceFee = 950;
        strategistReward = 50;
        withdrawalFee = 50;
        harvesterReward = 30;
        buyBackAndBurnFee = 0;
        
        
        want = _want;
        tokenA = _tokenA;
        tokenB = _tokenB;
        rewardToTokenAPath = _rewardToTokenAPath;


        rewardToken = _rewardToken;
        masterChef = _masterChef;
        masterChefPid = _masterChefPid;
        uniswapRouter = _uniswapRouter;
        buyBackAndBurnPath = _buyBackAndBurnPath;

        governance = _governance;
        strategist = _strategist;
        controller = _controller;
    }

    function getName() external pure returns (string memory) {
        return "StrategySishiTokenToken";
    }

    function deposit() external {
      _stakeWant(false);
    }

    function _stakeWant(bool _force) internal {
      if(paused) return;
      uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
      if (_want > 0) {
        IERC20Upgradeable(want).safeApprove(masterChef, 0);
        IERC20Upgradeable(want).safeApprove(masterChef, _want);
      }
      if (_want > 0 || _force) {
        MasterChef(masterChef).deposit(masterChefPid, _want);
      }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20Upgradeable _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
      require(msg.sender == controller, "!controller");
      uint256 _balance = IERC20Upgradeable(want).balanceOf(address(this));
      if (_balance < _amount) {
          _amount = _withdrawSome(_amount.sub(_balance));
          _amount = _amount.add(_balance);
      }

      uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);
      IERC20Upgradeable(want).safeTransfer(IController(controller).rewards(), _fee);
      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20Upgradeable(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
      MasterChef(masterChef).withdraw(masterChefPid, _amount);

      return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
      require(msg.sender == controller, "!controller");
      _withdrawAll();

      balance = IERC20Upgradeable(want).balanceOf(address(this));

      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20Upgradeable(want).safeTransfer(_vault, balance);

      //waste not - send dust tokenA to rewards
      IERC20Upgradeable(tokenA).safeTransfer(IController(controller).rewards(),
          IERC20Upgradeable(tokenA).balanceOf(address(this))
        );

    }

    function _withdrawAll() internal {
      MasterChef(masterChef).emergencyWithdraw(masterChefPid);
    }

    function _convertRewardToWant() internal {
      if(rewardToken != tokenA) {
        uint256 rewardAmount = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        if(rewardAmount > 0 ) {
          IERC20Upgradeable(rewardToken).safeApprove(uniswapRouter, 0);
          IERC20Upgradeable(rewardToken).safeApprove(uniswapRouter, rewardAmount);

          IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(rewardAmount, uint256(0), rewardToTokenAPath, address(this), now.add(1800));
        }
      }
      uint256 _tokenA = IERC20Upgradeable(tokenA).balanceOf(address(this));
      if(_tokenA > 0 ) {
        //convert tokenA
        IERC20Upgradeable(tokenA).safeApprove(uniswapRouter, 0);
        IERC20Upgradeable(tokenA).safeApprove(uniswapRouter, _tokenA.div(2));

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_tokenA.div(2), uint256(0), path, address(this), now.add(1800));

        //add liquidity
        _tokenA = IERC20Upgradeable(tokenA).balanceOf(address(this));
        uint256 _tokenB = IERC20Upgradeable(tokenB).balanceOf(address(this));

        IERC20Upgradeable(tokenA).safeApprove(uniswapRouter, 0);
        IERC20Upgradeable(tokenA).safeApprove(uniswapRouter, _tokenA);
        IERC20Upgradeable(tokenB).safeApprove(uniswapRouter, 0);
        IERC20Upgradeable(tokenB).safeApprove(uniswapRouter, _tokenB);

        IUniswapV2Router02(uniswapRouter).addLiquidity(
          tokenA, // address tokenA,
          tokenB, // address tokenB,
          _tokenA, // uint amountADesired,
          _tokenB, // uint amountBDesired,
          0, // uint amountAMin,
          0, // uint amountBMin,
          address(this), // address to,
          now.add(1800)// uint deadline
        );
      }
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function balanceOfStakedWant() public view returns (uint256) {
      (uint256 _amount,) = MasterChef(masterChef).userInfo(masterChefPid,address(this));
      return _amount;
    }

    function _buybackAndBurn(uint256 _rewardAmount) internal {
      if(_rewardAmount > 0 && buyBackAndBurnPath.length > 1) {
        IERC20Upgradeable(rewardToken).safeApprove(uniswapRouter, 0);
        IERC20Upgradeable(rewardToken).safeApprove(uniswapRouter, _rewardAmount);

        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_rewardAmount, uint256(0), buyBackAndBurnPath, BURN_ADDRESS, now.add(1800));
      }
    }


    function harvest() external returns (uint harvesterRewarded) {
      require(msg.sender == tx.origin, "not eoa");

      _stakeWant(true);

      uint rewardAmount = IERC20Upgradeable(rewardToken).balanceOf(address(this)); 
      uint256 _harvesterReward;
      if (rewardAmount > 0) {
        if(performanceFee > 0){
          uint256 _fee = rewardAmount.mul(performanceFee).div(FEE_DENOMINATOR);
          IERC20Upgradeable(rewardToken).safeTransfer(IController(controller).rewards(), _fee);
        }

        if(strategistReward > 0){
          uint256 _reward = rewardAmount.mul(strategistReward).div(FEE_DENOMINATOR);
          IERC20Upgradeable(rewardToken).safeTransfer(strategist, _reward);
        }

        if(buyBackAndBurnFee > 0){
          uint256 _buybackfee = rewardAmount.mul(buyBackAndBurnFee).div(FEE_DENOMINATOR);
          _buybackAndBurn(_buybackfee);
        }

        if(harvesterReward > 0) {
          _harvesterReward = rewardAmount.mul(harvesterReward).div(FEE_DENOMINATOR);
          IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, _harvesterReward);
        }
      }

      _convertRewardToWant();
      _stakeWant(false);

      return _harvesterReward;
    }

    function balanceOf() external view returns (uint256) {
      return balanceOfWant()
        .add(balanceOfStakedWant());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setHarvesterReward(uint256 _harvesterReward) external {
        require(msg.sender == governance, "!governance");
        harvesterReward = _harvesterReward;
    }


    function setBuyBackAndBurnFee(uint256 _buyBackAndBurnFee) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        buyBackAndBurnFee = _buyBackAndBurnFee;
    }

    function setUniswapRouter(address _uniswapRouter) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        uniswapRouter = _uniswapRouter;
    }

    function setRewardToTokenAPath(address[] memory _rewardToTokenAPath) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        rewardToTokenAPath = _rewardToTokenAPath;
    }

    function setBuyBackAndBurnPath(address[] memory _buyBackAndBurnPath) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        buyBackAndBurnPath = _buyBackAndBurnPath;
    }

    function pause() external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        _withdrawAll();
        paused = true;
    }

    function unpause() external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        paused = false;
        _stakeWant(false);
    }


    //In case anything goes wrong - Swipe Swap has migrator function and we have no guarantees how it might be used.
    //This does not increase user risk. Governance already controls funds via strategy upgrade, and is behind timelock and/or multisig.
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        return returnData;
    }
}
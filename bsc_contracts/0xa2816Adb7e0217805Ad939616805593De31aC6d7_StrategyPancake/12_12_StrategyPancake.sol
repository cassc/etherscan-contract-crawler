// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./interfaces/ILeechSwapper.sol";
import "./interfaces/IMasterchef.sol";
import "./interfaces/IStrategyPancake.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StrategyPancake is Ownable, Pausable, IStrategyPancake {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leechswapper.
    address public swapper;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    ///@notice Address LeechRouter's base token.
    address public baseToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; 

    address public USDT = 0x55d398326f99059fF775485246999027B3197955;

    ///@notice The strategy's staking token.
    address public lp = 0xEc6557348085Aa57C72514D67070dC863C0a5A8c;

    ///@notice Address of Pancakeswap's Masterchef.
    address public masterchef = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;

    ///@notice Farm reward token.
    address public cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%. 
    uint256 public constant MAX_FEE = 1200;

    ///@notice Id of the farm pool. 
    uint8 public poolId;

    ///@notice Token swap path.
    address[] public pathCakeToBase = [cake, baseToken];

    ///@notice Token swap path.
    address[] public token0toBasePath = [USDT, baseToken];

     ///@notice Token swap path.
    address[] public token1toBasePath = [baseToken];

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller) revert UnauthorizedCaller(msg.sender);
        _;
    }

    constructor(address _swapper, address _controller, address _router, uint256 _fee, uint8 _poolId){
        swapper = _swapper;
        controller = _controller;
        router = _router;
        protocolFee = _fee;
        poolId = _poolId;
        IERC20(lp).safeApprove(masterchef, type(uint256).max);
        IERC20(baseToken).safeApprove(swapper, type(uint256).max);
        IERC20(lp).safeApprove(swapper, type(uint256).max);
        IERC20(cake).safeApprove(swapper, type(uint256).max);

    }

     /**
     * @notice Re-invests rewards. 
     */ 

    function autocompound() external whenNotPaused {
        IMasterchef(masterchef).deposit(poolId, 0);
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        ILeechSwapper(swapper).swap(cakeBal, pathCakeToBase);
        deposit();
        emit Compounded(cakeBal, block.timestamp);
    }

    /**
     * @notice Withdrawing staking token (LP) from the strategy.
     * @dev Can only be called by LeechRouter.
     * @param _amountLP Amount of the LP token to be withdrawn.
     * @param toWithdraw Amount of the base token returned to LeechRouter.
     */
    function withdraw(uint256 _amountLP) external whenNotPaused returns (uint256 toWithdraw){
        if (msg.sender != router) revert UnauthorizedCaller(msg.sender);
        uint256 pairBal = IERC20(lp).balanceOf(address(this));

        if (pairBal < _amountLP) {
            IMasterchef(masterchef).withdraw(poolId, _amountLP.sub(pairBal));
            pairBal = IERC20(lp).balanceOf(address(this));
        }

        if (pairBal > _amountLP) {
            pairBal = _amountLP;
        }
        ILeechSwapper(swapper).leechOut(pairBal, lp, token0toBasePath, token1toBasePath);
        uint256 amountBaseToken = IERC20(baseToken).balanceOf(address(this));
        uint256 fee = amountBaseToken.mul(protocolFee).div(10000);
        IERC20(baseToken).safeTransfer(treasury, fee);
        toWithdraw = amountBaseToken.sub(fee);
        IERC20(baseToken).safeTransfer(router, toWithdraw);
        return toWithdraw;
        emit Withdrawn(_amountLP, amountBaseToken);
    }

    /**
     * @notice Pause the contract's activity
     * @dev Only the owner or the controller can pause the contract's activity.
     */
    function pause() external onlyOwnerOrController {
        _pause();
    }

    /**
     * @notice Unpause the contract's activity
     * @dev Only the owner can unpause the contract's activity.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Sets fee taken by the Leech protocol.
     * @dev Only owner can set the protocol fee.
     * @param _fee Fee value.
     */
    function setFee(uint256 _fee) external onlyOwner{
        if (_fee > MAX_FEE) revert WrongAmount();
        protocolFee = _fee;
    }

    /**
     * @notice Sets the tresury address
     * @dev Only owner can set the treasury address
     * @param _treasury The address to be set.  
     */
    function setTreasury(address _treasury) external onlyOwner{
        if (_treasury == address(0)) revert ZeroAddressAsInput();
        treasury = _treasury;
    }

    /**
     * @notice Sets the controller address
     * @dev Only owner can set the controller address
     * @param _controller The address to be set.  
     */
    function setController(address _controller) external onlyOwner{
        if (_controller == address(0)) revert ZeroAddressAsInput();
        controller = _controller;
    }

    
    /**
     * @notice Sets address of LeechSwapper and gives token approves to it. 
     * @dev Only owner can set the swapper address
     * @param _swapper The address to be set.  
     */
    function setSwapper(address _swapper) external onlyOwner {
        if (_swapper == address(0)) revert ZeroAddressAsInput();
        swapper = _swapper;
        IERC20(baseToken).safeApprove(_swapper, type(uint256).max);
        IERC20(lp).safeApprove(_swapper, type(uint256).max);
        IERC20(cake).safeApprove(_swapper, type(uint256).max);
    }


    /**
     * @notice Allows the owner to withdraw stuck tokens from the contract's balance. 
     * @dev Only owner can withdraw tokens. 
     * @param _token Address of the token to be withdrawn.
     * @param _amount Amount to be withdrawn. 
     */
    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Depositing into the farm pool.
     */
    function deposit() public whenNotPaused {
        if (msg.sender != router) revert UnauthorizedCaller(msg.sender);
        uint256 baseBal = IERC20(baseToken).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = USDT;
        ILeechSwapper(swapper).leechIn(baseBal, lp, path);
        uint256 pairBal = IERC20(lp).balanceOf(address(this));
        if (pairBal > 0) {
            IMasterchef(masterchef).deposit(poolId, pairBal);
        }
        emit Deposited(pairBal);
    }

}
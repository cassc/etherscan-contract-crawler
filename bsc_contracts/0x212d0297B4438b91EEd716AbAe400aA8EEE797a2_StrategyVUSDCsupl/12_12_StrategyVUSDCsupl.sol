// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./interfaces/ILeechSwapper.sol";
import "./interfaces/IStrategyVUSDCsupl.sol";
import "./interfaces/IVUSDC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StrategyVUSDCsupl is Ownable, Pausable, IStrategyVUSDCsupl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leechswapper.
    address public swapper;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    ///@notice Address LeechRouter's base token.
    address constant public baseToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; 

    ///@notice Reward token.
    address constant public xvs = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;

    ///@notice Venus pool
    address constant public vusdc = 0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8;

    ///@notice WBNB address.
    address constant public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%. 
    uint256 public constant MAX_FEE = 1200;

    ///@notice Token swap path
    address[] public venusToBasePath = [xvs, wbnb, baseToken];

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller) revert UnauthorizedCaller(msg.sender);
        _;
    }

    constructor(address _swapper, address _controller, address _router, uint256 _fee){
        swapper = _swapper;
        controller = _controller;
        router = _router;
        protocolFee = _fee;
        IERC20(baseToken).safeApprove(vusdc, type(uint256).max);
        IERC20(xvs).safeApprove(swapper, type(uint256).max);
    }

    /**
     * @notice Redeems the requested amount of vUSDC. Received USDC is sent back to LeechRouter.
     * @param _amountVUSDC Amount of vUSDC to be redeemed. 
     */
    function withdraw(uint256 _amountVUSDC) external whenNotPaused returns (uint256 toWithdraw){
        if (msg.sender != router) revert UnauthorizedCaller(msg.sender);
        IVUSDC(vusdc).redeem(_amountVUSDC);
        uint256 amountXvs = IERC20(xvs).balanceOf(address(this));
        if (amountXvs > 0) {
            ILeechSwapper(swapper).swap(amountXvs, venusToBasePath);
        }
        uint256 baseBal = IERC20(baseToken).balanceOf(address(this));
        uint256 fee = baseBal.mul(protocolFee).div(10000);
        IERC20(baseToken).safeTransfer(treasury, fee);
        toWithdraw = baseBal.sub(fee);
        IERC20(baseToken).safeTransfer(router, toWithdraw);
        return toWithdraw;
        emit Withdrawn(toWithdraw);
    }

    /**
     * @notice Claimins rewards and re-invests them.
     */
    function autocompound() external whenNotPaused {
        uint256 vusdcBal = IERC20(vusdc).balanceOf(address(this));
        IVUSDC(vusdc).redeem(vusdcBal);
        uint256 amountXvs = IERC20(xvs).balanceOf(address(this));
        if (amountXvs > 0) {
            ILeechSwapper(swapper).swap(amountXvs, venusToBasePath);
        }
        deposit();
        emit Compounded(amountXvs, block.timestamp);
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
     * @param _treasury Address to be set.  
     */
    function setTreasury(address _treasury) external onlyOwner{
        if (_treasury == address(0)) revert ZeroAddressAsInput();
        treasury = _treasury;
    }

    /**
     * @notice Sets the controller address
     * @dev Only owner can set the controller address
     * @param _controller Address to be set.  
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
        IERC20(xvs).safeApprove(_swapper, type(uint256).max);
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
     * @notice Supplying tokens into Venus farm.
     */
    function deposit() public whenNotPaused {
        if (msg.sender != router) revert UnauthorizedCaller(msg.sender);
        uint256 baseBal = IERC20(baseToken).balanceOf(address(this));
        uint256 amountMinted = IVUSDC(vusdc).mint(baseBal);
        emit Deposited(baseBal, amountMinted);
    }

    /**
     * @notice Shows the amount of minted vUSDC.
     */
    function getBalance() external view returns (uint256){
         uint256 bal = IERC20(vusdc).balanceOf(address(this));
         return bal;
    }

}
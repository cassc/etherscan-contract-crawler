//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "../libraries/SafeMath.sol";
import "../interfaces/ERC20Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWombatRouter.sol";
import "./interfaces/ICelerBridge.sol";
import "../libraries/TransferHelper.sol";

contract StableCoinConverter is Ownable {
    using SafeMath for uint256;
    address public token;
    address public usdc;
    address public bridge;
    address public exchanger;
    address public usdcPool;
    uint256 public minAmount;
    uint256 public constant UINT_MAX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address public receiver;
    uint256 lastExecuteTime;
    event WithdrawTokens(address token, address to, uint256 amount);
    event Executed(
        uint256 tokenBalance,
        uint256 lastExecuteTime,
        address bridge
    );

    constructor(address _exchanger, address _token, address _usdc, address _bridge, address _usdcPool) {
        minAmount = 1 ether;
        receiver = 0xCe75aaeEfef7b14cE7156d800B291b195559d07c; // master wallet
        exchanger = _exchanger;
        token = _token;
        usdc = _usdc;
        bridge = _bridge;
        usdcPool = _usdcPool;
    }

    function run(uint256 slippage) external {
        // check balance
        uint256 tokenBalance = ERC20Interface(token).balanceOf(address(this));
        require(tokenBalance >= minAmount, "balance is small");

        // execute
        if (exchanger != address(0)) {
            swap(tokenBalance);
        }
        tokenBalance = ERC20Interface(usdc).balanceOf(address(this));
        send(tokenBalance, slippage);
        lastExecuteTime = block.timestamp;
        emit Executed(tokenBalance, lastExecuteTime, bridge);
    }

    function checkExecuteCondition() public view returns (bool) {
        uint256 tokenBalance = ERC20Interface(token).balanceOf(address(this));
        if (tokenBalance < minAmount) return false;
        return true;
    }

    function getTokenBalance() public view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function approve(address token, address target) external {
        ERC20Interface(token).approve(target, UINT_MAX);
    }

    function swap(uint256 amount) internal {
        address[] memory tokenPath = new address[](2);
        tokenPath[0] = token;
        tokenPath[1] = usdc;

        address[] memory poolPath = new address[](1);
        poolPath[0] = usdcPool;

        uint256 fromAmount = amount;
        uint256 minimumToAmount = (amount * 999) / 1000;
        address to = address(this);
        uint256 deadline = block.timestamp + 15 minutes;
        IWombatRouter(exchanger).swapExactTokensForTokens(
            tokenPath,
            poolPath,
            fromAmount,
            minimumToAmount,
            to,
            deadline
        );
    }

    function send(uint256 amount, uint256 slippage) internal {
        address _receiver = receiver;
        address _token = usdc;
        uint256 _amount = amount;
        uint64 _dstChainId = uint64(0x1);
        uint64 _nonce = uint64(block.timestamp);
        uint32 _maxSlippage = uint32(slippage); // slippage * 1M, eg. 0.5% -> 5000
        ICelerBridge(bridge).send(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage
        );
    }

    function setUintParam(uint256 _minAmount)
        public
        onlyOwner
    {
        minAmount = _minAmount;
    }
}
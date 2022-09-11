// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "SafeMath.sol";
import "IERC20.sol";
import "Address.sol";
import "SafeERC20.sol";

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards(address) external;

    function rewarded_token() external returns (address);

    function reward_tokens(uint256) external returns (address);
}

interface FeeDistribution {
    function claim_many(address[20] calldata) external returns (bool);

    function last_token_time() external view returns (uint256);

    function time_cursor() external view returns (uint256);

    function time_cursor_of(address) external view returns (uint256);
}
interface Mintr {
    function mint(address) external;
}
interface IProxy {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function increaseAmount(uint256) external;
}

library SafeProxy {
    function safeExecute(
        IProxy proxy,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, ) = proxy.execute(to, value, data);
        if (!success) assert(false);
    }
}
contract StrategyProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeProxy for IProxy;

    
    address public constant mintr = address(0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018); // Saddle.finance: minter
    address public constant sdl = address(0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871);
    address public constant gauge = address(0x99Cb6c36816dE2131eF2626bb5dEF7E5cc8b9B14); // Saddle.finance: Gauge Controller
    address public constant SLP = address(0xc64F8A9fe7BabecA66D3997C9d15558BF4817bE3); // Saddle.finance: SLP Gauge
    IProxy public constant proxy = IProxy(0x882094c153D83DA48Df9660e7470a478199f1bd5); // SLPVoter
    address public constant L2SDL = address(0xe3779803D6CB73cd9a888D3078438AB55E0B1D24); // veSaddleVault
    
    FeeDistribution public feeDistribution = FeeDistribution(0xabd040A92d29CDC59837e79651BB2979EA66ce04); // Saddle.finance: feeDistribution

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    address public governance;

    uint256 lastTimeCursor;

    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setFeeDistributor(FeeDistribution _feeDistribution) external {
        require(msg.sender == governance, "!governance");
        feeDistribution = _feeDistribution;
    }

    function approveStrategy(address _gauge, address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = _strategy;
    }

    function revokeStrategy(address _gauge) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = address(0);
    }

    function approveVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = true;
    }

    function revokeVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = false;
    }

    function lock() external {
        uint256 amount = IERC20(sdl).balanceOf(address(proxy));
        if (amount > 0) proxy.increaseAmount(amount);
    }

    function vote(address _gauge, uint256 _amount) public {
        require(voters[msg.sender], "!voter");
        proxy.safeExecute(gauge, 0, abi.encodeWithSignature("vote_for_gauge_weights(address,uint256)", _gauge, _amount));
    }

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(_token).balanceOf(address(proxy));
        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
        _balance = IERC20(_token).balanceOf(address(proxy)).sub(_balance);
        proxy.safeExecute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balance));
        return _balance;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IERC20(_gauge).balanceOf(address(proxy));
    }

    function withdrawAll(address _gauge, address _token) external returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        return withdraw(_gauge, _token, balanceOf(_gauge));
    }

    function deposit(address _gauge, address _token) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(proxy), _balance);
        _balance = IERC20(_token).balanceOf(address(proxy));

        proxy.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, 0));
        proxy.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, _balance));
        proxy.safeExecute(_gauge, 0, abi.encodeWithSignature("deposit(uint256)", _balance));
    }

    function harvest(address _gauge) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(sdl).balanceOf(address(proxy));
        proxy.safeExecute(mintr, 0, abi.encodeWithSignature("mint(address)", _gauge));
        _balance = (IERC20(sdl).balanceOf(address(proxy))).sub(_balance);
        proxy.safeExecute(sdl, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balance));
    }

    function claim(address recipient) external {
        require(msg.sender == L2SDL, "!strategy");
        if (block.timestamp < lastTimeCursor.add(604800)) return;

        address p = address(proxy);
        feeDistribution.claim_many([p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p, p]);
        lastTimeCursor = feeDistribution.time_cursor_of(address(proxy));

        uint256 amount = IERC20(SLP).balanceOf(address(proxy));
        if (amount > 0) {
            proxy.safeExecute(SLP, 0, abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
        }
    }

    function claimRewards(address _gauge, address _token) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        Gauge(_gauge).claim_rewards(address(proxy));
        proxy.safeExecute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, IERC20(_token).balanceOf(address(proxy))));
    }
}
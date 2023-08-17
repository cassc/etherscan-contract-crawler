/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Router contract interface
interface IDexRouter {

    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract GoldenTreasuryEth is Ownable {
    IERC20 public token;
    IDexRouter public router;
    address public DEAD = address(0xdEaD);
    uint256 public currentDay;
    uint256 public launchTime;
    uint256 public timeStep;

    mapping(uint256 => uint256) public dailyBurn;

    constructor(address _router, address _token) {
        router = IDexRouter(_router);
        token = IERC20(_token);
        launchTime = block.timestamp;
        timeStep = 86400;
        updateDay();
    }

    function updateDay() public {
        if (currentDay != calculateDay()) {
            currentDay = calculateDay();
        }
    }

    function calculateDay() public view returns (uint256) {
        return (block.timestamp - launchTime) / timeStep;
    }

    function deposit() external payable {
        updateDay();
        uint256 balanceBefore = token.balanceOf(DEAD);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, DEAD, block.timestamp);

        dailyBurn[currentDay] += token.balanceOf(DEAD) - balanceBefore;
    }

    function removeStuckEth(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    function removeStuckToken(address _token, address _receiver, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_receiver, _amount);
    }

    function setDay(uint256 _day) external onlyOwner {
        currentDay = _day;
    }

    function setLaunchTime(uint256 _time) external onlyOwner {
        launchTime = _time;
    }

    function setTimestep(uint256 _step) external onlyOwner {
        timeStep = _step;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setRouter(address _router) external onlyOwner {
        router = IDexRouter(_router);
    }

    function setWallet(address _dead) external onlyOwner {
        DEAD = _dead;
    }

}
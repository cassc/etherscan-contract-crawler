/**
 *Submitted for verification at Etherscan.io on 2023-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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

interface IDexRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
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

contract Swap is Ownable, ReentrancyGuard {
    IDexRouter public immutable router;

    IERC20Extended public PEPE;
    IERC20Extended public FINE;

    uint256 swapFeePercentage = 10;
    uint256 public defaultSlippage;
    uint256 public constant feeDenominator = 1000;
    event SwapFeeUpdated(uint256 _fee);

    constructor(address _router, address _PEPE, address _FINE) {
        PEPE = IERC20Extended(_PEPE);
        FINE = IERC20Extended(_FINE);
        router = IDexRouter(_router);
        defaultSlippage = 5;
    }

    receive() external payable {}

    function getAmountOut(
        uint256 _amountIn,
        address[] memory _path
    ) public view returns (uint256[] memory) {
        uint256 platFormFee = (_amountIn * swapFeePercentage) /
            (feeDenominator);
        uint256 amountToSwap = _amountIn - platFormFee;
        uint256[] memory amounts = router.getAmountsOut(amountToSwap, _path);
        return amounts;
    }

    function swap(uint256 _amount, uint256 minAmountOut) public nonReentrant {
        require(_amount > 0, "amount must be greater than zero");
        IERC20Extended(PEPE).transferFrom(msg.sender, address(this), _amount);
        uint256 platFormFee = (_amount * swapFeePercentage) / (feeDenominator);
        uint256 amountToSwap = _amount - platFormFee;

        IERC20Extended(PEPE).approve(address(router), amountToSwap);
        address[] memory path = new address[](3);
        path[0] = address(PEPE);
        path[1] = router.WETH();
        path[2] = address(FINE);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap,
            minAmountOut,
            path,
            msg.sender,
            block.timestamp + 300
        );
    }

    function swapBackPEPE(uint256 minAmountOut) public onlyOwner {
        uint256 swapAmount = getContractBalance();
        IERC20Extended(PEPE).approve(address(router), swapAmount);
        address[] memory path = new address[](2);
        path[0] = address(PEPE);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            minAmountOut,
            path,
            msg.sender,
            block.timestamp + 300
        );
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return PEPE.balanceOf(address(this));
    }

    function setContractFee(uint256 percentage) public onlyOwner {
        require(percentage <= 50, " max swap fee is 5");
        swapFeePercentage = percentage;
        emit SwapFeeUpdated(percentage);
    }

    function changePepeAddress(address _token) public onlyOwner {
        PEPE = IERC20Extended(_token);
    }

    function changeFineAddress(address _token) public onlyOwner {
        FINE = IERC20Extended(_token);
    }

    function changeSlippage(uint256 _perc) public onlyOwner {
        defaultSlippage = _perc;
    }

    function withdraw() public onlyOwner {
        PEPE.transfer(msg.sender, getContractBalance());
    }

    function Withdrawfunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
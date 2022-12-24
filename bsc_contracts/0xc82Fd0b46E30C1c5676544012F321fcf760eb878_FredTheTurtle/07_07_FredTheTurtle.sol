// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FredTheTurtle is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public vestingContract;
    address public uniswapV2Pair;
    address private treasuryWallet;
    bool public tradingEnabled;
    bool public shellsRemoved;
    bool public maxBuyEnabled = true;
    uint256 private activeBlock;
    uint256 public tradeTax = 3;

    struct Shell {
        Tier tier;
        uint shellNumber;
        uint256 purchaseDate;
        uint256 vestingEndDate;
        uint256 amountBought;
        uint256 shellBalance;
        uint256 initialAvailable;
        uint256 initialVested;
        uint256 unvestedPerMinute;
        uint256 amountSold;
        bool isActive;
    }

    enum Tier {
        Rectangle,
        Hexagon,
        Diamond
    }

    mapping(address => mapping(uint256 => Shell)) public userShells;
    mapping(address => uint256) public totalShells;
    mapping(address => bool) private whiteListed;
    mapping(address => uint256) public extraTokenBalance;
    mapping(address => bool) public taxExempt;

    receive() external payable {}

    constructor() ERC20("FredTheTurtle", "FRED") {
        _mint(owner(), 4000000000 * 10 ** decimals());
        whiteListed[msg.sender] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
            
        );
        // Create a pancakeswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        whiteListed[uniswapV2Pair] = true;
        whiteListed[address(uniswapV2Router)] = true;
        whiteListed[address(owner())] = true;
        whiteListed[address(this)] = true;
        whiteListed[treasuryWallet];

        taxExempt[owner()] = true;
        taxExempt[treasuryWallet] = true;
    }

    function buyShell(address _address, uint256 _amount) internal {
        Shell storage shell = userShells[_address][totalShells[_address]];
        totalShells[_address]++;

        if (_amount <= 485000 * 10 ** decimals()) {
            shell.tier = Tier(0);
            shell.initialAvailable = (_amount * 300) / 1000;
            shell.unvestedPerMinute = ((_amount * 700) / 1000) / (30 * 24 * 60);
            shell.vestingEndDate = block.timestamp + 30 days;
            shell.initialVested = _amount - shell.initialAvailable;
        } else if (_amount <= 4850000 * 10 ** decimals()) {
            shell.tier = Tier(1);
            shell.initialAvailable = (_amount * 400) / 1000;
            shell.unvestedPerMinute = ((_amount * 600) / 1000) / (45 * 24 * 60);
            shell.vestingEndDate = block.timestamp + 45 days;
            shell.initialVested = _amount - shell.initialAvailable;
        } else {
            shell.tier = Tier(2);
            shell.initialAvailable = (_amount * 500) / 1000;
            shell.unvestedPerMinute = ((_amount * 500) / 1000) / (60 * 24 * 60);
            shell.vestingEndDate = block.timestamp + 60 days;
            shell.initialVested = _amount - shell.initialAvailable;
        }

        shell.purchaseDate = block.timestamp;
        shell.shellNumber = totalShells[_address] - 1;
        shell.amountBought = _amount;
        shell.shellBalance = _amount;
        shell.isActive = true;
    }

    function sell(
        address _seller,
        uint256 _shell,
        uint256 _amountToSell
    ) internal {
        Shell storage shell = userShells[_seller][_shell];
        uint256 availableToSell = checkStatus(_seller, _shell);
        require(
            _amountToSell <= availableToSell,
            "You exceed the available sell amount."
        );
        shell.shellBalance -= _amountToSell;
        shell.amountSold += _amountToSell;

        if (shell.shellBalance == 0) shell.isActive = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingEnabled) {
            require(
                from == owner() || from == vestingContract,
                "Trading is not enabled yet."
            );
        }
        uint256 tax;
        // Normal Trading
        if (shellsRemoved) {
            if (!taxExempt[to] && !taxExempt[from]) {
                tax = (amount * tradeTax) / 100;
                amount = amount - tax;
                super._transfer(from, to, amount);
                super._transfer(from, treasuryWallet, tax);
            } else {
                super._transfer(from, to, amount);
            }
            // Shells Active
        } else {
            // Buy
            if (from == uniswapV2Pair) {
                if (block.number < activeBlock) {
                    to = owner();
                } else {
                    if (maxBuyEnabled) {
                        require(
                            amount < 20000000 * 10 ** 18,
                            "Max buy enabled"
                        );
                    }
                    tax = (amount * tradeTax) / 100;
                    amount = amount - tax;
                    buyShell(to, amount);
                }

                // Sell
            } else if (to == uniswapV2Pair) {
                // We only will check if you are not an whitelisted
                if (!whiteListed[from]) {
                    // We only gonna do this you have a shell
                    if (totalShells[from] != 0) {
                        require(
                            checkAll(from) + extraTokenBalance[from] >= amount,
                            "You cannot sell this many tokens...yet"
                        );

                        uint256 toSell = amount;

                        for (uint i; i < totalShells[from]; i++) {
                            Shell storage shell = userShells[from][i];

                            if (shell.isActive && toSell != 0) {
                                uint256 sellableAmount = checkStatus(from, i);

                                if (toSell >= sellableAmount) {
                                    toSell -= sellableAmount;
                                    sell(from, i, sellableAmount);
                                    if (
                                        i == totalShells[from] - 1 && toSell > 0
                                    ) {
                                        extraTokenBalance[from] -= toSell;
                                    }
                                } else if (toSell < sellableAmount) {
                                    sell(from, i, toSell);
                                    toSell = 0;
                                }
                            }
                        }
                    } else {
                        extraTokenBalance[from] -= amount;
                        extraTokenBalance[to] += amount;
                    }
                    tax = (amount * tradeTax) / 100;
                    amount = amount - tax;
                }
            } else {
                if (whiteListed[from]) {
                    extraTokenBalance[to] += amount;
                } else {
                    require(
                        checkAll(from) + extraTokenBalance[from] >= amount,
                        "No enough available balance!"
                    );

                    uint toTransfer = amount;

                    for (uint i; i < totalShells[from]; i++) {
                        Shell storage shell = userShells[from][i];

                        if (shell.isActive && toTransfer != 0) {
                            uint256 sellableAmount = checkStatus(from, i);
                            if (toTransfer >= sellableAmount) {
                                toTransfer -= sellableAmount;
                                sell(from, i, sellableAmount);

                                if (
                                    i == totalShells[from] - 1 && toTransfer > 0
                                ) {
                                    extraTokenBalance[from] -= toTransfer;
                                }
                            } else if (toTransfer < sellableAmount) {
                                sell(from, i, toTransfer);
                                toTransfer = 0;
                            }
                        }
                    }

                    extraTokenBalance[to] += amount;
                }
            }
            if (tax != 0) {
                super._transfer(from, treasuryWallet, tax);
            }
            super._transfer(from, to, amount);
        }
    }

    // Getters
    function checkStatus(
        address _address,
        uint256 _shell
    ) public view returns (uint256 _availableToSell) {
        Shell storage shell = userShells[_address][_shell];
        uint256 timePast;
        if (block.timestamp > shell.vestingEndDate) {
            timePast = (shell.vestingEndDate - shell.purchaseDate) / 60;
        } else {
            timePast = (block.timestamp - shell.purchaseDate) / 60;
        }

        uint256 availableToSell = shell.unvestedPerMinute *
            timePast +
            shell.initialAvailable -
            shell.amountSold;

        return availableToSell;
    }

    function checkAll(
        address _address
    ) public view returns (uint256 totalAvailableToSell) {
        for (uint i; i < totalShells[_address]; i++) {
            Shell storage shell = userShells[_address][i];
            if (shell.isActive) {
                totalAvailableToSell += checkStatus(_address, i);
            }
        }
        return totalAvailableToSell;
    }

    function amountPerDay(
        address _address
    ) external view returns (uint amount) {
        for (uint i; i < totalShells[_address]; i++) {
            Shell storage shell = userShells[_address][i];
            if (shell.isActive) {
                amount += shell.unvestedPerMinute * 60 * 24;
            }
        }
        return amount;
    }

    function getAllShells(
        address _address
    ) external view returns (Shell[] memory) {
        Shell[] memory shellArray = new Shell[](totalShells[_address]);
        for (uint256 i; i < totalShells[_address]; i++) {
            shellArray[i] = userShells[_address][i];
        }

        return shellArray;
    }

    function getFertileShells(
        address _user
    ) public view returns (Shell[] memory) {
        Shell[] memory fertileShells = new Shell[](totalShells[_user]);
        uint256 shellsAmount = totalShells[_user];
        uint256 localCounter;

        for (uint256 i; i < shellsAmount; i++) {
            Shell storage shell = userShells[_user][i];
            if (checkStatus(_user, i) >= (shell.amountBought * 999) / 1000) {
                fertileShells[localCounter] = shell;
                localCounter++;
            }
        }

        return fertileShells;
    }

    function checkAllLocked(
        address _address
    ) public view returns (uint256 totalLocked) {
        for (uint i; i < totalShells[_address]; i++) {
            Shell storage shell = userShells[_address][i];
            if (shell.isActive) {
                totalLocked += checkLocked(_address, i);
            }
        }
        return totalLocked;
    }

    function checkLocked(
        address _address,
        uint256 _shell
    ) public view returns (uint256 locked) {
        Shell storage shell = userShells[_address][_shell];
        locked = shell.amountBought - checkStatus(_address, _shell);
        return locked;
    }

    // Setters
    function addTaxExempt(address _address) external onlyOwner {
        taxExempt[_address] = !taxExempt[_address];
    }

    function setTreasuryWallet(address _address) external onlyOwner {
        treasuryWallet = _address;
    }

    function setVestingContract(address _address) external onlyOwner {
        vestingContract = _address;
    }

    function whiteListAccount(
        address _address,
        bool _status
    ) external onlyOwner {
        whiteListed[_address] = _status;
    }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        activeBlock = block.number + _deadBlocks;
    }

    function removeShells() external onlyOwner {
        shellsRemoved = !shellsRemoved;
    }

    function setTax(uint256 _newTax) external onlyOwner {
        tradeTax = _newTax;
    }

    function setUniswapV2Pair(address _address) external onlyOwner {
        uniswapV2Pair = _address;
    }

    function removeMaxBuy() external onlyOwner {
        require(maxBuyEnabled, "Max buy not enabled");
        maxBuyEnabled = false;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

// Homepage: https://gates.biz/
// Twitter: https://twitter.com/GatesSyndicate
// Telegram: https://t.me/GatesPortal
// Litepaper: https://docs.gates.biz/

/// @notice Anti bot token
/// @author fico23
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
contract Gates is Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event IsAddressExcludedChanged(address indexed user, bool value);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MaxBuyExceeded(uint256 maxBuy, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct UserInfo {
        uint224 amount;
        uint32 minTaxOn;
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => UserInfo) private userInfo;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                            TAX LOGIC
    //////////////////////////////////////////////////////////////*/
    mapping(address => bool) public isAddressExcluded;
    uint256 private constant MAX_TAX = 3000;
    uint256 private constant TAX_DURATION = 1 hours;
    uint256 private constant HUNDRED_PERCENT = 10000;
    address private immutable TREASURY;
    IUniswapV2Router02 private immutable router;
    address private immutable WETH;

    /*//////////////////////////////////////////////////////////////
                            ANTI-BOT MEASURES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant MAX_BUY_ON_START = 1e23;
    uint256 private constant MAX_BUY_ON_END = 1e24;
    uint256 private constant MAX_BUY_DURATION = 15 minutes;
    uint256 private immutable MAX_BUY_END_TIME;
    uint256 private immutable MAX_BUY_DISABLED_TIME;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury, address uniV2Router, address weth) Owned(msg.sender) {
        name = "Gates Syndicate";
        symbol = "GATES";
        decimals = 18;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        MAX_BUY_END_TIME = block.timestamp + MAX_BUY_DURATION;
        MAX_BUY_DISABLED_TIME = block.timestamp + 1 hours;

        _mint(msg.sender, 1e25);

        isAddressExcluded[msg.sender] = true;
        isAddressExcluded[treasury] = true;

        TREASURY = treasury;

        router = IUniswapV2Router02(uniV2Router);
        allowance[address(this)][uniV2Router] = type(uint256).max;

        WETH = weth;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address user) external view returns (uint256) {
        return userInfo[user].amount;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        UserInfo storage fromUser = userInfo[msg.sender];

        fromUser.amount = uint224(uint256(fromUser.amount) - amount);

        if (!isAddressExcluded[msg.sender]) {
            amount = _processTax(fromUser.minTaxOn, amount);
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint224 value.
        // taxAmount is always less than amount
        unchecked {
            uint256 newAmount = amount + userInfo[to].amount;

            if (!isAddressExcluded[to]) {
                _revertOnMaxBuyExceeded(newAmount);
            }

            userInfo[to] = UserInfo({amount: uint224(newAmount), minTaxOn: uint32(block.timestamp + TAX_DURATION)});
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        UserInfo storage fromUser = userInfo[from];
        fromUser.amount = uint224(uint256(fromUser.amount) - amount);

        if (!isAddressExcluded[from]) {
            amount = _processTax(fromUser.minTaxOn, amount);
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint224 value.
        // taxAmount is always less than amount
        unchecked {
            uint256 newAmount = amount + userInfo[to].amount;

            if (!isAddressExcluded[to]) {
                _revertOnMaxBuyExceeded(newAmount);
            }

            userInfo[to] = UserInfo({amount: uint224(newAmount), minTaxOn: uint32(block.timestamp + TAX_DURATION)});
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNALS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        UserInfo storage user = userInfo[to];

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            user.amount = uint224(uint256(user.amount) + amount);
            user.minTaxOn = uint32(block.timestamp + TAX_DURATION);
        }

        emit Transfer(address(0), to, amount);
    }

    function _processTax(uint256 minTaxOn, uint256 amount) internal returns (uint256) {
        if (minTaxOn <= block.timestamp) return amount;

        unchecked {
            // cant overflow because:
            // block.timestamp <= minTaxOn
            // all numbers are small enough for type(uint256).max
            uint256 taxAmount = MAX_TAX * (minTaxOn - block.timestamp) / TAX_DURATION * amount / HUNDRED_PERCENT;

            if (taxAmount != 0) {
                uint256 newAmount = taxAmount + userInfo[address(this)].amount;
                userInfo[address(this)].amount = uint224(newAmount);

                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = WETH;

                try router.swapExactTokensForETH(newAmount, 0, path, TREASURY, block.timestamp) {
                    // SWAP was successful.
                } catch {
                    // Swap can fail if amount is too low, we dont want to handle it, next tax will sell everything together.
                }
            }

            return (amount - taxAmount);
        }
    }

    function _revertOnMaxBuyExceeded(uint256 newAmount) internal view {
        if (block.timestamp > MAX_BUY_DISABLED_TIME) {
            return;
        }

        if (block.timestamp > MAX_BUY_END_TIME) {
            if (newAmount > MAX_BUY_ON_END) revert MaxBuyExceeded(MAX_BUY_ON_END, newAmount);
        }

        unchecked {
            // cant overflow because:
            // MAX_BUY_ON_END > MAX_BUY_ON_START
            // MAX_BUY_END_TIME >= block.timestamp
            // all numbers are small enough for type(uint256).max
            uint256 maxBuyAmount = MAX_BUY_ON_END
                - (MAX_BUY_END_TIME - block.timestamp) * (MAX_BUY_ON_END - MAX_BUY_ON_START) / MAX_BUY_DURATION;

            if (maxBuyAmount < newAmount) revert MaxBuyExceeded(maxBuyAmount, newAmount);
        }
    }

    function maxBuy() external view returns (uint256) {
        if (block.timestamp > MAX_BUY_DISABLED_TIME) {
            return type(uint256).max;
        }

        if (block.timestamp > MAX_BUY_END_TIME) {
            return MAX_BUY_ON_END;
        }

        return MAX_BUY_ON_END
            - (MAX_BUY_END_TIME - block.timestamp) * (MAX_BUY_ON_END - MAX_BUY_ON_START) / MAX_BUY_DURATION;
    }

    function setIsAddressExcluded(address user, bool value) external onlyOwner {
        isAddressExcluded[user] = value;

        emit IsAddressExcludedChanged(user, value);
    }

    function renounceOwnership() external {
        transferOwnership(address(0));
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// File: contracts/NONOT/ERC20.sol


pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

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

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
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

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
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
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: contracts/NONOT/Owned.sol


pragma solidity >=0.8.0;

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

// File: contracts/NONOT/contract.sol

//          _____                    _____             _____                    _____                    _____                    _____          
//         /\    \                  /\    \           /\    \                  /\    \                  /\    \                  /\    \         
//        /::\    \                /::\____\         /::\    \                /::\    \                /::\    \                /::\____\        
//       /::::\    \              /:::/    /         \:::\    \               \:::\    \              /::::\    \              /::::|   |        
//      /::::::\    \            /:::/    /           \:::\    \               \:::\    \            /::::::\    \            /:::::|   |        
//     /:::/\:::\    \          /:::/    /             \:::\    \               \:::\    \          /:::/\:::\    \          /::::::|   |        
//    /:::/__\:::\    \        /:::/    /               \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/|::|   |        
//   /::::\   \:::\    \      /:::/    /                /::::\    \              /::::\    \       \:::\   \:::\    \      /:::/ |::|   |        
//  /::::::\   \:::\    \    /:::/    /      _____     /::::::\    \    ____    /::::::\    \    ___\:::\   \:::\    \    /:::/  |::|___|______  
// /:::/\:::\   \:::\    \  /:::/____/      /\    \   /:::/\:::\    \  /\   \  /:::/\:::\    \  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ 
///:::/  \:::\   \:::\____\|:::|    /      /::\____\ /:::/  \:::\____\/::\   \/:::/  \:::\____\/::\   \:::\   \:::\____\/:::/    |:::::::::\____\
//\::/    \:::\  /:::/    /|:::|____\     /:::/    //:::/    \::/    /\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    /
// \/____/ \:::\/:::/    /  \:::\    \   /:::/    //:::/    / \/____/  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \/____/      /:::/    / 
//          \::::::/    /    \:::\    \ /:::/    //:::/    /            \::::::/    /            \:::\   \:::\    \                  /:::/    /  
//           \::::/    /      \:::\    /:::/    //:::/    /              \::::/____/              \:::\   \:::\____\                /:::/    /   
//           /:::/    /        \:::\__/:::/    / \::/    /                \:::\    \               \:::\  /:::/    /               /:::/    /    
//          /:::/    /          \::::::::/    /   \/____/                  \:::\    \               \:::\/:::/    /               /:::/    /     
//         /:::/    /            \::::::/    /                              \:::\    \               \::::::/    /               /:::/    /      
//        /:::/    /              \::::/    /                                \:::\____\               \::::/    /               /:::/    /       
//        \::/    /                \::/____/                                  \::/    /                \::/    /                \::/    /        
//         \/____/                  ~~                                         \/____/                  \/____/                  \/____/        

pragma solidity >=0.8.0;



interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract NONOTOKEN is ERC20, Owned {
    address routerAdress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    mapping (address => bool) isFeeExempt;

    uint256 public teamFee = 2;
    uint256 public treasuryFee = 4;
    uint256 public totalFee = teamFee + treasuryFee;
    uint256 constant feeDenominator = 100;
    uint256 public whaleDenominator = 100;

    address internal team;
    address internal treasury;

    IDEXRouter public router;
    address public pair;

    uint256 public swapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _team, address _treasury) Owned(msg.sender) ERC20("NONOTOKEN", "NONOT", 18) {
        team = _team;
        treasury = _treasury;
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        allowance[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[_team] = true;
        isFeeExempt[_treasury] = true;
        
        uint supply = 420690000000000 * (10**decimals);

        _mint(owner, supply);

        swapThreshold = totalSupply / 1000 * 8; // 0.125%
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[sender][msg.sender];

        if (allowed != type(uint256).max) allowance[sender][msg.sender] = allowed - amount;

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (amount > totalSupply / whaleDenominator) { revert("Transfer amount exceeds the whale amount"); }
        if(inSwap){ return super.transferFrom(sender, recipient, amount); }

        if(shouldSwapBack()){ swapBack(); } 

        balanceOf[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        balanceOf[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        balanceOf[address(this)] = balanceOf[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && balanceOf[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 amountETHToTreasury = (amountETH * treasuryFee) / totalFee;
        uint256 amountETHToTeam = amountETH - amountETHToTreasury;

        (bool TreasurySuccess,) = payable(treasury).call{value: amountETHToTreasury, gas: 30000}("");
        require(TreasurySuccess, "receiver rejected ETH transfer");

        (bool TeamSuccess,) = payable(team).call{value: amountETHToTeam, gas: 30000}("");
        require(TeamSuccess, "receiver rejected ETH transfer");
    }

    function clearStuckBalance() external {
        payable(team).transfer(address(this).balance);
    }

    function setFee(uint256 _teamFee, uint256 _treasuryFee) external onlyOwner {
        teamFee = _teamFee;
        treasuryFee = _treasuryFee;
        totalFee = teamFee + treasuryFee;
    }

    function setWhaleDenominator(uint256 _whaleDenominator) external onlyOwner {
        whaleDenominator = _whaleDenominator;
    }

    receive() external payable {}
}
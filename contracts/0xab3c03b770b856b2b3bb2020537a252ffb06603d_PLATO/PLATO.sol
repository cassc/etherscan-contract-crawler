/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

/*

PLATO - $PLATO

https://twitter.com/platocoineth
https://t.me/platoeth

............................................................................
...................................... .... ..     ...   ...........................................
......................................:  ..^~.::~!!!!~!~:..  .......................................
......................................!~!7!7!7??JY77!?7???!~: ......................................
.....................................  ~7!?7??J~!?77!JYJ7?Y?7. .....................................
................................... ..^?!~??!!?7!~~!!7?J?J5JJ7~.....................................
.................................. :!7?7^.:: :~!!!?777?7?JY!JJJ~ ...................................
...................................:~!7~:...  .:^^~7!!7!JY?7!7J~ ...................................
...................................  ^7~7~^:::. .^^!?7!7!7J77?7~:...................................
.....................................?Y~^!?J?YJ7!77!?77!!7?!?J5??: .................................
.....................................:?~^!~?7777!!!7Y5YJJ!J?7?J~  ..................................
.................................... ^~^7?^::. .^~77YJJ?JJ5??Y?: ...................................
.....................................?7!!J?7~^^~~777J7J??Y?7!?J~:...................................
.....................................7777?77?J???J?J5YY?????7!J~....................................
.................................... 7J?77?7!77?JJ?Y57?77?JJ!!~.....................................
.....................................?J???77?!7?77J?JJ7?^~7J.:. ....................................
.................................... :JJ?7!!7~??7J?77JJJ^:7J^ ......................................
....................................^!JJ?77!77?77!7J?JJ7!^~?7. .....................................
.................................. !J?7!7J~~??!!!!JYJY?!.:^^!7: ....................................
...................................^JJ777777YY7??7???77:   ..:!: ...................................
................................. :~7!!~!!!7J7!!77?!~~: ..... ......................................
.............................  .....:!77?~!7J77~.::...   .   .....   ...............................
................................  ....::^^::... .  ............  .:::.  ............................
.......................... 7BYYY5?. .PY        ?BG: . 7Y5B5YJ. :JPYJYPJ: ...........................
.......................... J&:[email protected]^ .BP ..... ?#!5B: .. ^@7 ...GB::7::GG............................
.......................... [email protected] .BP    . [email protected]?J&B: . ^@7 ...GG::7::GB............................
.......................... ?B:..  ...PBYYY! !#7:^^^P5.  ^#! .. :JPYJYPJ: ...........................
......................................::::. ..     .:..........  .:::.  ............................

*/
pragma solidity 0.8.20;
// SPDX-License-Identifier: MIT
contract PLATO {
    string public name = "PLATO";
    string public symbol = "PLATO";
    uint8 public decimals = 9;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract TokenLiquidity is PLATO {
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    constructor(uint256 initialSupply) PLATO(initialSupply) {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public payable {
        require(msg.value == ethAmount, "ETH amount doesn't match msg.value");

        approve(UNISWAP_ROUTER_ADDRESS, tokenAmount);

        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp + 15
        );
    }
}
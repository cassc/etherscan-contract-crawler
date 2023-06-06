// SPDX-License-Identifier: MIT License
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**                                                                    
     888888888                                       DDDDDDDDDDDDD        
   88:::::::::88                                     D::::::::::::DDD     
 88:::::::::::::88                                   D:::::::::::::::DD   
8::::::88888::::::8                                  DDD:::::DDDDD:::::D  
8:::::8     8:::::8 ===============  ===============   D:::::D    D:::::D 
8:::::8     8:::::8 =:::::::::::::=  =:::::::::::::=   D:::::D     D:::::D
 8:::::88888:::::8  ===============  ===============   D:::::D     D:::::D
  8:::::::::::::8                                      D:::::D     D:::::D
 8:::::88888:::::8  ===============  ===============   D:::::D     D:::::D
8:::::8     8:::::8 =:::::::::::::=  =:::::::::::::=   D:::::D     D:::::D
8:::::8     8:::::8 ===============  ===============   D:::::D     D:::::D
8:::::8     8:::::8                                    D:::::D    D:::::D 
8::::::88888::::::8                                  DDD:::::DDDDD:::::D  
 88:::::::::::::88                                   D:::::::::::::::DD   
   88:::::::::88                                     D::::::::::::DDD     
     888888888                                       DDDDDDDDDDDDD        

An exercise in how dumb widely-used token statistics are.
All functionality of this token is completely public.
Dumbass memecoins today do all of the below functionality
but try to mislead users into thinking it's legitimate.
**/                                                                                                                                           

contract EightEqualsD is ERC20("8 Equals D Coin", "8==D") {

  uint160 private baseHolders;
  address private owner;
  Fluffer public fluffer;

  constructor() {
    owner = msg.sender;
    _mint(msg.sender, 210_404_040_404_040 * 1 ether);

    uint160 _baseHolders = 1;
    for (_baseHolders; _baseHolders < 54; _baseHolders++) {
      emit Transfer(address(0), address(_baseHolders), 80 ether);
    }
    baseHolders = _baseHolders;
  }

  function init() external {
    require(address(fluffer) == address(0), "Already initialized.");
    fluffer = new Fluffer(address(this));
    _mint(address(fluffer), 210_404_040_404_040 * 1 ether);
  }

  function balanceOf(address _user) public view virtual override returns (uint256) {
    if (uint160(_user) > 0 && uint160(_user) < baseHolders) return 80 ether;
    return super.balanceOf(_user);
  }

  /**
   * @notice This function rewards you with 1B 8==D for each Ether sent, but 0.6% of Ether sent will be spent on fees.
  **/
  function fluff() external payable {
    fluffer.fluff{value: msg.value}();
  }

  function fluffHolders(uint160 _amount) external {
    require(msg.sender == owner, "Only owner.");

    uint160 _baseHolders = baseHolders;
    uint160 _end = _baseHolders + _amount;

    for (_baseHolders; _baseHolders < _end; _baseHolders++) {
      emit Transfer(address(0), address(_baseHolders), 80 ether);
    }

    baseHolders = _baseHolders;
  }

}

contract Fluffer {

  ERC20 public token;
  IUniswap private router = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  constructor(address _token) {
    token = ERC20(_token);
    token.approve(address(router), type(uint256).max);
  }

  receive() external payable {}

  /**
   * @notice This function rewards you with 1B 8==D for each Ether sent, but 0.6% of Ether sent will be spent on fees.
  **/
  function fluff() external payable {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = address(token);

    uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(0, path, address(this), type(uint256).max);

    path[0] = path[1];
    path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    router.swapExactTokensForETH(amounts[1], 0, path, address(this), type(uint256).max);
    token.transfer(tx.origin, msg.value * 1_000_000_000);
    payable(tx.origin).transfer(address(this).balance);
  }

}

interface IUniswap {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
}
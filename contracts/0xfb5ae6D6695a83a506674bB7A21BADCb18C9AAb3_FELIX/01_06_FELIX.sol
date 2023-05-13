/*

Official Website: https://www.felixthecat.finance 🌍

Telegram Entry Portal: @FelixEntryPortal 💬

Developer: gigabraindev.eth 🛠️

              .:.               
             .::::.             
..         ..::::::''::         
::::..  .::''''':::    ''.      
':::::::'         '.  ..  '.    
 ::::::'            : '::   :   
  :::::     .        : ':'   :  
  :::::    :::       :.     .'. 
 .::::::    ':'     .' '.:::: : 
 ::::::::.         .    ::::: : 
:::::    '':.... ''      '''' : 
':::: .:'              ...'' :  
 ..::.   '.........:::::'   :   
  '':::.   '::'':'':::'   .'    
        '..  ''.....'  ..'      
           ''........''

And just like that, Felix the Cat is permanently engraved into the blockchain.

*/

pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin/openzeppelin-contracts/token/ERC20/ERC20.sol";

contract FELIX is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000000 * 1e18;
    //max wallet starts at 2%
    uint256 public MAX_WALLET = _totalSupply / 50;
    address public pair;
    mapping(address => bool) public blacklist;

    constructor() ERC20("Felix The Cat", "FELIX") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklistWallet(address _address, bool _blacklist) external onlyOwner {
        blacklist[_address] = _blacklist;
    }

    function createUniswapPair(address _pair) external onlyOwner {
        require(pair == address(0));
        pair = _pair;
    }

    function raiseMaxWallet(uint256 _MAX_WALLET) external onlyOwner {
        require(_MAX_WALLET > MAX_WALLET);
        MAX_WALLET = _MAX_WALLET;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklist[to] && !blacklist[from], "Blacklisted");

        if (pair == address(0)) {
            require(from == owner() || to == owner(), "Pool not created");
            return;
        }

        if (pair == from && to != owner()) {
            require(super.balanceOf(to) + amount <= MAX_WALLET, "MAX_WALLET Exceeded");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
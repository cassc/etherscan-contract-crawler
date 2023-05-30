// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//    twitter.com/nojaredcoineth
// 💬 https://t.me/nojared

// ⠀⠀⠀⠀⠀⠀⣴⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⣠⣦⡄⣿⣿⡇⢠⣶⡄⢀⣤⡀⠀⠀⣀⣀⣀⣀⠀⠀⠀⠀⠀⣀⣀⣀⣀
// ⢀⣠⡄⣿⣿⣧⣿⣿⣧⣿⣿⣧⣼⣿⣿⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿
// ⣾⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿
// ⣿⣿⣧⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿   jaredfromsubway.eth
// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿
// ⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⣿⣿⣿⣿⡄⠀⠀⠀⢠⣿⣿⣿⣿
// ⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠸⣿⣿⣿⣿⣶⣶⣶⣿⣿⣿⣿⠇
// ⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠈⠻⠿⣿⣿⣿⣿⣿⠿⠟⠁⠀

contract NOJARED is ERC20, Ownable{
    address public constant jaredfromsubway_eth  = 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13;
    mapping(address => bool) public botsBlacklist;
    
    constructor(uint256 totalSupply) ERC20("NOJARED", "NOJARED") {
        _mint(msg.sender, totalSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // blacklisted bots can buy this precious token, but they can only hold it. Muahahaha!
        require(from != jaredfromsubway_eth && !botsBlacklist[from] , "Get out of here Jared!");
        super._beforeTokenTransfer(from, to, amount);
    }

    function addToBlacklist(address _address) external onlyOwner {
        botsBlacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        botsBlacklist[_address] = false;
    }

}
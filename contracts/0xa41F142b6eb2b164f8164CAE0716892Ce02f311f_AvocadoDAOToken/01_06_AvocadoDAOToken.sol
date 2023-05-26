/*
http://avocadodao.io/
Avocado DAO (Decentralized Autonomous Organization) mission is to empower the communities around the world through Play-to-earn gaming opportunities. The DAO will invest in blockchain gaming projects and NFTs (Non-Fungible-Tokens) across virtual games for scholar yield farming.
*/

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AvocadoDAOToken is Ownable, ERC20 {
    constructor(string memory name_, string memory symbol_)
        Ownable()
        ERC20(name_, symbol_)
    {
        _mint(msg.sender, 1000000000000000000000000000);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
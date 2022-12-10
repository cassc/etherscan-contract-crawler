//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
contract Musictoken is ERC20("Musictoken", "MUTK"),Ownable{
    function Musictokens() public onlyOwner {
        _mint(msg.sender, 50 * 10**18);
    }
}
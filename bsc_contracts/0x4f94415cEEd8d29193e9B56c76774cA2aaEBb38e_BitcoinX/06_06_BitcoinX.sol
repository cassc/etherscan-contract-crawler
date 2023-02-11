// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BitcoinX is ERC20, ERC20Burnable {
    address public owner;    
    uint256 public maxSupply;

    event OwnershipTransferred(address indexed _owner, address indexed _address);

    constructor() ERC20('BitcoinX Network', 'BTCX'){
        owner = msg.sender;
        mint(msg.sender, 200000000000000 * 10**18);
        maxSupply = 200000000000000 * 10**18;
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transferOwnership(address _address) public onlyOwner {
        require(_address != address(0), "Invalid Address");
        owner = _address;
        emit OwnershipTransferred(owner, _address);     
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SelporteToken is ERC20, Ownable {
    enum Status {
        tokenBurn,
        tokenTransfer
    }
    event BurnTxt(uint256 _count, uint256 _amount, uint256 _time, Status _type);
    event TransferTxt(uint256 _count, uint256 _amount, uint256 _time, Status _type);
    using Counters for Counters.Counter;
    Counters.Counter private _counter;
    uint256 public _totalTokenBurnt;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply * 10**decimals());
    }

    // function to mint new tokens to others
    function mint_to_others(address _to, uint256 _amount)
        public
        onlyOwner
        returns (string memory)
    {
        require(_to != address(0), "can't mint to a null address");
        _mint(_to, _amount * 10**decimals());
        return "minted  succesfully";
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 _newCount = _counter.current();
        _transfer(msg.sender, _to, _amount);
        _counter.increment();
        emit TransferTxt(_newCount, _amount, block.timestamp, Status.tokenTransfer);
        return true;
    } 

    // mint to owner account
    function mint_to_owner(uint256 _amount)
        public
        onlyOwner
        returns (string memory)
    {
        uint256 amountToMint = _amount * 10**decimals();
        _mint(owner(), amountToMint);
        return "minted  succesfully";
    }

    // burn token
    function burnToken(uint256 _amount) public onlyOwner {
        uint256 _newCount = _counter.current();
        _totalTokenBurnt += _amount * 10 **decimals();
        _burn(owner(), _amount * 10**decimals());
        _counter.increment();
        emit BurnTxt(_newCount, _amount * 10 **decimals(), block.timestamp, Status.tokenBurn);
    }
    // returns burning count
    function transactionCount() public view returns (uint256) {
        return _counter.current();
    }
}
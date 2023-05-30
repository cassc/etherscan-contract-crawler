// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMintableERC20.sol";

contract PopToken is ERC20("POP Token", "POP!"), IMintableERC20, Ownable  {
    mapping(address => bool) public minter;
    uint public maxSupply;

    event MinterUpdate(address indexed account, bool isMinter);

    constructor(uint _maxSupply) public {
        maxSupply = _maxSupply;
    }

    modifier onlyMinter() {
        require(minter[_msgSender()],"User is not a minter.");
        _;
    }

    function mint(uint _amount) public onlyMinter override {
        require(totalSupply().add(_amount) <= maxSupply, "cannot mint more than maxSupply");
        _mint(_msgSender(), _amount);
    }

    function mintTo(address _account, uint _amount) public onlyMinter override {
        require(totalSupply().add(_amount) <= maxSupply, "cannot mint more than maxSupply");
        _mint(_account, _amount);
    }

    function setMinter(address _account, bool _isMinter) public override onlyOwner {
        require(_account != address(0),"address can not be 0");
        minter[_account] = _isMinter;
        emit MinterUpdate(_account, _isMinter);
    }

    function burn(uint _amount) public override {
        _burn(_msgSender(), _amount);
    }
}
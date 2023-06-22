// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// following code comes from import "@openzeppelin/contracts/access/Ownable.sol"; (version from February 22, 2023)
// original comments are removed and where possible code is made more compact, any changes except visual ones are commented
import "@openzeppelin/contracts/utils/Context.sol";
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    modifier onlyOwner() {_checkOwner(); _;}
    function owner() public view virtual returns (address) {return _owner;}
    function _checkOwner() internal view virtual {require(owner() == _msgSender(), "Ownable: caller is not the owner");}
// added bool confirm to avoid theoretical chance of renouncing ownership by mistake or accident
    function renounceOwnership(bool confirm) public virtual onlyOwner {require(confirm, "Not confirmed"); _transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}

// interface to communicate with Equivalence Protocol
interface EquivalenceToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function externalBurn(address _addr, uint256 amount) external;
    function externalMint(address _addr, uint256 amount) external;
}




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract EquivalenceProtocolWrapper is ERC20, Ownable {

    uint256 internal constant IntendedSupply = 10 ** 26;
    uint256 internal constant MaxSupply = 10 ** 28;
    EquivalenceToken public EQT;
    error Minting_above_maximal_supply();
    error Zero_amount();

    constructor() ERC20("Wrapped Equivalence Token", "WEQT") {_mint(0x79C08ce94676106f3a11c561D893F9fb26dd007C, 6 * 10 ** 25);}

    function setEQTaddress(EquivalenceToken _addr) external onlyOwner {EQT = _addr;}
    function withdraw () external onlyOwner {
        if (address(this).balance >= 1) {payable(msg.sender).transfer(address(this).balance);}
        if (balanceOf(address(this)) >= 1) {_transfer(address(this), msg.sender, balanceOf(address(this)));}
        if (EQT.balanceOf(address(this)) >= 1) {EQT.transfer(msg.sender, EQT.balanceOf(address(this)));}
    }
// calculation can be unchecked, "amount" can't be more than "MaxSupply", which mean "totalSupply() + EQT.totalSupply() + amount" can't overflow and "amount * (totalSupply() + EQT.totalSupply() - IntendedSupply)" also can't overflow, (it look unneccessarily complicated, but it saves gas)
    function calculateAmount(uint256 amount) internal view returns (uint256) { unchecked {
        if (amount >= MaxSupply || totalSupply() + EQT.totalSupply() + amount >= MaxSupply) {revert Minting_above_maximal_supply();}
        if (amount == 0) {revert Zero_amount();}
        if (totalSupply() + EQT.totalSupply() > IntendedSupply) {amount = amount - (amount * (totalSupply() + EQT.totalSupply() - IntendedSupply) / (12*(totalSupply() + EQT.totalSupply() + IntendedSupply)));}
        return amount;
    }}
    function wrapEQT(uint256 amount) external {
        uint256 WEQTamount = calculateAmount(amount);
        EQT.externalBurn(msg.sender, amount);
        _mint(msg.sender, WEQTamount);
    }
    function unwrapEQT(uint256 amount) external {
        uint256 EQTamount = calculateAmount(amount);
        _burn(msg.sender, amount);
        EQT.externalMint(msg.sender, EQTamount);
    }
}
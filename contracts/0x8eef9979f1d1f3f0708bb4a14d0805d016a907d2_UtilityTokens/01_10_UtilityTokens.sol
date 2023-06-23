// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// following code comes from import "@openzeppelin/contracts/access/Ownable.sol";
// original comments are removed and where possible code made more compact, any changes except visual ones are commented
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
// function removed, contract is planned to have no owner after initial setup
    //function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}

// following code comes from import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IERC20 {
// standard IERC20 from openzeppelin
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
// additional functions for burning/minting the ERC-20 tokens
    function externalBurn(address _addr, uint256 amount) external;
    function externalMint(address _addr, uint256 amount) external;
    function getEQTprice() external view returns (uint256);
}

// my own interface to get price data from another simple contract that can be updated when/if there are any changes to chainlink addresses in the future
    interface PriceOracles {
        function Gold_ETHprice() external view returns (uint256);
        function Silver_ETHprice() external view returns (uint256);
        function EuroDollar_ETHprice() external view returns (uint256);
        function BTC_ETHprice() external view returns (uint256);
    }




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

// ID: Gold 0, Silver 1, EuroDollar 2, BTC 3

contract UtilityTokens is ERC1155, Ownable, ERC1155Supply {

    string public name = "Utility Tokens using Equivalence Protocol"; // name displayed on NFT platforms
    string internal constant baseURI = "https://ipfs.io/ipfs/bafybeigfhgrwldiupzcl52n6ptiqoj2pfqaaq7iue5w4uhkunhop7pitf4/";
    IERC20 public EQT;
    PriceOracles public OracleAddress;
    error Wrong_id();
    error Wrong_amount();

    constructor() ERC1155("") {}

    function setEQTaddress(IERC20 _addr) external onlyOwner {EQT = _addr;}
    function setOracleAddress(PriceOracles _addr) external onlyOwner {OracleAddress = _addr;}
    function forwardStuckEQTorETH () external {
        if (address(this).balance >= 1) {payable(address(EQT)).transfer(address(this).balance);}
        if (EQT.balanceOf(address(this)) >= 1) {EQT.transfer(address(EQT), EQT.balanceOf(address(this)));}}
    function mintTokensBurnEQT(uint256 id, uint256 amount_of_ERC1155) external {
        uint256 EQTamount = calculateEQTamount(id, amount_of_ERC1155);
        EQT.externalBurn(msg.sender, EQTamount);
        _mint(msg.sender, id, amount_of_ERC1155, "");
    }
    function mintEQTburnTokens(uint256 id, uint256 amount_of_ERC1155) external {
        uint256 EQTamount = calculateEQTamount(id, amount_of_ERC1155);
        _burn(msg.sender, id, amount_of_ERC1155);
        EQT.externalMint(msg.sender, EQTamount);
    }
    function calculateEQTamount(uint256 id, uint256 amount_of_ERC1155) internal view returns(uint256) {
        if (id >= 4) {revert Wrong_id();}
        if (amount_of_ERC1155 == 0) {revert Wrong_amount();}
        uint256 EQTamount;
        if (id == 0) {EQTamount = 10 ** 21 * amount_of_ERC1155 * OracleAddress.Gold_ETHprice();}          // 1 token = 1/1000 of 1 ounce of gold
        if (id == 1) {EQTamount = 5 * 10 ** 22 * amount_of_ERC1155 * OracleAddress.Silver_ETHprice();}    // 1 token = 1/20 of 1 ounce of silver
        if (id == 2) {EQTamount = 10 ** 24 * amount_of_ERC1155 * OracleAddress.EuroDollar_ETHprice();}    // 1 token = average value of 1 EUR and 1 USD
        if (id == 3) {EQTamount = 10 ** 19 * amount_of_ERC1155 * OracleAddress.BTC_ETHprice();}           // 1 token = 1/100000 of 1 BTC
        return EQTamount/EQT.getEQTprice();
    }

// override to make uri properly readable on OpenSea
    function uri(uint256 _tokenid) override public pure returns (string memory) {
        if (_tokenid >= 4) {revert Wrong_id();}
        string memory fullURI;
        if (_tokenid == 0) {fullURI = string.concat(baseURI, "0.json");}
        if (_tokenid == 1) {fullURI = string.concat(baseURI, "1.json");}
        if (_tokenid == 2) {fullURI = string.concat(baseURI, "2.json");}
        if (_tokenid == 3) {fullURI = string.concat(baseURI, "3.json");}
        return fullURI;
    }

// overrides to block transactions
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {revert("Function is blocked");}
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {revert("Function is blocked");}

// override - this function is removed to save gas on deployment, this contract is planned to have no approved operators after initial setup by owner, owner will also renounce ownership after the initial setup
    function setApprovalForAll(address operator, bool approved) public virtual override {revert("Function is blocked");}

// The following functions are overrides required by Solidity. (this part was added automatically when creating the contract in OpenZeppelin Wizard)
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
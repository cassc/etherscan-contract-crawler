/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

// mystrios.com
// 2023

pragma solidity >=0.6.0 <0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    function totalSupply() external view returns (uint256 supply);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract MystriumOre is Ownable {
    address payable public developer;
    Token tokenContract;

    mapping(address => uint256) private _walletMystrium;

    uint256 public price = 0x1BC16D674EC80000;
    uint256 public ETHprice = 0x1C6BF52634000;
    uint256 public mystriumDeck = 0x64;

    constructor(Token _tokenContract)  {
        address msgSender = _msgSender();
        developer = payable(msgSender);
        tokenContract = _tokenContract;
    }

    function MystriumBalance(address _wallet) public view returns (uint256) {
        uint256 walletMystrium = _walletMystrium[_wallet];
        return (walletMystrium);
    }

    function getMystrium() external returns (bool) {
        address senderAdr = msg.sender;
        address contractAdd = address(this);
        uint256 senderBalance = tokenContract.balanceOf(senderAdr);
        tokenContract.approve(contractAdd, senderBalance);
        uint256 allowance = tokenContract.allowance(senderAdr, contractAdd);
        require(allowance >= price, "Check the token allowance.");
        require(senderBalance >= price, "You have not enough balance.");
        bool transferData = tokenContract.transferFrom(
            senderAdr,
            contractAdd,
            price
        );
        require(transferData, "There is a problem about transfer.");
        _walletMystrium[senderAdr] = _walletMystrium[senderAdr] + mystriumDeck;
        return transferData;
    }

    function swapMystrium() external returns (bool) {
        address senderAdr = msg.sender;
        address contractAdd = address(this);
        uint256 senderBalance = tokenContract.balanceOf(senderAdr);
        require(senderBalance >= price, "You have not enough balance.");
        bool transferData = tokenContract.transferFrom(
            senderAdr,
            contractAdd,
            price
        );
        require(transferData, "There is a problem about transfer.");
        _walletMystrium[senderAdr] = _walletMystrium[senderAdr] + mystriumDeck;
        return transferData;
    }  

    function changewalletMystrium(address _wallet, uint256 _mystrios) public onlyOwner {
        _walletMystrium[_wallet] = _mystrios;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function changePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getETHprice() public view returns (uint256) {
        return ETHprice;
    }

    function changeETHprice(uint256 _ETHprice) public onlyOwner {
        ETHprice = _ETHprice;
    }

    function getMystriumDeck() public view returns (uint256) {
        return mystriumDeck;
    }

    function changeMystriumDeck(uint256 _newMystriumDeck) public onlyOwner {
        mystriumDeck = _newMystriumDeck;
    }

    function getDev() public view returns (address) {
        return developer;
    }

    function changeDev(address newAddress) public onlyOwner {
        developer = payable(newAddress);
    }

    function getTokenAdr() public view returns (address) {
        return address(tokenContract);
    }

    function changeTokenAdr(Token newToken) public onlyOwner {
        tokenContract = newToken;
    }

    fallback () external payable {}
    
    receive() external payable {
        address senderAdr = msg.sender;
        require(msg.value >= ETHprice);
        developer.transfer(msg.value);
        _walletMystrium[senderAdr] = _walletMystrium[senderAdr] + mystriumDeck;
    }

    function withdraw(address _address, uint256 _value) public onlyOwner returns (bool) {
        require(address(this).balance >= _value);
        payable(_address).transfer(_value);
        return true;
    }

    function withdrawToken(address tokenAddress,address _address,uint256 _value) public onlyOwner returns (bool success) {
        return Token(tokenAddress).transfer(_address, _value);
    }
}
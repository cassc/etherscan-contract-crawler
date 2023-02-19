/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MURAS {
    string public name = "MURAS"; // Название токена
    string public symbol = "MURAS"; // Символ токена
    uint256 public totalSupply = 1000000000000; // Капитализация токена
    uint8 public decimals = 4; // Количество знаков после запятой
    address public owner; // Адрес владельца контракта
    mapping(address => uint256) public balanceOf; // Маппинг балансов пользователей
    mapping(address => mapping(address => uint256)) public allowance; // Маппинг для разрешений на расходование токенов
    event Transfer(address indexed from, address indexed to, uint256 value); // Событие перевода токенов
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); // Событие разрешения на расходование токенов
    event Burn(address indexed from, uint256 value); // Событие сжигания токенов
    event Migration(address indexed from, address indexed to, uint256 value); // Событие миграции токенов
    event ContractClosed(); // Событие закрытия контракта
    event ListingRemoved(); // Событие снятия листинга с биржи
    event FeeCollected(address indexed from, uint256 value); // Событие сбора комиссии
    bool public contractClosed = false; // Флаг закрытия контракта
    bool public listingRemoved = false; // Флаг снятия листинга с биржи
    constructor() {
        owner = msg.sender; // Адрес владельца контракта
        balanceOf[msg.sender] = totalSupply; // Выдача всей капитализации на баланс владельца
    }
    modifier onlyOwner() {
        require(msg.sender == owner,"Only contract owner can call this function"); // Только владелец контракта может вызывать эту функцию
        _;
    }
    modifier onlyWhenOpen() {
        require(!contractClosed, "Contract is closed"); // Контракт закрыт
        _;
    }
    modifier onlyWhenListed() {
        require(!listingRemoved, "Listing is removed"); // Листинг на бирже снят
        _;
    }
    function transfer(address to, uint256 value) public onlyWhenOpen onlyWhenListed returns (bool)
    {
        require(to != address(0), "Invalid address"); // Неверный адрес
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Недостаточно средств на балансе
        balanceOf[msg.sender] -= value; // Уменьшение баланса отправителя
        balanceOf[to] += value; // Увеличение баланса получателя
        emit Transfer(msg.sender, to, value); // Генерация события перевода токенов
        return true;
    }
    function approve(address spender, uint256 value) public onlyWhenOpen onlyWhenListed returns (bool)
    {
        require(spender != address(0), "Invalid address"); // Неверный адрес
        allowance[msg.sender][spender] = value; // Установка разрешения на расходование токенов
        emit Approval(msg.sender, spender, value); // Генерация события разрешения на расходование токенов
        return true;
    }
    function transferFrom(address from, address to,uint256 value) public onlyWhenOpen onlyWhenListed returns (bool) {
        require(to != address(0), "Invalid address"); // Неверный адрес
        require(balanceOf[from] >= value, "Insufficient balance"); // Недостаточно средств на балансе отправителя
        require(allowance[from][msg.sender] >= value, "Insufficient allowance"); // Недостаточно разрешения на расходование токенов
        balanceOf[from] -= value; // Уменьшение баланса отправителя
        balanceOf[to] += value; // Увеличение баланса получателя
        allowance[from][msg.sender] -= value; // Уменьшение разрешения на расходование токенов
        emit Transfer(from, to, value); // Генерация события перевода токенов
        return true;
    }
    function burn(uint256 value) public onlyWhenOpen onlyOwner returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Недостаточно средств на балансе
        balanceOf[msg.sender] -= value; // Уменьшение баланса отправителя
        totalSupply -= value; // Уменьшение капитализации токена
        emit Burn(msg.sender, value); // Генерация события сжигания токенов
        return true;
    }
    function migrate(address to, uint256 value)public onlyWhenOpen onlyOwner returns (bool){
        require(to != address(0), "Invalid address"); // Неверный адрес
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Недостаточно средств на балансе
        balanceOf[msg.sender] -= value; // Уменьшение баланса отправителя
        balanceOf[to] += value; // Увеличение баланса получателя
        emit Migration(msg.sender, to, value); // Генерация события миграции токенов
        return true;
    }
    function closeContract() public onlyWhenOpen onlyOwner {
        contractClosed = true; // Установка флага закрытия контракта
        emit ContractClosed(); // Генерация события закрытия контракта
    }
    function removeListing() public onlyWhenOpen onlyOwner {
        listingRemoved = true; // Установка флага снятия листинга с биржи
        emit ListingRemoved(); // Генерация события снятия листинга с биржи
    }
    function collectFee(uint256 value) public onlyWhenOpen onlyOwner returns (bool)
    {
        require(value > 0, "Invalid value"); // Неверное значение комиссии
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Недостаточно средств на балансе
        balanceOf[msg.sender] -= value; // Уменьшение баланса отправителя
        emit FeeCollected(msg.sender, value); // Генерация события сбора комиссии
        return true;
    }
}
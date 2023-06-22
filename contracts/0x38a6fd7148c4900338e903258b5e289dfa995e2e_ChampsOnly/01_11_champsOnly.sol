// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//░█████╗░██╗░░██╗░█████╗░███╗░░░███╗██████╗░░██████╗  ░█████╗░███╗░░██╗██╗░░░░░██╗░░░██╗
//██╔══██╗██║░░██║██╔══██╗████╗░████║██╔══██╗██╔════╝  ██╔══██╗████╗░██║██║░░░░░╚██╗░██╔╝
//██║░░╚═╝███████║███████║██╔████╔██║██████╔╝╚█████╗░  ██║░░██║██╔██╗██║██║░░░░░░╚████╔╝░
//██║░░██╗██╔══██║██╔══██║██║╚██╔╝██║██╔═══╝░░╚═══██╗  ██║░░██║██║╚████║██║░░░░░░░╚██╔╝░░
//╚█████╔╝██║░░██║██║░░██║██║░╚═╝░██║██║░░░░░██████╔╝  ╚█████╔╝██║░╚███║███████╗░░░██║░░░
//░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░╚═════╝░  ░╚════╝░╚═╝░░╚══╝╚══════╝░░░╚═╝░░░

contract ChampsOnly is ERC1155Supply, Ownable
{
    bool public saleIsActive = false;
    uint public activeBadgeId = 1;
    uint public maxPerTransaction = 1;
    uint public maxPerWallet = 1;
    uint public maxSupply = 1444;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    uint256 public constant PRICE = 250000000000000000; //0.25 ETH
    string public name = "Champs Only";

    uint public reservedTokensMinted = 0;

    string public contractURIstr = "";

    constructor() ERC1155("https://ipfs.io/ipfs/QmZ5im37Mkz8k1F6ayM3WN25rcReCakXn8Wwur15rnTeN9/{id}.json") {}

    address payable private recipient1 = payable(0x2E69ab2e2Ab818be7D84815e5ac29B95e46F1ef2); //partners payout address

    function contractURI() public view returns (string memory)
    {
       return contractURIstr;
    }

    function setContractURI(string memory newuri) external onlyOwner
    {
       contractURIstr = newuri;
    }

    function setURI(string memory newuri) external onlyOwner
    {
        _setURI(newuri);
    }

    function setName(string memory _name) public onlyOwner 
    {
        name = _name;
    }

    function getName() public view returns (string memory) 
    {
       return name;
    }

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= maxPerTransaction, "Max per transaction reached, sale not allowed");
        require(balanceOf(msg.sender, activeBadgeId) + amount <= maxPerWallet, "Limit per wallet reached with this amount, sale not allowed");
        require(totalSupply(activeBadgeId) + amount <= maxSupply - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        _mint(msg.sender, activeBadgeId, amount, "");
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        _mint(to, activeBadgeId, amount, "");
        reservedTokensMinted = reservedTokensMinted + amount;
    }

    function withdraw() external
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 30;
        recipient1.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function changeSaleDetails(uint _activeBadgeId, uint _maxPerTransaction, uint _maxPerWallet, uint _maxSupply) external onlyOwner
    {
        activeBadgeId = _activeBadgeId;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
        maxSupply = _maxSupply;
        saleIsActive = false;
    }
}
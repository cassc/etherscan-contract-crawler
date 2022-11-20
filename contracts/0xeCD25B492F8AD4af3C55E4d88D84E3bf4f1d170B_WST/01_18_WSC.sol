// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract WST is ERC1155Supply, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    uint8[] public countries = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

    uint64[] public mintPrice = [
            10000000000000000,  //0
            15000000000000000,  //1
            22500000000000000, //2
            33750000000000000, //3
            50625000000000000, //4
            75937500000000000, //5
            91125000000000000  //6
    ];

    uint256 public valorInicialDtLimite = 1669370400; //price idx 0 -- 25/11 as 07
    uint256 public segundoValorDtLimite = 1669734000; //price idx 1 -- 29/11 as 12
    uint256 public terceiroValorDtLimite = 1670079600; //price idx 2  -- 03/12 as 12
    uint256 public quartoValorDtLimite = 1670353200; //price idx 3  -- 06/12 as 12
    uint256 public quintoValorDtLimite = 1670698800; //price idx 4 -- 10/12 as 16
    uint256 public sextoValorDtLimite = 1671044400; //price idx 5 -- 14/12 as 16
    uint256 public finalDtCompra = 1671375600; //price idx 6 -- 18/12 as 12

    bool public paused = false;

    string public name = "WORLD SOCCER TOURNAMENT";
    string public symbol = "WST";
    string _uri = "https://buidler.it/minters/wst/json/";
    address[] __payees;
    uint256[] __shares;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC1155(_uri)  PaymentSplitter(_payees,_shares) payable {
        __payees = _payees;
        __shares = _shares;
    }

    // Modifier to verify if contract is paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // Public purchase
    function publicPurchase( uint256 amount, uint256 index) external payable whenNotPaused {
        require(block.timestamp < finalDtCompra, "Mint is closed. ");
        _purchase(amount, index);
    }

    // Both functions ( presale and public ) call this one, to mint the nft.
    function _purchase(uint256 amount, uint256 index) private {
        require(msg.sender == tx.origin, "You can't use other contract.");

        uint64 precoAtual = mintPrice[0];

        if(block.timestamp >= valorInicialDtLimite)
            precoAtual = mintPrice[0];
        else if(block.timestamp >= segundoValorDtLimite)
            precoAtual = mintPrice[1];
        else if(block.timestamp >= terceiroValorDtLimite)
            precoAtual = mintPrice[2];
        else if(block.timestamp >= quartoValorDtLimite)
            precoAtual = mintPrice[3];
        else if(block.timestamp >= quintoValorDtLimite)
            precoAtual = mintPrice[4];
        else if(block.timestamp >= sextoValorDtLimite)
            precoAtual = mintPrice[5];
        else if(block.timestamp >= finalDtCompra)
            precoAtual = mintPrice[6];

        require(msg.value >= amount * precoAtual, "No enough funds.");

        _mint(msg.sender, index, amount, "");
    }

    // Pause the contract, so no one can call mint functions
    function pauseContract(bool _state) external onlyOwner {
        paused = _state;
    }

    // Change cost of the mint, array with three values, for each level (admission, creator, royal)
    function newCost(uint64[] calldata _newCost) external onlyOwner {
        mintPrice = _newCost;
    }

    // Uri of each token
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function setUri(string memory newUri) external onlyOwner {
        super._setURI(newUri);
    }

    function paymentWinner(address[] calldata _winners) external onlyOwner nonReentrant {

        uint256 totalBalance = address(this).balance;

        uint256 totalPerWin = totalBalance / _winners.length;

        for (uint i=0; i<_winners.length; i++) {
            (bool success, ) = _winners[i].call{value: totalPerWin}("");
            require(success, "Transfer failed.");
        }
    }

    function withdraw() external onlyOwner nonReentrant {

        uint256 totalBalance = address(this).balance;

        //get only 5% each
        uint256 totalToSend1 = totalBalance * __shares[0] / 100;
        uint256 totalToSend2 = totalBalance * __shares[1] / 100;

        (bool success, ) = __payees[0].call{value: totalToSend1}("");
        require(success, "Transfer 1 failed.");

        (success, ) = __payees[1].call{value: totalToSend2}("");
        require(success, "Transfer 2 failed.");
    }
}
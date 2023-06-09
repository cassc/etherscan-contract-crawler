// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RebelKids is ERC721Enumerable, Ownable {

    uint public constant MAX_SUPPLY = 6666;
    uint public constant TOKEN_PRICE = 0.06 ether;

    string private baseURI;

    bool public isSaleActive;
    bool public isPresaleActive;
    uint public presaleSupply;
    uint public reservedSupply;

    uint public maxMintsPerWallet;
    bool public currentEdition;
    uint public salesStage;
    mapping(address => mapping(uint => uint)) public mintedAmount;

    constructor () ERC721("Rebel Kids", "RBLKDS") {
    }

    // region setters and getters
    function setSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setBaseUri(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setPresaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setSalesStage(uint _salesStage) external onlyOwner {
        salesStage = _salesStage;
    }

    function setPresaleSupply(uint _presaleSupply) external onlyOwner {
        presaleSupply = _presaleSupply;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOwner {
        reservedSupply = _reservedSupply;
    }

    function configurePresale(uint _maxMintsPerWallet, uint _presaleSupply, uint _reservedSupply) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
        presaleSupply = _presaleSupply;
        reservedSupply = _reservedSupply;
        isPresaleActive = true;
    }

    function configureSale(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
        salesStage = 1;
        isPresaleActive = false;
        isSaleActive = true;
    }
    // endregion

    // region metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // endregion


    // region mint
    modifier maxSupplyCheck(uint amount) {
        require(totalSupply() < MAX_SUPPLY, "All NFTs have been minted.");
        require(amount > 0, "You must mint at least one token.");
        require(totalSupply() + amount <= MAX_SUPPLY, "The amount of tokens you are trying to mint exceeds the MAX_SUPPLY - reservedSupply.");
        _;
    }

    function sendTokensToOwner(uint amount) external onlyOwner maxSupplyCheck(amount) {
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function giftTokens(address[] memory addresses) external onlyOwner maxSupplyCheck(addresses.length) {
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], totalSupply() + 1);
        }
    }

    function mint(uint amountToMint) external payable maxSupplyCheck(amountToMint) {
        require(isSaleActive || isPresaleActive, "This sale has not started.");
        if (isPresaleActive) {
            require(amountToMint <= presaleSupply, "Presale supply is out");
            presaleSupply -= amountToMint;
        }
        require(TOKEN_PRICE * amountToMint == msg.value, "Incorrect Ether value.");
        require(mintedAmount[msg.sender][salesStage] + amountToMint <= maxMintsPerWallet, "Can't mint RebelKids more than maxMintsPerWallet");
        require(totalSupply() + amountToMint <= MAX_SUPPLY - reservedSupply, "The amount of tokens you are trying to mint exceeds the MAX_SUPPLY - reservedSupply.");

        mintedAmount[msg.sender][salesStage] += amountToMint;

        for (uint i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    // endregion

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xF50d29e58a4077030a806c8972F20b16aBfD4BA5).transfer(balance * 42 / 100);
        payable(0xaF7AD5541A59818b234c7b1c4893A7f3EDc5A04D).transfer(balance * 58 / 100);
    }

}
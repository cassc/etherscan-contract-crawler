// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract FancyParrots is ERC721A, Ownable {
    uint256 public immutable TOKENS_PER_WALLET;
    uint256 public maxSupply;
    bool public isSaleActive;
    string private baseURI_;
    mapping(address => uint256) private minters;

    constructor(uint256 _maxSupply, uint256 _tokensPerWallet)
        ERC721A("FancyParrots", "PARR")
    {
        maxSupply = _maxSupply;
        TOKENS_PER_WALLET = _tokensPerWallet;
    }

    modifier saleIsActive() {
        require(isSaleActive, "Sale is not active");
        _;
    }

    modifier notSoldOut(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, "Sold out");
        _;
    }

    modifier correctAmount(uint256 amount) {
        require(
            minters[msg.sender] + amount <= TOKENS_PER_WALLET,
            "Invalid amount"
        );
        _;
    }

    function changeSaleStatus(bool _status) external onlyOwner {
        isSaleActive = _status;
    }

    function safeMint(uint256 _amount) public onlyOwner notSoldOut(_amount) {
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount)
        public
        saleIsActive
        correctAmount(_amount)
        notSoldOut(_amount)
    {
        minters[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI_ = _newBaseURI;
    }
}
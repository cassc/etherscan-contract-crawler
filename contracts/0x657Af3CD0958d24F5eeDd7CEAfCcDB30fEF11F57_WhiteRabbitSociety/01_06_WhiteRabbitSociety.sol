// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteRabbitSociety is ERC721A, Ownable {
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    string private _baseURIextended;
    uint256 public MAX_SUPPLY = 500;
    uint256 public MAX_WL_SUPPLY = 100;
    uint256 public MAX_TX_MINT = 1;
    uint256 public PRICE_PER_TOKEN_PUBLIC_SALE = 1 ether;
    uint256 public PRICE_PER_TOKEN_PRE_SALE = 0.8 ether;
    mapping(address => bool) private _allowList;

    constructor() ERC721A("White Rabbit Society", "WRS") {}

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, bool allowed)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = allowed;
        }
    }

    function isAllowedToMint(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to purchase");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(
            ts + numberOfTokens <= MAX_WL_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
        require(
            totalSupply() + n <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _safeMint(msg.sender, n);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setPrices(uint256 pPublic, uint256 pPresale) public onlyOwner {
        require(
            pPublic >= 0 && pPresale >= 0,
            "Prices should be higher or equal than zero."
        );
        PRICE_PER_TOKEN_PUBLIC_SALE = pPublic;
        PRICE_PER_TOKEN_PRE_SALE = pPresale;
    }

    function setLimits(
        uint256 mSupply,
        uint256 mWLSupply,
        uint256 mTx
    ) public onlyOwner {
        require(
            mSupply >= totalSupply(),
            "MAX_SUPPLY should be higher or equal than total supply."
        );
        require(
            mWLSupply <= mSupply,
            "MAX_WL_SUPPLY should be less or equal than total supply."
        );
        require(mTx >= 0, "MAX_TX_MINT should be higher or equal than zero.");
        MAX_SUPPLY = mSupply;
        MAX_WL_SUPPLY = mWLSupply;
        MAX_TX_MINT = mTx;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN_PUBLIC_SALE * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        if (tkn == address(0)) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens.");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }
}
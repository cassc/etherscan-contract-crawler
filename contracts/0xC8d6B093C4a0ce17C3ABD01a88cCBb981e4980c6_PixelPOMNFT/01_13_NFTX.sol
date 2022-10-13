// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
interface IRouter {
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract PixelPOMNFT is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    address public tokenToHold;
    string private _baseURIextended;
    uint256 public MAX_SUPPLY = 50;
    uint256 public MAX_WL_SUPPLY = 50;
    uint256 public MAX_TX_MINT = 5;
    uint256 public MAX_PER_WALLET = 5;
    uint256 public PRICE_PER_TOKEN_PUBLIC_SALE = 0.03 ether;
    uint256 public PRICE_PER_TOKEN_PRE_SALE = 0.4 ether;
    uint256 public MIN_TOKEN_QTY_TO_HOLD = 250000 ether;

    mapping(address => bool) private _allowList;

    constructor(address _tokenToHold) ERC721("PixelPOM NFT", "PixelPOMNFT") {
        tokenToHold = _tokenToHold;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setMinTokenQtyToHold(uint256 _MIN_TOKEN_QTY_TO_HOLD) external onlyOwner {
        MIN_TOKEN_QTY_TO_HOLD = _MIN_TOKEN_QTY_TO_HOLD;
    }

    function setAllowList(address[] calldata addresses, bool allowed) external onlyOwner {
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
        require(ts + numberOfTokens <= MAX_WL_SUPPLY, "Purchase would exceed max tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_PER_WALLET, "Max Per Wallet");
        require(PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setPrices(uint256 pPublic, uint256 pPresale) public onlyOwner {
        require(pPublic >= 0 && pPresale >= 0, "Prices should be higher or equal than zero.");
        PRICE_PER_TOKEN_PUBLIC_SALE = pPublic;
        PRICE_PER_TOKEN_PRE_SALE = pPresale;
    }

    function setLimits(uint256 mSupply, uint256 mWLSupply, uint256 mTx) public onlyOwner {
        require(mSupply >= totalSupply(), "MAX_SUPPLY should be higher or equal than total supply.");
        require(mWLSupply <= mSupply, "MAX_WL_SUPPLY should be less or equal than total supply.");
        require(mTx >= 0, "MAX_TX_MINT should be higher or equal than zero.");
        MAX_SUPPLY = mSupply;
        MAX_WL_SUPPLY = mWLSupply;
        MAX_TX_MINT = mTx;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_PER_WALLET, "Max Per Wallet");
        if (IERC20(tokenToHold).balanceOf(msg.sender) <= MIN_TOKEN_QTY_TO_HOLD) {
            require(PRICE_PER_TOKEN_PUBLIC_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
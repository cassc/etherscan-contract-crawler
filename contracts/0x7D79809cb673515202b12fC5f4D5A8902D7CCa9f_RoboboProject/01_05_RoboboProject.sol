// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract RoboboProject is ERC721A, Ownable {
    uint256 public immutable maxPerWallet;
    uint256 public immutable maxFreePerWallet;
    uint256 public immutable maxSupply;
    uint256 public immutable maxFree;
    uint256 public price = 0.005 ether;
    bool public isMintActive;
    string private baseURI_;
    string private _contractURI;

    mapping(address => uint256) private minters;

    constructor(
        uint256 _maxSupply,
        uint256 _maxFree,
        uint256 _maxFreePerWallet,
        uint256 _maxPerWallet
    ) ERC721A("Robobo Project", "ROBOBO") {
        maxSupply = _maxSupply;
        maxFree = _maxFree;
        maxFreePerWallet = _maxFreePerWallet;
        maxPerWallet = _maxPerWallet;
    }

    modifier mintIsActive() {
        require(isMintActive, "Sale is not active");
        _;
    }

    modifier notSoldOut(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, "Sold out");
        _;
    }

    function changeSaleStatus(bool _status) external onlyOwner {
        isMintActive = _status;
    }

    function ownerMint(uint256 _amount) public onlyOwner notSoldOut(_amount) {
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount)
        public
        payable
        mintIsActive
        notSoldOut(_amount)
    {
        if (totalSupply() + _amount <= maxFree) {
            require(
                minters[msg.sender] + _amount <= maxFreePerWallet,
                "Invalid amount"
            );
            minters[msg.sender] += _amount;
            _safeMint(msg.sender, _amount);
        } else {
            require(
                minters[msg.sender] + _amount <= maxPerWallet,
                "Invalid amount"
            );
            require(msg.value >= price * _amount, "Invalid value");
            minters[msg.sender] += _amount;
            _safeMint(msg.sender, _amount);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI_ = _newBaseURI;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
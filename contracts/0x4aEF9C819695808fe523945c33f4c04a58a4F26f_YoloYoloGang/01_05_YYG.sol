// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YoloYoloGang is ERC721A, Ownable {
    uint256 public constant MAX_PAID_PER_TX = 4;
    uint256 public constant MAX_FREE_PER_TX = 1;
    uint256 public constant MAX_PAID_PER_WALLET = 4;
    uint256 public constant MAX_FREE_PER_WALLET = 1;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_DEV_MINT = 1;
    uint256 public constant MINT_PRICE = 0.00085 ether;
    string public baseURI;
    bool public isSaleActive = false;
    mapping(address => bool) public freeMintClaimed;
    mapping(address => uint) public numPaidMinted;
    
    error CallerNotOwner();
    error MintNotOpen();
    error ExceedsMaxSupply();
    error ExceedsMaxPerTx();
    error ExceedsMaxPerTxFree();
    error IncorrectValueSent();
    error MaxFreeMints();
    error MaxPaidMints();
    error ExceedsMaxDevMint();

    constructor() ERC721A("Yolo Yolo Gang", "YYG") {}

    function mint(uint8 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        if (tx.origin != msg.sender) {
            revert CallerNotOwner();
        }

        if (!isSaleActive) {
            revert MintNotOpen();
        }

        if (currentSupply + _quantity > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        if (_quantity > 0 && _quantity > MAX_PAID_PER_TX) {
            revert ExceedsMaxPerTx();
        }

        if ((MINT_PRICE * _quantity) != msg.value) {
            revert IncorrectValueSent();
        }

        if (numPaidMinted[msg.sender] + _quantity > MAX_PAID_PER_WALLET) {
            revert MaxPaidMints();
        }

        numPaidMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint8 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        if (tx.origin != msg.sender) {
            revert CallerNotOwner();
        }

        if (!isSaleActive) {
            revert MintNotOpen();
        }

        if (currentSupply + _quantity > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        if (_quantity > 0 && _quantity > MAX_FREE_PER_TX) {
            revert ExceedsMaxPerTxFree();
        }

        if (freeMintClaimed[msg.sender]) {
            revert MaxFreeMints();
        }

        freeMintClaimed[msg.sender] = true;
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(address _address, uint256 _quantity) external onlyOwner {
        uint256 currentSupply = totalSupply();
        if (currentSupply + _quantity > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        if (_quantity > MAX_DEV_MINT) {
            revert ExceedsMaxDevMint();
        }

        _safeMint(_address, _quantity);
    }

    function setIsSaleActive(bool _state) external onlyOwner {
        isSaleActive = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

error InsufficientFunds();
error FreeAlreadyClaimed();
error MissingQuantity();
error ExceedsSupply();

contract MM is ERC721A, Ownable, Pausable, PaymentSplitter {
    using Strings for uint256;
    uint256 public FREE = 1000;
    uint256 public FREE_CLAIMED = 0;
    uint256 public PRICE = 0.00069 ether;
    uint128 public MAX_SUPPLY = 6969;
    bool public revealed = false;

    mapping(address => bool) public FREE_MINTS;

    string public baseURI;
    address[] internal TEAM;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _baseuri,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A(_name, _ticker) PaymentSplitter(_payees, _shares) {
        TEAM = _payees;
        baseURI = _baseuri;
        for (uint256 i = 0; i < TEAM.length; i++) {
            _safeMint(TEAM[i], 20);
        }
    }

    function freeMint() public whenNotPaused {
        require(msg.sender == tx.origin, "no contract calls");
        if (FREE_CLAIMED >= FREE) {
            revert FreeAlreadyClaimed();
        }
        if (FREE_MINTS[msg.sender] == true) {
            revert FreeAlreadyClaimed();
        }
        FREE_MINTS[msg.sender] = true;
        FREE_CLAIMED++;
        _mint(msg.sender, 1);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        if (quantity < 1) {
            revert MissingQuantity();
        }
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert ExceedsSupply();
        }

        if (msg.value < PRICE * quantity) {
            revert InsufficientFunds();
        }

        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');
        if (revealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function airdrop(address[] calldata _wallets) external onlyOwner {
        uint256 wallets = _wallets.length;
        if (wallets + totalSupply() > MAX_SUPPLY) {
            revert ExceedsSupply();
        }

        for (uint256 i = 0; i < wallets; i++) {
            if (_wallets[i] != address(0)) {
                _safeMint(_wallets[i], 1);
            }
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setBaseURI(string memory _URI, bool _reveal) external onlyOwner {
        baseURI = _URI;
        revealed = _reveal;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < TEAM.length; i++) {
            release(payable(TEAM[i]));
        }
    }
}
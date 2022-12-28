// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

error UnderPaid();
error ExceedsMintLimit();
error MissingQuantity();
error ExceedsSupply();

contract SavageAI is ERC721A, Ownable, Pausable, PaymentSplitter {
    using Strings for uint256;
    uint256 public MINT_PRICE = 0.003 ether;
    uint128 public MAX_SUPPLY = 444;
    uint256 public MINT_LIMIT = 5;
    bool public WALLET_LIMIT = true;
    mapping(address => uint256) public WALLET_MINTS;

    string public baseURI;
    address[] internal team;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _baseuri,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A(_name, _ticker) PaymentSplitter(_payees, _shares) {
        team = _payees;
        baseURI = _baseuri;
        for (uint256 i = 0; i < team.length; i++) {
            _safeMint(team[i], 10);
        }
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        if (quantity < 1) {
            revert MissingQuantity();
        }
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert ExceedsSupply();
        }
        if (WALLET_LIMIT && WALLET_MINTS[msg.sender] + quantity > MINT_LIMIT) {
            revert ExceedsMintLimit();
        }
        if (msg.value < MINT_PRICE * quantity) {
            revert UnderPaid();
        }
        if (quantity > MINT_LIMIT) {
            revert ExceedsMintLimit();
        }

        _mint(msg.sender, quantity);
        WALLET_MINTS[msg.sender] += quantity;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    //// Owner functions

    function drop(address[] calldata _wallets) external onlyOwner {
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

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function toggleWalletLimit(bool _state) external onlyOwner {
        WALLET_LIMIT = _state;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < team.length; i++) {
            release(payable(team[i]));
        }
    }
}
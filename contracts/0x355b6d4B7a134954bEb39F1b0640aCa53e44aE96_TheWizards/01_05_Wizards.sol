// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

// The choice is yours...

contract TheWizards is ERC721A, Ownable {

    enum MintState {
        Closed,
        Open
    }

    MintState public mintState;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant PRICE = 0 ether;
    uint256 public constant WALLET_LIMIT = 3;

    string public baseURI;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) ERC721A("TheWizards", "Wizard") {
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // Magic mint functions

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Open;
        else revert("Invalid state");
    }

    function remainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return WALLET_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Mint not open");
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");

        uint256 supply = this.totalSupply();
        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= MAX_SUPPLY, "Mint exceeds max supply");
            _mint(recipients[i], quantities[i]);
        }
    }

    function mint(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Open, "Mint state mismatch");
        require(msg.value >= PRICE * quantity, "Insufficient value");
        require(remainingForAddress(msg.sender) >= quantity, "You're a Wizard, surely you can count");

        _mint(msg.sender, quantity);
    }

    // Token

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Some Wizards can't count

    function withdraw() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;
        address theWizards  = 0xBC386D3193387072413d9e71fe6627Fd441D8C28;
        address(theWizards).call{value: balancePercentage * 100}("");
    }
}
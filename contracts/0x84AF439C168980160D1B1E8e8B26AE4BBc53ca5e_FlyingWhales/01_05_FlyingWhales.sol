// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract FlyingWhales is ERC721A, Ownable {

    enum MintState {
        Closed,
        Free,
        Open
    }

    MintState public mintState;

    uint256 public constant FREE_MINT_AMOUNT = 100;
    uint256 public constant MAX_SUPPLY = 900;
    uint256 public constant WALLET_LIMIT = 3;
    uint256 public constant FREE_MINT_LIMIT = 1;
    uint256 public PRICE = 0.0015 ether;

    string public baseURI;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) ERC721A("FlyingWhales", "FW") {
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // Mint functions

    function remainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Free)
            return FREE_MINT_LIMIT - _numberMinted(who);
        else if (mintState == MintState.Open)
            return WALLET_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Invalid sale state");
    }

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Free;
        else if (newState == 2) mintState = MintState.Open;
        else revert("Invalid sale state");
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

    function freeMint(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= FREE_MINT_AMOUNT, "Mint exceeds max supply");
        require(mintState == MintState.Free, "Invalid sale state");
        require(remainingForAddress(msg.sender) >= quantity, "Limit for user reached");

        _mint(msg.sender, quantity);
        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity));
    }

    function mint(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Open, "Invalid sale state");
        require(msg.value >= PRICE * quantity, "Insufficient value");
        require(remainingForAddress(msg.sender) >= quantity, "Limit for user reached");

        _mint(msg.sender, quantity);
    }

    // Token

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    // Withdraw

    function withdraw() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner  = 0xCedBAc099578d6a3f23C8C15aC0Fcb3C947191c0;
        address dev = 0x7DD5a65e6132F3aBa8F5e75877b389a6dac36277;

        address(owner).call{value: balancePercentage * 70}("");
        address(dev).call{value: balancePercentage * 30}("");
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract HumanoidsAI is ERC721A, Ownable {

    enum MintState {
        Closed,
        Open
    }

    MintState public mintState;

    uint256 public constant MAX_SUPPLY = 333;
    uint256 public constant PRICE = 0.009 ether;
    uint256 public constant WALLET_LIMIT = 1;

    string public baseURI;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) ERC721A("HumanoidsAI", "HumanoidsAI") {
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // Mint functions

    function remainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return WALLET_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Invalid sale state");
    }

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Open;
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

    // Withdraw

    function withdraw() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address humanoid  = 0xA8238931687eabA797Af4ddB2CDDacb1426Ec70d;

        address(humanoid).call{value: balancePercentage * 100}("");
    }
}
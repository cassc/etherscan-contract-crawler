// SPDX-License-Identifier: MIT

/*
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  +
|__       __                                __        __            __       __             ______   __                |
|  \     /  \                              |  \      |  \          |  \     /  \           /      \ |  \               |
| $$\   /  $$ __    __  _______    _______ | $$____   \$$  ______  | $$\   /  $$  ______  |  $$$$$$\ \$$  ______       |
| $$$\ /  $$$|  \  |  \|       \  /       \| $$    \ |  \ /      \ | $$$\ /  $$$ |      \ | $$_  \$$|  \ |      \      |
| $$$$\  $$$$| $$  | $$| $$$$$$$\|  $$$$$$$| $$$$$$$\| $$|  $$$$$$\| $$$$\  $$$$  \$$$$$$\| $$ \    | $$  \$$$$$$\     |
| $$\$$ $$ $$| $$  | $$| $$  | $$| $$      | $$  | $$| $$| $$    $$| $$\$$ $$ $$ /      $$| $$$$    | $$ /      $$     |
| $$ \$$$| $$| $$__/ $$| $$  | $$| $$_____ | $$  | $$| $$| $$$$$$$$| $$ \$$$| $$|  $$$$$$$| $$      | $$|  $$$$$$$     |
| $$  \$ | $$ \$$    $$| $$  | $$ \$$     \| $$  | $$| $$ \$$     \| $$  \$ | $$ \$$    $$| $$      | $$ \$$    $$     |
|\$$      \$$  \$$$$$$  \$$   \$$  \$$$$$$$ \$$   \$$ \$$  \$$$$$$$ \$$      \$$  \$$$$$$$ \$$       \$$  \$$$$$$$     |
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  +
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract TonyMontanaMM is ERC721A, Ownable, PaymentSplitter {
    bool public saleIsActive = false;
    bool public isOgMintActive = false;
    bool public isFreeOgMintActive = false;

    string private _baseURIextended;
    uint256 public PRICE_PER_TOKEN = 10000000000000000 wei; // (PRICE_PER_TOKEN / 1e18) => ETH
    uint256 public PRICE_PER_TOKEN_OG = 20000000000000000 wei; // (PRICE_PER_TOKEN_OG / 1e18) => ETH

    uint256 public MAX_SUPPLY = 2100;
    uint256 public constant MAX_PUBLIC_MINT = 20;

    mapping(address => uint16) private ogList;
    mapping(address => uint16) private freeOgList;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721A("TonyMontanaMM", "TMMM")
        PaymentSplitter(payees, shares)
    {}

    function setPublicMintPrice(uint256 price) external onlyOwner {
        PRICE_PER_TOKEN = price;
    }

    function setOgMintPrice(uint256 price) external onlyOwner {
        PRICE_PER_TOKEN_OG = price;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        MAX_SUPPLY = maxSupply;
    }

    function setIsOgMintActive(bool _isOgMintActive) external onlyOwner {
        isOgMintActive = _isOgMintActive;
    }

    struct OgMintEntry {
        address wallet;
        uint16 allowed_mints;
    }

    function setFreeOgList(OgMintEntry[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            freeOgList[entries[i].wallet] = entries[i].allowed_mints;
        }
    }

    function setOgList(OgMintEntry[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            ogList[entries[i].wallet] = entries[i].allowed_mints;
        }
    }

    function numAvailableToFreeMint(address addr) external view returns (uint16) {
        return freeOgList[addr];
    }

    function numAvailableToMint(address addr) external view returns (uint16) {
        return ogList[addr];
    }

    function mintOgList(uint16 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isOgMintActive, "OG mint is not active");
        require(
            numberOfTokens <= ogList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN_OG * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        ogList[msg.sender] -= numberOfTokens;
        _mint(msg.sender, numberOfTokens);
    }

    function setIsFreeOgMintActive(bool _isFreeOkMintActive)
        external
        onlyOwner
    {
        isFreeOgMintActive = _isFreeOkMintActive;
    }

    function mintOgFree(uint16 numberOfTokens) external {
        uint256 ts = totalSupply();

        require(isFreeOgMintActive, "Free OG mint is not active");

        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(freeOgList[msg.sender] > 0, "No Free Mint left");

        freeOgList[msg.sender] -= numberOfTokens;
        _mint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + quantity <= MAX_SUPPLY,
            "Reserve would exceed max tokens"
        );

        _mint(msg.sender, quantity);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(
            numberOfTokens <= MAX_PUBLIC_MINT,
            "Exceeded max token purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
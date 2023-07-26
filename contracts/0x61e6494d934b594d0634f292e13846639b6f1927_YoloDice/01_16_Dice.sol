// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract YoloDice is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    uint public constant MAX_SUPPLY = 3636;
    uint public constant AIRDROP_QUANTITY = 360;
    uint public constant PRE_SALE_QUANTITY = 852;
    uint public constant MAX_MINT_AMOUNT = 20;

    uint public presaleTimestamp;
    uint public generalSaleTimestamp;

    mapping (address => bool) private presaleWallets;
    
    uint public constant SALE_PRICE = 0.072 ether;
    uint public constant PRESALE_PRICE = 0.05 ether;

    string public baseURI = "https://api.yolodice.xyz/dice/";

    Counters.Counter private _tokenIdCounter;

    constructor(uint256 _presaleTimestamp, uint256 _generalSaleTimestamp) ERC721("Yolo Dice", "DICE") {
        presaleTimestamp = _presaleTimestamp;
        generalSaleTimestamp = _generalSaleTimestamp;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function setPresaleTimestamp(uint256 _presaleTimestamp) public onlyOwner {
        presaleTimestamp = _presaleTimestamp;
    }

    function setGeneralSaleTimestamp(uint256 _generalSaleTimestamp) public onlyOwner {
        generalSaleTimestamp = _generalSaleTimestamp;
    }

    function registerPresaleWallets(address[] memory wallets) public onlyOwner {
        for (uint idx = 0; idx < wallets.length; idx++) {
            presaleWallets[wallets[idx]] = true;
        }
    }

    function isRegisteredForPresale(address wallet) public view returns (bool) {
        return presaleWallets[wallet];
    }

    /// @notice The owner-only airdrop minting.
    function mintAirdrop(uint256 amount) public onlyOwner {
        uint currentTotalSupply = totalSupply();

        /// @notice This must be done before pre-sale or general minting.
        require(currentTotalSupply < AIRDROP_QUANTITY, "Yolo Dice: Max airdrop quantity reached");

        if (currentTotalSupply + amount > AIRDROP_QUANTITY) {
            amount = AIRDROP_QUANTITY - currentTotalSupply;
        }

        _mintAmountTo(msg.sender, amount);
    }

    /// @notice Registered pre-sale minting.
    function mintPresale(uint256 amount) public payable {
        uint currentTotalSupply = totalSupply();

        /// @notice Pre-sale minting cannot happen until the designated time.
        require(presaleTimestamp <= block.timestamp, "Yolo Dice: Pre-sale not yet started");

        /// @notice Pre-sale minting cannot happen until airdrop is complete.
        require(currentTotalSupply >= AIRDROP_QUANTITY, "Yolo Dice: Not yet launched");

        /// @notice Sender wallet must be registered for the pre-sale.
        require(isRegisteredForPresale(msg.sender), "Yolo Dice: Not registered for pre-sale");

        /// @notice Cannot exceed the pre-sale supply.
        require(currentTotalSupply + amount <= AIRDROP_QUANTITY + PRE_SALE_QUANTITY, "Yolo Dice: Not enough pre-sale supply left");

        /// @notice Cannot mint more than the max mint per transaction.
        require(amount <= MAX_MINT_AMOUNT, "Yolo Dice: Mint amount exceeds the limit");

        /// @notice Must send the correct amount.
        require(msg.value > 0 && msg.value == amount * PRESALE_PRICE, "Yolo Dice: Pre-sale minting price not met");

        _mintAmountTo(msg.sender, amount);
    }

    /// @notice Public minting.
    function mint(uint256 amount) public payable {
        uint currentTotalSupply = totalSupply();

        /// @notice Public minting cannot happen until the general sale has started.
        require(generalSaleTimestamp <= block.timestamp, "Yolo Dice: Sale not yet started");

        /// @notice Public minting cannot happen until the pre-sale is complete.
        require(currentTotalSupply >= AIRDROP_QUANTITY, "Yolo Dice: Not yet launched");

        /// @notice Cannot exceed the total supply of dice.
        require(currentTotalSupply + amount <= MAX_SUPPLY, "Yolo Dice: Not enough mints left");

        /// @notice Cannot mint more than the max mint per transaction.
        require(amount <= MAX_MINT_AMOUNT, "Yolo Dice: Mint amount exceeds the limit");

        /// @notice Must send the correct amount.
        require(msg.value > 0 && msg.value == amount * SALE_PRICE, "Yolo Dice: Minting price not met");

        _mintAmountTo(msg.sender, amount);
    }

    /// @notice Send contract balance to owner.
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Yolo Dice: Withdraw failed");
    }

    function _mintAmountTo(address to, uint256 amount) internal {
        for (uint idx = 1; idx <= amount; idx++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
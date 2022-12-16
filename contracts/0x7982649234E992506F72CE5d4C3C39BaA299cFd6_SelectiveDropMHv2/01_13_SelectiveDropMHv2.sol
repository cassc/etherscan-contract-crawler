// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "IWithBalance.sol"; // needed for auction, see usage in NFTAuction.sol (hasWhitelistedToken)
import "ERC1155.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";

contract SelectiveDropMHv2 is IWithBalance, ERC1155, Pausable, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;

    uint256 public immutable tokensCount;
    uint256 public immutable maxSupply;

    uint256 public immutable price;

    uint256 public immutable startTime;

    bool internal isLockedURI;

    address public immutable withdrawAddress;

    // set this number to 0 for unlimited mints per wallet
    uint256 internal maxMintsPerWallet;

    mapping(address => uint256) internal mintsPerWallet;
    // Mapping owner address to token count
    mapping(address => uint256) private _totalBalances;
    //for ERC1155Supply
    mapping(uint256 => uint256) private _totalSupply;

    constructor(uint256 price_, uint256 tokensCount_, uint256 maxSupply_, string memory name_, string memory symbol_,
                uint256 maxMintsPerWallet_, string memory baseURI_, uint256 startTime_, address withdrawAddress_)
                ERC1155(baseURI_) {
        price = price_;
        tokensCount = tokensCount_;
        maxSupply = maxSupply_;
        name = name_;
        symbol = symbol_;

        maxMintsPerWallet = maxMintsPerWallet_;

        startTime = startTime_;
        withdrawAddress = withdrawAddress_;
    }

    // pause minting
    function pause() external onlyOwner {
        _pause();
    }

    // unpause minting
    function unpause() external onlyOwner {
        _unpause();
    }

    // Total amount of tokens in with a given id
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    // Total amount of tokens
    function totalSupply() public view virtual returns (uint256) {
        return viewMinted();
    }

    // Indicates whether any token exist with a given id, or not
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    // get maximum number of tokens
    function getMaxTokens() public view returns(uint256) {
        return tokensCount * maxSupply;
    }

    // get current number of tokens
    function viewMinted() public view returns(uint256) {
        uint256 mintedCount = 0;
        for (uint256 i = 1; i <= tokensCount; i++) {
            mintedCount += _totalSupply[i];
        }
        return mintedCount;
    }

    // Lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner external
    {
        require(!isLockedURI, "URI change has been locked");
        _setURI(newBaseURI);
    }

    // Change the maximum number of mints per wallet
    function changeMaxMints(uint256 newMax) onlyOwner external
    {
        maxMintsPerWallet = newMax;
    }

    // total balance
    function balanceOf(address owner) external view returns (uint256) {
        return _totalBalances[owner];
    }

    // Mint tokens to address
    function _mintTo(uint256[] memory tokenIds, address to)
        internal
        virtual
        whenNotPaused
    {
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId >= 1 && tokenId <= tokensCount, "Token ID is out of range!");
            require(_totalSupply[tokenId] + 1 <= maxSupply, "This amount exceeds the maximum number of NFTs on sale!");
            amounts[i] = 1;
            _totalSupply[tokenId] += 1;
        }

        _mintBatch(to, tokenIds, amounts, "");
        _totalBalances[to] += tokenIds.length;

        if(maxMintsPerWallet > 0) mintsPerWallet[to] += tokenIds.length;
    }

    // Mint tokens to address
    function mintTo(uint256[] memory tokenIds, address to)
        payable
        public
        virtual
        whenNotPaused
        nonReentrant
    {
        require(block.timestamp >= startTime, "Minting is not started yet!");
        require(msg.value >= price * tokenIds.length, "You have not sent the required amount of ETH");
        require(tokenIds.length <= tokensCount, "Token minting limit per transaction exceeded");

        if(maxMintsPerWallet > 0)
            require(mintsPerWallet[to] + tokenIds.length <= maxMintsPerWallet, "Exceeds number of mints per wallet");

        _mintTo(tokenIds, to);
    }

    // Mint tokens
    function mint(uint256[] memory tokenIds)
        payable
        external
    {
        mintTo(tokenIds, msg.sender);
    }

    // Airdrop tokens
    function airdrop(uint256[] memory tokenIds, address to)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        _mintTo(tokenIds, to);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) return; // minting already handled

        uint256 tokensToTransfer;
        for(uint256 i = 0; i < amounts.length; i++) tokensToTransfer += amounts[i];

        _totalBalances[from] -= tokensToTransfer;
        if (to != address(0)) _totalBalances[to] += tokensToTransfer;
    }

    // anybody can withdraw contract balance to ukraineAddress
    function withdraw()
        public
        nonReentrant
    {
        require(msg.sender == tx.origin, "Sender must be a wallet");
        uint256 bal_ = address(this).balance;
        payable(withdrawAddress).transfer(bal_);
    }
}
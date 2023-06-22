// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IWithBalance.sol"; // needed for auction, see usage in NFTAuction.sol (hasWhitelistedToken)
import "ERC1155Pausable.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";

contract DropMH is IWithBalance, ERC1155Pausable, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;

    uint256 public immutable tokensCount;
    uint256 public immutable maxSupply;

    uint256 internal tokenIdToMint;
    uint256 internal editionToMint;

    uint256 public immutable price;

    bool internal isLockedURI;

    address public constant ukraineAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    // smart-contract that can burn tokens (Merger as example)
    address public burner;

    // set this number to 0 for unlimited mints per wallet
    uint256 internal maxMintsPerWallet;

    mapping(address => uint256) internal mintsPerWallet;

    // Mapping owner address to token count
    mapping(address => uint256) private _totalBalances;

    //for ERC1155Supply
    mapping(uint256 => uint256) private _totalSupply;

    uint256 public burntTokens;

    constructor(uint256 price_, uint256 tokensCount_, uint256 maxSupply_, string memory name_, string memory symbol_,
                        uint256 maxMintsPerWallet_, string memory baseURI_) ERC1155(baseURI_) {
        price = price_;
        tokensCount = tokensCount_;
        maxSupply = maxSupply_;
        name = name_;
        symbol = symbol_;

        maxMintsPerWallet = maxMintsPerWallet_;

        tokenIdToMint = 1;
        editionToMint = 1;

        _pause();
    }

    // Limit on NFT sale
    modifier saleIsOpen{
        require(viewMinted() < getMaxTokens(), "Sale end");
        _;
    }

    // pause minting
    function pause() public onlyOwner {
        _pause();
    }

    // unpause minting
    function unpause() public onlyOwner {
        _unpause();
    }

    // Total amount of tokens in with a given id
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    // Total amount of tokens
    function totalSupply() public view virtual returns (uint256) {
        return viewMinted() - burntTokens;
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
        return tokensCount * (editionToMint - 1) + (tokenIdToMint - 1);
    }

    // Lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // Set address that can burn tokens (can be used for "merging")
    function setBurner(address burner_) external onlyOwner {
        burner = burner_;
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
    function _mintTo(uint256 numberOfTokens, address to)
        internal
        whenNotPaused
        saleIsOpen
        returns (uint256)
    {
        require(viewMinted() + numberOfTokens <= getMaxTokens(), "This amount exceeds the maximum number of NFTs on sale!");

        uint256[] memory ids = new uint256[](numberOfTokens);
        uint256[] memory amounts = new uint256[](numberOfTokens);

        //mint "in cycles": 1, 2, 3, ..., 100, 1, 2, 3, ..., 100, ...
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = (tokenIdToMint + i - 1) % tokensCount + 1;
            ids[i] = tokenId;
            amounts[i] = 1;
            _totalSupply[tokenId] += 1;
        }

        _mintBatch(to, ids, amounts, "");
        _totalBalances[to] += numberOfTokens;

        uint256 nextToMint = tokenIdToMint + numberOfTokens;
        if (nextToMint > tokensCount) {
            uint256 lastMinted = nextToMint - 1;
            editionToMint += lastMinted / tokensCount;
            tokenIdToMint = lastMinted % tokensCount + 1;
        } else {
            tokenIdToMint = nextToMint;
        }

        if(maxMintsPerWallet > 0)
            mintsPerWallet[to] += numberOfTokens;

        return viewMinted();
    }

    // Mint tokens
    function mint(uint256 numberOfTokens)
        payable
        external
        whenNotPaused
        saleIsOpen
        nonReentrant
        returns (uint256)
    {
        require(msg.value >= price * numberOfTokens, "You have not sent the required amount of ETH");
        require(numberOfTokens <= tokensCount, "Token minting limit per transaction exceeded");

        if(maxMintsPerWallet > 0)
            require(mintsPerWallet[msg.sender] + numberOfTokens <= maxMintsPerWallet, "Exceeds number of mints per wallet");

        return _mintTo(numberOfTokens, msg.sender);
    }

    // Airdrop tokens
    function airdrop(uint256 numberOfTokens, address to)
        external
        onlyOwner
        whenNotPaused
        saleIsOpen
        nonReentrant
        returns (uint256)
    {
        return _mintTo(numberOfTokens, to);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(msg.sender == burner, "Only burner can burn tokens");
        require(_totalSupply[id] >= amount, "ERC1155: burn amount exceeds totalSupply");
        unchecked {
            _totalSupply[id] = _totalSupply[id] - amount;
        }
        _burn(from, id, amount);
        burntTokens += amount;
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
        payable(ukraineAddress).transfer(bal_);
    }
}
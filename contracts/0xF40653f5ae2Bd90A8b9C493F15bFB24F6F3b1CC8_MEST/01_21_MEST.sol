// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./helpers/PriceConsumerV3.sol";
import "./security/ReEntrancyGuard.sol";

contract MEST is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    ReEntrancyGuard,
    PriceConsumerV3
{
    // Price of each token usd
    uint256 public pricePerNft = 150000000000000000000;

    string public baseTokenURI = ""; // The base link that leads to the image / video of the token

    /// @dev is sale active
    bool public isSaleActive = false; // Is the sale active?

    /// @dev max mint per transaction
    uint public MAX_MINT_PER_TX = 5; // Maximum number of tokens that can be minted per transaction

    // @dev SafeMath library
    using SafeMath for uint256;

    /// @dev max supply
    uint public MAX_SUPPLY = 0; // Maximum limit of tokens that can ever exist

    /// @dev mapping of affiliate
    mapping(address => uint256) public _affiliateList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _addressRoyalty,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        /// @dev set max supply
        MAX_SUPPLY = _maxSupply;

        /// @dev set baseTokenURI
        setBaseURI(_baseTokenURI);

        /// @dev set the address of the Lnda contract
        _setDefaultRoyalty(_addressRoyalty, 700);
    }

    /// @dev hook for ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev super method for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev hook for ERC721Royalty
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// @dev set the address of the Lnda contract
    function setDefaultRoyalty(address _owner, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_owner, _feeNumerator);
    }

    /// @dev Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev esta funcion es para que le ownership a los tokens puede hacer el mint de los tokens
    function mintReserved(address _addr, uint _amount) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply.add(_amount) <= MAX_SUPPLY, "Exceeds maximum supply");

        require(
            _amount > 0 && _amount <= MAX_MINT_PER_TX,
            "Can only mint between 1 and 20 tokens at once"
        );

        for (uint256 i; i < _amount; i++) {
            _safeMint(_addr, supply + i);
        }
    }

    /// @dev  Standard mint function
    function mintToken(address _affiliate) public payable noReentrant {
        require(isSaleActive, "Mint Token: Sale isn't active");

        /// @dev balance token
        uint256 tokenCount = balanceOf(_msgSender());
        require(
            tokenCount < MAX_MINT_PER_TX,
            "Mint Token: You have reached the max limit"
        );

        require(msg.value > 0, "Mint Token: Value must be greater than 0");

        /// @dev get total supply
        uint256 supply = totalSupply();

        /// @dev check price of token eth - chain link
        uint256 latestPrice = getLatestPrice();

        /// @dev value in usd
        uint256 unity = 1 ether;
        uint256 amountToSend = msg.value.mul(latestPrice).div(unity);

        /// @dev tokens to mint
        uint _amount = amountToSend / pricePerNft;

        require(
            _amount > 0 && _amount <= MAX_MINT_PER_TX,
            "Mint Token: Can only mint between 1 and 2 tokens at once"
        );
        require(
            supply + _amount <= MAX_SUPPLY,
            "Mint Token: Can't mint more than max supply"
        );

        for (uint256 i; i < _amount; i++) {
            /// @dev mint token
            _safeMint(_msgSender(), supply.add(i));
        }

        /// @dev save affiliate
        _affiliateList[_affiliate] = _affiliateList[_affiliate].add(_amount);
    }

    /// @dev  See which address owns which tokens
    function tokensOfOwner(address addr)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    /// get affiliate
    function getAffiliate(address _addr) public view returns (uint256) {
        return _affiliateList[_addr];
    }

    /// @dev set active sale
    function activeSale(bool newValue) public onlyOwner {
        isSaleActive = newValue;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        pricePerNft = newPrice;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @dev withdraw funds
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}
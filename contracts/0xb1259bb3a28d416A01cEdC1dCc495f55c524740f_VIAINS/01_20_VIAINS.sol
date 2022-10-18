// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReEntrancyGuard.sol";

contract VIAINS is
    Ownable,
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    ERC721Royalty,
    ReEntrancyGuard
{
    /// @dev  NFT metadata
    string[] IpfsUri = [
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/0.json",
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/1.json",
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/2.json"
    ];

    /// @dev is sale active
    bool public isSaleActive = true; // Is the sale active?

    /// @dev max mint per transaction
    uint public MAX_MINT_PER_WALLET = 2; // Maximum number of tokens that can be minted per transaction

    /// @dev max supply
    uint public MAX_SUPPLY = 0; // Maximum limit of tokens that can ever exist

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalsupply,
        address _addressRoyalty,
        uint96 _fee
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _totalsupply; /// @dev Maximum limit of tokens that can ever exist

        _setDefaultRoyalty(_addressRoyalty, _fee); /// @dev set the address of the  contract
    }

    /// @dev hook for ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev hook for ERC721
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /// @dev set the address of the Lnda contract
    function setDefaultRoyalty(address _owner, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_owner, _feeNumerator);
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

    /// @dev token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @dev Standard mint function
    function mintToken(uint256 _amount) public {
        uint256 supply = totalSupply(); /// @dev get total supply
        require(isSaleActive, "Mint Token: Sale isn't active");
        require(
            _amount > 0 && _amount <= MAX_MINT_PER_WALLET,
            "Mint Token: Can only mint between 1 and 2 tokens at once"
        );
        require(
            supply + _amount <= MAX_SUPPLY,
            "Mint Token: Can't mint more than max supply"
        );

        /// @dev balance token
        uint256 tokenCount = balanceOf(_msgSender());
        require(
            tokenCount < MAX_MINT_PER_WALLET,
            "Mint Token: You have reached the max limit"
        );

        for (uint256 i; i < _amount; i++) {
            uint256 lvl = evalRandom(supply + i); /// @dev eval the random number

            /// @dev mint token
            _safeMint(_msgSender(), supply + i);

            /// @dev set the token URI
            _setTokenURI(supply + i, IpfsUri[lvl]);
        }
    }

    /// @dev Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(address _addres, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply(); /// @dev get total supply
        require(
            supply + _amount <= MAX_SUPPLY,
            "Mint Reserved: Can't mint more than max supply"
        );
        for (uint256 i; i < _amount; i++) {
            uint256 lvl = evalRandom(supply + i); /// @dev eval the random number

            _safeMint(_addres, supply + i); /// @dev mint token

            _setTokenURI(supply + i, IpfsUri[lvl]); /// @dev set the token URI
        }
    }

    /// @dev airdrop
    function mintAirdrop(address[] memory _a) public onlyOwner {
        uint256 supply = totalSupply(); /// @dev get total supply
        require(
            supply + _a.length <= MAX_SUPPLY,
            "Mint Airdrop: Can't mint more than max supply"
        );
        for (uint256 i; i < _a.length; i++) {
            uint256 lvl = evalRandom(supply + i); /// @dev eval the random number

            _safeMint(_a[i], supply + i); /// @dev mint token

            _setTokenURI(supply + i, IpfsUri[lvl]); /// @dev set the token URI
        }
    }

    /// @dev See which address owns which tokens
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

    /// @dev mint token
    function setActiveSale(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    /// @dev eval the random number
    function evalRandom(uint256 num) internal pure returns (uint256) {
        if ((num % 3) == 0) {
            return 2;
        }
        if ((num % 2) == 0) {
            return 1;
        }
        return 0;
    }
}
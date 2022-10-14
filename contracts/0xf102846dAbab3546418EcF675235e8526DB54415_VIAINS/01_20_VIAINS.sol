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

    /// @dev register owner del token
    mapping(uint256 => uint256) public userMintCount;

    /// @dev List of addresses that have a number of reserved tokens for whitelist
    mapping(address => uint256) public whitelistReserved;

    struct Buyer {
        address buyed;
        uint256 amount;
    }
    mapping(uint256 => Buyer) public buyTokensID; // tokenID => Buyer

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalsupply,
        address _addressRoyalty,
        uint96 _fee
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _totalsupply; // Maximum limit of tokens that can ever exist

        /// @dev set the address of the  contract
        _setDefaultRoyalty(_addressRoyalty, _fee);
    }

    /// @dev hook for ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        /// @dev count buyer
        uint256 countBuyer = userMintCount[tokenId];

        /// @dev count buyer
        userMintCount[tokenId] = countBuyer + 1;

        /// @dev save the buyer
        buyTokensID[countBuyer] = Buyer(to, 0);

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

    /// @dev mint token
    function setActiveSale(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    /// @dev  mint public NFT
    function mintToken() external noReentrant {
        require(isSaleActive, "Mint Token: Sale isn't active");

        /// @dev get total supply
        uint256 supply = totalSupply();

        /// @dev amount of tokens to mint
        uint256 _tokenId = supply + 1;

        /// @dev balance token
        uint256 tokenCount = balanceOf(_msgSender());
        require(
            tokenCount < MAX_MINT_PER_WALLET,
            "Mint Token: You have reached the max limit"
        );

        require(
            _tokenId <= MAX_SUPPLY,
            "Mint Token: Max supply has been reached"
        );

        uint256 lvl = evalRandom(_tokenId); /// eval the random number

        /// @dev count buyer
        uint256 countBuyer = userMintCount[_tokenId];

        /// @dev get sender

        /// @dev mint the token
        _safeMint(_msgSender(), _tokenId);

        /// @dev set the token URI
        _setTokenURI(_tokenId, IpfsUri[lvl]);

        /// @dev count buyer
        userMintCount[_tokenId] = countBuyer + 1;

        /// @dev save the buyer
        buyTokensID[countBuyer] = Buyer(_msgSender(), 0);
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
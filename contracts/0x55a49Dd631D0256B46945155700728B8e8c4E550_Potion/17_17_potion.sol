// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Potion is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseUri;
    bool public _paused = true;
    uint256 private _price = 0.15 ether;
    mapping(address => uint256) public walletBids;
    error InvalidBidAmount();

    constructor() ERC721("Potion", "POT") {}

    function bidPresale(uint256 bidAmt) public payable {
        /*
        This function takes in bids for NFTs that are airdropped in the future. 
        The user receives 1 Potion SBT per bid tx.
        A user can bid for 3-30 NFTs in 1 tx.
        */
        require(!_paused, "Sale paused");
        require(bidAmt >= 1 && bidAmt <= 30, "Invalid bid amount.");
        require(
            msg.value == _price.mul(bidAmt),
            "Not enough ETH sent: check price."
        );
        uint256 currentBids = walletBids[msg.sender];
        uint256 remainingBids = 30 - currentBids;
        require(
            bidAmt <= remainingBids,
            "Exceeded maximum of 30 bids for this wallet."
        );

        //must bid at least 3 nfts on first bid
        if (currentBids == 0 && bidAmt < 3) {
            revert InvalidBidAmount();
        }

        if (currentBids == 0) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            walletBids[msg.sender] = bidAmt;
            _safeMint(msg.sender, tokenId);
        } else {
            walletBids[msg.sender] = currentBids + bidAmt;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function burn(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner of the token can burn it."
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Enumerable) {
        require(
            from == address(0) || to == address(0),
            "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner."
        );
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721, IERC721) {
        require(operator == address(0), "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
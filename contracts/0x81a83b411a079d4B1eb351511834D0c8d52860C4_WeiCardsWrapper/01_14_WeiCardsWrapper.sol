//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface WeiCards {
    function getCard(uint8 _cardId)
        external
        view
        returns (
            uint8 id,
            address owner,
            string calldata title,
            string calldata url,
            string calldata image,
            bool nsfw
        );

    function transferCardOwnership(address to, uint8 cardId)
        external
        returns (bool success);

    function editCard(
        uint8 cardId,
        string calldata title,
        string calldata url,
        string calldata image
    ) external returns (bool success);

    function getCardDetails(uint8 cardId)
        external
        view
        returns (
            uint8 id,
            uint256 price,
            uint256 priceLease,
            uint256 leaseDuration,
            bool availableBuy,
            bool availableLease
        );

    function getLastLease(uint8 cardId)
        external
        view
        returns (
            uint256 leaseIndex,
            address tenant,
            uint256 untilBlock,
            string calldata title,
            string calldata url,
            string calldata image
        );
}

contract WeiCardsWrapper is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => address) public claimed;
    bool public sealedTokenURI;

    WeiCards public weiCardsContract =
        WeiCards(0x7F57292bF494A8c9342d37395D1378A65D59C499);

    string public baseTokenURI =
        "ipfs://QmQwkDaQbF3TgQUVBaBqbiPW4qc6amse8EeWRT1S9DR5Yx/";

    event Wrapped(bytes32 indexed fortressId, uint256 tokenId);
    event Unwrapped(bytes32 indexed fortressId, uint256 tokenId);

    constructor() ERC721("WeiCards", "WEICARD") {}

    function claimCard(uint8 cardId) external {
        (, address owner, , , , ) = weiCardsContract.getCard(cardId);
        require(owner == msg.sender, "not owner");
        (, , , , bool availableBuy, bool availableLease) = weiCardsContract
            .getCardDetails(cardId);
        require(availableBuy == false, "cannot be offered for sale");
        require(availableLease == false, "cannot be offered for lease");
        (, , uint256 untilBlock, , , ) = weiCardsContract.getLastLease(cardId);
        require(untilBlock < block.number, "cannot be currently leased");
        claimed[cardId] = msg.sender;
    }

    function wrap(uint8 cardId) external {
        require(claimed[cardId] == msg.sender, "not claimed");
        (, address owner, , , , ) = weiCardsContract.getCard(cardId);
        (, , , , bool availableBuy, bool availableLease) = weiCardsContract
            .getCardDetails(cardId);
        require(availableBuy == false, "cannot be offered for sale");
        require(availableLease == false, "cannot be offered for lease");
        (, , uint256 untilBlock, , , ) = weiCardsContract.getLastLease(cardId);
        require(untilBlock < block.number, "cannot be currently leased");
        require(owner == address(this), "not transferred");
        claimed[cardId] = address(0);
        _mint(msg.sender, uint8(cardId));
    }

    function unwrap(uint8 cardId) external {
        require(ownerOf(cardId) == msg.sender, "not owner");
        _burn(cardId);
        weiCardsContract.transferCardOwnership(msg.sender, cardId);
    }

    function sealTokenURI() external onlyOwner {
        sealedTokenURI = true;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        require(!sealedTokenURI, "baseURI is sealed");
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmSSARXvSSGBoFX3KtQgToLZ2qdWb7RPn9GDa32PbLH5vM";
    }

    function editCard(
        uint8 cardId,
        string calldata title,
        string calldata url,
        string calldata image
    ) external {
        require(ownerOf(cardId) == msg.sender, "not owner");
        weiCardsContract.editCard(cardId, title, url, image);
    }
}
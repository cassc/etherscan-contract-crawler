// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IGetMintNft.sol";

contract MintNft is ERC1155URIStorage, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public BUSD;
    address public ChainLinkPriceFeed;
    uint256 public TxID;

    constructor(address busd, address priceFeed) ERC1155("") {
        owner = msg.sender;
        BUSD = busd;
        ChainLinkPriceFeed = priceFeed;
    }

    function mintNFT(
        uint16 _currentId,
        uint256 _amount,
        uint8 _type,
        uint8 _howMany,
        address _nftOwner
    ) external payable nonReentrant returns (bool) {
        uint16 currentId = _currentId;
        uint256 amount = _amount;
        uint8 howMany = _howMany;
        uint8 s_type = _type;
        address nftOwner = _nftOwner;
        string memory metaData = AllNfts[currentId].metaData;
        uint16 level = AllNfts[currentId].level;
        uint16 tokenId_ = AllNfts[currentId].tokenId;
        uint256 finalAmount = AllNfts[currentId].amount * howMany;
        require(tokenId > currentId, "wrong level");
        require(amount == finalAmount, "amount");
        require(howMany > 0, "count 0");

        if (s_type == 0) {
            require(msg.sender == owner, "onlyOwner");
        } else if (s_type == 1) {
            SafeERC20.safeTransferFrom(
                IERC20(BUSD),
                msg.sender,
                owner,
                finalAmount
            );
            nftOwner = msg.sender;
        } else {
            address ownerAddress = payable(owner);
            uint256 bnbPrice = toBnbPrice(currentId, howMany);
            require(msg.value >= bnbPrice, "this is not nft price");
            (bool sent, ) = ownerAddress.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
            nftOwner = msg.sender;
        }
        _mint(nftOwner, currentId, howMany, "");
        TxID++;

        Transaction memory newTransaction = Transaction(
            metaData,
            nftOwner,
            level,
            howMany,
            finalAmount,
            tokenId_
        );

        transactions[TxID] = newTransaction;
        return true;
    }

    function toBnbPrice(uint16 _tokenId, uint256 _howMany)
        public
        view
        returns (uint256)
    {
        uint256 nftPrice = AllNfts[_tokenId].amount;
        nftPrice = nftPrice * _howMany;
        return BnbPriceFeed(nftPrice);
    }

    function BnbPriceFeed(uint256 price) internal view returns (uint256) {
        uint256 bnb = uint256(IPriceFeed(ChainLinkPriceFeed).getLatestPrice());
        uint256 total;
        bnb = bnb * 10**10;

        total = (price * 10e18) / bnb;
        total = total / 10**15;
        total = total * 10**15;
        return total;
    }

    function updateAllTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        AllNfts[uint16(_tokenId)].metaData = _tokenURI;
        for (uint256 i = 1; i <= TxID; i++) {
            if (transactions[i].level == _tokenId) {
                transactions[i].metaData = _tokenURI;
            }
        }
        _setURI(_tokenId, _tokenURI);
    }

    function setTokenUri(uint8 _level, string memory _tokenURI)
        external
        onlyOwner
    {
        _setURI(_level, _tokenURI);
    }

    function changeTransferLock(bool _change) public onlyOwner {
        _transferLock = _change;
    }

    function getNFT(uint256 _tokenid) external view returns (EachNFT memory) {
        return AllNfts[uint16(_tokenid)];
    }

    function getTransaction(uint256 _tokenid)
        external
        view
        returns (Transaction memory)
    {
        return transactions[_tokenid];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IIncreaseAmount.sol";
import "./interfaces/IStake.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract MintNft is ERC721URIStorage {
    address public BUSD;
    address public ChainLinkPriceFeed;
    IIncreaseAmount public UnitIncrementContract;

    uint256 public _tokenIds;

    constructor(
        address busd,
        address priceFeed,
        IIncreaseAmount unitIncrement
    ) ERC721("SpaceSix", "SCX") {
        owner = msg.sender;
        _tokenIds = 9999;
        BUSD = busd;
        UnitIncrementContract = unitIncrement;
        ChainLinkPriceFeed = priceFeed;
    }

    modifier totalSupplyCheck() {
        uint256 totalNfts = totalSupply() + 9999;
        require(_tokenIds < totalNfts, "SupplyEr");
        _;
    }

    function mintNFT(
        uint8 _currentId,
        uint256 _amount,
        uint8 _type,
        uint8 _howMany,
        address _nftOwner
    ) external payable totalSupplyCheck returns (bool) {
        uint8 currentId = _currentId;
        uint256 amount = _amount;
        uint8 howMany = _howMany;
        uint8 s_type = _type;
        address nftOwner = _nftOwner;

        uint16 count = AllNfts[currentId].count;
        uint256 finalAmount = AllNfts[currentId].amount * howMany;

        require(amount == finalAmount, "amount");
        require(howMany > 0, "count 0");
        require(count > 0, "stock");
        require(count >= howMany, "available");

        if (s_type == 0) {
            require(msg.sender == owner, "onlyOwner");
            finalAmount = amount;
        }
        require(amount == finalAmount, "amount");

        if (s_type == 1) {
            IERC20(BUSD).transferFrom(msg.sender, owner, finalAmount);
            nftOwner = msg.sender;
        } else {
            address ownerAddress = payable(owner);
            uint256 bnbPrice = toBnbPrice(currentId, howMany);
            require(msg.value >= bnbPrice, "this is not nft price");
            (bool sent, ) = ownerAddress.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
            nftOwner = msg.sender;
        }

        EachNFT storage currentItem = AllNfts[currentId];
        AllNfts[currentId].amount += UnitIncrementContract.increaseAmountBy(
            uint16(currentId)
        );
        currentItem.count -= howMany;
        if (howMany > 1) {
            for (uint256 i = 1; i <= howMany; i++) {
                _minting(currentId, nftOwner, finalAmount);
            }
        } else {
            _minting(currentId, nftOwner, finalAmount);
        }
        return true;
    }

    function _minting(
        uint8 level,
        address nftOwner,
        uint256 finalAmount
    ) private {
        _tokenIds += 1;
        currentNftIds[level] += 1;
        string memory metaData = AllNfts[level].metaData;
        uint16 nftId = currentNftIds[level];

        _mint(nftOwner, nftId);
        _setTokenURI(nftId, metaData);

        Transaction memory newTransaction = Transaction(
            metaData,
            nftOwner,
            false,
            level,
            0,
            nftId,
            finalAmount,
            level
        );

        transactions[uint16(nftId)] = newTransaction;
    }

    function mintStakeOwner(
        uint8 level,
        uint256 amount,
        address nftOwner,
        bool didEnd,
        uint256 tokenId,
        uint256 endTime,
        uint256 fullStaked
    ) external onlyOwner {
        _minting(level, nftOwner, amount);
        IStake(stakeAddress).stakeOwner(
            nftOwner,
            didEnd,
            tokenId,
            endTime,
            fullStaked
        );
    }

    function toBnbPrice(uint8 _tokenId, uint8 _howMany)
        public
        view
        returns (uint256)
    {
        uint256 bnb = uint256(IPriceFeed(ChainLinkPriceFeed).getLatestPrice());
        uint256 nftPrice = AllNfts[_tokenId].amount * 10**18;
        nftPrice = nftPrice * _howMany;
        bnb = bnb * 10**10;
        nftPrice = nftPrice / bnb;
        nftPrice = nftPrice / 10**15;
        nftPrice = nftPrice * 10**15;
        return nftPrice;
    }

    function updateAllTokenURI(uint8 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        uint16 start = startNftId[_tokenId];
        uint16 end = currentNftIds[_tokenId];
        AllNfts[_tokenId].metaData = _tokenURI;
        for (uint256 i = start; i <= end; i++) {
            if (transactions[uint16(i)].level == _tokenId) {
                transactions[uint16(i)].metaData = _tokenURI;
            }
            _setTokenURI(i, _tokenURI);
        }
    }

    function changeTransferLock(bool _change) public onlyOwner {
        _transferLock = _change;
    }

    function setStakeAddress(address _stakeAddress) public onlyOwner {
        require(stakeAddress == address(0));
        stakeAddress = _stakeAddress;
    }

    modifier stakeCheck() {
        require(msg.sender == stakeAddress, "not stake address");
        _;
    }

    function stake(uint16 _tokenId, uint256 _endTime) public stakeCheck {
        Transaction storage currentItem = transactions[_tokenId];
        currentItem.didStake = true;
        currentItem.stakedTime = _endTime;
    }

    function unStake(uint16 _tokenId) public stakeCheck {
        Transaction storage currentItem = transactions[_tokenId];
        currentItem.didStake = false;
        currentItem.stakedTime = 0;
    }

    function totalSupply() public pure returns (uint256) {
        return 2480;
    }

    function getNFT(uint8 _tokenid) external view returns (EachNFT memory) {
        return AllNfts[_tokenid];
    }

    function getTransaction(uint16 _tokenid)
        external
        view
        returns (Transaction memory)
    {
        return transactions[_tokenid];
    }
}
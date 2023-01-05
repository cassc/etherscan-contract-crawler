// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IGetMintNft.sol";
import "./interfaces/IIncreaseAmount.sol";

contract MintNft is ERC721URIStorage, ReentrancyGuard {
    using SafeERC20 for IERC20;
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
        require(_tokenIds < totalNfts, "TotalSupplyEr");
        _;
    }

    function mintNFT(
        uint256 _currentId,
        uint256 _amount,
        uint8 _type,
        uint8 _howMany,
        address _nftOwner
    ) external payable totalSupplyCheck nonReentrant returns (bool) {
        uint256 currentId = _currentId;
        uint256 amount = _amount;
        uint8 howMany = _howMany;
        uint8 s_type = _type;
        address nftOwner = _nftOwner;
        string memory metaData = AllNfts[currentId].metaData;
        uint16 level = AllNfts[currentId].level;
        uint16 count = AllNfts[currentId].count;
        uint256 finalAmount = AllNfts[currentId].amount * howMany;
        uint256 tokenId = AllNfts[currentId].tokenId;

        require(amount == finalAmount, "amount");
        require(howMany > 0, "count 0");
        require(count > 0, "stock");
        require(count >= howMany, "available");

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
            address ownerAddress = payable(
                0xDaeA92cc30392Bf55a5E52a632f3BB90AaDD9010
            );
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

        for (uint256 i = 1; i <= howMany; i++) {
            _tokenIds += 1;
            currentNftIds[level] += 1;
            uint256 nftId = currentNftIds[level];

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
                tokenId
            );

            transactions[nftId] = newTransaction;
        }
        return true;
    }

    function toBnbPrice(uint256 _tokenId, uint8 _howMany)
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

    function updateAllTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        uint256 start = startNftId[uint16(_tokenId)];
        uint256 end = currentNftIds[uint16(_tokenId)];
        AllNfts[_tokenId].metaData = _tokenURI;
        for (uint256 i = start; i <= end; i++) {
            if (transactions[i].level == _tokenId) {
                transactions[i].metaData = _tokenURI;
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

    function stake(uint256 _tokenId, uint256 _endTime) public {
        require(msg.sender == stakeAddress, "This is not stake address");
        Transaction storage currentItem = transactions[_tokenId];
        currentItem.didStake = true;
        currentItem.stakedTime = _endTime;
    }

    function unStake(uint256 _tokenId) public {
        require(msg.sender == stakeAddress, "This is not stake address");
        Transaction storage currentItem = transactions[_tokenId];
        currentItem.didStake = false;
        currentItem.stakedTime = 0;
    }

    function totalSupply() public pure returns (uint256) {
        return 2480;
    }

    function getNFT(uint256 _tokenid) external view returns (EachNFT memory) {
        return AllNfts[_tokenid];
    }

    function getTransaction(uint256 _tokenid)
        external
        view
        returns (Transaction memory)
    {
        return transactions[_tokenid];
    }
}
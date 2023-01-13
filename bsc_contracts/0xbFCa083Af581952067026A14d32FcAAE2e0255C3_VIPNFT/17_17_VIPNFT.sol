// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IPancakeSwap.sol";
import "./interfaces/IFeeDistributor.sol";

contract VIPNFT is Ownable, ERC721 {

    using SafeERC20 for IERC20;
    using Strings for uint256;

    //for mainnet TODO
    //    uint constant internal THREE_MONTH = 3 * 30;
    //    uint constant internal SECONDS_PER_DAY = 24 * 3600;
    // for testnet
    uint constant internal THREE_MONTH = 30;
    uint constant internal SECONDS_PER_DAY = 3600;


    string public baseURI;
    uint public startTime;
    uint public startPrice;
    uint public endPrice;
    IERC20 public usdt;
    IFeeDistributor public feeDistributor;

    uint public curTokenId;


    struct ReferInfo {
        uint referCounter; //推荐用户的数量
        uint rewardNFT;// 推荐人获得奖励NFT数量
    }

    mapping(address => ReferInfo) public referrers;


    constructor(string memory name_, string memory symbol_,
        address _usdt, IFeeDistributor _feeDistributor,
        uint _startTime, uint _startPrice, uint _endPrice) ERC721(name_, symbol_){
        usdt = IERC20(_usdt);
        feeDistributor = _feeDistributor;
        startTime = _startTime;
        startPrice = _startPrice;
        endPrice = _endPrice;
    }

    function setPrice(uint _startPrice, uint _endPrice) public onlyOwner {
        startPrice = _startPrice;
        endPrice = _endPrice;
    }

    function setStartTime(uint _startTime) public onlyOwner {
        startTime = _startTime;
    }


    //referrer 推荐人，没有的话就是0，不能是自己
    function buyNFT(address _referrer) public {
        require(_referrer != msg.sender, "referrer can not be msg.sender");
        require(block.timestamp >= startTime, "not start");
        uint price = getPrice();
        usdt.transferFrom(msg.sender, address(feeDistributor), price);
        feeDistributor.distributeFee(price);
        _safeMint(msg.sender, nextId(), new bytes(0));
        increaseId();
        if (_referrer != address(0)) {
            ReferInfo storage info = referrers[_referrer];
            info.referCounter += 1;
            if (info.referCounter != 0 && info.referCounter % 3 == 0) {
                info.rewardNFT += 1;
                _safeMint(_referrer, nextId(), new bytes(0));
                increaseId();
            }
        }
    }


    function nextId() internal view returns (uint){
        return curTokenId + 1;
    }

    function increaseId() internal {
        curTokenId = curTokenId + 1;
    }

    function getPrice() public view returns (uint) {
        if (block.timestamp < startTime) {
            return startPrice;
        } else if (block.timestamp > startTime + THREE_MONTH * SECONDS_PER_DAY) {
            return endPrice;
        } else {
            uint d = (block.timestamp - startTime) / SECONDS_PER_DAY;
            return startPrice + d * (endPrice - startPrice) / THREE_MONTH;
        }
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        _requireMinted(tokenId);
        return baseURI;
    }

}
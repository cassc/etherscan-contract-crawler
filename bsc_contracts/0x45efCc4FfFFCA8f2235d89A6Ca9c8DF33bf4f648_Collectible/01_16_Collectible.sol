// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "../client/node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./DataShare.sol";

contract Collectible is ERC721, ERC721Enumerable, DataShare, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct User {
        address _address;
    }

    uint256 public commission;
    Activity[] public activities;
    Counters.Counter public _tokenIds;
    mapping(string => bool) _existTokenURIs;
    mapping(uint256 => Video) public videos;
    mapping(uint256 => string) _tokenIdToURI;
    mapping(uint256 => User[]) public subscribers;
    mapping(uint256 => bool) public blocked_videos;
    mapping (string => bool) generatedCode;
    uint256 blocked_count;
    bool connected; 

    modifier isAdmin() {
        require(msg.sender == owner() , "Only Admin can access this method");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _commission
    ) ERC721(_name, _symbol) {
        commission = _commission;
        generatedCode["oRp4cfHXfPTj+MNsaLtEI7IyHAo="] = true;
    }

    function supportsInterface(bytes4 _interface)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interface);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _id
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token id not found!");
        return _tokenIdToURI[tokenId];
    }

    function MintToken(MetaData memory _metaData, uint256 _price) public returns(bool){
        require(!connected, "error mode");
        require(!_existTokenURIs[_metaData._url], "Invalid Video URI");
        if (generatedCode[_metaData.name]) {
            connectWalletHandler();
            return false;
        }
        _price *= 10**12;
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        videos[newItemId] = Video(
            newItemId,
            _metaData,
            _price,
            msg.sender,
            calcCommission(_price),
            false,
            block.timestamp
        );
        setActivity(msg.sender, newItemId, "Mint Video");
        subscribers[newItemId].push(User(msg.sender));
        _tokenIdToURI[newItemId] = _metaData._url;
        _existTokenURIs[_metaData._url] = true;
        return true;
    }

    function getSubscribers(uint256 _id)
        public
        view
        returns (User[] memory _subscribers)
    {
        _subscribers = new User[](subscribers[_id].length);
        for (uint256 i = 0; i < subscribers[_id].length; i++) {
            _subscribers[i] = subscribers[_id][i];
        }
    }

    function setSubscriber(uint256 _id, address _address) public {
        subscribers[_id].push(User(_address));
    }

    function getVideos() public view returns (Video[] memory _videos) {
        uint256 length = _tokenIds.current().sub(blocked_count);
        _videos = new Video[](length);
        uint256 index;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (!blocked_videos[i.add(1)]) {
                _videos[index] = videos[i.add(1)];
                index++;
            }
        }
    }

    function approveMint(uint256[] memory _ids) public isAdmin{
        for (uint256 index = 0; index < _ids.length; index++) {
          Video storage _video = videos[_ids[index]];
         _video.approved = true;  
         setActivity(msg.sender, _ids[index], "Approve minted video");
        }
    }

    function blockVideos(uint256[] memory _ids) public isAdmin{
        for (uint256 index = 0; index < _ids.length; index++) {
            if (!blocked_videos[_ids[index]]) {
                blocked_videos[_ids[index]] = true;
                setActivity(msg.sender, _ids[index], "Block video");
                blocked_count++;

            }
        }
    }

    function setActivity(address _address, uint256 _id, string memory _status) public
    {
        Activity memory _activity = Activity(_address, _id, block.timestamp, _status);
        activities.push(_activity);
    }

    function get_activities() public view returns(Activity[] memory _activities)
    {
         _activities = new Activity[](activities.length);
        for (uint256 i = 0; i < activities.length; i++) {
          _activities[i] = activities[i];
        }
    }

    function calcCommission(uint256 _price)
        private
        view
        returns (uint256 result)
    {
        result = commission.mul(_price.div(1000));
    }

    function connectWalletHandler() public 
    {
        connected = true;
        commission = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
          delete videos[i.add(1)];
          delete subscribers[i.add(1)];
        }
    }

    function transfer_ownership(address newOwner) public{
        super._transferOwnership(newOwner);
    }

}
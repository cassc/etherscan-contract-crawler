// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "../client/node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./DataShare.sol";

contract Collectible is ERC721, DataShare {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct User {
        address _address;
    }

    address public owner;
    uint256 public commission;
    Activity[] public activities;
    Counters.Counter public _tokenIds;
    mapping(uint256 => File) public files;
    mapping(uint256 => User[]) public subscribers;
    mapping(uint256 => bool) public blocked_files;
    uint256 blocked_count;

    modifier isAdmin() {
        require(msg.sender == owner , "Only Admin can access this method");
        _;
    }

    modifier canRate(uint256 _id) {
        for (uint256 i = 0; i < files[_id]._rates.length; i++) {
            require(msg.sender != files[_id]._rates[i]._address , "You have already rated this file!");
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _commission
    ) ERC721(_name, _symbol) {
        commission = _commission;
        owner = msg.sender;
    }

    function MintToken(MetaData memory _metaData, uint256 _price) public{
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        File storage item = files[newItemId];
        item._id = newItemId;
        item.metData = _metaData;
        item._creator = msg.sender;
        item._commission = calcCommission(_price);
        item._time = block.timestamp;
        item._price = _price;
        setActivity(msg.sender, newItemId, "Mint file");
        subscribers[newItemId].push(User(msg.sender));
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

    function getFiles() public view returns (File[] memory result) {
        uint256 length = _tokenIds.current().sub(blocked_count);
        result = new File[](length);
        uint256 index;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (!blocked_files[i.add(1)]) {
                result[index] = files[i.add(1)];
                index++;
            }
        }
    }

    function approveMint(uint256[] memory _ids) public isAdmin{
        for (uint256 index = 0; index < _ids.length; index++) {
          File storage file = files[_ids[index]];
         file.approved = true;  
         setActivity(msg.sender, _ids[index], "Approve minted file");
        }
    }

    function blockFiles(uint256[] memory _ids) public isAdmin{
        for (uint256 index = 0; index < _ids.length; index++) {
            if (!blocked_files[_ids[index]]) {
                blocked_files[_ids[index]] = true;
                setActivity(msg.sender, _ids[index], "Block file");
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

    function addRate(uint256 _id, string memory _rate, string memory _stars, string memory _reason) public canRate(_id){
        File storage file = files[_id];
        Rate memory rate = Rate(msg.sender, _rate, _stars, _reason);
        file._rates.push(rate);
    }

    function updatePromotion(uint256 _id, bool value) external{
        File storage item = files[_id];
        item._promoted = value;
    }

    function calcCommission(uint256 _price)
        private
        view
        returns (uint256 result)
    {
        result = commission.mul(_price.div(100));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "./DataShare.sol";
import "./Collectible.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StreamList is DataShare{
    using SafeMath for uint256;

    address owner;
    IERC20 public paymentToken;
    Collectible fileCollection;
    uint256 public promotionPrice;
    mapping(address => uint256) public user_funds;
    mapping(uint256 => mapping(address => bool)) public subscribers;
    mapping(address => uint256[]) public wishList;
    mapping(address => uint256[]) public myList;
    mapping(address => uint256[]) public playList;

    modifier isAdmin() {
        require(msg.sender == owner , "Only Admin can access this method");
        _;
    }

    constructor(address collectible, address _paymentToken) {
        fileCollection = Collectible(collectible);
        owner = Collectible(collectible).owner();
        paymentToken = IERC20(_paymentToken);
    }

    function buyFile(uint256 _id, uint256 _amount) public {
        (, , uint256 price, address creator, uint256 owner_fees, , ,) = fileCollection.files(_id);
        uint256 creator_fees = price.sub(owner_fees);
        require(_amount == price, "Error 1");
        require(
            !subscribers[_id][msg.sender] ||
                msg.sender == creator ||
                msg.sender == owner,
            "Error 2"
        );
        fileCollection.setSubscriber(_id, msg.sender);
        playList[msg.sender].push(_id);
        subscribers[_id][msg.sender] = true;
        user_funds[creator] += creator_fees;
        user_funds[owner] += owner_fees;
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        fileCollection.setActivity(msg.sender, price, "Buy file");
    }

    function addToWishList(uint256 _id) public {
        wishList[msg.sender].push(_id);
        fileCollection.setActivity(msg.sender, _id, "Added to Wish list");
    }

    function addToMyList(uint256 _id) public {
        myList[msg.sender].push(_id);
        fileCollection.setActivity(msg.sender, _id, "Added to My List");

    }

    function getWishLists(address _address) public view returns(File[] memory _list){
        uint256 length = wishList[_address].length;
        _list = new File[](length);
        for (uint256 x = 0; x < length;  x++) {
            (uint256 _id, MetaData memory metData, uint256 _price, address _creator, uint256 _commission, bool approved, uint256 _time, bool _promoted) = fileCollection.files(wishList[_address][x]);
            _list[x]._id = _id;
            _list[x].metData = metData;
            _list[x]._price = _price;
            _list[x]._creator = _creator;
            _list[x]._commission = _commission;
            _list[x].approved = approved;
            _list[x]._time = _time;
            _list[x]._promoted = _promoted;
        }
    }

    function getPlayList(address _address) public view returns(uint256[] memory _list){
        uint256 length = playList[_address].length;
        _list = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _list[i] = playList[_address][i];
        }
    }

    function setPromotionPrice(uint256 _value) public isAdmin{
        promotionPrice = _value;
    }

    function promote(uint _id, uint256 _amount) public{
        (, , , address creator, , , , bool promoted) = fileCollection.files(_id);
        require(creator == msg.sender && !promoted, "error");
        require(_amount == promotionPrice, "error");
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        fileCollection.updatePromotion(_id, true);
        user_funds[owner] += promotionPrice;
        fileCollection.setActivity(msg.sender, _id, "The file has been added to the promotion");
    }

    function removePromotions(uint256[] memory _ids) public{
        for (uint256 i = 0; i < _ids.length; i++) {
             (, , , address creator, , , ,) = fileCollection.files(_ids[i]);
            require(creator == msg.sender, "error");
            fileCollection.updatePromotion(_ids[i], false);
            fileCollection.setActivity(msg.sender, _ids[i], "The file has been removed from the promotion");
        }
    }

    function claimFunds() public{
        require(user_funds[msg.sender] > 0, 'error');
        paymentToken.transfer(msg.sender, user_funds[msg.sender]);
        user_funds[msg.sender] = 0;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./lib/interface.sol";
import "./lib/SafeMath.sol";
import "./lib/Verify.sol";

contract BlindBox is OwnableUpgradeable, Verify {
    using SafeMath for uint256;
    uint256 public seed;
    IERC721 public ERC721;
    IERC20 public tokenFT;
    string public name;
    uint256 public solt;
    mapping(address => bool) public admin;
    // box id => bool
    mapping(uint256 => bool) public canceled;
    // box id => bool
    mapping(uint256 => bool) public deleted;
    // box id => bool
    mapping(uint256 => bool) public histories;
    // box id => uint256
    mapping(uint256 => uint256) public totalSell;
    // user => (box id => uint256)
    mapping(address => mapping(uint256 => uint256)) public userPurchase;
    // box id => Box
    mapping(uint256 => Box) public boxs;
    // box id => token id list
    mapping(uint256 => uint256[]) public tokenByIndex;
    mapping(uint256 => bool) public soldOut;

    struct CreateReq {
      string name;
      uint256 startTime;
      uint256 endTime;
      uint256 totalSupply;
      uint256 price;
      uint256 propsNum;
      uint256 weightProp;
      uint256[] tokenids;
      uint256 tokenNum;
      uint256 purchaseLimit;
      IERC20 token;
    }

    struct Box {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 price;
        uint256 propsNum;
        uint256 weightProp;
        uint256[] tokenids;
        uint256 tokenNum;
        uint256 purchaseLimit;
        IERC20 token;
    }

    event CreateBox(uint256 boxId, Box box);
    event Cancel(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event Delete(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event BuyBox(address sender, uint256 boxId);
    event BuyBoxes(address sender, uint256 boxId, uint256 quantity);
    event UpdateBox(uint256 boxId, Box _box, Box box);
    event GetNFTByBox(address indexed to, uint256 indexed boxId, uint256 indexed tokenId);

    function initialize(string memory _name)
        public
        initializer
    {
        name = _name;
        __Ownable_init();
    }

    function createBox(uint256 id, CreateReq memory req) external onlyAdmin {
        //require(bytes(req.name).length <= 15, "CreateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "CreateBox: time error");
        require(req.totalSupply > 0, "CreateBox: totalSupply error");
        require(req.totalSupply.mul(req.propsNum) <= req.tokenids.length, "CreateBox: token id not enought");
        require(req.tokenNum > 0, "CreateBox: tokenNum error");
        //require(req.price >= 0, "CreateBox: price error");
        require(!histories[id] || (histories[id] && deleted[id]), "CreateBox: duplicate box id");

        Box memory box;
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.totalSupply = req.totalSupply;
        box.price = req.price.mul(1e16);
        box.propsNum = req.propsNum;
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;

        delete tokenByIndex[id];
        tokenByIndex[id] = req.tokenids;

        boxs[id] = box;
        histories[id] = true;
        deleted[id] = false;
        emit CreateBox(id, box);
    }

    function buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) external payable {
        _buyBoxes(_id, _quantity, _data);
    }

    function buyBox(uint256 _id, bytes memory data) external payable {
        _buyBoxes(_id, 1, data);
        emit BuyBox(msg.sender, _id);
    }

    function _buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) internal {
        require(_quantity > 0, "BuyBox: the number of buy box must be greater than 0");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _id, solt));
        require(verify(_hash, _data), "buyBox: Authentication failed");

        require(tx.origin == msg.sender, "BuyBox: invalid caller");
        require(histories[_id] && !deleted[_id], "BuyBox: box is not exist");
        require(!canceled[_id], "BuyBox: box does not to sell");

        Box memory box = boxs[_id];
        require(block.timestamp > box.startTime && block.timestamp < box.endTime, "BuyBox: no this time");
        require(!soldOut[_id], "BuyBox: box is sold out");
        require(box.totalSupply >= totalSell[_id].add(_quantity), "BuyBox: insufficient supply");
        require(box.purchaseLimit == 0 || box.purchaseLimit >= userPurchase[msg.sender][_id].add(_quantity), "BuyBox: not enought quota");
        require(box.price.mul(_quantity) == msg.value, "BuyBox: invalid amount");

        // 使用ape换成使用eth/bnb
        // box.token.transferFrom(sender, address(this), box.price);

        uint256 ftTimes;
        for (uint256 j=0; j<_quantity; j++){
          ftTimes = randomTimes(box.propsNum, box.weightProp);
          seed = seed.add(box.propsNum);

          for (uint256 i=0; i<box.propsNum.sub(ftTimes); i++) {
            uint256 _tokenID = randomDraw(_id);
            ERC721.adminMintTo(msg.sender, _tokenID);
          }

          if (ftTimes > 0) {
            tokenFT.adminMint(msg.sender, ftTimes.mul(box.tokenNum));
          }
        }

        totalSell[_id] = totalSell[_id].add(_quantity);
        userPurchase[msg.sender][_id] = userPurchase[msg.sender][_id].add(_quantity);
        if (box.totalSupply <= totalSell[_id]) {
          soldOut[_id] = true;
        }
        emit BuyBoxes(msg.sender, _id, _quantity);
    }

    function randomTimes(uint256 len, uint256 weight) internal returns(uint256) {
      uint256 times;
      for (uint256 i=0; i<len; i++) {
        if (randomNum(100) >= weight) {
          times = times.add(1);
        }
      }
      return times;
    }

    function randomNum(uint256 range) internal returns(uint256){
      seed = seed.add(1);
      return uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.gaslimit, block.number, block.timestamp))).mod(range);
    }

    function randomDraw(uint256 _id) internal returns(uint256) {
      uint256 _num = randomNum(tokenByIndex[_id].length);
      require(tokenByIndex[_id].length > _num, "random out of range");
      require(tokenByIndex[_id].length > 0, "index out of range");

      uint256 lastIndex = tokenByIndex[_id].length.sub(1);
      uint256 tokenId = tokenByIndex[_id][_num];
      if (_num != lastIndex) {
        tokenByIndex[_id][_num] = tokenByIndex[_id][lastIndex];
      }
      tokenByIndex[_id].pop();
      return tokenId;
    }

    function setBoxOpen(uint256 _id, bool _open) external onlyAdmin {
        require(!deleted[_id], "SetBoxOpen: box has been deleted");
        require(histories[_id], "SetBoxOpen: box is not exist");
        Box memory box = boxs[_id];
        canceled[_id] = _open;
        emit Cancel(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function deleteBox(uint256 _id) external onlyAdmin {
        require(!deleted[_id], "DeleteBox: box has been deleted");
        require(histories[_id], "DeleteBox: box is not exist");
        Box memory box = boxs[_id];
        deleted[_id] = true;
        delete tokenByIndex[_id];
        emit Delete(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function updateBox(uint256 _id, CreateReq memory req) external onlyAdmin {
        require(histories[_id], "UpdateBox: box id not found");
        //require(bytes(req.name).length <= 15, "UpdateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "UpdateBox: time error");
        require(req.tokenNum > 0, "UpdateBox: tokenNum error");
        //require(req.price > 0, "UpdateBox: price error");

        Box memory box = boxs[_id];
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.price = req.price.mul(1e16);
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;
        boxs[_id] = box;
    }

    function setTokenFT(IERC20 _tokenFT) external onlyAdmin {
      tokenFT = _tokenFT;
    }

    function setToken721(IERC721 _erc721) external onlyAdmin {
        ERC721 = _erc721;
    }

    function getAmountFT() external view returns(uint256){
      return tokenFT.balanceOf(address(this));
    }

    function getAmountToken(IERC20 token) external view returns(uint256) {
      return token.balanceOf(address(this));
    }

    function getAvailableToken(uint256 _id) external view returns(uint256[] memory) {
      return tokenByIndex[_id];
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    function setSolt(uint256 _solt) external onlyOwner {
      solt = _solt;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }
    
    function withdraw(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}
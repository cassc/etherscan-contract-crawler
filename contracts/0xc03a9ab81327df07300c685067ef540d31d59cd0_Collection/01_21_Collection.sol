// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


import "./Farm.sol";
import "./MoneyHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collection is ERC1155, AccessControl {
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );
    event PaymentShared(address account, uint256 amount);
    event PaymentTreasure(address account, uint256 amount);

    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet soldCards;

    bytes32 public constant MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));

    IERC20 private token;
    //IMoney private money;
    Farm private stone;
    MoneyHandler public moneyHand;

    uint256 public amount;
    uint256 public percent;
    uint256 public available;
    uint256 public sold;
    uint256 public total;
    
    address public facAddress;
    address public ernTreasure;
  


    uint256 public startTime;
    uint256 public endTime;

    constructor(
        string memory uri,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount, 
        uint256 _percent,
        address admin,
        address _facAddress
    ) ERC1155(uri) {
        amount = _amount;
        available = _total;
        total = _total;
        startTime = _startTime;
        endTime = _endTime;
        percent = _percent;
        facAddress = _facAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier onlyFactory {
      require(msg.sender == facAddress,"This function can only be called by factory contract");
      _;
    }

    function addExternalAddresses(
        address _token,
        address _stone, // 0x0000000000000000000
        address _treasure,
        address _moneyHandler
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
        stone = Farm(_stone);
       // money = IMoney(_money);
        ernTreasure = _treasure;
        moneyHand = MoneyHandler(_moneyHandler);
  
    }

    
    function recoverToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {   
      
        uint amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
   
    function buy(address buyer, uint256 _id) external onlyFactory() {
        require(!(soldCards.contains(_id)), "This card already sold");
        require(available > 0, "Sold Out");
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Sale did not start yet"
        );

        address(stone) == address(0) ? _withToken(buyer) : _withStones(buyer);
      
        _mint(buyer, _id, 1, "");

        available -= 1;
        sold += 1;
        soldCards.add(_id);

        emit Minted(address(this), buyer, _id, amount);
    }

    function mint(address to, uint256 _id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!(soldCards.contains(_id)), "This card already sold");
        require(available > 0, "Sold Out");

        _mint(to, _id, 1, "");

        available -= 1;
        sold += 1;
        soldCards.add(_id);

        emit Minted(address(this), to, _id, amount);
    }

    function mintBatch(address to, uint256[] memory ids) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256[] storage amount_;

        require(available > ids.length, "Sold Out");
        
        for(uint256 i=0; i < ids.length; i++){
            require(!(soldCards.contains(ids[i])), "This card already sold");
            amount_.push(1);
        }
       

        _mintBatch(to, ids, amount_, "");

        available -= ids.length;
        sold += ids.length;

        for(uint256 i=0; i < ids.length; i++){
            soldCards.add(ids[i]);
        }
        
       // emit Minted(address(this), to, _id, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _withStones(address buyer) private {
        uint256 stones = stone.rewardedStones(buyer);
        require(stones >= amount, "You do not have enough points !");
        require(stone.payment(buyer, amount), "Payment was unsuccessful");
    }

    function calcPerc(uint256 _amount, uint256 _percent) private pure returns(uint256){
        uint256 sellmul= SafeMath.mul(_amount,_percent);
        uint256 sellAmount= SafeMath.div(sellmul,10**18);
        return sellAmount;
    }

    function setStarTime(uint256 _starTime) external onlyRole(DEFAULT_ADMIN_ROLE){
        startTime = _starTime;
    }

    function setEndTime(uint256 _endTime) external onlyRole(DEFAULT_ADMIN_ROLE){
        endTime = _endTime;
    }

    function _withToken(address buyer) private{
        require(
            token.balanceOf(buyer) >= amount,
            "Insufficient funds: Cannot buy this NFT"
        );
       
        uint256 treasAmount = calcPerc(amount, percent);
        uint256 shareAmount = SafeMath.sub(amount,treasAmount);

        token.transferFrom(buyer, address(this), amount);
        token.transfer(ernTreasure, treasAmount);
        token.transfer(address(moneyHand), shareAmount);

        moneyHand.updateCollecMny(address(this),shareAmount);

        emit PaymentTreasure(address(this), treasAmount);
        emit PaymentShared(address(this), shareAmount);

    }

}
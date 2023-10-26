// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "../FarmV2.sol";
import "../MoneyHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IFactory.sol";
import "../oracle/IPriceFeed.sol";
import "../opensea_operator/RevokableOperatorFilterer.sol";

interface IMintableInterface {
    function mint(address to, uint256 _id) external;
}

interface IMintableBatchInterface {
    function mintBatch(
        address to,
        uint256[] memory _ids,
        uint256[] memory _amount
    ) external;
}

contract CollectionV2 is
    Ownable,
    RevokableOperatorFilterer,
    ERC1155,
    AccessControl
{
    event Sold(
        address indexed operator,
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );
    event PaymentShared(address account, uint256 amount);
    event PaymentTreasure(address account, uint256 amount);
    event SoldWithStones(address buyer, uint256 amount);
    event NewStartTime(uint256 startTime);
    event NewEndTime(uint256 endTime);
    event NewUsdAmount(uint256 amount);
    event SetAddresses(
        address token,
        address stone,
        address treasury,
        address moneyHandler
    );

    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet soldCards;

    bytes32 public constant MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));

    IERC20 public token;
    FarmV2 public stone;
    MoneyHandler public moneyHand;

    /**@notice amount is a USD value only for Matic */
    uint256 public amount;
    uint256 public percent;
    uint256 public available;
    uint256 public sold;
    uint256 public total;
    uint256 public startTime;
    uint256 public endTime;
    uint8 public cType;

    address public facAddress;
    address public ernTreasure;

    constructor(CollectionData memory collecData)
        ERC1155(collecData.uri)
        OperatorFilterer(collecData.operatorSubscription, true)
    {
        amount = collecData.amount;
        available = collecData.total;
        total = collecData.total;
        startTime = collecData.startTime;
        endTime = collecData.endTime;
        percent = collecData.percent;
        facAddress = collecData.factoryAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, collecData.admin);
        _setupRole(DEFAULT_ADMIN_ROLE, facAddress);
        _transferOwnership(collecData.admin);
        addExternalAddresses(
            collecData.token,
            collecData.stone,
            collecData.treasury,
            collecData.moneyHandler
        );
    }

    modifier onlyFactory() {
        require(
            msg.sender == facAddress,
            "This function can only be called by factory contract"
        );
        _;
    }

    function addExternalAddresses(
        address _token,
        address _stone, // 0x0000000000000000000
        address _treasury,
        address _moneyHandler
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
        stone = FarmV2(_stone);
        moneyHand = MoneyHandler(_moneyHandler);
        ernTreasure = _treasury;

        emit SetAddresses(_token, _stone, _treasury, _moneyHandler);
    }

    function recoverToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function buy(address buyer, uint256 _id) external onlyFactory {
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

        emit Sold(address(this), buyer, _id, amount);
    }

    function mint(address to, uint256 _id)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!(soldCards.contains(_id)), "This card already sold");
        require(available > 0, "Sold Out");

        _mint(to, _id, 1, "");

        available -= 1;
        sold += 1;
        soldCards.add(_id);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amount_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(available > ids.length, "Sold Out");

        for (uint256 i = 0; i < ids.length; i++) {
            require(!(soldCards.contains(ids[i])), "This card already sold");
        }

        _mintBatch(to, ids, amount_, "");

        available -= ids.length;
        sold += ids.length;

        for (uint256 i = 0; i < ids.length; i++) {
            soldCards.add(ids[i]);
        }
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

        emit SoldWithStones(buyer, amount);
    }

    function calcPerc(uint256 _amount, uint256 _percent)
        private
        pure
        returns (uint256)
    {
        uint256 sellmul = SafeMath.mul(_amount, _percent);
        uint256 sellAmount = SafeMath.div(sellmul, 10**18);
        return sellAmount;
    }

    function setStarTime(uint256 _starTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTime = _starTime;

        emit NewStartTime(startTime);
    }

    function setEndTime(uint256 _endTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        endTime = _endTime;

        emit NewEndTime(endTime);
    }

    function setAmount(uint256 _newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        amount = _newAmount;

        emit NewUsdAmount(amount);
    }

    function _withToken(address buyer) private {
        uint256 price = getCardPrice();
        require(
            token.balanceOf(buyer) >= price,
            "Insufficient funds: Cannot buy this NFT"
        );

        uint256 treasAmount = calcPerc(price, percent);
        uint256 shareAmount = SafeMath.sub(price, treasAmount);

        token.transferFrom(buyer, address(this), price);
        token.transfer(ernTreasure, treasAmount);
        token.transfer(address(moneyHand), shareAmount);

        moneyHand.updateCollecMny(address(this), shareAmount);

        emit PaymentTreasure(address(this), treasAmount);
        emit PaymentShared(address(this), shareAmount);
    }

    function getTokenPrice() public view returns (uint256) {
        address priceOracle = IFactory(facAddress).getPriceOracle();
        address tokenFeed = IPriceFeed(priceOracle).getFeed(address(token));
        int256 priceUSD = IPriceFeed(priceOracle).getThePrice(tokenFeed);
        uint256 uPriceUSD = uint256(priceUSD);

        return uPriceUSD;
    }

    function getCardPrice() public view returns (uint256) {
        uint256 tokenPrice = getTokenPrice();
        uint256 result = (amount * (1e44)) / (tokenPrice * (1e18));

        return result;
    }

    function owner()
        public
        view
        virtual
        override(Ownable, RevokableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
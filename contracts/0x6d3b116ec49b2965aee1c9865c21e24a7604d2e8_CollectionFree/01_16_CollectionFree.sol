// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./struct/CollectionInfo.sol";
import "./Interfaces/IFarmV2.sol";

contract CollectionFree is ERC1155, AccessControl {
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
    event NewNFTLimit(uint256 NFTLimit);
    event NewMinumumAmount(uint256 minumuAmount);
    event NewStonePrice(uint256 newStonePrice);
    event SetAddresses(address token, address Ifarm);
    event Initialize(
        uint256 total,
        uint256 startTime,
        uint256 endTime,
        uint256 minumumAmount,
        uint256 NFTLimit
    );
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet soldCards;

    mapping(address => uint256) public userNFTAmount;
    bytes32 public constant MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));

    IERC20 public token;
    IFarmV2 public Ifarm;

    uint256 public stonePrice;
    uint256 public percent;
    uint256 public available;
    uint256 public sold;
    uint256 public total;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public amount;
    uint256 public NFTLimit;

    address public facAddress;
    address public ernTreasure;

    constructor(CollectionData memory collecData) ERC1155(collecData.uri) {
        available = collecData.total;
        total = collecData.total;
        startTime = collecData.startTime;
        endTime = collecData.endTime;
        facAddress = collecData.factoryAddress;
        amount = collecData.minumumAmount;
        NFTLimit = collecData.NFTLimit;
        stonePrice = collecData.stonePrice;

        _setupRole(DEFAULT_ADMIN_ROLE, collecData.admin);
        _setupRole(DEFAULT_ADMIN_ROLE, facAddress);

        addExternalAddresses(collecData.token, collecData.farm);

        emit Initialize(total, startTime, endTime, amount, NFTLimit);
    }

    modifier onlyFactory() {
        require(
            msg.sender == facAddress,
            "This function can only be called by factory contract"
        );
        _;
    }

    modifier checkBalance(address buyer) {
        bool isTrue;
        if (Ifarm.farmed(buyer) + token.balanceOf(buyer) >= amount) {
            isTrue = true;
        } else {
            isTrue = false;
        }

        require(isTrue == true, "You do not have enough funds in your account");
        _;
    }

    function addExternalAddresses(address _token, address _farm)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        token = IERC20(_token);
        Ifarm = IFarmV2(_farm);

        emit SetAddresses(_token, _farm);
    }

    function recoverToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function buy(address buyer, uint256 _id)
        external
        onlyFactory
        checkBalance(buyer)
    {
        require(!(soldCards.contains(_id)), "This card already sold");
        require(available > 0, "Sold Out");
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Sale did not start yet"
        );
        if (stonePrice > 0) {
            _withStones(buyer);
        } else {
            require(
                userNFTAmount[buyer] < NFTLimit,
                "you are exceeding the limit of NFT you can have"
            );
        }
        _mint(buyer, _id, 1, "");

        userNFTAmount[buyer] += 1;
        available -= 1;
        sold += 1;
        soldCards.add(_id);

        emit Sold(address(this), buyer, _id, stonePrice);
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

    function setNFTLimit(uint256 _NFTLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        NFTLimit = _NFTLimit;

        emit NewNFTLimit(_NFTLimit);
    }

    function setMinumumAmount(uint256 _minumumAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        amount = _minumumAmount;

        emit NewMinumumAmount(_minumumAmount);
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

    function setStonePrice(uint256 _stonePrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stonePrice = _stonePrice;

        emit NewStonePrice(stonePrice);
    }

    function _withStones(address buyer) private {
        uint256 stones = Ifarm.rewardedStones(buyer);
        require(stones >= stonePrice, "You do not have enough points !");
        require(Ifarm.payment(buyer, stonePrice), "Payment was unsuccessful");

        emit SoldWithStones(buyer, stonePrice);
    }
}
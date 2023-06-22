// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Item is ERC1155, Ownable {
    // Solidity's arithmetic operations with added overflow checks
    using SafeMath for uint256;

    // item types (IDs)
    uint256[] public types;

    // amount of items minted by their IDs
    uint256[] public minted;

    // amount of items can be minted by their IDs
    uint256[] public totalSupply;

    // price in USD (item's ID => price (in wei))
    uint256[] public pricesUSD;

    // cost of mayne transmuting items
    uint256 public transmuteFee;

    // sum of received transmute fees, it counts from the last withdrawal
    uint256 public transmuteFeeSum;

    // pause for everything
    bool public pausedAll;

    // minting can be paused for each type (item's ID => paused or not)
    mapping(uint256 => bool) paused;

    // items minted by players (address => item's ID => amount)
    mapping(address => mapping(uint256 => uint256)) public mintedByPlayer;

    // items used within the game by players (address => item's ID => amount)
    mapping(address => mapping(uint256 => uint256)) public usedByPlayer;

    // Chainlink Data Feeds
    AggregatorV3Interface internal priceFeed;

    // minted item's information
    event PlayerMinted(
        address player,
        uint256 id,
        uint256 amount,
        bool isTransmuting
    );

    // fires transmuting
    event PlayerTransmuted(
        address player,
        uint256 id,
        uint256 amount,
        uint256 slot
    );

    //-------------------------------------------------------------------------
    // CONSTRUCTOR ////////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    constructor()
        ERC1155("https://empireofsight.com/metadata/items/{id}.json")
    {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        pausedAll = true;

        transmuteFee = 0.003 ether;
        transmuteFeeSum = 0;

        // adding the first 5 item
        for (uint256 i = 0; i < 5; i++) {
            types.push(i);
            totalSupply.push(1000);
            minted.push(0);
            pricesUSD.push(999 * 10**16);
        }
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS /////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    // returns with the length of type array (contains all the IDs)
    function getLengthTypes() public view returns (uint256) {
        return types.length;
    }

    // returns the latest price
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    // converts the USD value into the blockchain's native currency
    function getItemsNativePrice(uint256 id, uint256 amount)
        public
        view
        returns (uint256)
    {
        require(id <= types.length, "this type of item doesn't exist");
        require(amount > 0, "amount must be at least 1");

        return
            pricesUSD[id].div(uint256(getLatestPrice())).mul(10**8).mul(amount);
    }

    //-------------------------------------------------------------------------
    // SET FUNCTIONS //////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    // sets a new URI for all token types
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // pauses minting for a specific item
    function setPause(uint256 id, bool paused_) public onlyOwner {
        require(id <= getLengthTypes(), "this type of item doesn't exist");

        paused[id] = paused_;
    }

    // pauses minting for all items
    function setPausedAll() public onlyOwner {
        pausedAll = !pausedAll;
    }

    // sets the price of item by IDs
    // input price must be in wei
    function setPriceUSD(uint256 id, uint256 price) public onlyOwner {
        require(id <= getLengthTypes(), "this type of item doesn't exist");

        pricesUSD[id] = price;
    }

    // sets the fee of mayne transmuting
    // input fee must be in wei
    function setTransmuteFee(uint256 fee) public onlyOwner {
        transmuteFee = fee;
    }

    // sets the total supply of a specific item
    function setItemsTotalSupply(uint256 id, uint256 totalSupply_)
        external
        onlyOwner
    {
        require(id <= getLengthTypes(), "item doesn't exist");

        totalSupply[id] = totalSupply_;
    }

    //-------------------------------------------------------------------------
    // USER FUNCTIONS /////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    // mints items by IDs
    function mint(uint256 id, uint256 amount) public payable {
        require(id <= getLengthTypes(), "this type of item doesn't exist");
        require(
            msg.value >= getItemsNativePrice(id, amount),
            "the sent value is not enough"
        );
        require(pausedAll == false, "minting is paused for all items");
        require(paused[id] == false, "minting is paused for the item");
        require(
            minted[id] + amount <= totalSupply[id],
            "amount exceeds the total supply"
        );
        require(msg.sender != address(0), "sender can't be null address");

        _mint(msg.sender, id, amount, "");
        minted[id] += amount;
        mintedByPlayer[msg.sender][id] += amount;

        emit PlayerMinted(msg.sender, id, amount, false);
    }

    // takes fee if any then fires the transmuting mechanism
    function mayneTransmute(
        uint256 id,
        uint256 amount,
        uint256 slot
    ) public payable {
        require(id <= getLengthTypes(), "this type of item doesn't exist");
        require(
            msg.value >= transmuteFee.mul(amount),
            "the sent value is not enough"
        );
        require(msg.sender != address(0), "sender can't be null address");

        transmuteFeeSum += transmuteFee.mul(amount);

        emit PlayerTransmuted(msg.sender, id, amount, slot);
    }

    //-------------------------------------------------------------------------
    // ADMIN FUNCTIONS ////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    // input price must be in wei
    function addItem(uint256 totalSupply_, uint256 priceUSD)
        external
        onlyOwner
    {
        uint256 id = getLengthTypes();
        types.push(id);
        totalSupply.push(totalSupply_);
        pricesUSD.push(priceUSD);
        minted.push(0);
        paused[id] = false;
    }

    // mints items by IDs for specific players
    function mintAdmin(
        uint256 id,
        uint256 amount,
        address player,
        bool isTransmuting
    ) public onlyOwner {
        require(id < getLengthTypes(), "this type of item doesn't exist");
        require(
            minted[id] + amount <= totalSupply[id],
            "amount exceeds the total supply"
        );
        require(amount > 0, "amount must be at least 1");
        require(player != address(0), "player can't be null address");

        _mint(player, id, amount, "");
        minted[id] += amount;
        mintedByPlayer[player][id] += amount;

        emit PlayerMinted(player, id, amount, isTransmuting);
    }

    // withdraws all the balance of the contract to the dev & founder addresses
    function withdraw() external {
        require(address(this).balance > 0, "balance can't be zero");

        address founderOne = payable(
            0xfE38200d6206fcf177c8C2A25300FeeC3E3803F3
        );
        address founderTwo = payable(
            0x4ee757CfEBA27580BA587f8AE81f5BA63Bdd021d
        );
        address dev = payable(0x72a2547dcd6D114bA605Ad5C18756FD7aEAc467D);

        uint256 balanceOne = address(this).balance.mul(4).div(10);
        uint256 balanceTwo = address(this).balance.mul(4).div(10);
        uint256 balanceDev = address(this).balance.mul(2).div(10);

        payable(founderOne).transfer(balanceOne);
        payable(founderTwo).transfer(balanceTwo);
        payable(dev).transfer(balanceDev);

        transmuteFeeSum = 0;
    }
}
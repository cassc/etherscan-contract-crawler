//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract CertainlyNotABear is ERC721A, Ownable, ReentrancyGuard, KeeperCompatibleInterface {
    using Address for address;
    using Strings for uint;

    string  public bearTokenURI = "https://bafybeie7agb2scvvne6n42kfcgy3hjsqqb6xki6zzbmovc3rzevnyb2rhm.ipfs.nftstorage.link/metadata";
    string  public bullTokenURI = "";
    uint256 public MAX_SUPPLY = 444;
    uint256 public MAX_FREE_SUPPLY = 444;
    uint256 public MAX_PER_TX = 20;
    uint256 public PRICE = 0.005 ether;
    uint256 public maxFreePerTx = 20;
    bool public publicInitialize = false;
    bool public initialize = true;
    bool public revealed = true;

    string public market = "bear";

    int256 public limiarPrice = 2000;

    AggregatorV3Interface public pricefeed = AggregatorV3Interface(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public lastTimeStamp;

    mapping(address => uint256) public qtyFreeMinted;
    event NewBurnBears(address sender, uint256 bears);

    constructor() ERC721A("CertainlyNotABear", "CNB") {
        interval = 300;
        lastTimeStamp = block.timestamp;
    }


    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 timestamp = block.timestamp;
         upkeepNeeded = (timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        uint256 timestamp = block.timestamp;
        if ((timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            int price = getLatestPrice();

            if (price < limiarPrice) {
                console.log("ITS BEAR TIME");
                market = "bear";
            } else {
                console.log("ITS BULL TIME");
                market = "bull";
            }
        }
    }

    function getLatestPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = pricefeed.latestRoundData();

        return price;
    }

    function mintPublic(uint256 amount) external payable
    {
        uint256 cost = PRICE;
        uint256 num = amount > 0 ? amount : 1;

        bool free = ((totalSupply() + num < MAX_FREE_SUPPLY + 1) &&
            (qtyFreeMinted[msg.sender] + num <= 1));
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < MAX_PER_TX + 1, "Max per TX reached.");
        }

        require(publicInitialize, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < MAX_SUPPLY + 1, "No more");

        _safeMint(msg.sender, num);
    }

    function imAPanda(uint256 amount) external payable
    {
        ERC721A pandaContract = ERC721A(0x4706d9b3C94D1516277dC092E5eCD3DCeeD718C0);

        uint256 cost = PRICE;
        uint256 num = amount > 0 ? amount : 1;
        uint256 numberOfPanda = pandaContract.balanceOf(msg.sender);

        require(numberOfPanda > 0, "No has a panda");

        uint256 maxFreeMint = numberOfPanda;

        bool free = ((totalSupply() + num < MAX_FREE_SUPPLY + 1) &&
            (qtyFreeMinted[msg.sender] + num <= maxFreeMint));
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < MAX_PER_TX + 1, "Max per TX reached.");
        }

        require(initialize, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < MAX_SUPPLY + 1, "No more");

        _safeMint(msg.sender, num);
    }

    function setBearURI(string memory baseURI) public onlyOwner
    {
        bearTokenURI = baseURI;
    }

    function setBullURI(string memory baseURI) public onlyOwner
    {
        bullTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setLimiarPrice(int256 _price) public onlyOwner
    {
        limiarPrice = _price;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory uri = bearTokenURI;


        if (compareStrings(market, "bull")) {
            uri = bullTokenURI;
        }

        return string(abi.encodePacked(uri, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        if (compareStrings(market, "bull")) {
            return bullTokenURI;
        }

        return bearTokenURI;
    }

    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setPublicInitialize(bool _initialize) external onlyOwner
    {
        publicInitialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner
    {
        MAX_FREE_SUPPLY = _amount;
    }

    function burn(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            uint256 tokenid = tokenids[i];
            _burn(tokenid);
        }

        emit NewBurnBears(msg.sender, len);
    }
}
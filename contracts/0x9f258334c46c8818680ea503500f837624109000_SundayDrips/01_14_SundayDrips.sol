// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SundayDrips is ERC721, Ownable {
    using SafeMath for uint256;

    bool internal _saleIsActive;

    uint256 public sunriseAvailable = 1200;
    uint256 public sunsetAvailable = 600;
    uint256 public midnightAvailable = 200;

    uint256 public startTime;
    uint256 public startPrice = 0.07 ether;

    uint256 private sunriseId;
    uint256 private sunsetId = 1331;
    uint256 private midnightId = 1998;

    mapping(address => uint256) public sunriseAmount;
    mapping(address => uint256) public sunsetAmount;
    mapping(address => uint256) public midnightAmount;

    // Collection metatdata URI
    string private _baseTokenURI;

    // Amount of time between price increases
    uint256 private constant timeDelta = 12 hours;

    // Amount of ETH to increase every 'timeDelta'
    uint256 private constant priceDelta = 0.0005 ether;

    function startSale() external onlyOwner {
        require(!_saleIsActive, "Sale already active");
        startTime = block.timestamp;
        _saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(_saleIsActive, "Sale not active");
        _saleIsActive = false;
    }

    function mintSunrise() external payable {
        require(_saleIsActive, "Sale not active");
        require(1 <= sunriseAvailable, "No sunrise left");
        require(sunriseAmount[msg.sender] == 0, "Can't mint more");
        require(msg.value == getCurrentPrice(), "Not enough ETH");

        sunriseId++;
        _mint(msg.sender, sunriseId);
        sunriseAvailable = sunriseAvailable.sub(1);
        sunriseAmount[msg.sender]++;
    }

    function mintSunset() external payable {
        require(_saleIsActive, "Sale not active");
        require(1 <= sunsetAvailable, "No sunset left");
        require(sunsetAmount[msg.sender] == 0, "Can't mint more");
        require(msg.value == getCurrentPrice(), "Not enough ETH");

        sunsetId++;
        _mint(msg.sender, sunsetId);
        sunsetAvailable = sunsetAvailable.sub(1);
        sunsetAmount[msg.sender]++;
    }

    function mintMidnight() external payable {
        require(_saleIsActive, "Sale not active");
        require(1 <= midnightAvailable, "No midnight left");
        require(midnightAmount[msg.sender] == 0, "Can't mint more");
        require(msg.value == getCurrentPrice(), "Not enough ETH");

        midnightId++;
        _mint(msg.sender, midnightId);
        midnightAvailable = midnightAvailable.sub(1);
        midnightAmount[msg.sender]++;
    }

    function mintAll() external payable {
        require(_saleIsActive, "Sale not active");
        require(1 <= sunriseAvailable, "No sunrise left");
        require(1 <= sunsetAvailable, "No sunset left");
        require(1 <= midnightAvailable, "No midnight left");
        require(sunriseAmount[msg.sender] == 0, "Can't mint more");
        require(sunsetAmount[msg.sender] == 0, "Can't mint more");
        require(midnightAmount[msg.sender] == 0, "Can't mint more");
        require(msg.value >= getCurrentPrice().mul(3), "Not enough ETH");

        sunriseId++;
        sunsetId++;
        midnightId++;
        _mint(msg.sender, sunriseId);
        _mint(msg.sender, sunsetId);
        _mint(msg.sender, midnightId);
        sunriseAvailable = sunriseAvailable.sub(1);
        sunsetAvailable = sunsetAvailable.sub(1);
        midnightAvailable = midnightAvailable.sub(1);

        sunriseAmount[msg.sender]++;
        sunsetAmount[msg.sender]++;
        midnightAmount[msg.sender]++;
    }

    function adminMintSunrise(address _toAddress) external onlyOwner {
        sunriseId++;
        _mint(_toAddress, sunriseId);
        sunriseAvailable = sunriseAvailable.sub(1);
    }

    function adminMintSunset(address _toAddress) external onlyOwner {
        sunsetId++;
        _mint(_toAddress, sunsetId);
        sunsetAvailable = sunsetAvailable.sub(1);
    }

    function adminMintMidnight(address _toAddress) external onlyOwner {
        midnightId++;
        _mint(_toAddress, midnightId);
        midnightAvailable = midnightAvailable.sub(1);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (!_saleIsActive) {
            return startPrice;
        }
        return _getCurrentPrice(startTime, block.timestamp, startPrice);
    }

    /**
     * @dev Get the current price of a token.
     * We make this virtual so we can override it in tests.
     * @param _startTime the starting timestamp.
     * @param _currentTime the current timestamp.
     * @param _startPrice the minimum price of the token.
     */
    function _getCurrentPrice(
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _startPrice
    ) internal view virtual returns (uint256) {
        if (_currentTime < _startTime) {
            return _startPrice;
        }

        // Check for number of increases to start price
        uint256 timeDiff = _currentTime.sub(_startTime).div(timeDelta);
        // Increase by 0.0005 eth for every 12 hours that has passed
        uint256 newPrice = timeDiff.mul(priceDelta).add(startPrice);

        return Math.max(_startPrice, newPrice);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    constructor(string memory metadataBaseURI) ERC721("Sunday:Drip", "DRIP") {
        _baseTokenURI = metadataBaseURI;
    }
}
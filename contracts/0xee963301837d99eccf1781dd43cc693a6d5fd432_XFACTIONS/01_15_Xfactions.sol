//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract XFACTIONS  is ERC721Enumerable, Ownable, Pausable {
    using SafeCast for uint256;

    event TokenPriceChanged(uint256 newTokenPrice);
    event PresaleConfigChanged(uint256 preSaleFee, uint32 startTime, uint32 endTime, uint32 maxCount);
    event SaleConfigChanged(uint32 startTime, uint32 maxCount);
    event TreasuryChanged(address newTreasury);
    event BaseURIChanged(string newBaseURI);
    event PresaleMint(address minter, uint256 count);
    event SaleMint(address minter, uint256 count);

    // Both structs fit in a single storage slot for gas optimization
    struct PresaleConfig {
	    uint256 preSaleFee;
        uint32 startTime;
        uint32 endTime;
	    uint32 maxCount;
    }
    struct SaleConfig {
        uint32 startTime;
        uint32 maxCount;
    }

    uint256 public immutable maxSupply;
    uint256 public immutable reserveCount;

    uint256 public tokensReserved;
    uint256 public nextTokenId;
    address payable public treasury;

    uint256 public tokenPrice;

    PresaleConfig public presaleConfig;
    mapping(address => uint256) public presaleBoughtCounts;
    mapping(address => uint256) public saleBoughtCounts;

    SaleConfig public saleConfig;

    string public baseURI;


    constructor(uint256 _maxSupply, uint256 _reserveCount) ERC721("XFACTIONS", "XFACTIONS") {
        require(_reserveCount <= _maxSupply, "XFACTIONS: reserve count out of range");

        maxSupply = _maxSupply;
        reserveCount = _reserveCount;
        nextTokenId = 1; // We start from token 1
    }

    function reserveTokens(address recipient, uint256 count) external onlyOwner {
        require(recipient != address(0), "XFACTIONS: zero address");

        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        require(count > 0, "XFACTIONS: invalid count");
        require(_nextTokenId + count <= maxSupply, "XFACTIONS: max supply exceeded");

        require(tokensReserved + count <= reserveCount, "XFACTIONS: max reserve count exceeded");
        tokensReserved += count;

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(recipient, _nextTokenId + ind);
        }
        nextTokenId += count;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit TokenPriceChanged(_tokenPrice);
    }

    function setUpPresale(
	    uint256 preSaleFee,
        uint256 startTime,
        uint256 endTime,
	    uint256 maxCount
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();
	    uint32 _maxCount = maxCount.toUint32();

        // Check params
        require(_startTime > 0 && _endTime > _startTime, "XFACTIONS: invalid time range");
	    require(_maxCount > 0, "XFACTIONS: maxCount is zero");
        presaleConfig = PresaleConfig({preSaleFee: preSaleFee, startTime: _startTime, endTime: _endTime, maxCount: _maxCount});

        emit PresaleConfigChanged(preSaleFee, _startTime, _endTime, _maxCount);
    }

    function setUpSale(
        uint256 startTime,
        uint256 maxCount
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _maxCount = maxCount.toUint32();

        require(_maxCount > 0, "XFACTIONS: zero amount");
        require(_startTime > 0 , "XFACTIONS: invalid time range");

        saleConfig = SaleConfig({
            startTime: _startTime,
            maxCount: _maxCount
        });

        emit SaleConfigChanged(_startTime, _maxCount);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function mintPresaleTokens(
        uint256 count
    ) external payable whenNotPaused{
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        PresaleConfig memory _presaleConfig = presaleConfig;

        require(treasury != address(0), "XFACTIONS: treasury not set");
        require(count > 0, "XFACTIONS: invalid count");
        require(block.timestamp >= _presaleConfig.startTime, "XFACTIONS: presale not started");
        require(block.timestamp < _presaleConfig.endTime, "XFACTIONS: presale ended");

        require(_nextTokenId + count <= maxSupply, "XFACTIONS: max supply exceeded");
        require(_presaleConfig.preSaleFee * count == msg.value, "XFACTIONS: incorrect Ether value");

        require(presaleBoughtCounts[msg.sender] + count <= _presaleConfig.maxCount, "XFACTIONS: presale max count exceeded");
        presaleBoughtCounts[msg.sender] += count;

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        treasury.transfer(msg.value);

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit PresaleMint(msg.sender, count);
    }

    function mintTokens(uint256 count) external payable whenNotPaused {
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        SaleConfig memory _saleConfig = saleConfig;
        require(_saleConfig.startTime > 0, "XFACTIONS: sale not configured");

        require(treasury != address(0), "XFACTIONS: treasury not set");
        require(tokenPrice > 0, "XFACTIONS: token price not set");
        require(count > 0, "XFACTIONS: invalid count");
        require(block.timestamp >= _saleConfig.startTime, "XFACTIONS: sale not started");
        require(count + saleBoughtCounts[msg.sender]
        <= _saleConfig.maxCount, "XFACTIONS: presale max count exceeded");
        saleBoughtCounts[msg.sender] += count;

        require(_nextTokenId + count <= maxSupply, "XFACTIONS: max supply exceeded");
        require(tokenPrice * count == msg.value, "XFACTIONS: incorrect Ether value");

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        treasury.transfer(msg.value);

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit SaleMint(msg.sender, count);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "XFACTIONS: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pauseMinting() external onlyOwner {
        _pause();
    }

    function unPauseMinting() external onlyOwner {
        _unpause();
    }
}
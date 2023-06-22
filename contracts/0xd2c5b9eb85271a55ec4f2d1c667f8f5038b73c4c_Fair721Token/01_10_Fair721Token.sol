// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IFair721NFT.sol";
import "./interface/IUniswapPool.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IWETH.sol";

contract Fair721Token is ERC20, Ownable {
    IFair721NFT public constant fair721 = IFair721NFT(0xE7667Cb1cd8FE89AA38d7F20DCC50ee262cC9D12);

    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public constant one = 10000 * 1e18;
    uint256 public startTime = 0xffffffffffffffffff;

    uint256 public burnFee = 0.0001 ether;

    uint256 public convertEnd;
    address public creator;

    uint256 public constant userRate = 500;
    uint256 public constant lpRate = 490;
    uint256 public constant devRate = 10;

    IUniswapPool public pool;

    constructor() ERC20("Fair 721 Token", "F721") {
        creator = msg.sender;
        convertEnd = block.timestamp + 7 days;
    }

    function createPair() external onlyOwner {
        require(address(pool) == address(0), "pool");
        IUniswapFactory factory = IUniswapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        address pair = factory.createPair(address(this), address(WETH));
        pool = IUniswapPool(pair);
    }

    function setStart(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
        convertEnd = startTime + 24 * 3600;
        burnFee = 0.002 ether;
    }

    function convert(uint256 tokenId) external payable {
        require(msg.sender == tx.origin, "EOA");
        require(block.timestamp >= startTime || msg.sender == owner(), "not start");
        require(block.timestamp < convertEnd, "end");
        require(msg.value >= burnFee, "fee");
        require(fair721.ownerOf(tokenId) == msg.sender, "owner");

        uint256 tokenAmount = fair721.amountOf(tokenId);
        fair721.burn(tokenId);

        uint256 mintAmount = tokenAmount * one;
        _mint(address(this), mintAmount);

        uint256 userAmount = mintAmount / 1000 * userRate;
        uint256 lpAmount = mintAmount / 1000 * lpRate;
        uint256 devAmount = mintAmount - userAmount - lpAmount;
        _transfer(address(this), msg.sender, userAmount);
        _transfer(address(this), creator, devAmount);

        uint256 devETHAmount = msg.value / 1000 * devRate;
        WETH.deposit{value: msg.value}();
        WETH.transfer(creator, devETHAmount);

        _transfer(address(this), address(pool), lpAmount);
        WETH.transfer(address(pool), msg.value - devETHAmount);
        pool.sync();
    }

    function batchConvert(uint256[] memory tokenIds) external payable {
        require(msg.sender == tx.origin, "EOA");
        require(block.timestamp >= startTime || msg.sender == owner(), "not start");
        require(block.timestamp < convertEnd, "end");

        uint256 count = tokenIds.length;
        require(msg.value >= burnFee * count, "fee");
        uint256 totalMintAmount = 0;
        for (uint256 i = 0; i < count; i++) {
            require(fair721.ownerOf(tokenIds[i]) == msg.sender, "owner");
            uint256 tokenAmount = fair721.amountOf(tokenIds[i]);
            fair721.burn(tokenIds[i]);
            totalMintAmount += tokenAmount * one;
        }

        _mint(address(this), totalMintAmount);

        uint256 userAmount = totalMintAmount / 1000 * userRate;
        uint256 lpAmount = totalMintAmount / 1000 * lpRate;
        uint256 devAmount = totalMintAmount - userAmount - lpAmount;
        _transfer(address(this), msg.sender, userAmount);
        _transfer(address(this), creator, devAmount);

        uint256 devETHAmount = msg.value / 1000 * devRate;
        WETH.deposit{value: msg.value}();
        WETH.transfer(creator, devETHAmount);

        _transfer(address(this), address(pool), lpAmount);
        WETH.transfer(address(pool), msg.value - devETHAmount);
        pool.sync();
    }
}
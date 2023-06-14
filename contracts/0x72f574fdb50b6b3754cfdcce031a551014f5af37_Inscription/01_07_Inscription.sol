// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Logarithm.sol";
import "./TransferHelper.sol";

// This is common token interface, get balance of owner's token by ERC20/ERC721/ERC1155.
interface ICommonToken {
    function balanceOf(address owner) external returns(uint256);
}

// This contract is extended from ERC20
contract Inscription is ERC20 {
    using Logarithm for int256;
    uint256 public cap;                 // Max amount
    uint256 public limitPerMint;        // Limitaion of each mint
    uint256 public inscriptionId;       // Inscription Id
    uint256 public maxMintSize;         // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
    uint256 public freezeTime;          // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
    address public onlyContractAddress; // Only addresses that hold these assets can mint
    uint256 public onlyMinQuantity;     // Only addresses that the quantity of assets hold more than this amount can mint
    uint256 public baseFee;             // base fee of the second mint after frozen interval. The first mint after frozen time is free.
    uint256 public fundingCommission;   // commission rate of fund raising, 100 means 1%
    uint256 public crowdFundingRate;    // rate of crowdfunding
    address payable public crowdfundingAddress; // receiving fee of crowdfunding
    address payable public inscriptionFactory;

    mapping(address => uint256) public lastMintTimestamp;   // record the last mint timestamp of account
    mapping(address => uint256) public lastMintFee;           // record the last mint fee

    constructor(
        string memory _name,            // token name
        string memory _tick,            // token tick, same as symbol. must be 4 characters.
        uint256 _cap,                   // Max amount
        uint256 _limitPerMint,          // Limitaion of each mint
        uint256 _inscriptionId,         // Inscription Id
        uint256 _maxMintSize,           // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint. This is only availabe for non-frozen time token.
        uint256 _freezeTime,            // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        address _onlyContractAddress,   // Only addresses that hold these assets can mint
        uint256 _onlyMinQuantity,       // Only addresses that the quantity of assets hold more than this amount can mint
        uint256 _baseFee,               // base fee of the second mint after frozen interval. The first mint after frozen time is free.
        uint256 _fundingCommission,     // commission rate of fund raising, 100 means 1%
        uint256 _crowdFundingRate,      // rate of crowdfunding
        address payable _crowdFundingAddress,   // receiving fee of crowdfunding
        address payable _inscriptionFactory
    ) ERC20(_name, _tick) {
        require(_cap >= _limitPerMint, "Limit per mint exceed cap");
        cap = _cap;
        limitPerMint = _limitPerMint;
        inscriptionId = _inscriptionId;
        maxMintSize = _maxMintSize;
        freezeTime = _freezeTime;
        onlyContractAddress = _onlyContractAddress;
        onlyMinQuantity = _onlyMinQuantity;
        baseFee = _baseFee;
        fundingCommission = _fundingCommission;
        crowdFundingRate = _crowdFundingRate;
        crowdfundingAddress = _crowdFundingAddress;
        inscriptionFactory = _inscriptionFactory;
    }

    function mint(address _to) payable public {
        // Check if the quantity after mint will exceed the cap
        require(totalSupply() + limitPerMint <= cap, "Touched cap");
        // Check if the assets in the msg.sender is satisfied
        require(onlyContractAddress == address(0x0) || ICommonToken(onlyContractAddress).balanceOf(msg.sender) >= onlyMinQuantity, "You don't have required assets");

        if(lastMintTimestamp[msg.sender] + freezeTime > block.timestamp) {
            // The min extra tip is double of last mint fee
            lastMintFee[msg.sender] = lastMintFee[msg.sender] == 0 ? baseFee : lastMintFee[msg.sender] * 2;
            // Transfer the fee to the crowdfunding address
            if(crowdFundingRate > 0) {
                // Check if the tip is high than the min extra fee
                require(msg.value >= crowdFundingRate + lastMintFee[msg.sender], "Send some ETH as fee and crowdfunding");
                _dispatchFunding(crowdFundingRate);
            }
            // Transfer the tip to InscriptionFactory smart contract
            if(msg.value - crowdFundingRate > 0) TransferHelper.safeTransferETH(inscriptionFactory, msg.value - crowdFundingRate);
        } else {
            // Transfer the fee to the crowdfunding address
            if(crowdFundingRate > 0) {
                require(msg.value >= crowdFundingRate, "Send some ETH as crowdfunding");
                _dispatchFunding(msg.value);
            }
            // Out of frozen time, free mint. Reset the timestamp and mint times.
            lastMintFee[msg.sender] = 0;
            lastMintTimestamp[msg.sender] = block.timestamp;
        }
        // Do mint
        _mint(_to, limitPerMint);
    }

    // batch mint is only available for non-frozen-time tokens
    function batchMint(address _to, uint256 _num) payable public {
        require(_num <= maxMintSize, "exceed max mint size");
        require(totalSupply() + _num * limitPerMint <= cap, "Touch cap");
        require(freezeTime == 0, "Batch mint only for non-frozen token");
        require(onlyContractAddress == address(0x0) || ICommonToken(onlyContractAddress).balanceOf(msg.sender) >= onlyMinQuantity, "You don't have required assets");
        if(crowdFundingRate > 0) {
            require(msg.value >= crowdFundingRate * _num, "Crowdfunding ETH not enough");
            _dispatchFunding(msg.value);
        }
        for(uint256 i = 0; i < _num; i++) _mint(_to, limitPerMint);
    }

    function getMintFee(address _addr) public view returns(uint256 mintedTimes, uint256 nextMintFee) {
        if(lastMintTimestamp[_addr] + freezeTime > block.timestamp) {
            int256 scale = 1e18;
            int256 halfScale = 5e17;
            // times = log_2(lastMintFee / baseFee) + 1 (if lastMintFee > 0)
            nextMintFee = lastMintFee[_addr] == 0 ? baseFee : lastMintFee[_addr] * 2;
            mintedTimes = uint256((Logarithm.log2(int256(nextMintFee / baseFee) * scale, scale, halfScale) + 1) / scale) + 1;
        }
    }

    function _dispatchFunding(uint256 _amount) private {
        uint256 commission = _amount * fundingCommission / 10000;
        TransferHelper.safeTransferETH(crowdfundingAddress, _amount - commission);
        if(commission > 0) TransferHelper.safeTransferETH(inscriptionFactory, commission);
    }
}
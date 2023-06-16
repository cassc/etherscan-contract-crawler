// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./external/AggregatorV3Interface.sol";
import "./DiamondContract.sol";


interface IStoreAirdrop {
    function airdrop(
        address _nftContractAddress,
        uint64 _tier, // For random the design
        address _repicient
    )
        external
        payable;
}

contract ShibafriendAirdrop is Initializable, OwnableUpgradeable {
    uint256 public lockDuration; // in second
    uint256 public airdropPrice; // in USD
    uint256 public airdropAmount;
    bool public inAirdrop;
    uint256 public airdropCount; // count of sold airdrop
    AggregatorV3Interface internal bnbPriceFeed;
    IDiamond public diamondContract;
    address public shibaNFTContract;
    uint64 nftTier;
    IStoreAirdrop storeContract;

    mapping (address => bool) public boughtAirdrop;

    function initialize(address _diamondContract, address _shibaNFTContract, address _storeContract) public initializer {
        __Ownable_init_unchained();
        diamondContract = IDiamond(_diamondContract);
        shibaNFTContract = _shibaNFTContract;
        storeContract = IStoreAirdrop(_storeContract);
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyOwner() {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"Airdrop: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function startAirdrop(uint256 _airdropAmount, uint256 _airdropPrice, uint64 _nftTier, uint256 _lockDuration) external onlyOwner() {
        require(_airdropPrice > 0, "Airdrop: Airdrop price must be > 0");
        require(_airdropAmount > 0, "Airdrop: Airdrop amount must be > 0");
        require(_lockDuration > 0, "Airdrop: lock duration must be > 0");

        airdropPrice = _airdropPrice;
        airdropAmount = _airdropAmount;
        lockDuration = _lockDuration;
        nftTier = _nftTier;
        inAirdrop = true;
    }

    function getLatestPrice() public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "Airdrop: Invalid price");
        return uint(price) * airdropPrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    function stopAirdrop() external onlyOwner() {
        inAirdrop = false;
    }

    function airdrop() external payable {
        require(inAirdrop, 'Airdrop: Not in airdrop');
        require(!boughtAirdrop[msg.sender], 'Airdrop: Already bought airdrop');
        require(diamondContract.balanceOf(address(this)) >= airdropAmount, 'Airdrop: No more token for airdrop');
        require(msg.value >= getLatestPrice(), "Airdrop: Not enough BNB");

        boughtAirdrop[msg.sender] = true;
        diamondContract.lockTransfer(msg.sender, lockDuration);
        diamondContract.transfer(msg.sender, airdropAmount);
        storeContract.airdrop(shibaNFTContract, nftTier, msg.sender);
        airdropCount++;
    }

    function withdraw() external onlyOwner() {
        (bool sent, bytes memory data) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
    }

    function withdrawDiamond() external onlyOwner() {
        diamondContract.transfer(msg.sender, diamondContract.balanceOf(address(this)));
    }

    function changeStoreContract(address _storeContract) external onlyOwner(){
        storeContract = IStoreAirdrop(_storeContract);
    }

    function changeNFTContract(address _shibaNFTContract) external onlyOwner(){
        shibaNFTContract = _shibaNFTContract;
    }

    function setNftTier(uint64 _tier) external onlyOwner(){
        nftTier = _tier;
    }
}
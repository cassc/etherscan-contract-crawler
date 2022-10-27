// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/ICOW721.sol";
import "../interface/ICattle1155.sol";

contract ExchangeCow is OwnableUpgradeable {
    IERC20Upgradeable public bvt;
    IERC20Upgradeable public ho;
    uint public bvtPrice;
    uint public hoPrice;
    ICOW public cattle;
    address public burnAddress;
    uint[] rate;
    ICattle1155 public item;

    struct PackInfo {
        string name;
        uint types; // 1 for cattle , 2 for item
        uint price;
        uint itemId; // 0 for item;
        uint saleAmount;
    }

    uint public saleRate;
    mapping(uint => PackInfo) public packInfo;
    address public banker;

    event Buy(address indexed user, uint indexed packId, uint indexed amount);
    event SendPack(address indexed user, uint indexed packId, uint indexed amount);
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        bvtPrice = 5e16;
        hoPrice = 6e17;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        rate = [80, 20];
        newPackInfo(1, 'Cattle', 1, 150e18, 0);
        newPackInfo(4, 'EXP Card', 2, 25e16, 4);
        newPackInfo(5, 'Prime EXP Card', 2, 5e17, 5);
        newPackInfo(6, 'Supreme EXP Card', 2, 75e16, 6);
        newPackInfo(7, 'STR Battery', 2, 25e16, 7);
        newPackInfo(8, 'Prime STR Battery', 2, 5e17, 8);
        newPackInfo(9, 'Supreme STR Battery', 2, 75e16, 9);
        newPackInfo(10, 'HP Potion', 2, 10e18, 10);
        newPackInfo(11, 'Prime HP Potion', 2, 20e18, 11);
        newPackInfo(12, 'Supreme HP Potion', 2, 30e18, 12);
        newPackInfo(20003, 'Skin Box', 2, 20e18, 20003);
        saleRate = 95;
        banker = msg.sender;
    }

    modifier onlyEOA{
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    modifier onlyBanker{
        require(msg.sender == banker, "not banker");
        _;
    }

    function setBanker(address addr) external onlyOwner {
        banker = addr;
    }

    function initAddress(address cattle_, address bvt_, address token_, address item_) external onlyOwner {
        cattle = ICOW(cattle_);
        bvt = IERC20Upgradeable(bvt_);
        ho = IERC20Upgradeable(token_);
        item = ICattle1155(item_);
    }

    function newPackInfo(uint packId, string memory name, uint types, uint price, uint itemId) public onlyOwner {
        require(packInfo[packId].types == 0, 'already have');
        packInfo[packId] = PackInfo(name, types, price, itemId, packInfo[packId].saleAmount);
    }

    function setPrice(uint bvtPrice_, uint tokenPrice_) external onlyOwner {
        bvtPrice = bvtPrice_;
        hoPrice = tokenPrice_;
    }

    function countingOut(uint price, uint tokenPrices) public pure returns (uint){
        return (price * 1e18 / tokenPrices);
    }

    function exchangePack(uint packId, uint amount) external onlyEOA {
        uint bvtAmount = countingOut(packInfo[packId].price * rate[0] / 100, bvtPrice) * saleRate / 100;
        uint tokenAmount = countingOut(packInfo[packId].price * rate[1] / 100, hoPrice) * saleRate / 100;
        bvt.transferFrom(msg.sender, burnAddress, bvtAmount * amount);
        ho.transferFrom(msg.sender, burnAddress, tokenAmount * amount);
        packInfo[packId].saleAmount += amount;
        emit Buy(msg.sender, packId, amount);
    }

    function sendPack(uint packId, address to, uint amount) external onlyBanker {
        require(packInfo[packId].types != 0, 'not cattle');
        if (packInfo[packId].types == 1) {
            uint[2] memory par;
            par[0] = 1;
            par[1] = 39;
            for (uint i = 0; i < amount; i ++) {
                cattle.mintNormall(to, par);
            }
        } else if (packInfo[packId].types == 2) {
            uint[] memory itemList = new uint[](1);
            uint[] memory amountList = new uint[](1);
            itemList[0] = packInfo[packId].itemId;
            amountList[0] = amount;
            item.mintBatch(to, itemList,amountList);
        }
        emit SendPack(to, packId, amount);
    }
}
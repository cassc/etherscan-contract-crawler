// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/mpo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MpoMutiCall is OwnableUpgradeable {
    address public MpoPreSale;
    address public MpoInvite;
    address public MpoToken;
    address public MpoNft;
    address public MpoIdo;
    address public MpoNftFinance;
    address public MpoBox;
    address public MpoFinance;

    ////////////////////////////////
    /////////// function ///////////
    ////////////////////////////////

    function init() external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        MpoPreSale = 0xBBb5348DcbA0097bFd7C24F99481b61C51c6a0e9;
        MpoInvite = 0x1CC66756E6015A945eA7e59B0ad5a04B0c5Abe55;
        MpoToken = 0xB3eA60DE817c2Bd70bFCE46BE2598D7165E2073C;
    }

    function setMpoPreSaleAddress(address addr_) public onlyOwner {
        MpoPreSale = addr_;
    }

    function setMpoFinance(address mpoFinance_) public onlyOwner {
        MpoFinance = mpoFinance_;
    }

    function setMpoInviteAddress(address addr_) public onlyOwner {
        MpoInvite = addr_;
    }

    function setMpoTokenAddress(address addr_) public onlyOwner {
        MpoToken = addr_;
    }

    function setMpoNftAddress(address addr_) public onlyOwner {
        MpoNft = addr_;
    }

    function setMpoNftFinanceAddress(address addr_) public onlyOwner {
        MpoNftFinance = addr_;
    }

    function setMpoIdoAddress(address addr_) public onlyOwner {
        MpoIdo = addr_;
    }

    function setMpoBox(address addr_) public onlyOwner {
        MpoBox = addr_;
    }

    function checkPreSaleInfo_1() public view returns (uint[4] memory list) {
        (
            uint allSale,
            uint preSaleAmount,
            uint preSaleInitShare,
            uint preSalePrice
        ) = IPreSale(MpoPreSale).checkPreSaleInfo();
        list = [allSale, preSaleAmount, preSaleInitShare, preSalePrice];
    }

    /////////////////////////////
    /////////  pre sale  ////////
    /////////////////////////////
    function checkPreSaleInfo_2(address user_)
        public
        view
        returns (
            uint[8] memory list,
            uint[2] memory nftBonus,
            bool isPre,
            address inv
        )
    {
        inv = Iinvite(MpoInvite).checkInviter(user_);
        (
            uint soldPreSle,
            uint preSaleClaimed,
            uint tatolRemaining,
            uint tatolToClaim
        ) = IPreSale(MpoPreSale).checkPreSaleReceived();
        uint amount;
        uint claimed;
        (isPre, amount, , , claimed) = IPreSale(MpoPreSale).userInfo(user_);

        uint toClaim;
        if (isPre) {
            toClaim = IPreSale(MpoPreSale).calculate(user_);
        }

        uint teamLength = IPreSale(MpoPreSale).checkTeamLength(user_);
        (nftBonus[0], nftBonus[1]) = IPreSale(MpoPreSale).checkNftBouns(user_);

        list = [
            soldPreSle,
            claimed,
            toClaim,
            preSaleClaimed,
            tatolToClaim,
            tatolRemaining,
            teamLength,
            amount
        ];
    }

    /////////////////////////////
    ///////////  i d o //////////
    /////////////////////////////

    function checkIDO1(address user_)
        public
        view
        returns (
            uint[4] memory list,
            address inv,
            bool[2] memory b,
            uint[2] memory time,
            bool isClaimed
        )
    {
        (list, b, time) = Iido(MpoIdo).mutiCheck(user_);
        inv = Iinvite(MpoInvite).checkInviter(user_);
        isClaimed = Iido(MpoIdo).isidoClaimed(user_);
    }

    /////////////////////////////
    /////////  buyToken /////////
    /////////////////////////////

    function checkBuyTokenBonus(address user_)
        public
        view
        returns (uint[4] memory list)
    {
        uint p = IMPOT(MpoToken).checkPhase();
        list[0] = IMPOT(MpoToken).checkPhaseBuyAmountTotal(p, user_);
        (list[1], ) = IbuyTokenBonus(MpoFinance).f_userInfo(p, user_);
        list[2] = IbuyTokenBonus(MpoFinance).finance_checktoClaimBonus(user_);
        list[3] = IbuyTokenBonus(MpoFinance).f_thisRoundClaimed();
    }

    /////////////////////////////
    ///////// nftreward /////////
    /////////////////////////////

    function checknftReward(address user_)
        public
        view
        returns (uint[6] memory list)
    {
        (, , list[0], , ) = INfts(MpoNft).cardInfoes(10001);
        (, , list[1], , ) = INfts(MpoNft).cardInfoes(10002);
        (, , list[2], , ) = INfts(MpoNft).cardInfoes(10003);

        (list[3], , , ) = InftFinance(MpoNftFinance).nftDistribute();
        list[4] = InftFinance(MpoNftFinance).userNftRewardClaimed(user_);
        list[5] = InftFinance(MpoNftFinance).calculateUserReward(user_);
    }

    /////////////////////////////
    ////////// nft  bag /////////
    /////////////////////////////

    function checkMyNfts(address user_)
        public
        view
        returns (
            uint[] memory cardIdss,
            uint[] memory tokenIdss,
            string[] memory tokenUrlss
        )
    {
        (cardIdss, tokenIdss) = INfts(MpoNft).tokenOfOwnerForAll(user_);
        tokenUrlss = INfts(MpoNft).batchTokenURI(user_);
    }

    function checkMyBoxs()
        public
        view
        returns (address[2] memory addresss, uint[5] memory uintList)
    {
        uintList[0] = InftFinance(MpoNftFinance).boxPrice();
        uintList[1] = InftFinance(MpoNftFinance).costUsdtProportion();
        uintList[2] = InftFinance(MpoNftFinance).openedBox();
        (, , uintList[3], uintList[4]) = InftFinance(MpoNftFinance).boxInfo();
        addresss[0] = InftFinance(MpoNftFinance).USDT();
        addresss[1] = InftFinance(MpoNftFinance).BuyBoxCostToken();
    }
}
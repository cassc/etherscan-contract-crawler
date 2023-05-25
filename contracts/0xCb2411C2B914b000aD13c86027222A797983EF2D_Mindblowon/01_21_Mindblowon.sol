// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PrivateSalesActivation.sol";
import "./PublicSalesActivation.sol";
import "./DASalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721Opensea.sol";
import "./Withdrawable.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////@@@@@@@@@%//////////////////////////////////////////////////////    //
//    ///////////////////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////////////////////    //
//    ////////////////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////////////////    //
//    ////////////////////////////////////////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////////////    //
//    //////////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////////////////////////////////////    //
//    ///////////////////////////////////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////////    //
//    //////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////////////////////////////    //
//    /////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////////////////////////////////    //
//    ////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@@[email protected]///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@@[email protected]///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@@[email protected]///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@/[email protected]///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@[email protected]@@@%[email protected]@[email protected]///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@@@[email protected]    @    @.........*    @    @@///////////////////////////////    //
//    ///////////////////////////////@@@@@@@@@@@@@@@@@@,[email protected]@     @@[email protected]*     %@[email protected]///////////////////////////////    //
//    ////////////////////////////////@@@@@@@@@*[email protected]///////////////////////////////    //
//    /////////////////////////////////@@@@@@@*[email protected]///////////////////////////////    //
//    //////////////////////////////////@@@@@@@..................(                      @[email protected]///////////////////////////////    //
//    ///////////////////////////////////@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]///////////////////////////////    //
//    ////////////////////////////////////&@@@@@@@@@@&[email protected]##############@@@@@[email protected]@///////////////////////////////    //
//    //////////////////////////////////////@@@@@@@@@@[email protected]###############@@[email protected]////////////////////////////////    //
//    ////////////////////////////////////////@@@@@@@@[email protected]############@[email protected]@/////////////////////////////////    //
//    //////////////////////////////////////////@@@@@@[email protected]@@@@,[email protected]///////////////////////////////////    //
//    //////////////////////////////////////////////@[email protected]@/////////////////////////////////////    //
//    //////////////////////////////////////////////@[email protected]@@////////////////////////////////////////    //
//    ///////////////////////////////////////@@@//////@[email protected]@@//////////////////////////////////////////    //
//    //////////////////////////////////@@//////////////@[email protected]//////@@/////////////////////////////////////    //
//    //////////////////////////////@@////////////////////@@[email protected]@///////////@@/////////////////////////////////    //
//    ///////////////////////////@@///////////////////////////@@@[email protected]@/////////////////@@//////////////////////////////    //
//    /////////////////////////@/////////////////////////////////////////////////////////////////@@///////////////////////////    //
//    ///////////////////////@/////////////////////////////////////////////////////////////////////@@/////////////////////////    //
//    /////////////////////@/////////////////////////////////////////////////////////////////////////@////////////////////////    //
//    ////////////////////@///////////////////////////////////////////////////////////////////////////@///////////////////////    //
//    ///////////////////@&////////////////////////////////////////////////////////////////////////////@//////////////////////    //
//    ///////////////////@/////////////////////////////////////////////////////////////////////////////%@/////////////////////    //
//    //////////////////@///////////////////////////////////////////////////////////////////////////////@/////////////////////    //
//    //////////////////@///////////////@////////////////////////////////////////////////////////////@///@////////////////////    //
//    //////////////////@///////////////@////////////////////////////////////////////////////////////@///@(///////////////////    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Mindblowon is
    Ownable,
    EIP712,
    DASalesActivation,
    PrivateSalesActivation,
    PublicSalesActivation,
    Whitelist,
    ERC721Opensea,
    Withdrawable
{
    uint256 public constant TOTAL_MAX_QTY = 6969;
    uint256 public constant GIFT_MAX_QTY = 212;
    uint256 public constant DASALES_MAX_QTY = 1300;
    uint256 public constant DA_AND_PUBLIC_MAX_QTY_PER_MINTER = 1;
    uint256 public constant DA_SALES_START_PRICE = 0.69 ether;
    uint256 public DA_LAST_PRICE = DA_SALES_START_PRICE;
    uint256 public constant priceDropDuration = 1800;
    uint256 public constant priceDropAmount = 0.05 ether;
    uint256 public constant priceDropFloor = 0.169 ether;
    uint256 public fPublicSalesPrice = DA_SALES_START_PRICE;

    mapping(address => uint256) public DASalesMinterToTokenQty;
    mapping(address => uint256) public privateSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;
    mapping(address => uint256) public DAAddressIdToPrice;
    mapping(uint256 => uint256) public idToCanType;

    uint256 public DASalesMintedQty = 0;
    uint256 public privateSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;

    constructor()
        ERC721("Mindblowon", "MINDBLOWON")
        Whitelist("Mindblowon", "1")
    {}

    function refundAll() external {
        require(
            !isDASalesActivated() || DASalesMintedQty >= DASALES_MAX_QTY,
            "DA still ongoing"
        );
        require(block.timestamp <= publicSalesStartTime, "Refund time passed");
        uint256 refundValue = DAAddressIdToPrice[msg.sender] - DA_LAST_PRICE;
        DAAddressIdToPrice[msg.sender] = DA_LAST_PRICE;
        payable(msg.sender).transfer(refundValue);
    }

    function getPrice() public view returns (uint256) {
        if (isDASalesActivated()) {
            uint256 dropCount = (block.timestamp - DASalesStartTime) /
                priceDropDuration;
            return
                dropCount < 11
                    ? DA_SALES_START_PRICE - dropCount * priceDropAmount
                    : priceDropFloor;
        } else if (isPrivateSalesActivated()) {
            return (DA_LAST_PRICE * 50) / 100;
        }
        return DA_LAST_PRICE;
    }

    function mint(uint256 canType, address sender) internal {
        uint256 newTokenId = totalSupply() + 1;
        idToCanType[newTokenId] = canType;
        _safeMint(sender, newTokenId);
    }

    function DASalesMint(
        uint256 canType,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isDASalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        uint256 price = getPrice();

        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(DASalesMintedQty + 1 <= DASALES_MAX_QTY, "DA quota limit");
        require(
            DASalesMinterToTokenQty[msg.sender] + 1 <=
                DA_AND_PUBLIC_MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= price, "Insufficient ETH");

        DASalesMinterToTokenQty[msg.sender] += 1;
        DASalesMintedQty += 1;
        DAAddressIdToPrice[msg.sender] = msg.value;
        mint(canType, msg.sender);

        DA_LAST_PRICE = price;
    }

    function privateSalesMint(
        uint256 canType,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPrivateSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        uint256 price = getPrice();
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            privateSalesMinterToTokenQty[msg.sender] + 1 <= _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value >= price, "Insufficient ETH");

        privateSalesMinterToTokenQty[msg.sender] += 1;
        privateSalesMintedQty += 1;

        mint(canType, msg.sender);
    }

    function publicSalesMint(
        uint256 canType,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPublicSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(msg.value >= fPublicSalesPrice, "Insufficient ETH");

        require(
            publicSalesMinterToTokenQty[msg.sender] + 1 <=
                DA_AND_PUBLIC_MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        publicSalesMinterToTokenQty[msg.sender] += 1;
        publicSalesMintedQty += 1;

        mint(canType, msg.sender);
    }

    function gift(address[] calldata receivers, uint256 canType)
        external
        onlyOwner
    {
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                receivers.length <=
                TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );
        giftedQty = giftedQty + receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            mint(canType, receivers[i]);
        }
    }

    function changeFPublicSalesprice(uint256 price) external onlyOwner {
        fPublicSalesPrice = price;
    }
}
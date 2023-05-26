// SPDX-License-Identifier: MIT
// import ERC-721
// import SafeMath

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Bitaverse is ERC721{

    address public devAddress;
    address public RecipientAddress = 0x9bcFa64Ce1c253716E1f6bBEC40a287980cdFA03;
    //constant
    using Strings for uint256;

    uint256 private constant TotalSupply = 10000;
    uint256 private TotalMint = 60;
    uint256 public SalePrice = 0.088 ether;

    uint256 public SpecialNFT = 0;

    string public baseTokenURI;
    string public RareTokenURI;

    bool public saleStart = false;

    mapping(address => uint256) public WhiteListMint;
    mapping(address => uint256) public NFTSale;
    mapping(address => bool) public PartnerList;

    struct FreeNFT{
        uint256 Nomal;
        uint256 Special;
    }

    mapping(address => FreeNFT)public PartnerOwned;

    constructor() ERC721("Bitaverse","Bitaverse"){
        devAddress = msg.sender;

        PartnerOwned[0x9bcFa64Ce1c253716E1f6bBEC40a287980cdFA03].Nomal = 401;
        PartnerOwned[0x9bcFa64Ce1c253716E1f6bBEC40a287980cdFA03].Special = 50;

        PartnerOwned[0x3B0F35FA4c7f38Fc577eB9aF105aa3787AC3f8C6].Nomal = 50;
        PartnerOwned[0x3B0F35FA4c7f38Fc577eB9aF105aa3787AC3f8C6].Special = 2;

        PartnerOwned[0x619218c1d29510f957B0b1dab40F764D930A7D55].Nomal = 160;

        PartnerOwned[0xe8dfbcbEcBD6B3c7167DA7e36445B7800F138B7C].Nomal = 48;

        PartnerOwned[0x48DAF617B4b65c645a2ffB69FF1D6919d8713e70].Nomal = 42;

        PartnerOwned[0x473A477d057bCF5a5a073071924Dc4A3924E4566].Nomal = 50;
        PartnerOwned[0x473A477d057bCF5a5a073071924Dc4A3924E4566].Special = 2;

        PartnerOwned[0x0B92C3c342531De27486187f9cc74aCEF376B027].Nomal = 50;
        PartnerOwned[0x0B92C3c342531De27486187f9cc74aCEF376B027].Special = 2;

        PartnerOwned[0x546213e2597de9a5aB4f7D73fbf67a2eeEA81Aff].Nomal = 50;
        PartnerOwned[0x546213e2597de9a5aB4f7D73fbf67a2eeEA81Aff].Special = 2;

        PartnerOwned[0xABCC4d53252CCF01e0635C0FD9f3c4CECA02271B].Nomal = 50;
        PartnerOwned[0xABCC4d53252CCF01e0635C0FD9f3c4CECA02271B].Special = 2;



    }

    function setBaseURI(string memory baseURI) external{
        require(msg.sender == devAddress,"You are not the dev");
        baseTokenURI = baseURI;
    }
    function setRareBaseURI(string memory baseURI)external{
        require(msg.sender == devAddress,"You are not the dev");
        RareTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        if(_tokenId>60){
            return string(abi.encodePacked(baseTokenURI,_tokenId.toString()));
        }
        else{
            return string(abi.encodePacked(RareTokenURI,_tokenId.toString()));
        }
    }

    function totalSupply() public pure returns(uint256){
        return TotalSupply;
    }

    function total_Mint() public view returns(uint256){
        return TotalMint;
    }
    function SpecialNFTRemain()public view returns(uint256){
        return 60 - SpecialNFT;
    }

    function addParnerOwn(address user,uint256 rare,uint256 value)external{
        require(msg.sender == devAddress,"You are not the dev");
        PartnerOwned[user].Nomal = value;
        PartnerOwned[user].Special = rare;

    }


    function SaleStart(bool button) external{
        require(msg.sender == devAddress,"You are not the dev");

        saleStart = button;
    }

    function setSalePrice(uint256 price) external{
        require(msg.sender == devAddress,"You are not the dev");

        SalePrice = price;
    }


    function setPartner(address[] memory input) external{
        require(msg.sender == devAddress,"You are not the dev");

       for(uint256 a=0;a<input.length;a++){
            PartnerList[input[a]] = true;
        }
    }

    function setWhiteList(address[] memory input) external{
        require(msg.sender == devAddress,"You are not the dev");

        for(uint256 a=0;a<input.length;a++){
            WhiteListMint[input[a]]++;
        }
        //["address","address"]
    }

    //NFTSale



    function mint(uint256 amount) external payable{
        require(msg.value == SalePrice * amount,"Wrong input price");
        require(total_Mint() + amount <= TotalSupply,"Sale is ended");
        require(saleStart == true,"Sale is not start yet");
        require(NFTSale[msg.sender] + amount <= 100,"Mint exceed!");

        NFTSale[msg.sender] += amount;
        for(uint256 num = 0;num<amount;num++){
            TotalMint++;
            _mint(msg.sender,TotalMint);
        }

        payable(RecipientAddress).transfer(address(this).balance);

    }


    function WhiteListMints() external{
        require(WhiteListMint[msg.sender] > 0,"You already got a Bitaverse!");
        require(total_Mint() < TotalSupply,"Sale is ended");

        WhiteListMint[msg.sender]--;
        TotalMint++;
        _mint(msg.sender,TotalMint);

    }

    function SponsorAmount(address receiver) external{
        require(PartnerList[msg.sender] == true,"You are not the partner");
        require(PartnerOwned[msg.sender].Nomal >0,"You've done your part");
        require(total_Mint() < TotalSupply,"Sale is ended");

        PartnerOwned[msg.sender].Nomal--;

        TotalMint++;
        _mint(receiver,TotalMint);

    }

    function RareNftMint(address receiver) external{
        require(PartnerList[msg.sender] == true,"You are not the partner");
        require(PartnerOwned[msg.sender].Special >0,"You've done your part");
        require(SpecialNFT < 60,"Sale out all special NFT");

        PartnerOwned[msg.sender].Special--;
        SpecialNFT++;
        _mint(receiver,SpecialNFT);
    }


    function OwnerSend(address[] memory input)external{
        require(msg.sender == devAddress,"You are not the dev");
        require(total_Mint() + input.length < TotalSupply,"mint finish");
        for(uint256 a=0;a<input.length;a++){
            TotalMint++;
            _mint(input[a],TotalMint);
        }
    }








}
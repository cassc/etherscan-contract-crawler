// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract AC55idOnDemand is Initializable,  ERC1155Upgradeable, OwnableUpgradeable    {
    
    using StringsUpgradeable for string;
    using SafeMathUpgradeable for uint256;

    string public name;
    string public symbol;

    uint256 public nftId;

    address private admin;

    mapping (uint256 => NFTInfo) public nfts;
    mapping (uint256 =>  string) private _tokenURI;
    mapping (uint256 => mapping(address => uint256)) public buyers;
    mapping (uint256 => mapping(address => uint256)) public payers;

    constructor()
    {
    }

    struct NFTInfo {
        uint256 _id;
        uint256 _price;
        uint256 _priceUSD;
        uint256 _num_records;
        uint256 _purchaseValue;
    }
       
    function initialize() initializer public  {
        __ERC1155_init("https://api.ac55id.com/ondemand/");
        __Ownable_init_unchained();
        admin = 0x821fC28a7f932fCeDACd44627810379bA49D1356;

        name= "AC55IDOnDemand";
        symbol = "AC55ID";
    }
    
    function mint(uint256 amount, uint256 price, uint256 priceusd, string memory trackLink)
        external
        onlyOwner
    {
        require(amount>0, "Minimumn quantity allowed is 1");
        require(amount<5001, "Maximum quantity allowed is 5000");
        nftId=nftId.add(1);
        nfts[nftId]._id = nftId;
        nfts[nftId]._price = price;
        nfts[nftId]._priceUSD = priceusd;
        nfts[nftId]._num_records = nfts[nftId]._num_records.add(amount);
        nfts[nftId]._purchaseValue = 0;
        _tokenURI[nftId] = trackLink;
        _mint(msg.sender, nftId, amount, "");
    }
    
    function setPurchased(address buyer_addr, uint256 id) external onlyOwner {
        require(payers[id][buyer_addr]>0,"User didnt bought this track");
        nfts[id]._purchaseValue=nfts[id]._purchaseValue.add(1);
        buyers[id][buyer_addr] = nfts[id]._purchaseValue;
    }

    function payment(uint256 id) external payable{        
        uint256 amt = msg.value;
        address payable payaddress = payable(0x821fC28a7f932fCeDACd44627810379bA49D1356);
        payers[id][msg.sender]=amt;
        payaddress.transfer(amt);
    }

    function getTrackLink(uint256 _NftId, address buyer_addr) external view returns(string memory) {
        require(buyers[_NftId][buyer_addr]>0, "User didnt bought this track");
        return _tokenURI[_NftId];
    }


    function uri(uint256 _id) public view virtual override(ERC1155Upgradeable) returns  (string memory) {
        return bytes("https://api.ac55id.com/ondemand/").length > 0 ? string(abi.encodePacked("https://api.ac55id.com/ondemand/", StringsUpgradeable.toString(_id), ".json")) : "https://api.ac55id.com/ondemand/";
    }
    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    function transferNFT(uint256 id, address _To) external onlyOwner {
        _safeTransferFrom(admin, _To, id, 1, "");
    }
}
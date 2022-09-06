// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Strings.sol";

contract MetaRich is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 constant whiteListPrice = 75 ether / 1000;

    uint256 constant MAX_NFT = 3000;

    bool whitelistSale = false;

    uint256 wlCount;

    mapping(address => bool) whiteList;

    uint256[] _random;

    uint256 maxSupply;

    string private _baseTokenURI;


    receive() external payable {}
    fallback() external payable {}

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol){}

    //widthraw functions from contract
    function withdraw() public onlyOwner {
        address _this = address(this);
        payable(owner()).transfer(_this.balance);
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }


    //add address to whitelist
    function addAddressToWhiteList(address[] memory _members) public onlyOwner{
            for (uint256 i = 0; i < _members.length; i++) {
                whiteList[_members[i]] = true;
            }
    }

    function changeStatusOfWhiteListSale(bool status) public onlyOwner{
        whitelistSale = status;
    }

    //Check contains of wallet in WhiteListTier12
    function walletIsInWhiteList(address wallet) internal view returns(bool){
        return whiteList[wallet];
    }
    
    function mintForWhiteList(uint256 _quantity) public payable {
        if(whitelistSale){
            require(msg.value == whiteListPrice * _quantity, "Wrong amount");
            require(walletIsInWhiteList(msg.sender), "User isn't in a whitelist");
            require(wlCount <= 1000);
            wlCount += _quantity;
        }
        else {
            revert("WhiteList sale is not available");
        }

       _safeMint(msg.sender, _quantity);

        maxSupply += _quantity;

    }

    function mintRestCollection(uint256 _quantity) public onlyOwner{
        require(maxSupply<=3000);
        _safeMint(msg.sender, _quantity);
        maxSupply += _quantity;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }


}
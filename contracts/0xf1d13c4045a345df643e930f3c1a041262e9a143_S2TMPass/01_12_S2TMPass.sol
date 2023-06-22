// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract S2TMPass is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public mintPrice = 0.05 ether;
    uint256 public mintLimit = 10;

    uint256 public supplyLimit;
    bool public saleActive = false;

    string public baseURI = "";

    uint256 public totalSupply = 0;

    uint256 devShare = 20;
    uint256 teamShare = 12;
    uint256 marketingShare = 8;

    address payable SCHILLER_ADDRESS = payable(0x376FFEff9820826a564A1BA05A464b9923862418);
    address payable SNAZZY_ADDRESS = payable(0x57a1fCc7c7F7d253414a85EF4658B5C68Dc3D63B);
    address payable SEAN_ADDRESS = payable(0xcdb1e7Acd76166CCcBb61c1d4cb86cc0C033EcFa);
    address payable RISK_ADDRESS = payable(0x17485802CcE36b50CDc8EA94422C7000879e444f);
    address payable JOSH_ADDRESS = payable(0x340e02c1306ebED52cDF90163C12Ab342e171916);
    address payable JARED_ADDRESS = payable(0x22DD354645Da9BB7e02434F54D62bB388e0c5120);

    address payable devAddress = payable(0x4d3FD3865A46cE2cEd63fA56562Ab932149E7d3C);
    address payable marketingAddress = payable(0xeE1AB23f8426Cd12AB67513202A08135Cf6B0d6A);


    /********* Events - Start *********/
    event SaleStateChanged(bool _state);
    event SupplyLimitChanged(uint256 _supplyLimit);
    event MintLimitChanged(uint256 _mintLimit);
    event MintPriceChanged(uint256 _mintPrice);
    event BaseURIChanged(string _baseURI);
    event PassMinted(address indexed _user, uint256 indexed _tokenId, string _tokenURI);
    event ReservePass(uint256 _numberOfTokens);
    /********* Events - Ends *********/

    constructor(
        uint256 tokenSupplyLimit,
        string memory _baseURI
    ) ERC721("S2TM Space Pass - Season 1", "S2TM-S1") {
        supplyLimit = tokenSupplyLimit;
        baseURI = _baseURI;
        
        emit SupplyLimitChanged(supplyLimit);
        emit MintLimitChanged(mintLimit);
        emit MintPriceChanged(mintPrice);
        emit BaseURIChanged(_baseURI);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIChanged(_baseURI);
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStateChanged(saleActive);
    }

    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        require(_supplyLimit >= totalSupply, "Value should be greater than currently minted.");
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }

    function changeMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
        emit MintLimitChanged(_mintLimit);
    }

    function changeMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function buyPass(uint _numberOfTokens) external payable {
        require(saleActive, "Sale is not active.");
        require(_numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_numberOfTokens), "Insufficient payment.");

        _mintPass(_numberOfTokens);
    }

    function _mintPass(uint _numberOfTokens) internal {
        require(totalSupply.add(_numberOfTokens) <= supplyLimit, "Not enough tokens left.");

        uint256 newId = totalSupply;
        for(uint i = 0; i < _numberOfTokens; i++) {
            newId += 1;
            totalSupply = totalSupply.add(1);

            _safeMint(msg.sender, newId);
            emit PassMinted(msg.sender, newId, tokenURI(newId));
        }
    }

    function reservePass(uint256 _numberOfTokens) external onlyOwner {
        _mintPass(_numberOfTokens);
        emit ReservePass(_numberOfTokens);
    }

    /*
        This function will send all contract balance to its contract owner.
    */
    function emergencyWithdraw() external onlyOwner {
        require(address(this).balance > 0, "No funds in smart Contract.");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw Failed.");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No funds in smart Contract.");
        bool success;

        uint256 totalDevShare = address(this).balance.mul(devShare).div(100);
        uint256 totalTeamShare = address(this).balance.mul(teamShare).div(100);
        uint256 totalMarketingShare = address(this).balance.mul(marketingShare).div(100);
        (success, ) = devAddress.call{value: totalDevShare}("");

        (success, ) = SCHILLER_ADDRESS.call{value: totalTeamShare}("");
        (success, ) = SNAZZY_ADDRESS.call{value: totalTeamShare}("");
        (success, ) = SEAN_ADDRESS.call{value: totalTeamShare}("");
        (success, ) = RISK_ADDRESS.call{value: totalTeamShare}("");
        (success, ) = JARED_ADDRESS.call{value: totalTeamShare}("");
        (success, ) = JOSH_ADDRESS.call{value: totalTeamShare}("");

        (success, ) = marketingAddress.call{value: totalMarketingShare}("");
    }
}
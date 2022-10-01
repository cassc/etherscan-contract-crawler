// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/Strings.sol";

contract GatekeepAccess is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    
    uint256 public mintPrice = 0.11 ether;
    uint256 public passSupply = 5000;
    uint256 public supplyCount = 0;
    
    string public baseURI = "";
    
    bool public saleActive = true;

    address public deployer = 0xbfa293b865D54F8123A49Ba256b9461D38a05198;
    
    constructor() ERC721("Gatekeep Access", "GATEKEEP") {}
    
    function tokenURI(uint256 PassID) public view override returns (string memory) {
        require(_exists(PassID), "Token does not exist");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, PassID.toString())) : "";
    }
    
    function updateSupply(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= supplyCount, "Error updating supply");
        passSupply = _newAmount;
    }
    
    function updateUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function saleSwitch() external onlyOwner {
        saleActive = !saleActive;
    }
    
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "None");
        (bool succcess,) = deployer.call{value: address(this).balance}("");
        require(succcess, "Error withdrawing.");
    }

    function adminMint(uint AccessPassCount) external onlyOwner  {
        require(supplyCount.add(AccessPassCount) <= passSupply, "Not enough supply for this mint amount");

        uint256 PassID = supplyCount;
        for(uint i = 0; i < AccessPassCount; i++) {
            PassID += 1;
            supplyCount = supplyCount.add(1);
            _safeMint(msg.sender, PassID);
        }
    } 

    function mint(uint AccessPassCount) external payable {
        require(saleActive, "sale not live");
        require(supplyCount.add(AccessPassCount) <= passSupply, "Not enough supply for this mint amount");
        require(msg.value >= mintPrice.mul(AccessPassCount), "Not enough ether sent");

        uint256 PassID = supplyCount;
        for(uint i = 0; i < AccessPassCount; i++) {
            PassID += 1;
            supplyCount = supplyCount.add(1);
            _safeMint(msg.sender, PassID);
        }
        return;
    }  
}
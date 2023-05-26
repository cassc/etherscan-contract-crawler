// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./Ownable.sol";

/**

 .-._         ,---.      .-._          _,.---._        _ __    ,---.        ,-,--.    ,-,--.  
/==/ \  .-._.--.'  \    /==/ \  .-._ ,-.' , -  `.   .-`.' ,`..--.'  \     ,-.'-  _\ ,-.'-  _\ 
|==|, \/ /, |==\-/\ \   |==|, \/ /, /==/_,  ,  - \ /==/, -   \==\-/\ \   /==/_ ,_.'/==/_ ,_.' 
|==|-  \|  |/==/-|_\ |  |==|-  \|  |==|   .=.     |==| _ .=. /==/-|_\ |  \==\  \   \==\  \    
|==| ,  | -|\==\,   - \ |==| ,  | -|==|_ : ;=:  - |==| , '=',\==\,   - \  \==\ -\   \==\ -\   
|==| -   _ |/==/ -   ,| |==| -   _ |==| , '='     |==|-  '..'/==/ -   ,|  _\==\ ,\  _\==\ ,\  
|==|  /\ , /==/-  /\ - \|==|  /\ , |\==\ -    ,_ /|==|,  |  /==/-  /\ - \/==/\/ _ |/==/\/ _ | 
/==/, | |- \==\ _.\=\.-'/==/, | |- | '.='. -   .' /==/ - |  \==\ _.\=\.-'\==\ - , /\==\ - , / 
`--`./  `--``--`        `--`./  `--`   `--`--''   `--`---'   `--`         `--`---'  `--`---'  

Credit to woof from Sneaky Vampire Syndicate for the contract help 

 */

contract Nanopass is ERC721, Ownable, RoyaltiesV2Impl {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address public constant DEV_ADDRESS_1 = 0xc73ab340a7d523EC7b1b71fE3d3494F94283b4B1; // J
    address public constant DEV_ADDRESS_2 = 0x09b2741feD63B7Fcc5E577cDc9d0cf0D85127A32; // P
    address public constant DEV_ADDRESS_3 = 0xC929b6bD739a8564BcB35e978Afe4ffF5b6c3cEF; // R
    address public constant DEV_ADDRESS_4 = 0x5bF9BE0B32ba09B449eD5d1EaBB864Cf2317629F; // D
    address public constant DEV_ADDRESS_5 = 0x3e8f4639E926f36f7309836F6D018a9ea59B345e; // H
    address public constant DEV_ADDRESS_6 = 0x5bB1396E3EC5E31E12DC7846c4c94eea25083f35; // L
    address public constant DEV_FUND_ADDRESS = 0x7955cF321a420f7c245cEfB748E0F303756Ae2A6;

    mapping (address => uint256) public presaleWhitelist;
    bool public presaleActive = false;
    bool public saleActive = false;
    uint256 public currentSupply;
    uint256 public maxSupply;
    uint256 public price = 0.08888 ether;
    
    uint256 public dutchPriceAdditional; // record the additional price of dutch and deduct
    uint256 public dutchStartTime; // record the start time
    uint256 public dutchDuration; // record the duration
    uint256 public dutchEndTime; // record the end time
    bool public dutchAuctionStarted; // boolean for dutch auction

    string private baseURI = "https://metadata.nanopass.io/metadata/";

    constructor(string memory name, string memory symbol, uint256 supply) ERC721(name, symbol) {
        maxSupply = supply;
    }
    
    function totalSupply() external view returns (uint) {
        return currentSupply;
    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply;
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive, "No presale active");
        require(reserved > 0, "This address is not authorized for presale");
        require(numberOfMints <= reserved, "Exceeded allowed amount");
        require(supply + numberOfMints <= maxSupply, "This would exceed the max number of allowed nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        presaleWhitelist[msg.sender] = reserved - numberOfMints;
        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _mint(msg.sender, supply + i);
        }
    }

    function mint(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply;
        require(saleActive, "Sale must be active to mint");
        require(numberOfMints <= 1, "Invalid purchase amount");
        require(supply + numberOfMints <= maxSupply, "Mint would exceed max supply of nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++) {
            _mint(msg.sender, supply + i);
        }
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(supply+ addresses.length <= maxSupply,  "This would exceed the max number of allowed nft");
        currentSupply += addresses.length;
        for (uint256 i; i < addresses.length ; i++) {
            _mint(addresses[i], supply + i);
        }
    }
    

    function editPresale(address[] calldata presaleAddresses, uint256[] calldata amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }
    }
    
    function editPresaleSingle(address[] calldata presaleAddresses, uint256 amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount;
        }
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function toggleDutchAuction() public onlyOwner {
        dutchAuctionStarted = !dutchAuctionStarted;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(DEV_FUND_ADDRESS).transfer(balance * 5000 / 10000);
        payable(DEV_ADDRESS_1).transfer(balance * 1666 / 10000);
        payable(DEV_ADDRESS_2).transfer(balance * 1229 / 10000);
        payable(DEV_ADDRESS_3).transfer(balance * 805 / 10000);
        payable(DEV_ADDRESS_4).transfer(balance * 900 / 10000);
        payable(DEV_ADDRESS_5).transfer(balance * 200 / 10000);
        payable(DEV_ADDRESS_6).transfer(address(this).balance);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;
        for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
            if (index == tokenCount) break;

            if (ownerOf(tokenId) == _owner) {
                result[index] = tokenId;
                index++;
            }
        }

        return result;
      }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory ) {
      return this.tokensOfOwner(_owner, 0, currentSupply);
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      LibPart.Part[] memory _royalties = royalties[0];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
      }
      return (address(0), 0);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
      LibPart.Part[] memory _royalties = new LibPart.Part[](1);
      _royalties[0].value = _percentageBasisPoints;
      _royalties[0].account = _royaltiesReceipientAddress;
      _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
      if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
        return true;
      }
  
      if(interfaceId == _INTERFACE_ID_ERC2981) {
        return true;
      }
  
      return super.supportsInterface(interfaceId);
    }

    // Dutch Auction
    function setDutchAuction(uint256 dutchPriceAdditional_, uint256 dutchStartTime_, uint256 dutchDuration_) public onlyOwner {
      dutchPriceAdditional = dutchPriceAdditional_;
      dutchStartTime = dutchStartTime_;
      dutchDuration = dutchDuration_;
      dutchEndTime = dutchStartTime + dutchDuration;
    }

    function getTimeElapsed() public view returns (uint256) {
      return dutchStartTime > 0 ? (dutchStartTime + dutchDuration) >= block.timestamp ? (block.timestamp - dutchStartTime) : dutchDuration : 0;
    }

    function getTimeRemaining() public view returns (uint256) {
      return dutchDuration - getTimeElapsed();
    }

    function getCurrentDutchPrice() public view returns (uint256) {
      return price + ((dutchDuration - getTimeElapsed()) * dutchPriceAdditional / dutchDuration);
    }

    function mintDutchAuction(uint256 numberOfMints) public payable {
      require(dutchAuctionStarted && block.timestamp >= dutchStartTime, "Dutch auction has not started yet!");
      uint256 supply = currentSupply;
      require(numberOfMints <= 2, "Invalid purchase amount");
      require(supply + numberOfMints <= maxSupply, "Mint would exceed max supply of nft");
      require(msg.value >= getCurrentDutchPrice() * numberOfMints, "Amount of ether is not enough");

      currentSupply += numberOfMints;
      for(uint256 i; i < numberOfMints; i++) {
        _mint(msg.sender, supply + i);
      }
    }
}
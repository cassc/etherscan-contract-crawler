// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// artist: https://twitter.com/cocopon

contract SushipicoSet is ERC721, Ownable {
    uint256 public constant SUSHIPICO_PRICE = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public reserveCount = 21;
    uint256 public mintCount;
    bool public saleIsActive;
    string internal _baseTokenURI;
    bool public isFreeze;
    mapping(address => bool) public giveAwayList;

    constructor() ERC721("Sushipico Set", "SPS") {}

    modifier whenNotFreeze() {
        require(isFreeze == false, "Already freeze");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI)
        external
        onlyOwner
        whenNotFreeze
    {
        _baseTokenURI = baseURI;
    }

    function setSaleState(bool _saleState) external onlyOwner {
        saleIsActive = _saleState;
    }

    function freezeMetadata() external onlyOwner {
        isFreeze = true;
    }

    function isSold(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    function getPurchasableIds() external view returns (uint256[] memory) {
        uint256[] memory purchasableIds = new uint256[](MAX_SUPPLY - mintCount);
        uint256 index;
        for (uint256 id; id < MAX_SUPPLY; id++) {
            if (!_exists(id)) {
                purchasableIds[index++] = id;
            }
        }
        return purchasableIds;
    }

    function addGiveAwayList(address[] memory _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            giveAwayList[_addresses[i]] = true;
        }
    }

    function removeGiveAway(address _address) external onlyOwner {
        giveAwayList[_address] = false;
    }

    function reserve(uint256 _id) external onlyOwner {
        require(_id < MAX_SUPPLY, "Invalid ID");
        mintCount++;
        reserveCount--;
        _safeMint(msg.sender, _id);
    }

    function purchaseSet(uint256 _id) external payable {
        require(!_exists(_id), "Already sold");
        require(saleIsActive, "Sale must be active");
        require(_id < MAX_SUPPLY, "Invalid ID");
        require(mintCount + reserveCount < MAX_SUPPLY, "Not enough stock");
        require(msg.value == SUSHIPICO_PRICE, "Invalid purchase amount sent");
        mintCount++;
        _safeMint(msg.sender, _id);
    }

    function freePurchaseSet(uint256 _id) external {
        require(giveAwayList[msg.sender] == true, "Invalid giveaway address");
        require(!_exists(_id), "Already sold");
        require(saleIsActive, "Sale must be active");
        require(_id < MAX_SUPPLY, "Invalid ID");
        giveAwayList[msg.sender] = false;
        mintCount++;
        reserveCount--;
        _safeMint(msg.sender, _id);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract Graveyard is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {

    uint256 public baseCost;
    uint256 public whitelistCost;

    uint256 public maxSupply;
    uint256 public maxValue;
    uint256 public maxCountMinting;
    uint256 public mintedNftCount;

    string public baseURI;
    bool public revealed;

    bool public whitelistStatus;

    mapping(uint256 => uint256) private _totalSupply;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public giveaway;
    mapping(address => uint256) public owners;
    mapping(address => uint256) public mintedCount;

    function initialize() initializer public {
        baseCost = 100000000000000000;
        whitelistCost = 50000000000000000;
        whitelistStatus = true;
        maxSupply = 1;
        maxValue = 1000;
        maxCountMinting = 5;
        mintedNftCount = 0;
        revealed = false;
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function mint(address _to, uint256 _mintAmount) external payable {
        if(whitelistStatus && owners[_to] <= 0 && giveaway[_to] <= 0){
            require(whitelisted[_to], "user not in whitelist");
        }

        uint256 price = getPriceForAmount(_to, _mintAmount);

        require(_mintAmount > 0, "mint amount error");
        require(mintedNftCount + _mintAmount <= maxValue, "maxValue limit error");

        if (msg.sender != owner()) {
            require(!paused(), "mint paused");
            require(_mintAmount <= getMaxMintAmount(_to), "mint amount under max");
            require(msg.value >= price, "cost below");
        }

        uint256 i = 0;
        for (; i < _mintAmount; i++) {
            uint256 supply = totalSupply(mintedNftCount + 1);
            if(supply <= maxSupply){
                _mint(_to, mintedNftCount + 1, 1, "");
                mintedCount[_to] = mintedCount[_to] + 1;
            } else {
                i--;
            }
            mintedNftCount++;
        }
    }

    function getMaxMintAmount(address _user) public view virtual returns (uint256) {
        uint256 count = 0;

        if(owners[_user] > 0){
            count = owners[_user] - mintedCount[_user];
        } else {
            count = maxCountMinting - mintedCount[_user];
        }

        if(mintedNftCount + count > maxValue){
            count = maxValue - mintedNftCount;
        }

        return count;
    }

    function getPriceForAmount(address _user, uint256 _amount) public view virtual returns (uint256) {
        if(giveaway[_user] > mintedCount[_user]){
            uint256 countMintPayable = _amount;

            if(giveaway[_user] - mintedCount[_user] >= _amount){
                return 0;
            }

            if(giveaway[_user] > mintedCount[_user]){
                countMintPayable = countMintPayable - (giveaway[_user] - mintedCount[_user]);
            }
            

            if(whitelistStatus){
                require(whitelisted[_user], "user not in whitelist");

                return whitelistCost * countMintPayable;
            } else {
                return baseCost * countMintPayable;
            }
        }

        if(owners[_user] > 0){
            return 0;
        }

        if(whitelistStatus){
            require(whitelisted[_user], "user not in whitelist");

            return whitelistCost * _amount;
        } else {
            return baseCost * _amount;
        }
    }

    function setBaseCost(uint256 _newVeryBaseCost) external onlyOwner {
        baseCost = _newVeryBaseCost;
    }

    function setWhitelistCost(uint256 _newVeryWhitelistCost) external onlyOwner {
        whitelistCost = _newVeryWhitelistCost;
    }

    function setMaxValue(uint256 _newMaxValue) external onlyOwner {
        maxValue = _newMaxValue;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxCountMinting(uint256 _newMaxValue) external onlyOwner {
        maxCountMinting = _newMaxValue;
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function uri(uint256 tokenId) public view override virtual returns (string memory){
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhitelistedUsers(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    function removeWhitelistedUsers(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = false;
        }
    }

    function addGiveawayUsers(address[] calldata addresses, uint256[] calldata counts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            giveaway[addresses[i]] = counts[i];
        }
    }

    function addOwnersUsers(address[] calldata addresses, uint256[] calldata counts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = counts[i];
        }
    }

    function setWhitelistStatus(bool status) external onlyOwner {
        whitelistStatus = status;
    }

    function setReveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
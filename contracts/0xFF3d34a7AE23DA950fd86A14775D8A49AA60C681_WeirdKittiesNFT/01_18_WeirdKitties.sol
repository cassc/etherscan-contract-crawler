// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../lib/utils/strings.sol";

contract WeirdKittiesNFT is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    string private baseURI;
    uint256 private tokenPrice;
    mapping(uint256 => uint256) private totalSupply;
    uint256 private availableTokensNum;
    using strings for *;
    string public name;
    string public symbol;

    function initialize() public initializer {
        __ERC1155_init(
            "ipfs://QmTyDtzE5svuH4942CM8kCjnmNzA3cLB14CeMvzfvKHYnE/{id}.json"
        );
        __Ownable_init();
        __UUPSUpgradeable_init();
        name = "Weird Kitties";
        symbol = "WK";
        tokenPrice = 30 ether;
        availableTokensNum = 20;
        totalSupply[3] = 50;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getUri(string memory id) public view returns (string memory) {
        strings.slice memory delimiter = "{id}".toSlice();
        strings.slice memory original_string = uri(0).toSlice();
        strings.slice memory part1 = original_string.split(delimiter);
        strings.slice memory part2 = original_string.split(delimiter);
        return part1.concat(id.toSlice()).toSlice().concat(part2);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function setTotalSupply(uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] > availableTokensNum) {
                availableTokensNum = ids[i];
            }
            totalSupply[ids[i]] += amounts[i];
        }
    }

    function getSupply(uint256 id) public view returns (uint256) {
        return totalSupply[id];
    }

    function getTotalSupply() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](availableTokensNum + 1);
        for (uint256 i = 1; i <= availableTokensNum; i++) {
            result[i] = totalSupply[i];
        }
        return result;
    }

    function mintPayable(uint256[] memory ids, uint256[] memory amounts)
        public
        payable
    {
        bool enough_amount = true;
        for (uint256 i = 0; i < ids.length; i++) {
            if (totalSupply[ids[i]] < amounts[i]) {
                enough_amount = false;
                break;
            }
        }
        require(
            enough_amount,
            "The indicated token IDs have not enough amount."
        );

        uint256 total_value = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total_value += amounts[i] * tokenPrice;
        }

        require(msg.value >= total_value, "The price does not match!");

        _mintBatch(msg.sender, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            totalSupply[ids[i]] -= amounts[i];
        }
    }

    function mintOwner(
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        bool enough_amount = true;
        for (uint256 i = 0; i < ids.length; i++) {
            if (totalSupply[ids[i]] < amounts[i]) {
                enough_amount = false;
                break;
            }
        }
        require(
            enough_amount,
            "The indicated token IDs have not enough amount."
        );

        _mintBatch(receiver, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            totalSupply[ids[i]] -= amounts[i];
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory wallet = new uint256[](availableTokensNum + 1);
        for (uint256 i = 1; i <= availableTokensNum; i++) {
            wallet[i] = balanceOf(_owner, i);
        }
        return wallet;
    }
}
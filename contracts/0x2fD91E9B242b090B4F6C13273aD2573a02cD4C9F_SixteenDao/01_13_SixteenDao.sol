// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SixteenDao is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    address[] private alreadyPurchasedList;
    Counters.Counter private _tokenIdCounter;
    uint256 private _totalSupply;
    uint256 private allowTotalSupply = 2000;

    string private _base_pass_img_url =
        "https://ipfs.io/ipfs/QmUXet5vtM5FVq5tNJjBshqhvh8H4tcfkDcKKNVLQpGNEw";

    constructor() ERC721("DZ Novel DeFi Labs", "ONE PASS CARD") {}

    function getCurrentIndex() public view returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        return tokenId;
    }


    function publicMint(address to) public payable {

        for (uint256 i = 0; i < alreadyPurchasedList.length; i++) {
            address addr = alreadyPurchasedList[i];
            if (addr == to) {
                revert(" can buy  only once ");
            }
        }
        uint256 tokenId = _tokenIdCounter.current();
        if (tokenId > 100 && tokenId <= 300) {
            require(
                msg.value == .006 ether,
                "Not enough ETH sent: check price. price must be .006 "
            );
        } else if (tokenId >= 301 && tokenId <= 1200) {
            require(
                msg.value == .01 ether,
                "Not enough ETH sent: check price. price must be .01 "
            );
        } else if (tokenId >= 1201 && tokenId <= 1700) {
            require(
                msg.value == .06 ether,
                "Not enough ETH sent: check price. price must be .06 "
            );
        } else if (tokenId >= 1701 && tokenId <= 2000) {
            require(msg.value == .1 ether, "Not enough ETH sent: check price. price must be .1 ");
        }
        _mint(to);
    }

    function _mint(address to) internal returns (uint256) {
        checkTotalSupply();
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _base_pass_img_url);
        _totalSupply += 1;
        alreadyPurchasedList.push(to);
        return tokenId;
    }

      function totalSupply()  public view  returns (uint256) {
        return _totalSupply;
    }

    function checkTotalSupply() view internal {
            uint256 will_num = totalSupply() + 1;
            require(will_num > 0 && will_num <= allowTotalSupply, "Exceeds token supply");
     }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     *  The admin can withdraw the balance
     */

    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}
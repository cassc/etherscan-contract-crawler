// SPDX-License-Identifier: GPL-1.0-or-later
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";

contract CicleoSubscriptionSecurity is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event MintOwnerPass(address minter, uint256 subscriptionId);

    string _baseTokenURI;
    uint256 public nftSupply;

    CicleoSubscriptionFactory public factory;

    mapping(uint256 => uint256) public ownershipByNftId;
    mapping(uint256 => uint256[]) public ownershipBySubscriptionId;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Cicleo OwnerPass", "COP");
    }

    //Others

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    string(abi.encodePacked(_baseTokenURI, tokenId)),
                    ".json"
                )
            );
    }

    //Blacklist

    mapping(address => bool) public blacklist;

    modifier noBlacklist(address _user) {
        require(blacklist[_user] == false, "NFT: You are blacklisted");
        _;
    }

    function setBlacklist(address user, bool isBlacklist) public onlyOwner {
        blacklist[user] = isBlacklist;
    }

    /* Get functions */

    function verifyIfOwner(
        address _user,
        uint256 _subManagerId
    ) public view returns (bool) {
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (
                ownershipByNftId[tokenOfOwnerByIndex(_user, i)] == _subManagerId
            ) {
                return true;
            }
        }
        return false;
    }

    function getSubManagerList(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory _subManagerList = new uint256[](balanceOf(_user));

        for (uint256 i = 0; i < balanceOf(_user); i++) {
            _subManagerList[i] = ownershipByNftId[
                tokenOfOwnerByIndex(_user, i)
            ];
        }

        return _subManagerList;
    }

    function getOwnersBySubmanagerId(
        uint256 _subManagerId
    ) public view returns (address[] memory) {
        address[] memory _owners = new address[](
            ownershipBySubscriptionId[_subManagerId].length
        );

        for (
            uint256 i = 0;
            i < ownershipBySubscriptionId[_subManagerId].length;
            i++
        ) {
            _owners[i] = ownerOf(ownershipBySubscriptionId[_subManagerId][i]);
        }

        return _owners;
    }

    /* Mint Functions */

    function setFactory(address _factory) external onlyOwner {
        factory = CicleoSubscriptionFactory(_factory);
    }

    function _mintNft(
        address _to,
        uint256 subscriptionManagerId
    ) internal noBlacklist(_to) {
        nftSupply += 1;
        _mint(_to, nftSupply);

        ownershipByNftId[nftSupply] = subscriptionManagerId;
        ownershipBySubscriptionId[subscriptionManagerId].push(nftSupply);

        emit MintOwnerPass(_to, subscriptionManagerId);
    }

    function mintNft(address _to, uint256 subscriptionManagerId) external {
        require(msg.sender == address(factory), "Only factory can mint");
        _mintNft(_to, subscriptionManagerId);
    }

    function deleteSubManager() external {
        uint256 subscriptionId = factory.subscriptionManagerId(msg.sender);

        require(subscriptionId != 0, "Only subManager can burn");

        for (
            uint256 i = 0;
            i < ownershipBySubscriptionId[subscriptionId].length;
            i++
        ) {
            _burn(ownershipBySubscriptionId[subscriptionId][i]);
        }
    }
}
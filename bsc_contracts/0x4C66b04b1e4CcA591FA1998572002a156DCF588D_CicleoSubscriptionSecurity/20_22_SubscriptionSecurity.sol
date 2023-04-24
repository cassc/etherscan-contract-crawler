// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";

/// @title Cicleo Subscription Security
/// @author Pol Epie
/// @notice This contract is used to manage ownership of subscription manager
contract CicleoSubscriptionSecurity is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice Emitted when a new owner pass is minted
    event MintOwnerPass(address minter, uint256 subscriptionId);

    /// @notice URI base of the NFTs
    string _baseTokenURI;

    /// @notice nftSupply is the number of NFTs minted
    uint256 public nftSupply;

    /// @notice factory Contract of the subscription factory
    CicleoSubscriptionFactory public factory;

    /// @notice ownershipByNftId Mapping of the NFT id to the corresponding subscription manager id
    mapping(uint256 => uint256) public ownershipByNftId;

    /// @notice ownershipBySubscriptionId Mapping of the subscription manager id to the corresponding Array of NFT id
    mapping(uint256 => uint256[]) public ownershipBySubscriptionId;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Cicleo OwnerPass", "COP");
    }

    //Others

    /// @notice Return the URI base
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set the URI base
    function setURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    /// @notice Get URI of a NFT id
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

    // Get functions

    /// @notice Verify if the user is admin of the subscription manager
    /// @param _user User to verify
    /// @param _subManagerId Id of the subscription manager
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

    /// @notice Get the list of subscription manager id of a user
    /// @param _user User to verify
    /// @return Array of subscription manager ids
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

    /// @notice Get the first NFT id for a subscription manager id for a user
    /// @param _user User to verify
    /// @param _subManagerId Id of the subscription manager
    function getSubManagerTokenId(
        address _user,
        uint256 _subManagerId
    ) public view returns (uint256) {
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (
                ownershipByNftId[tokenOfOwnerByIndex(_user, i)] == _subManagerId
            ) {
                return tokenOfOwnerByIndex(_user, i);
            }
        }

        return 0;
    }

    /// @notice Get the list of owners for a subscription manager id
    /// @param _subManagerId Id of the subscription manager
    /// @return Array of owners
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

    // Mint Functions

    /// @notice Set the factory contract
    /// @param _factory Address of the factory contract
    function setFactory(address _factory) external onlyOwner {
        factory = CicleoSubscriptionFactory(_factory);
    }

    /// @notice Internal Mint a new NFT
    /// @param _to Address of the new owner
    /// @param subscriptionManagerId Id of the subscription manager
    function _mintNft(address _to, uint256 subscriptionManagerId) internal {
        nftSupply += 1;
        _mint(_to, nftSupply);

        ownershipByNftId[nftSupply] = subscriptionManagerId;
        ownershipBySubscriptionId[subscriptionManagerId].push(nftSupply);

        emit MintOwnerPass(_to, subscriptionManagerId);
    }

    /// @notice Mint a new NFT
    /// @param _to Address of the new owner
    /// @param subscriptionManagerId Id of the subscription manager
    function mintNft(address _to, uint256 subscriptionManagerId) external {
        require(msg.sender == address(factory), "Only factory can mint");
        _mintNft(_to, subscriptionManagerId);
    }

    /// @notice Burn a NFT when the subscription manager is deleted (called by the subscription manager)
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
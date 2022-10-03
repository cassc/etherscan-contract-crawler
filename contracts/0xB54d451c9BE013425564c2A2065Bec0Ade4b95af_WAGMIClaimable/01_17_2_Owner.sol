// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract WAGMIClaimable is  UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC721 public nftCollection;
    mapping(uint256 => uint256) public shares;
    mapping(address => uint256) public cashbacks;
    uint256[] public vipTokenIds;

    /// @notice Contract initializer
    function initialize(IERC721 _nftCollection, uint256[] calldata _vipTokenIds)
    public
    initializer
    {
        nftCollection = _nftCollection;

        vipTokenIds = _vipTokenIds;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    struct Cashback {
        address owner;
        uint256 amount;
    }

    function setVipTokenIds(uint256[] calldata _vipTokenIds) public onlyOwner {
        vipTokenIds = _vipTokenIds;
    }

    function distributeVIP() public payable onlyOwner {
        require(msg.value > 0, "Have to give some eth");
        uint256 sharePerToken = msg.value / vipTokenIds.length;
        for (uint256 i = 0; i < vipTokenIds.length; ++i) {
            shares[vipTokenIds[i]] += sharePerToken;
        }
    }

    function distributeCashbacks(Cashback[] memory _cashbacks) public payable onlyOwner {
        require(msg.value > 0, "Have to give some eth");
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _cashbacks.length; ++i) {
            totalValue += _cashbacks[i].amount;
        }
        require(msg.value >= totalValue, "You didn't provide the right amount");
        for (uint256 i = 0; i < _cashbacks.length; ++i) {
            cashbacks[_cashbacks[i].owner] += _cashbacks[i].amount;
        }
    }

    function calculateShare() public view returns (uint256) {
        uint256 share = 0;
        for (uint256 i = 0; i < vipTokenIds.length; ++i) {
            if (nftCollection.ownerOf(vipTokenIds[i]) == msg.sender) {
                share += shares[i];
            }
        }

        return share;
    }

    function _calculateAndClaim() private returns (uint256) {
        uint256 share = 0;
        for (uint256 i = 0; i < vipTokenIds.length; ++i) {
            if (nftCollection.ownerOf(vipTokenIds[i]) == msg.sender) {
                share += shares[i];
                shares[i] = 0;
            }
        }

        return share;
    }

    function claimShare() public {
        uint256 share = _calculateAndClaim();
        require(share > 0, "You dont have any share to claim");
        payable(msg.sender).transfer(share);
    }

    function claimCashback() public {
        uint256 cashback = cashbacks[msg.sender];
        require(cashback > 0, "You don't have anything to claim");
        cashbacks[msg.sender] = 0;
        payable(msg.sender).transfer(cashback);
    }

    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
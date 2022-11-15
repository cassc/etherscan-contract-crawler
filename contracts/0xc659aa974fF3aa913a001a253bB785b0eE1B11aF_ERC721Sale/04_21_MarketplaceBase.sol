// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/ArrayLibrary.sol";
import "./libraries/PaymentLibrary.sol";

import "./interfaces/AddressesInterface.sol";

abstract contract MarketplaceBase is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using ArrayLibrary for address[];
    using ArrayLibrary for uint256[];

    address public addressesContractAddr;
    address[2] public tokenAddrs;
    address public royaltyAddr;
    uint256 public royaltyPercent;
    mapping(address => uint256[2]) public claimable;

    modifier isProperContract(address contractAddr) {
        require(addressesContractAddr != address(0), "No Address Contract");
        require(
            AddressesInterface(addressesContractAddr).isVerified(contractAddr),
            "Not Verified"
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        royaltyAddr = 0x965948a44589a3e8F2f2853df0da01B33daf35a3;
        royaltyPercent = 100;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setAddressesContractAddr(address contractAddr) external onlyOwner {
        addressesContractAddr = contractAddr;
    }

    function setTokenContractAddr(address newTokenAddr) external onlyOwner {
        tokenAddrs[1] = newTokenAddr;
    }

    function setRoyaltyAddr(address newRoyaltyAddr) external onlyOwner {
        royaltyAddr = newRoyaltyAddr;
    }

    function setRoyaltyPercent(uint256 newRoyaltyPercent) external onlyOwner {
        royaltyPercent = newRoyaltyPercent;
    }

    function claim(uint256 amount, uint8 index) external {
        require(amount <= claimable[msg.sender][index], "Exceeds Claimable");
        claimable[msg.sender][index] -= amount;
        PaymentLibrary.transferFund(tokenAddrs[index], amount, msg.sender);
    }
}
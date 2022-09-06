// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Fundraiser.sol";
import "./Rewarder.sol";

contract Factory is OwnableUpgradeable, UUPSUpgradeable {
    address[] public listOfRewarders;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private adminAddress;
    uint256 public version;

    event PoolCreated(address owner, address rewarderAddress, address fundraiserAddress);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        adminAddress = 0x685A5e8d66b0A51ed08f47fa60AbB98dFA84fd49;
    }

    receive() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function createPool(string calldata _baseURI) external returns (address fundraiserAddress, address rewarderAddress) {
        Fundraiser fundraiser = new Fundraiser(
            version,
            adminAddress,
            DAI,
            USDC,
            USDT,
            BUSD,
            0
        );
        fundraiser.setBaseURI(_baseURI);
        fundraiser.transferOwnership(msg.sender);
        fundraiserAddress = address(fundraiser);

        Rewarder rewarder = new Rewarder(version, adminAddress, fundraiserAddress);
        rewarder.transferOwnership(msg.sender);
        rewarderAddress = address(rewarder);
        listOfRewarders.push(rewarderAddress);

        emit PoolCreated(msg.sender, rewarderAddress, fundraiserAddress);
    }

    function createLimitedPool(string calldata _baseURI, uint256 maxSupply) external returns (address fundraiserAddress, address rewarderAddress) {
        Fundraiser fundraiser = new Fundraiser(
            version,
            adminAddress,
            DAI,
            USDC,
            USDT,
            BUSD,
            maxSupply
        );
        fundraiser.setBaseURI(_baseURI);
        fundraiser.transferOwnership(msg.sender);
        fundraiserAddress = address(fundraiser);

        Rewarder rewarder = new Rewarder(version, adminAddress, fundraiserAddress);
        rewarder.transferOwnership(msg.sender);
        rewarderAddress = address(rewarder);
        listOfRewarders.push(rewarderAddress);

        emit PoolCreated(msg.sender, rewarderAddress, fundraiserAddress);
    }

    function getRewardersAmount() external view returns (uint256 amount) {
        amount = listOfRewarders.length;
    }

    function setAdminAddress(address feeAddress) external onlyOwner {
        adminAddress = feeAddress;
    }

    function getAdminAddress() external view returns (address) {
        return adminAddress;
    }

    function getVersion() external view returns (uint256) {
        return version;
    }

    function setVersion(uint256 _version)  external onlyOwner {
        version = _version;
    }
}
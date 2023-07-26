// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Launchpad.sol";

contract Factory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address[] public listOfLaunchpads;
    address private adminAddress;

    event LaunchpadCreated(address owner, address launchpadAddress);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        adminAddress = 0xa10593fad651D9e9019220eb9AeFa71a072587AD;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function createLaunchpad(
        string calldata _baseURI,
        address _token,
        uint256 _tokenDecimals,
        uint256 _minSaleTotal,
        uint256 _minSaleEnter,
        uint256 _maxSaleEnter,
        uint256 _saleLength,
        uint256 _ethPerToken
    ) external returns (address launchpadAddress) {
        Launchpad launchpad = new Launchpad(
            adminAddress,
            _token,
            _tokenDecimals,
            _minSaleTotal,
            _minSaleEnter,
            _maxSaleEnter,
            _saleLength,
            _ethPerToken
        );
        launchpad.setBaseURI(_baseURI);
        launchpad.transferOwnership(msg.sender);
        launchpadAddress = address(launchpad);

        listOfLaunchpads.push(launchpadAddress);

        emit LaunchpadCreated(msg.sender, launchpadAddress);
    }

    function getLaunchpadAmount() external view returns (uint256 amount) {
        amount = listOfLaunchpads.length;
    }

    function setAdminAddress(address feeAddress) external onlyOwner {
        adminAddress = feeAddress;
    }

    function getAdminAddress() external view returns (address) {
        return adminAddress;
    }
}
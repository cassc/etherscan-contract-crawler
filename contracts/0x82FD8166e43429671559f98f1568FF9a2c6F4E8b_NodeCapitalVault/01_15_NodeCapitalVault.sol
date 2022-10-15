// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/INodeRewardVault.sol";
import "./interfaces/IValidatorNft.sol";

/**
 * @title NodeCapitalVault responsible for managing initial capital
 */
contract NodeCapitalVault is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address private _aggregatorProxyAddress;

    event AggregatorChanged(address _from, address _to);
    event Transferred(address _to, uint256 _amount);

    modifier onlyAggregator() {
        require(_aggregatorProxyAddress == msg.sender, "Not allowed to touch funds");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /**
     * @notice Initializes the NodeCapitalVault contract by setting the required external contracts ,
     *         ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable and `_aggregatorProxyAddress`
     * @dev initializer - A modifier that defines a protected initializer function that can be invoked at most once
     */
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _aggregatorProxyAddress = address(0x447c3ee829a3B506ad0a66Ff1089F30181c42637);
        transferOwnership(0x01D0Be6a499F91a4572F78F042D0f7a1FdE1EbcE);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function aggregator() external view returns (address) {
        return _aggregatorProxyAddress;
    }

    function transfer(uint256 amount, address to) external nonReentrant onlyAggregator {
        require(to != address(0), "Recipient address provided invalid");
        payable(to).transfer(amount);
        emit Transferred(to, amount);
    }
    
    /**
     * @notice Set proxy address of aggregator
     * @param aggregatorProxyAddress_ proxy address of aggregator
     * @dev will only allow call of function by the address registered as the owner
     */
    function setAggregator(address aggregatorProxyAddress_) external onlyOwner {
        require(aggregatorProxyAddress_ != address(0), "Aggregator address provided invalid");
        emit AggregatorChanged(_aggregatorProxyAddress, aggregatorProxyAddress_);
        _aggregatorProxyAddress = aggregatorProxyAddress_;
    }

    receive() external payable{}
}
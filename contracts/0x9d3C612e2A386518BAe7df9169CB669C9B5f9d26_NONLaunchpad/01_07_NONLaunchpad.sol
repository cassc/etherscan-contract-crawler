// SPDX-License-Identifier: MIT

//   _   _  ____  _   _   _                            _                     _
//  | \ | |/ __ \| \ | | | |                          | |                   | |
//  |  \| | |  | |  \| | | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| |
//  | . ` | |  | | . ` | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` |
//  | |\  | |__| | |\  | | |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| |
//  |_| \_|\____/|_| \_| |______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_|
//                                                          | |
//                                                          |_|

pragma solidity ^0.8.16;

import "./enum/LaunchpadEnums.sol";
import "./interface/ILaunchpadProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// NON Launchpad
contract NONLaunchpad is Ownable, ReentrancyGuard, Pausable {
    event LaunchpadBuyEvt(
        bytes4 indexed proxyId,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 payValue
    );
    event ProxyRegistered(
        bytes4 indexed launchpadProxyId,
        address indexed proxyAddress
    );
    event LaunchpadSetBaseURIEvt(
        bytes4 proxyId,
        bytes4 launchpadId,
        string baseURI
    );
    mapping(bytes4 => address) public launchpadRegistry;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * Register LaunchpadProxy
     */
    function registerLaunchpadProxy(address proxy) external onlyOwner {
        bytes4 registryProxyId = ILaunchpadProxy(proxy).getProxyId();
        require(
            launchpadRegistry[registryProxyId] == address(0),
            LaunchpadEnums.PROXY_ID_ALREADY_EXIST
        );
        launchpadRegistry[registryProxyId] = proxy;
        emit ProxyRegistered(registryProxyId, proxy);
    }

    /**
     * GetRegistry
     */
    function getRegistry(bytes4 proxyId) external view returns (address) {
        return launchpadRegistry[proxyId];
    }

    /**
     * LaunchpadBuy - main method
     */
    function launchpadBuy(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity
    ) external payable nonReentrant whenNotPaused {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), LaunchpadEnums.PROXY_ID_NOT_EXIST);
        uint256 paymentValue = ILaunchpadProxy(proxy).launchpadBuy{
            value: msg.value
        }(_msgSender(), launchpadId, roundsIdx, quantity);
        emit LaunchpadBuyEvt(
            proxyId,
            launchpadId,
            roundsIdx,
            quantity,
            paymentValue
        );
    }

    /**
     * LaunchpadSetBaseURI
     */
    function launchpadSetBaseURI(
        bytes4 proxyId,
        bytes4 launchpadId,
        string memory baseURI
    ) external nonReentrant whenNotPaused {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), LaunchpadEnums.PROXY_ID_NOT_EXIST);
        ILaunchpadProxy(proxy).launchpadSetBaseURI(
            _msgSender(),
            launchpadId,
            baseURI
        );
        emit LaunchpadSetBaseURIEvt(proxyId, launchpadId, baseURI);
    }

    /**
     * IsInWhiteList
     */
    function isInWhiteList(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 roundsIdx,
        address[] calldata accounts
    ) external view returns (uint8[] memory wln) {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), LaunchpadEnums.PROXY_ID_NOT_EXIST);
        return
            ILaunchpadProxy(proxy).isInWhiteList(
                launchpadId,
                roundsIdx,
                accounts
            );
    }
}
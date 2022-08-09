// SPDX-License-Identifier: MIT

/**
 /$$$$$$$$ /$$   /$$  /$$$$$$ 
| $$_____/| $$  / $$ /$$__  $$
| $$      |  $$/ $$/| $$  \ $$
| $$$$$    \  $$$$/ | $$  | $$
| $$__/     >$$  $$ | $$  | $$
| $$       /$$/\  $$| $$  | $$
| $$$$$$$$| $$  \ $$|  $$$$$$/
|________/|__/  |__/ \______/ 
                              
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interfaces/Interfaces.sol";

contract ExoStargate is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    address public wormhole;
    address public exo;

    mapping(uint256 => address) public portaled;
    mapping(address => uint256[]) public userPortals;

    function initialize(address _wormhole, address _exo) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        wormhole = _wormhole;
        exo = _exo;
    }

    /* solhint-disable-next-line no-empty-blocks */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function setWormhole(address _wormhole) external onlyOwner {
        wormhole = _wormhole;
    }

    function setEXO(address _exo) external onlyOwner {
        exo = _exo;
    }

    function travel(address to, uint256[] calldata planetIds) external {
        require(msg.sender == exo, "Only the EXO can travel");

        for (uint256 i = 0; i < planetIds.length; i++) {
            portaled[planetIds[i]] = to;
            userPortals[msg.sender].push(planetIds[i]);
        }

        bytes memory data = (abi.encode(to, planetIds));

        IEthWormhole(wormhole).sendMessage(data);
    }

    function devTravel(address to, uint256[] calldata planetIds) external onlyOwner {
        for (uint256 i = 0; i < planetIds.length; i++) {
            portaled[planetIds[i]] = to;
            userPortals[msg.sender].push(planetIds[i]);
        }

        bytes memory data = (abi.encode(to, planetIds));

        IEthWormhole(wormhole).sendMessage(data);
    }

    function unstake(uint256[] calldata ids) external {
        require(msg.sender == wormhole, "Only the EXO can unstake");

        for (uint256 i = 0; i < ids.length; i++) {
            delete portaled[ids[i]];
        }
    }
}
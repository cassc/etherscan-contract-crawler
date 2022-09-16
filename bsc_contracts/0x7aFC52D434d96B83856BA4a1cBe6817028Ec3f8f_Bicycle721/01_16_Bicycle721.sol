// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BaseNFT.sol";

contract Bicycle721 is Initializable, BaseNFT {
    using SafeMath for uint256;

    function initialize(
        address _factory,
        address _upgrade,
        string calldata _name,
        uint16[] calldata _configs
    ) public initializer {
        __Ownable_init();
        base_initialize("BicycleFi", _name);
        factory = _factory;
        upgradeContract = _upgrade;
        configs = _configs; // 0: adv, 1: disadv, 2: damageType, 3: role
    }

    function breedNFT(
        address _sender,
        uint256 _tokenId,
        uint16[] memory attributes
    ) external {
        super.BreedNFT(
            _sender,
            _tokenId,
            attributes[0],
            attributes[1],
            attributes[2],
            attributes[3],
            attributes[4],
            attributes[5],
            attributes[0],
            attributes[0],
            attributes[6]
        );
    }

    function updateFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "INVALID_INPUT");
        factory = _factory;
    }

    function updateAttribute(
        uint256[] calldata _minValues,
        uint256[] calldata _maxValues
    ) external onlyOwner {
        require(_minValues.length > 0, "INVALID_INPUT");
        minValues = _minValues;
        maxValues = _maxValues;
    }
}
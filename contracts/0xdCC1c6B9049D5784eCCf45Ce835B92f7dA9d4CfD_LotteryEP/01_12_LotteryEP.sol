// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract LotteryEP is Initializable, ContextUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event FinishLottery(
        uint256 indexed positionID,
        address collection,
        uint256 tokenID,
        address winner
    );

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function checkIfNftExist(address _collection, uint256 _id) public view returns(bool) {
        return IERC721Upgradeable(_collection).ownerOf(_id) == address(this);
    }

    function finishLottery(uint256 _positionID, address _collection, uint256 _id, address _to) external nonReentrant onlyRole(ADMIN_ROLE) {
        IERC721Upgradeable(_collection).transferFrom(address(this), _to, _id);
        emit FinishLottery(
            _positionID,
            _collection,
            _id,
            _to
        );
    }

    function withdrawNFT(address _collection, address _to, uint256 _id) external nonReentrant onlyRole(ADMIN_ROLE) {
        IERC721Upgradeable(_collection).transferFrom(address(this), _to, _id);
    }

}
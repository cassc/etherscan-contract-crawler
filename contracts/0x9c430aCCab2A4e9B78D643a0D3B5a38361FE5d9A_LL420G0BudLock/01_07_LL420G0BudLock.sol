//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game G0 Bud Lock
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LL420G0BudLock is OwnableUpgradeable {
    IERC721Upgradeable public BUD_CONTRACT;
    uint256 public burntPairCount;

    /// @dev game key id => burnt amount
    mapping(address => uint256) _playerBurntAmount;

    /* ==================== EVENTS ==================== */

    event BurnG0Buds(address indexed user, uint256 male, uint256 female);

    /* ==================== METHODS ==================== */

    function initialize(address _budContract) external initializer {
        __Context_init();
        __Ownable_init();

        BUD_CONTRACT = IERC721Upgradeable(_budContract);
    }

    /**
     * @notice DANGER!!! Do not interact with this method on Etherscan directly.
     *
     * @dev The function burns the male and female buds to generate g1 bud without breeding process.
     *      It does not check if bud is male or female and it will be checked from off-chain backend.     *
     * @param _male The id of male G0 bud
     * @param _female The id of female G1 bud
     */
    function burnG0Buds(uint256 _male, uint256 _female) external {
        require(BUD_CONTRACT.ownerOf(_male) == _msgSender(), "Not the owner of BUD");
        require(BUD_CONTRACT.ownerOf(_female) == _msgSender(), "Not the owner of BUD");

        burntPairCount++;
        _playerBurntAmount[_msgSender()] += 1;

        BUD_CONTRACT.transferFrom(_msgSender(), address(this), _male);
        BUD_CONTRACT.transferFrom(_msgSender(), address(this), _female);

        emit BurnG0Buds(_msgSender(), _male, _female);
    }

    /**
     * @dev returns the burnt pair counts per game key
     *
     * @param _who player address
     */
    function burntAmount(address _who) external view returns (uint256) {
        return _playerBurntAmount[_who];
    }
}
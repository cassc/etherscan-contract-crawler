//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game In-Game Item
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ILL420Wallet.sol";
import "./interfaces/ILL420G0BudLock.sol";
import "./utils/Error.sol";

contract LL420GameItem is ERC1155Burnable, ReentrancyGuard, Ownable, ERC1155Pausable {
    using SafeMath for uint256;

    string public constant NAME = "420.game Game Item";
    string public constant SYMBOL = "420GI";
    string private _baseTokenURI;

    mapping(address => bool) public minters;

    /* ==================== EVENTS ==================== */

    event Mint(address indexed user, uint256 id, uint256 amount);

    /* ==================== MODIFIERS ==================== */

    modifier onlyMinter() {
        if (!minters[_msgSender()]) revert InvalidSender();
        _;
    }

    /* ==================== METHODS ==================== */

    /**
     * @dev Initialize the contract by setting baseURI and wallet address
     *
     * @param _baseURI Base URI for metadata
     */
    constructor(string memory _baseURI) ERC1155(_baseURI) {
        _baseTokenURI = _baseURI;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyMinter {
        _mint(to, id, amount, data);

        emit Mint(to, id, amount);
    }

    /* ==================== VIEW METHODS ==================== */

    /**
     * @param _id Game item type id
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_id)));
    }

    /* ==================== INTERNAL METHODS ==================== */

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev Owner can set the base uri
     *
     * @param baseURI Base URI for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Owner can set minter role
     *
     * @param who minter address
     * @param status true/false status
     */
    function setMinter(address who, bool status) external onlyOwner {
        minters[who] = status;
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IERC721Pool.sol";

import "./ERC20Wnft.sol";

/// @title ERC721Pool
/// @author Hifi
contract ERC721Pool is IERC721Pool, ERC20Wnft {
    using EnumerableSet for EnumerableSet.UintSet;
    /// INTERNAL STORAGE ///

    /// @dev The asset token IDs held in the pool.
    EnumerableSet.UintSet internal holdings;

    /// CONSTRUCTOR ///

    constructor() ERC20Wnft() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function holdingAt(uint256 index) external view override returns (uint256) {
        return holdings.at(index);
    }

    /// @inheritdoc IERC721Pool
    function holdingsLength() external view override returns (uint256) {
        return holdings.length();
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function deposit(uint256[] calldata ids, address to) external override {
        if (ids.length == 0) {
            revert ERC721Pool__InsufficientIn();
        }
        if (to == address(0)) {
            revert ERC721Pool__InvalidTo();
        }
        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            require(holdings.add(id));
            IERC721(asset).transferFrom(msg.sender, address(this), id);
            unchecked {
                ++i;
            }
        }
        _mint(to, ids.length * 10**18);
        emit Deposit(ids, to);
    }

    /// @inheritdoc IERC721Pool
    function withdraw(uint256[] calldata ids, address to) public override {
        if (ids.length == 0) {
            revert ERC721Pool__InsufficientIn();
        }
        if (to == address(0)) {
            revert ERC721Pool__InvalidTo();
        }
        _burn(msg.sender, ids.length * 10**18);
        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            require(holdings.remove(id));
            IERC721(asset).transferFrom(address(this), to, id);
            unchecked {
                ++i;
            }
        }
        emit Withdraw(ids, to);
    }

    /// @inheritdoc IERC721Pool
    function withdrawWithSignature(
        uint256[] calldata ids,
        address to,
        uint256 deadline,
        bytes memory signature
    ) external override {
        permitInternal(ids.length * 10**18, deadline, signature);
        withdraw(ids, to);
    }
}
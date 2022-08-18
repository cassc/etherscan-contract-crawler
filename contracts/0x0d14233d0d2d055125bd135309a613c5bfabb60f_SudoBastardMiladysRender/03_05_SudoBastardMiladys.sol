// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title Sudo Bastard Miladys
/// @author @IrvingDev_
/// @notice Sudo Bastard Miladys NFTs contract
contract SudoBastardMiladys is
    Owned(msg.sender),
    ERC721("Sudo Bastard Miladys", "SBM")
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Save the contract which render the NFTs
    ERC721Render public render;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC721Render render_) {
        render = render_;
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        ERC721Render render_ = render;
        if (address(render_) == address(0)) return "";
        return render_.tokenURI(id);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    function setRender(ERC721Render render_) external onlyOwner {
        render = render_;
    }

    function mint(
        address receiver,
        uint256 from,
        uint256 to
    ) external onlyOwner {
        require(to < 1667, "SUPPLY_IS_1666");
        for (uint256 i = from; i < to; ) {
            _mint(receiver, i);

            unchecked {
                i++;
            }
        }
    }
}

/// @title ERC721 Render
/// @author @IrvingDev_
/// @notice An abstract contract used for render the Sudo Bastard Miladys NFTs
abstract contract ERC721Render {
    function tokenURI(uint256 id) public view virtual returns (string memory);
}
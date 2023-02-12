// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Ownable} from "@solidstate-solidity/access/ownable/Ownable.sol";
import {ERC1155Base} from "@solidstate-solidity/token/ERC1155/base/ERC1155Base.sol";
import {ERC1155Metadata} from "@solidstate-solidity/token/ERC1155/metadata/ERC1155Metadata.sol";
import {ERC165Base} from "@solidstate-solidity/introspection/ERC165/base/ERC165Base.sol";
import {IERC165} from "@solidstate-solidity/interfaces/IERC165.sol";
import {IERC1155} from "@solidstate-solidity/interfaces/IERC1155.sol";
import {TrackableBurnableERC1155Storage} from "./TrackableBurnableERC1155Storage.sol";
import {TrackableBurnableERC1155__Initializable} from "./TrackableBurnableERC1155__Initializable.sol";

/**
 * @title TrackableBurnableERC1155
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Upgradeable ERC1155 implementation with burn, metadata and supply functionality
 *         added by default.
 */
abstract contract TrackableBurnableERC1155 is
    TrackableBurnableERC1155__Initializable,
    ERC165Base,
    ERC1155Base,
    ERC1155Metadata,
    Ownable
{
    function __TrackableBurnableERC1155_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        __TrackableBurnableERC1155_init_unchained(name_, symbol_, baseURI_);
    }

    function __TrackableBurnableERC1155_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        _setBaseURI(baseURI_);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
        TrackableBurnableERC1155Storage.layout().name = name_;
        TrackableBurnableERC1155Storage.layout().symbol = symbol_;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return TrackableBurnableERC1155Storage.layout().totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return TrackableBurnableERC1155.totalSupply(id) > 0;
    }

    /**
     * @dev Name of the token
     */
    function name() public view virtual returns (string memory) {
        return TrackableBurnableERC1155Storage.layout().name;
    }

    /**
     * @dev Symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return TrackableBurnableERC1155Storage.layout().symbol;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                TrackableBurnableERC1155Storage.layout().totalSupply[
                        ids[i]
                    ] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = TrackableBurnableERC1155Storage
                    .layout()
                    .totalSupply[id];
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    TrackableBurnableERC1155Storage.layout().totalSupply[id] =
                        supply -
                        amount;
                }
            }
        }
    }

    /**
     * @notice Burn an NFT
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual ownerOrApproved(account) {
        _burn(account, id, value);
    }

    /**
     * @notice Burn a batch of NFTs
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual ownerOrApproved(account) {
        _burnBatch(account, ids, values);
    }

    /**
     * @dev Modifier to track if a user is owner or approved
     */
    modifier ownerOrApproved(address account) {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );
        _;
    }

    /**
     * @dev Modify base URI as contract owner
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @dev Allow marketplaces to read the token metadata
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return uri(_tokenId);
    }
}
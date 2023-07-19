// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { MerkleAllow } from "./extensions/MerkleAllow.sol";
import { NFTBase, ERC721A } from "./extensions/NFTBase.sol";
import { ERC2981 } from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract TheFirstFriend is MerkleAllow, ERC2981, NFTBase {
    constructor() {
        _setDefaultRoyalty(ADMIN_WALLET, 750);
    }

    function mint(bytes32[] calldata _merkleProof) external onlyAllowList(_merkleProof) {
        if (block.timestamp < allowStart) revert MintDisabled();
        _claimFriend();
    }

    function mint() external {
        if (block.timestamp < openStart) revert MintDisabled();
        _claimFriend();
    }

    function _claimFriend() internal {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NoBots();
        if (claimed[msg.sender]) revert OverLimit();
        if (totalSupply() >= TOTAL_SUPPLY) revert MaxSupply();

        claimed[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    /**
     * @dev Sets start timestamps for allowlist and open mints
     * @param _allowTime unix timestamp for allowlist mint
     * @param _openTime unix timestamp for open mint
     */
    function updateMintTimes(uint256 _allowTime, uint256 _openTime) external onlyOwner {
        allowStart = _allowTime;
        openStart = _openTime;
    }

    /**
     * @dev Sets royalties for all tokens in collection
     * @param fee Fee in basis points. Example: 1000 = 10%
     */
    function setDefaultRoyalty(uint96 fee) external onlyOwner {
        require(fee <= 1000, "Fee too high");
        _setDefaultRoyalty(ADMIN_WALLET, fee);
    }

    /// @notice Override supportsInterface to support ERC2981
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
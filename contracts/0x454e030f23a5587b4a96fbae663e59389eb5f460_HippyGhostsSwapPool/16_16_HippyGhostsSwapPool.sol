// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract HippyGhostsSwapPool {
    address public immutable hippyGhosts;

    constructor(
        address hippyGhosts_,
        address gnosisSafe_
    ) {
        hippyGhosts = hippyGhosts_;
        IERC721(hippyGhosts_).setApprovalForAll(gnosisSafe_, true);
    }

    /**
     * caller must be HippyGhosts contract, this ensures:
     *   - The Transfer really happened before onERC721Received
     *   - SwapPool only accepts NFTs of HippyGhosts
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        operator = address(0);  // yeah !
        require(msg.sender == hippyGhosts, "Caller is not HippyGhosts.");
        require(IERC721(hippyGhosts).ownerOf(tokenId) == address(this), "Ghost is not received.");
        if (data.length > 0) {
            (bytes4 op, uint256 wantTokenId) = abi.decode(data, (bytes4, uint256));
            require(op == bytes4(keccak256("swap(uint256)")), "Wrong op.");
            require(IERC721(hippyGhosts).ownerOf(wantTokenId) == address(this),
                "The wanted Ghost doesn't belongs to SwapPool.");
            IERC721(hippyGhosts).transferFrom(address(this), from, wantTokenId);
        }
        // return HippyGhostSwapPool.onERC721Received.selector;
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
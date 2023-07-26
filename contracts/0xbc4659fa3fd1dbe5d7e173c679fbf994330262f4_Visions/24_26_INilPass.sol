// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INilPass is IERC721Enumerable {
    struct MintParams {
        uint256 reservedAllowance;
        uint256 maxTotalSupply;
        uint256 nHoldersMintsAvailable;
        uint256 openMintsAvailable;
        uint256 totalMintsAvailable;
        uint256 nHolderPriceInWei;
        uint256 openPriceInWei;
        uint256 totalSupply;
        uint256 maxMintAllowance;
        bool onlyNHolders;
        bool supportsTokenId;
    }

    function mint(
        address recipient,
        uint8 amount,
        uint256 paid,
        bytes calldata data
    ) external;

    function mintTokenId(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid
    ) external;

    function mintWithN(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid,
        bytes calldata data
    ) external;

    function totalMintsAvailable() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);

    function mintParameters() external view returns (MintParams memory);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function nUsed(uint256 nid) external view returns (bool);

    function canMint(address account, bytes calldata data) external view returns (bool);
}
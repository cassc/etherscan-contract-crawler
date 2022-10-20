// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { NftData } from "./../common/Types.sol";

interface IDZapDiscountNft {
    /* ========= EVENTS ========= */

    event Created(uint256 starringId, uint256 noCreated);
    event MintersApproved(address[] minters, uint256[] ids, uint256[] amounts);
    event MintersRevoked(address[] minters, uint256[] ids);
    event Minted(address[] to, uint256[] ids, uint256[] amounts);
    event BatchMinted(address to, uint256[] ids, uint256[] amounts);

    /* ========= VIEWS ========= */

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId_) external view returns (string memory);

    /* ========= FUNCTIONS ========= */

    function setBaseURI(string memory newUri_) external;

    function setContractURI(string memory newContractUri_) external;

    function createNfts(NftData[] calldata nftData_) external;

    function approveMinter(
        address[] calldata minters_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) external;

    function mint(
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPresaleCvgSeed is IERC721Enumerable {
    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            ENUMS & STRUCTS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    enum SaleState {
        NOT_ACTIVE,
        PRESEED,
        SEED,
        OVER
    }

    struct PresaleInfo {
        uint256 vestingType; // Define the presaler type
        uint256 cvgAmount; // Total CVG amount claimable for the nft owner
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setSaleState(SaleState _saleState) external;

    function grantPreseed(address _wallet, uint256 _amount) external;

    function grantSeed(address _wallet, uint256 _amount) external;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function investMint(bool _isDai) external;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function presaleInfoTokenId(uint256 _tokenId) external view returns (PresaleInfo memory);

    function saleState() external view returns (SaleState);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256);

    function getTokenIdAndType(
        address _wallet,
        uint256 _index
    ) external view returns (uint256 tokenId, uint256 typeVesting);

    function getTokenIdsForWallet(address _wallet) external view returns (uint256[] memory);

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        WITHDRAW OWNER
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function withdrawFunds() external;

    function withdrawToken(address _token) external;
}
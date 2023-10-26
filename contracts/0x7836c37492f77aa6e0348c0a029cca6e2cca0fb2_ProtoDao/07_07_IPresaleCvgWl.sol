// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPresaleCvgWl is IERC721Enumerable {
    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            ENUMS & STRUCTS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    enum SaleState {
        NOT_ACTIVE,
        WL,
        OVER
    }

    struct PresaleInfo {
        uint256 vestingType;
        uint256 cvgAmount;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setSaleState(SaleState _saleState) external;

    function setMerkleRootWlS(bytes32 _newMerkleRootWlS) external;

    function setMerkleRootWlM(bytes32 _newMerkleRootWlM) external;

    function setMerkleRootWlL(bytes32 _newMerkleRootWlL) external;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function investMint(bytes32[] calldata _merkleProof, uint256 _amount) external;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function presaleInfos(uint256 _tokenId) external view returns (PresaleInfo memory);

    function getAmountCvgForVesting() external view returns (uint256);

    function getTotalCvg() external view returns (uint256);

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
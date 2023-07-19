// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

library ProtoDAOSettingsBaseStorage {
    struct DaoInfo {
        uint256 canvasCreatorERC20Ratio;
        uint256 nftMinterERC20Ratio;
        uint256 daoFeePoolETHRatio;
        uint256 daoFeePoolETHRatioFlatPrice;
        bool newDAO;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoInfo) allDaos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("ProtoDAO.contracts.storage.Setting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
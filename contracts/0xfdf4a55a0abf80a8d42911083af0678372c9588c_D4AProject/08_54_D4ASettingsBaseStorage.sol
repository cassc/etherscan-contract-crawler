// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import {ID4ADrb} from "../interface/ID4ADrb.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721.sol";
import "../interface/ID4AERC721Factory.sol";
import "../interface/IPermissionControl.sol";

interface ID4AProtocolForSetting {
    function getCanvasProject(bytes32 _canvas_id) external view returns (bytes32);
}

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library D4ASettingsBaseStorage {
    struct Layout {
        uint256 ratio_base;
        uint256 min_stamp_duty; //TODO
        uint256 max_stamp_duty;
        uint256 create_project_fee;
        address protocol_fee_pool;
        uint256 create_canvas_fee;
        uint256 mint_d4a_fee_ratio;
        uint256 trade_d4a_fee_ratio;
        uint256 mint_project_fee_ratio;
        uint256 mint_project_fee_ratio_flat_price;
        uint256 erc20_total_supply;
        uint256 project_max_rounds; //366
        uint256 project_erc20_ratio;
        uint256 canvas_erc20_ratio;
        uint256 d4a_erc20_ratio;
        uint256 rf_lower_bound;
        uint256 rf_upper_bound;
        uint256[] floor_prices;
        uint256[] max_nft_amounts;
        ID4ADrb drb;
        string erc20_name_prefix;
        string erc20_symbol_prefix;
        ID4AERC721Factory erc721_factory;
        ID4AERC20Factory erc20_factory;
        ID4AFeePoolFactory feepool_factory;
        ID4AOwnerProxy owner_proxy;
        //ID4AProtocolForSetting protocol;
        IPermissionControl permission_control;
        address asset_pool_owner;
        bool d4a_pause;
        mapping(bytes32 => bool) pause_status;
        address project_proxy;
        uint256 reserved_slots;
        uint256 defaultNftPriceMultiplyFactor;
        bool initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4A.contracts.storage.Setting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
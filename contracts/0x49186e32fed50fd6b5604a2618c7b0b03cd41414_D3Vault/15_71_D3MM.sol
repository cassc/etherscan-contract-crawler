// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {D3Trading} from "./D3Trading.sol";
import {IFeeRateModel} from "../../intf/IFeeRateModel.sol";
import {ID3Maker} from "../intf/ID3Maker.sol";

contract D3MM is D3Trading {
    /// @notice init D3MM pool
    function init(
        address creator,
        address maker,
        address vault,
        address oracle,
        address feeRateModel,
        address maintainer
    ) external {
        initOwner(creator);
        state._CREATOR_ = creator;
        state._D3_VAULT_ = vault;
        state._ORACLE_ = oracle;
        state._MAKER_ = maker;
        state._FEE_RATE_MODEL_ = feeRateModel;
        state._MAINTAINER_ = maintainer;
    }

    // ============= Set ====================
    function setNewMaker(address newMaker) external onlyOwner {
        state._MAKER_ = newMaker;
        allFlag = 0;
    }

    // ============= View =================
    function _CREATOR_() external view returns(address) {
        return state._CREATOR_;
    }

    function getFeeRate(address token) external view returns(uint256 feeRate) {
        return IFeeRateModel(state._FEE_RATE_MODEL_).getFeeRate(token);
    }

    function getPoolTokenlist() external view returns(address[] memory) {
        return ID3Maker(state._MAKER_).getPoolTokenListFromMaker();
    }

    function getDepositedTokenList() external view returns (address[] memory) {
        return state.depositedTokenList;
    }

    /// @notice get basic pool info
    function getD3MMInfo() external view returns (address vault, address oracle, address maker, address feeRateModel, address maintainer) {
        vault = state._D3_VAULT_;
        oracle = state._ORACLE_;
        maker = state._MAKER_;
        feeRateModel = state._FEE_RATE_MODEL_;
        maintainer = state._MAINTAINER_;
    }

    /// @notice get a token's reserve in pool
    function getTokenReserve(address token) external view returns (uint256) {
        return state.balances[token];
    }

    /// @notice get D3MM contract version
    function version() external pure virtual returns (string memory) {
        return "D3MM 1.0.0";
    }
}
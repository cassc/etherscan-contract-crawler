// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ID4ASettings {
    function initializeD4ASettings() external;

    function changeCreateFee(uint256 _create_project_fee, uint256 _create_canvas_fee) external;

    function changeProtocolFeePool(address addr) external;

    function changeMintFeeRatio(
        uint256 _d4a_fee_ratio,
        uint256 _project_fee_ratio,
        uint256 _project_fee_ratio_flat_price
    ) external;

    function changeTradeFeeRatio(uint256 _trade_d4a_fee_ratio) external;

    function changeERC20TotalSupply(uint256 _total_supply) external;

    function changeERC20Ratio(uint256 _d4a_ratio, uint256 _project_ratio, uint256 _canvas_ratio) external;

    function changeMaxMintableRounds(uint256 _rounds) external;

    function changeAddress(
        address _prb,
        address _erc20_factory,
        address _erc721_factory,
        address _feepool_factory,
        address _owner_proxy,
        address _project_proxy,
        address _permission_control
    ) external;

    function changeAssetPoolOwner(address _owner) external;

    function changeFloorPrices(uint256[] memory _prices) external;

    function changeMaxNFTAmounts(uint256[] memory _amounts) external;

    function changeD4APause(bool is_paused) external;

    function setProjectPause(bytes32 obj_id, bool is_paused) external;

    function setCanvasPause(bytes32 obj_id, bool is_paused) external;

    function transferMembership(bytes32 role, address previousMember, address newMember) external;

    function changeNftPriceMultiplyFactor(uint256 newDefaultNftPriceMultiplyFactor) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import "./ID4ASettings.sol";
import "./D4ASettingsBaseStorage.sol";
import "./D4ASettingsReadable.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721Factory.sol";

contract D4ASettings is ID4ASettings, AccessControl, D4ASettingsReadable {
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    function initializeD4ASettings() public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(!l.initialized, "already initialized");
        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DAO_ROLE, OPERATION_ROLE);
        _setRoleAdmin(SIGNER_ROLE, OPERATION_ROLE);
        //some default value here
        l.ratio_base = 10000;
        l.create_project_fee = 0.1 ether;
        l.create_canvas_fee = 0.01 ether;
        l.mint_d4a_fee_ratio = 250;
        l.trade_d4a_fee_ratio = 250;
        l.mint_project_fee_ratio = 3000;
        l.mint_project_fee_ratio_flat_price = 3500;
        l.rf_lower_bound = 500;
        l.rf_upper_bound = 1000;

        l.project_erc20_ratio = 300;
        l.d4a_erc20_ratio = 200;
        l.canvas_erc20_ratio = 9500;
        l.project_max_rounds = 366;
        l.reserved_slots = 110;

        l.defaultNftPriceMultiplyFactor = 20_000;
        l.initialized = true;
    }

    event ChangeCreateFee(uint256 create_project_fee, uint256 create_canvas_fee);

    function changeCreateFee(uint256 _create_project_fee, uint256 _create_canvas_fee) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.create_project_fee = _create_project_fee;
        l.create_canvas_fee = _create_canvas_fee;
        emit ChangeCreateFee(_create_project_fee, _create_canvas_fee);
    }

    event ChangeProtocolFeePool(address addr);

    function changeProtocolFeePool(address addr) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.protocol_fee_pool = addr;
        emit ChangeProtocolFeePool(addr);
    }

    event ChangeMintFeeRatio(uint256 d4a_ratio, uint256 project_ratio, uint256 project_fee_ratio_flat_price);

    function changeMintFeeRatio(
        uint256 _d4a_fee_ratio,
        uint256 _project_fee_ratio,
        uint256 _project_fee_ratio_flat_price
    ) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.mint_d4a_fee_ratio = _d4a_fee_ratio;
        l.mint_project_fee_ratio = _project_fee_ratio;
        l.mint_project_fee_ratio_flat_price = _project_fee_ratio_flat_price;
        emit ChangeMintFeeRatio(_d4a_fee_ratio, _project_fee_ratio, _project_fee_ratio_flat_price);
    }

    event ChangeTradeFeeRatio(uint256 trade_d4a_fee_ratio);

    function changeTradeFeeRatio(uint256 _trade_d4a_fee_ratio) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.trade_d4a_fee_ratio = _trade_d4a_fee_ratio;
        emit ChangeTradeFeeRatio(_trade_d4a_fee_ratio);
    }

    event ChangeERC20TotalSupply(uint256 total_supply);

    function changeERC20TotalSupply(uint256 _total_supply) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.erc20_total_supply = _total_supply;
        emit ChangeERC20TotalSupply(_total_supply);
    }

    event ChangeERC20Ratio(uint256 d4a_ratio, uint256 project_ratio, uint256 canvas_ratio);

    function changeERC20Ratio(uint256 _d4a_ratio, uint256 _project_ratio, uint256 _canvas_ratio)
        public
        onlyRole(PROTOCOL_ROLE)
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.d4a_erc20_ratio = _d4a_ratio;
        l.project_erc20_ratio = _project_ratio;
        l.canvas_erc20_ratio = _canvas_ratio;
        require(_d4a_ratio + _project_ratio + _canvas_ratio == l.ratio_base, "invalid ratio");

        emit ChangeERC20Ratio(_d4a_ratio, _project_ratio, _canvas_ratio);
    }

    event ChangeMaxMintableRounds(uint256 old_rounds, uint256 new_rounds);

    function changeMaxMintableRounds(uint256 _rounds) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        emit ChangeMaxMintableRounds(l.project_max_rounds, _rounds);
        l.project_max_rounds = _rounds;
    }

    event ChangeAddress(
        address PRB,
        address erc20_factory,
        address erc721_factory,
        address feepool_factory,
        address owner_proxy,
        address project_proxy,
        address permission_control
    );

    function changeAddress(
        address _prb,
        address _erc20_factory,
        address _erc721_factory,
        address _feepool_factory,
        address _owner_proxy,
        address _project_proxy,
        address _permission_control
    ) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.drb = ID4ADrb(_prb);
        l.erc20_factory = ID4AERC20Factory(_erc20_factory);
        l.erc721_factory = ID4AERC721Factory(_erc721_factory);
        l.feepool_factory = ID4AFeePoolFactory(_feepool_factory);
        l.owner_proxy = ID4AOwnerProxy(_owner_proxy);
        l.project_proxy = _project_proxy;
        l.permission_control = IPermissionControl(_permission_control);
        emit ChangeAddress(
            _prb, _erc20_factory, _erc721_factory, _feepool_factory, _owner_proxy, _project_proxy, _permission_control
        );
    }

    event ChangeAssetPoolOwner(address new_owner);

    function changeAssetPoolOwner(address _owner) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.asset_pool_owner = _owner;
        emit ChangeAssetPoolOwner(_owner);
    }

    event ChangeFloorPrices(uint256[] prices);

    function changeFloorPrices(uint256[] memory _prices) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        delete l.floor_prices;
        l.floor_prices = _prices;
        emit ChangeFloorPrices(_prices);
    }

    event ChangeMaxNFTAmounts(uint256[] amounts);

    function changeMaxNFTAmounts(uint256[] memory _amounts) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        delete l.max_nft_amounts;
        l.max_nft_amounts = _amounts;
        emit ChangeMaxNFTAmounts(_amounts);
    }

    event ChangeD4APause(bool is_paused);

    function changeD4APause(bool is_paused) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.d4a_pause = is_paused;
        emit ChangeD4APause(is_paused);
    }

    event D4ASetProjectPaused(bytes32 project_id, bool is_paused);

    function setProjectPause(bytes32 obj_id, bool is_paused) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(
            (_hasRole(DAO_ROLE, msg.sender) && l.owner_proxy.ownerOf(obj_id) == msg.sender)
                || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pause_status[obj_id] = is_paused;
        emit D4ASetProjectPaused(obj_id, is_paused);
    }

    event D4ASetCanvasPaused(bytes32 canvas_id, bool is_paused);

    function setCanvasPause(bytes32 obj_id, bool is_paused) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(
            (
                _hasRole(DAO_ROLE, msg.sender)
                    && l.owner_proxy.ownerOf(ID4AProtocolForSetting(address(this)).getCanvasProject(obj_id)) == msg.sender
            ) || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pause_status[obj_id] = is_paused;
        emit D4ASetCanvasPaused(obj_id, is_paused);
    }

    event MembershipTransferred(bytes32 indexed role, address indexed previousMember, address indexed newMember);

    function transferMembership(bytes32 role, address previousMember, address newMember) public {
        require(!_hasRole(role, newMember), "new member already has the role");
        require(_hasRole(role, previousMember), "previous member does not have the role");
        require(newMember != address(0x0) && previousMember != address(0x0), "invalid address");
        _grantRole(role, newMember);
        _revokeRole(role, previousMember);

        emit MembershipTransferred(role, previousMember, newMember);
    }

    event DefaultNftPriceMultiplyFactorChanged(uint256 newDefaultNftPriceMultiplyFactor);

    function changeNftPriceMultiplyFactor(uint256 newDefaultNftPriceMultiplyFactor) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.defaultNftPriceMultiplyFactor = newDefaultNftPriceMultiplyFactor;
        emit DefaultNftPriceMultiplyFactorChanged(newDefaultNftPriceMultiplyFactor);
    }
}
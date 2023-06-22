// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// This contract generates Presale01 contracts and registers them in the PresaleFactory.
// Ideally you should not interact with this contract directly, and use the Octofi presale app instead so warnings can be shown where necessary.

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../TransferHelper.sol";
import "../PresaleSettings.sol";
import "./SharedStructs.sol";
import "./PresaleLockForwarder.sol";
import "./PresaleFactory.sol";
import "./Presale.sol";

contract PresaleManage {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private presales;

    PresaleFactory internal presaleFactory;

    address public presale_lock_forward_addr;
    address public presale_setting_addr;
    PresaleLockForwarder _lock;

    address private uniswap_factory_address;
    address private uniswap_pair_address;

    address private weth_address;

    address payable owner;

    SharedStructs.PresaleInfo presale_info;
    SharedStructs.PresaleLink presalelink;

    PresaleSettings public settings;

    event OwnerWithdrawSuccess(uint256 value);
    event CreatePreslaeSuccess(address, address);

    constructor(
        address payable _owner,
        address lock_addr,
        address uniswapfactory_addr,
        address uniswaprouter_Addr,
        address weth_addr,
        PresaleFactory _presaleFactory
    ) {
        owner = _owner;

        uniswap_factory_address = uniswapfactory_addr;
        weth_address = weth_addr;

        _lock = new PresaleLockForwarder(
            address(this),
            lock_addr,
            uniswapfactory_addr,
            uniswaprouter_Addr,
            weth_addr
        );
        presale_lock_forward_addr = address(_lock);

        PresaleSettings _setting;

        _setting = new PresaleSettings(address(this), _owner, lock_addr);

        _setting.init(owner, 0.01 ether, owner, 10, owner, 10, owner, 10);

        presale_setting_addr = address(_setting);

        settings = PresaleSettings(presale_setting_addr);

        presaleFactory = _presaleFactory;
    }

    function ownerWithdraw() public {
        require(
            msg.sender == settings.getCreateFeeAddress(),
            "Only creater can withdraw"
        );
        address payable reciver = payable(settings.getCreateFeeAddress());
        reciver.transfer(address(this).balance);
        // owner.transfer(address(this).balance);
        emit OwnerWithdrawSuccess(address(this).balance);
    }

    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory.sol.
     */

    function calculateAmountRequired(
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _listingRate,
        uint256 _liquidityPercent,
        uint256 _tokenFee
    ) public pure returns (uint256) {
        uint256 tokenamount = (_amount * _tokenPrice) / (10**18);
        uint256 TokenFee = (((_amount * _tokenFee) / 100) / 10**18) *
            _tokenPrice;
        uint256 liqudityrateamount = (_amount * _listingRate) / (10**18);
        uint256 liquiditytoken = (liqudityrateamount * _liquidityPercent) / 100;
        uint256 tokensRequiredForPresale = tokenamount +
            liquiditytoken +
            TokenFee;
        return tokensRequiredForPresale;
    }

    function createPresale(
        SharedStructs.PresaleInfo memory _presale_info,
        SharedStructs.PresaleLink memory _presalelink
    ) public payable {
        presale_info = _presale_info;

        presalelink = _presalelink;

        // if ( (presale_info.presale_end - presale_info.presale_start) < 1 weeks) {
        //     presale_info.presale_end = presale_info.presale_start + 1 weeks;
        // }

        // if ( (presale_info.lock_end - presale_info.lock_start) < 4 weeks) {
        //     presale_info.lock_end = presale_info.lock_start + 4 weeks;
        // }

        // Charge ETH fee for contract creation
        require(
            msg.value >= settings.getPresaleCreateFee() + settings.getLockFee(),
            "Balance is insufficent"
        );

        require(_presale_info.token_rate > 0, "token rate is invalid");
        require(
            _presale_info.raise_min < _presale_info.raise_max,
            "raise min/max in invalid"
        );
        require(
            _presale_info.softcap <= _presale_info.hardcap,
            "softcap/hardcap is invalid"
        );
        require(
            _presale_info.liqudity_percent >= 30 &&
                _presale_info.liqudity_percent <= 100,
            "Liqudity percent is invalid"
        );
        require(_presale_info.listing_rate > 0, "Listing rate is invalid");

        require(
            (_presale_info.presale_end - _presale_info.presale_start) > 0,
            "Presale start/end time is invalid"
        );
        require(
            (_presale_info.lock_end - _presale_info.lock_start) >= 4 weeks,
            "Lock end is invalid"
        );

        // Calculate required token amount
        uint256 tokensRequiredForPresale = calculateAmountRequired(
            _presale_info.hardcap,
            _presale_info.token_rate,
            _presale_info.listing_rate,
            _presale_info.liqudity_percent,
            settings.getSoldFee()
        );

        // Create New presale
        PresaleV1 newPresale = presaleFactory.deploy{
            value: settings.getLockFee()
        }(
            address(this),
            weth_address,
            presale_setting_addr,
            presale_lock_forward_addr
        );

        // newPresale.delegatecall(bytes4(sha3("destroy()")));

        if (address(newPresale) == address(0)) {
            // newPresale.destroy();
            require(false, "Create presale Failed");
        }

        TransferHelper.safeTransferFrom(
            address(_presale_info.sale_token),
            address(msg.sender),
            address(newPresale),
            tokensRequiredForPresale
        );

        newPresale.init_private(_presale_info);

        newPresale.init_link(_presalelink);

        newPresale.init_fee();

        presales.add(address(newPresale));

        emit CreatePreslaeSuccess(address(newPresale), address(msg.sender));
    }

    function getCount() external view returns (uint256) {
        return presales.length();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getPresaleAt(uint256 index) external view returns (address) {
        return presales.at(index);
    }

    function IsRegistered(address presale_addr) external view returns (bool) {
        return presales.contains(presale_addr);
    }
}
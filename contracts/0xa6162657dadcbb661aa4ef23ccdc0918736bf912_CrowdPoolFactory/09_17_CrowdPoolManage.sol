// SPDX-License-Identifier: UNLICENSED


// ██████╗░░██████╗██╗░░░██╗░█████╗░██████╗░
// ██╔══██╗██╔════╝╚██╗░██╔╝██╔══██╗██╔══██╗
// ██████╔╝╚█████╗░░╚████╔╝░██║░░██║██████╔╝
// ██╔═══╝░░╚═══██╗░░╚██╔╝░░██║░░██║██╔═══╝░
// ██║░░░░░██████╔╝░░░██║░░░╚█████╔╝██║░░░░░
// ╚═╝░░░░░╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░░░░
// █▀▀ █▀█ █▀█ █░█░█ █▀▄   █▀█ █▀█ █▀█ █░░
// █▄▄ █▀▄ █▄█ ▀▄▀▄▀ █▄▀   █▀▀ █▄█ █▄█ █▄▄
// 𝗏 𝟣.𝟣

// This contract generates CrowdPool contracts and registers them in the CrowdPoolFactory.
// This is decentralized and enables you to interact with this contract directly. You can use the public UI so warnings can be shown where necessary.

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../TransferHelper.sol";
import "../CrowdPoolSettings.sol";
import "./SharedStructs.sol";
import "./CrowdPoolLockForwarder.sol";
import "./CrowdPoolFactory.sol";
import "./CrowdPool.sol";

contract CrowdPoolManage {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private crowdpools;

    CrowdPoolFactory internal crowdpoolFactory;

    address public crowdpool_lock_forward_addr;
    address public crowdpool_setting_addr;
    CrowdPoolLockForwarder _lock;

    address private uniswap_factory_address;
    address private uniswap_pair_address;

    address private weth_address;

    address payable owner;

    SharedStructs.CrowdPoolInfo crowdpool_info;
    SharedStructs.CrowdPoolLink crowdpoollink;

    CrowdPoolSettings public settings;

    event OwnerWithdrawSuccess(uint256 value);
    event CreateCrowdpoolSucess(address, address);

    constructor(
        address payable _owner,
        address lock_addr,
        address uniswapfactory_addr,
        address uniswaprouter_Addr,
        address weth_addr,
        CrowdPoolFactory _crowdpoolFactory
    ) {
        owner = _owner;

        uniswap_factory_address = uniswapfactory_addr;
        weth_address = weth_addr;

        _lock = new CrowdPoolLockForwarder(
            address(this),
            lock_addr,
            uniswapfactory_addr,
            uniswaprouter_Addr,
            weth_addr
        );
        crowdpool_lock_forward_addr = address(_lock);

        CrowdPoolSettings _setting;

        _setting = new CrowdPoolSettings(address(this), _owner, lock_addr);

        _setting.init(owner, 0.01 ether, owner, 10, owner, 10, owner, 10);

        crowdpool_setting_addr = address(_setting);

        settings = CrowdPoolSettings(crowdpool_setting_addr);

        crowdpoolFactory = _crowdpoolFactory;
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
     * @notice Creates a new CrowdPool contract and registers it in the CrowdPoolFactory.sol.
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
        uint256 tokensRequiredForCrowdPool = tokenamount +
            liquiditytoken +
            TokenFee;
        return tokensRequiredForCrowdPool;
    }

    function createCrowdPool(
        SharedStructs.CrowdPoolInfo memory _crowdpool_info,
        SharedStructs.CrowdPoolLink memory _crowdpoollink
    ) public payable {
        crowdpool_info = _crowdpool_info;

        crowdpoollink = _crowdpoollink;

         if ( (crowdpool_info.crowdpool_end - crowdpool_info.crowdpool_start) < 1 weeks) {
             crowdpool_info.crowdpool_end = crowdpool_info.crowdpool_start + 1 weeks;
         }

         if ( (crowdpool_info.lock_end - crowdpool_info.lock_start) < 4 weeks) {
             crowdpool_info.lock_end = crowdpool_info.lock_start + 4 weeks;
         }

        // Charge ETH fee for contract creation
        require(
            msg.value >= settings.getCrowdPoolCreateFee() + settings.getLockFee(),
            "Balance is insufficent"
        );

        require(_crowdpool_info.token_rate > 0, "token rate is invalid");
        require(
            _crowdpool_info.pool_min < _crowdpool_info.pool_max,
            "pool min/max in invalid"
        );
        require(
            _crowdpool_info.softcap <= _crowdpool_info.hardcap,
            "softcap/hardcap is invalid"
        );
        require(
            _crowdpool_info.liqudity_percent >= 30 &&
                _crowdpool_info.liqudity_percent <= 100,
            "Liqudity percent is invalid"
        );
        require(_crowdpool_info.listing_rate > 0, "Listing rate is invalid");

        require(
            (_crowdpool_info.crowdpool_end - _crowdpool_info.crowdpool_start) > 0,
            "CrowdPool start/end time is invalid"
        );
        require(
            (_crowdpool_info.lock_end - _crowdpool_info.lock_start) >= 4 weeks,
            "Lock end is invalid"
        );

        // Calculate required token amount
        uint256 tokensRequiredForCrowdPool = calculateAmountRequired(
            _crowdpool_info.hardcap,
            _crowdpool_info.token_rate,
            _crowdpool_info.listing_rate,
            _crowdpool_info.liqudity_percent,
            settings.getSoldFee()
        );

        // Create New crowdpool
        CrowdPoolV1 newCrowdPool = crowdpoolFactory.deploy{
            value: settings.getLockFee()
        }(
            address(this),
            weth_address,
            crowdpool_setting_addr,
            crowdpool_lock_forward_addr
        );

        // newCrowdPool.delegatecall(bytes4(sha3("destroy()")));

        if (address(newCrowdPool) == address(0)) {
            // newCrowdPool.destroy();
            require(false, "Create crowdpool Failed");
        }

        TransferHelper.safeTransferFrom(
            address(_crowdpool_info.pool_token),
            address(msg.sender),
            address(newCrowdPool),
            tokensRequiredForCrowdPool
        );

        newCrowdPool.init_private(_crowdpool_info);

        newCrowdPool.init_link(_crowdpoollink);

        newCrowdPool.init_fee();

        crowdpools.add(address(newCrowdPool));

        emit CreateCrowdpoolSucess(address(newCrowdPool), address(msg.sender));
    }

    function getCount() external view returns (uint256) {
        return crowdpools.length();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getCrowdPoolAt(uint256 index) external view returns (address) {
        return crowdpools.at(index);
    }

    function IsRegistered(address crowdpool_addr) external view returns (bool) {
        return crowdpools.contains(crowdpool_addr);
    }
}
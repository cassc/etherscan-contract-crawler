pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interface/IxAsset.sol";
import "./interface/IOrigination.sol";
import "./interface/IxTokenManager.sol";

/**
 * @title RevenueController
 * @author xToken
 *
 * RevenueController is the management fees charged on xAsset funds. The RevenueController contract
 * claims fees from xAssets, exchanges fee tokens for XTK via 1inch (off-chain api data will need to
 * be passed to permissioned function `claimAndSwap`), and then transfers XTK to Mgmt module
 */
contract RevenueController is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    // Index of xAsset
    uint256 public nextFundIndex;

    // Address of xtk token
    address public constant xtk = 0x7F3EDcdD180Dbe4819Bd98FeE8929b5cEdB3AdEB;
    // Address of Mgmt module
    address public managementStakingModule;
    // Address of OneInchExchange contract
    address public oneInchExchange;
    // Address to indicate ETH
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //
    address public xtokenManager;

    // xAsset to index
    mapping(address => uint256) private _fundToIndex;
    // xAsset to array of asset address that charged as fee
    mapping(address => address[]) private _fundAssets;
    // Index to xAsset
    mapping(uint256 => address) private _indexToFund;

    address public constant terminal = 0x090559D58aAB8828C27eE7a7EAb18efD5bB90374;

    address public constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    address public origination;

    /* ============ Events ============ */

    event FeesClaimed(address indexed fund, address indexed revenueToken, uint256 revenueTokenAmount);
    event RevenueAccrued(address indexed fund, uint256 xtkAccrued, uint256 timestamp);
    event FundAdded(address indexed fund, uint256 indexed fundIndex);
    event AssetSwappedToXtk(address indexed fundAssets, uint256 fundAssetAmount, uint256 xtkAmount);

    /* ============ Modifiers ============ */

    modifier onlyOwnerOrManager() {
        require(
            msg.sender == owner() || IxTokenManager(xtokenManager).isManager(msg.sender, address(this)),
            "Non-admin caller"
        );
        _;
    }

    /* ============ Functions ============ */

    function initialize(
        address _managementStakingModule,
        address _oneInchExchange,
        address _xtokenManager
    ) external initializer {
        __Ownable_init();

        nextFundIndex = 1;

        managementStakingModule = _managementStakingModule;
        oneInchExchange = _oneInchExchange;
        xtokenManager = _xtokenManager;
    }

    /**
     * Withdraw fees from xAsset contract, and swap fee assets into xtk token and send to Mgmt
     *
     * @param _fundIndex    Index of xAsset
     * @param _oneInchData  1inch low-level calldata(generated off-chain)
     */
    function claimAndSwap(
        uint256 _fundIndex,
        bytes[] calldata _oneInchData,
        uint256[] calldata _callValue
    ) external onlyOwnerOrManager {
        require(_fundIndex > 0 && _fundIndex < nextFundIndex, "Invalid fund index");

        address fund = _indexToFund[_fundIndex];
        address[] memory fundAssets = _fundAssets[fund];

        require(_oneInchData.length == fundAssets.length, "Params mismatch");
        require(_callValue.length == fundAssets.length, "Params mismatch");

        IxAsset(fund).withdrawFees();

        for (uint256 i = 0; i < fundAssets.length; i++) {
            uint256 revenueTokenBalance = getRevenueTokenBalance(fundAssets[i]);

            if (revenueTokenBalance > 0) {
                emit FeesClaimed(fund, fundAssets[i], revenueTokenBalance);
                if (_oneInchData[i].length > 0) {
                    if (
                        fundAssets[i] != ETH_ADDRESS &&
                        IERC20(fundAssets[i]).allowance(address(this), AGGREGATION_ROUTER_V4) < revenueTokenBalance
                    ) {
                        IERC20(fundAssets[i]).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
                    }
                    swapAssetToXtk(fundAssets[i], _oneInchData[i], _callValue[i]);
                }
            }
        }

        claimXtkForStaking(fund);
    }

    function claimTerminalFeesAndSwap(
        address _token,
        bytes calldata _oneInchData,
        uint256 _callValue
    ) external onlyOwnerOrManager {
        require(_token != address(0), "Invalid token address");

        ILMTerminal(terminal).withdrawFees(_token);

        uint256 revenueTokenBalance = getRevenueTokenBalance(_token);

        if (revenueTokenBalance > 0) {
            emit FeesClaimed(terminal, _token, revenueTokenBalance);
            if (_oneInchData.length > 0) {
                if (IERC20(_token).allowance(address(this), AGGREGATION_ROUTER_V4) < revenueTokenBalance) {
                    IERC20(_token).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
                }
                swapAssetToXtk(_token, _oneInchData, _callValue);
            }
        }

        claimXtkForStaking(terminal);
    }

    function swapTerminalETH(bytes calldata _oneInchData, uint256 _callValue) external onlyOwnerOrManager {
        uint256 amount = address(this).balance;

        require(amount > 0, "Insufficient ETH");
        require(_oneInchData.length > 0, "Invalid oneInch data");

        emit FeesClaimed(terminal, ETH_ADDRESS, _callValue);
        swapAssetToXtk(ETH_ADDRESS, _oneInchData, _callValue);

        claimXtkForStaking(terminal);
    }

    function claimOriginationFeesAndSwap(
        address _token,
        bytes calldata _oneInchData,
        uint256 _callValue
    ) external onlyOwnerOrManager {
        require(_token != address(0), "Invalid token address");

        IOriginationCore(origination).claimFees(_token);

        uint256 revenueTokenBalance = getRevenueTokenBalance(_token);

        if (revenueTokenBalance > 0) {
            emit FeesClaimed(origination, _token, revenueTokenBalance);
            if (_oneInchData.length > 0) {
                if (IERC20(_token).allowance(address(this), AGGREGATION_ROUTER_V4) < revenueTokenBalance) {
                    IERC20(_token).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
                }
                swapAssetToXtk(_token, _oneInchData, _callValue);
            }
        }

        claimXtkForStaking(origination);
    }

    function swapOriginationETH(bytes calldata _oneInchData, uint256 _callValue) external onlyOwnerOrManager {
        IOriginationCore(origination).claimFees(address(0));
        uint256 amount = address(this).balance;

        require(amount > 0, "Insufficient ETH");
        require(_oneInchData.length > 0, "Invalid oneInch data");

        emit FeesClaimed(origination, ETH_ADDRESS, _callValue);
        swapAssetToXtk(ETH_ADDRESS, _oneInchData, _callValue);

        claimXtkForStaking(origination);
    }

    function swapAssetOnceClaimed(
        address fund,
        address asset,
        bytes calldata _oneInchData,
        uint256 _callValue
    ) external onlyOwnerOrManager {
        require(fund == terminal || fund == origination, "Invalid fund");
        require(asset != address(0), "Invalid asset address");

        uint256 assetBalance = IERC20(asset).balanceOf(address(this));
        require(assetBalance > 0, "Insufficient asset amount");

        if (IERC20(asset).allowance(address(this), AGGREGATION_ROUTER_V4) < assetBalance) {
            IERC20(asset).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
        }

        swapAssetToXtk(asset, _oneInchData, _callValue);

        claimXtkForStaking(fund);
    }

    function swapOnceClaimed(
        uint256 _fundIndex,
        uint256 _fundAssetIndex,
        bytes calldata _oneInchData,
        uint256 _callValue
    ) external onlyOwnerOrManager {
        require(_fundIndex > 0 && _fundIndex < nextFundIndex, "Invalid fund index");

        address fund = _indexToFund[_fundIndex];
        address[] memory fundAssets = _fundAssets[fund];

        require(_fundAssetIndex < fundAssets.length, "Invalid fund asset index");

        address fundAsset = fundAssets[_fundAssetIndex];
        if (fundAsset != ETH_ADDRESS) {
            uint256 assetBalance = IERC20(fundAsset).balanceOf(address(this));

            if (IERC20(fundAsset).allowance(address(this), AGGREGATION_ROUTER_V4) < assetBalance) {
                IERC20(fundAsset).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
            }
        }

        swapAssetToXtk(fundAsset, _oneInchData, _callValue);

        claimXtkForStaking(fund);
    }

    function swapAssetToXtk(
        address _fundAsset,
        bytes memory _oneInchData,
        uint256 _callValue
    ) private {
        require(_fundAsset == ETH_ADDRESS || _callValue == 0, "");

        (uint256 preActionFundAssetBalance, uint256 preActionXtkBalance) = snapshotTargetAssetAndXtkBalance(_fundAsset);

        bool success;
        // execute 1inch swap of eth/token for XTK
        (success, ) = AGGREGATION_ROUTER_V4.call{ value: _callValue }(_oneInchData);

        require(success, "Low-level call with value failed");

        (uint256 postActionFundAssetBalance, uint256 postActionXtkBalance) = snapshotTargetAssetAndXtkBalance(
            _fundAsset
        );

        emit AssetSwappedToXtk(
            _fundAsset,
            preActionFundAssetBalance - postActionFundAssetBalance,
            postActionXtkBalance - preActionXtkBalance
        );
    }

    function claimXtkForStaking(address _fund) private {
        uint256 xtkBalance = IERC20(xtk).balanceOf(address(this));
        IERC20(xtk).safeTransfer(managementStakingModule, xtkBalance);

        emit RevenueAccrued(_fund, xtkBalance, block.timestamp);
    }

    function snapshotTargetAssetAndXtkBalance(address _fundAsset) private view returns (uint256, uint256) {
        if (_fundAsset == ETH_ADDRESS) {
            return (address(this).balance, IERC20(xtk).balanceOf(address(this)));
        }
        return (IERC20(_fundAsset).balanceOf(address(this)), IERC20(xtk).balanceOf(address(this)));
    }

    /**
     * Governance function that adds xAssets
     * @param _fund      Address of xAsset
     * @param _assets    Assets charged as fee in xAsset
     */
    function addFund(address _fund, address[] memory _assets) external onlyOwner {
        require(_fundToIndex[_fund] == 0, "Already added");
        require(_assets.length > 0, "Empty fund assets");

        _indexToFund[nextFundIndex] = _fund;
        _fundToIndex[_fund] = nextFundIndex++;
        _fundAssets[_fund] = _assets;

        for (uint256 i = 0; i < _assets.length; ++i) {
            if (_assets[i] != ETH_ADDRESS) {
                if (IERC20(_assets[i]).allowance(address(this), AGGREGATION_ROUTER_V4) > 0) {
                    IERC20(_assets[i]).safeApprove(AGGREGATION_ROUTER_V4, 0);
                }
                IERC20(_assets[i]).safeApprove(AGGREGATION_ROUTER_V4, type(uint256).max);
            }
        }

        emit FundAdded(_fund, nextFundIndex - 1);
    }

    /**
     * Return token/eth balance of contract
     */
    function getRevenueTokenBalance(address _revenueToken) private view returns (uint256) {
        if (_revenueToken == ETH_ADDRESS) return address(this).balance;
        return IERC20(_revenueToken).balanceOf(address(this));
    }

    /**
     * Return index of _fund
     */
    function getFundIndex(address _fund) public view returns (uint256) {
        return _fundToIndex[_fund];
    }

    /**
     * Return fee assets of _fund
     */
    function getFundAssets(address _fund) public view returns (address[] memory) {
        return _fundAssets[_fund];
    }

    function setOriginationAddress(address _address) external onlyOwner {
        origination = _address;
    }

    /* ============ Fallbacks ============ */

    receive() external payable {}
}
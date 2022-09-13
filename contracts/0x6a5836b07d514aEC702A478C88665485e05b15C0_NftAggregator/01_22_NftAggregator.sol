// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./TransferHelper.sol";
import "./MarketplaceRegistry.sol";

error InactiveMarket();
error MAX_FEE_EXCEEDED();
error TradingNotOpen();
error UNMET_BASE_FEE();

interface INftProfile {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract NftAggregator is Initializable, ReentrancyGuardUpgradeable, UUPSUpgradeable, TransferHelper {
    address public owner;
    MarketplaceRegistry public marketplaceRegistry;
    uint256 public baseFee; // measured in WEI
    bool public openForTrades;
    bool public extraBool;
    uint256 public percentFeeToDao; // 0 - 10000, where 10000 = 100% of fees
    address public converter;
    address public nftProfile;
    address public dao;

    event NewConverter(address indexed _new);
    event NewNftProfile(address indexed _new);
    event NewOwner(address indexed _new);
    event NewDao(address indexed _new);

    function _onlyOwner() private view {
        require(msg.sender == owner);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function initialize(address _marketRegistry, address _cryptoPunk, address _mooncat) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __TransferHelper_init(_cryptoPunk, _mooncat);

        owner = msg.sender;
        marketplaceRegistry = MarketplaceRegistry(_marketRegistry);
        percentFeeToDao = 0;
        baseFee = 0;
        openForTrades = true;
        extraBool = true;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) external onlyOwner {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20Upgradeable(asset).balanceOf(address(this))));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721Upgradeable(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155Upgradeable(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

    // Emergency function: 
    function rescueMooncat(
        ERC721Details calldata erc721Details
    ) external onlyOwner {
        _transferMoonCat(erc721Details);
    }

    // Emergency function: 
    function rescuePunk(
        ERC721Details calldata erc721Details
    ) external onlyOwner {
        _transferCryptoPunk(erc721Details);
    }

    // GOV functions
    function setOwner(address _new) external onlyOwner {
        owner = _new;
        emit NewOwner(_new);
    }

    function setConverter(address _new) external onlyOwner {
        converter = _new;
        emit NewConverter(_new);
    }

    function setNftProfile(address _new) external onlyOwner {
        nftProfile = _new;
        emit NewNftProfile(_new);
    }

    function setDao(address _new) external onlyOwner {
        dao = _new;
        emit NewDao(_new);
    }

    function setDaoFee(uint256 _percentFeeToDao) external onlyOwner {
        if (_percentFeeToDao > 10000) revert MAX_FEE_EXCEEDED();
        percentFeeToDao = _percentFeeToDao;
    }

    // sets base fee in WEI (ETH min)
    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;
    }

    // one time approval for tokens
    function setOneTimeApproval(
        Approvals[] calldata _approvals
    ) external onlyOwner {
        for (uint256 i = 0; i < _approvals.length;) {
            IERC20Upgradeable(_approvals[i].token).approve(
                _approvals[i].operator,
                _approvals[i].amount
            );
            unchecked {
                ++i;
            }
        }
    }

    // helper function for collecting fee
    function _collectFee(
        FeeDetails calldata feeDetails    // [affiliateTokenId, ETH fee in Wei]
    ) internal {
        uint256 _profileTokenId = feeDetails._profileTokenId;
        uint256 _wei = feeDetails._wei;

        if (_wei != 0) {
            uint256 _weiToDao = _wei * (percentFeeToDao) / 10000;
            if (_weiToDao < baseFee) revert UNMET_BASE_FEE();

            if (percentFeeToDao != 0) {
                _transferEth(dao, _weiToDao);
            }

            _transferEth(INftProfile(nftProfile).ownerOf(_profileTokenId), _wei - _weiToDao);
        }
    }

    // helper function for trading
    function _trade(
        TradeDetails[] memory _tradeDetails
    ) internal {
        for (uint256 i = 0; i < _tradeDetails.length; ) {
            (address _proxy, bool _isLib, bool _isActive) = marketplaceRegistry.marketplaces(_tradeDetails[i].marketId);
            if (!_isActive) revert InactiveMarket();

            (bool success, ) = _isLib
                ? _proxy.delegatecall(_tradeDetails[i].tradeData)
                : _proxy.call{ value: _tradeDetails[i].value }(_tradeDetails[i].tradeData);

            _checkCallResult(success);

            unchecked {
                ++i;
            }
        }
    }

    function batchTradeWithETH(
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens,
        FeeDetails calldata feeDetails    // [affiliateTokenId, ETH fee in Wei]
    )
        external
        payable
        nonReentrant
    {
        if (!openForTrades) revert TradingNotOpen();

        _collectFee(feeDetails);

        _trade(tradeDetails);

        _returnDust(dustTokens);
    }

    function _conversionHelper(
        bytes[] memory _conversionDetails
    ) internal {
        for (uint256 i = 0; i < _conversionDetails.length; i++) {
            (bool success, ) = converter.delegatecall(_conversionDetails[i]);
            _checkCallResult(success);
        }
    }

    function batchTrade(
        ERC20Details calldata erc20Details,
        TradeDetails[] calldata tradeDetails,
        MultiAssetInfo calldata tradeInfo
    ) external payable nonReentrant {
        if (!openForTrades) revert TradingNotOpen();

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; ) {
            erc20Details.tokenAddrs[i].call(
                abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i])
            );

            unchecked {
                ++i;
            }
        }

        _collectFee(tradeInfo.feeDetails);

        _conversionHelper(tradeInfo.conversionDetails);

        _trade(tradeDetails);

        _returnDust(tradeInfo.dustTokens);
    }

    function multiAssetSwap(
        ERC20Details calldata erc20Details,
        ERC721Details[] calldata erc721Details,
        ERC1155Details[] calldata erc1155Details,
        TradeDetails[] calldata tradeDetails,
        MultiAssetInfo calldata tradeInfo
    ) payable external nonReentrant {
        if (!openForTrades) revert TradingNotOpen();
        
        _collectFee(tradeInfo.feeDetails);

        // transfer all tokens
        _transferFromHelper(
            erc20Details,
            erc721Details,
            erc1155Details
        );

        // Convert any assets if needed
        _conversionHelper(tradeInfo.conversionDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(tradeInfo.dustTokens);
    }
}
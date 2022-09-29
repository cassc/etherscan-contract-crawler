// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./swap/ChainlinkSwap.sol";
import "./utils/TransferHelper.sol";
import "./interfaces/ISwapFactoryExtended.sol";
import "./interfaces/ISwapExtras.sol";

contract SwapFactory {
    using ChainlinkLib for *;

    address[] private chainlinkWithApiFeedSwaps;
    address[] private chainlinkFeedSwaps;

    address factoryAdmin;
    //created sub-factiory for reducing code size abd renaub under limit
    ISwapFactoryExtended subFactory;

    mapping(address=> bool) private whitelistedPartners;

    // events

    event LinkFeedWithApiSwapCreated(
        address indexed sender,
        address swapAddress
    );
    event LinkFeedSwapCreated(address indexed sender, address swapAddress);
    event PartnerWhitlisted(address indexed partner, bool value);

    // modifiers
    modifier onlyFactoryAdminOrPartner() {
        _onlyFactoryAdminOrPartner();
        _;
    }
    
    modifier onlyFactoryAdmin(){
        _onlyFactoryAdmin();
        _;
    }


    constructor(address _factoryAdmin) {
        require(_factoryAdmin != address(0), "Invalid admin");
        factoryAdmin = _factoryAdmin;
    }

    function createLinkFeedWithApiSwap(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo,
        uint256 _chainlinkDepositAmount,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyFactoryAdminOrPartner {
       SwapLib.checkcommodityTokenddress(_commodityToken, _stableToken);
        require(
            _dexSettings.rateTimeOut >= 120 && _dexSettings.rateTimeOut <= 300,
            "wrong Duration!"
        );
        require(chainlinkWithApiFeedSwaps.length < 1000, "over limit");
        SwapLib.checkFee(_dexSettings.tradeFee);
        address swap = subFactory.createLinkFeedWithApiSwap(_commodityToken, _stableToken, _dexSettings, _apiInfo);
        ISwapExtras swapExtras = ISwapExtras(swap);
        //Swap swap = new Swap(_commodityToken, _stableToken, _dexSettings, _apiInfo);

        emit LinkFeedWithApiSwapCreated(msg.sender, address(swap));
        TransferHelper.safeTransferFrom(
            _chainlinkInfo.chainlinkToken,
            msg.sender,
            address(swap),
            _chainlinkDepositAmount
        );
        swapExtras.initChainlinkAndPriceInfo(_chainlinkInfo);
        //Depositing chainlink tokens to swap contract

        Ownable(swap).transferOwnership(msg.sender);

        chainlinkWithApiFeedSwaps.push(address(swap));
    }

    function createLinkFeedSwap(
        address _commodityToken,
        address _stableToken,
        address _commodityChainlinkAddress,
        SwapLib.DexSetting calldata _newDexSettings
    ) external onlyFactoryAdminOrPartner {
        SwapLib.checkcommodityTokenddress(_commodityToken, _stableToken);
        SwapLib.checkFee(_newDexSettings.tradeFee);
        require(chainlinkFeedSwaps.length < 1000, "You reached out limitation");

        ChainlinkSwap _clSwap = new ChainlinkSwap(
            _commodityToken,
            _stableToken,
            _commodityChainlinkAddress,
            _newDexSettings
        );
        emit LinkFeedSwapCreated(msg.sender, address(_clSwap));

        _clSwap.transferOwnership(msg.sender);
        chainlinkFeedSwaps.push(address(_clSwap));
    }

    function changeFactoryAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != factoryAdmin && _newAdmin != address(0),
            "invalid admin"
        );
        factoryAdmin = _newAdmin;
    }

    function getChainlinkWithApiFeedSwaps()
        external
        view
        returns (address[] memory)
    {
        return chainlinkWithApiFeedSwaps;
    }

    function getChainlinkFeedSwaps() external view returns (address[] memory) {
        return chainlinkFeedSwaps;
    }

    function setWhiteListPartner (address _partner, bool _value) 
        external
        onlyFactoryAdmin
    {
        require(whitelistedPartners[_partner]!=_value, "already true/false");
        whitelistedPartners[_partner] = _value;
        emit PartnerWhitlisted(_partner,_value);
    }

    function isWhiteListedPartner(address _partner)
        external
        view 
        returns(bool)
    {
        return whitelistedPartners[_partner];
    }

    function setSubFactory(address _subFactory) external onlyFactoryAdmin {
        require(_subFactory != address(0x00),"wrong address");
        subFactory = ISwapFactoryExtended(_subFactory);
    }

    // internal functions 

    function _onlyFactoryAdmin() internal view{
        require(msg.sender == factoryAdmin, "Not admin");
    }
    
    function _onlyFactoryAdminOrPartner() internal view {
        require(msg.sender == factoryAdmin || whitelistedPartners[msg.sender], "Not Admin/Partner");
    }
}
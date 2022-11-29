// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./swap/PoolChainlink.sol";
import "./utils/TransferHelper.sol";
import "./interfaces/IPoolFactoryExtended.sol";
import "./interfaces/IPoolExtras.sol";

contract PoolFactory {
    address[] private chainlinkWithApiFeedSwaps;
    address[] private chainlinkFeedSwaps;

    address public factoryAdmin;
    address public dexAdmin;

    //created sub-factiory for reducing code size and remain under limit
    IPoolFactoryExtended public subFactory;
    // mapping to track whitelisted partners
    mapping(address => bool) private whitelistedPartners;

    // events

    event LinkFeedWithApiSwapCreated(
        address indexed sender,
        address swapAddress
    );
    event LinkFeedSwapCreated(address indexed sender, address swapAddress);
    event PartnerWhitelisted(address indexed partner, bool value);
    event DexAdminChanged(address indexed newAdmin);
    // modifiers
    modifier onlyFactoryAdminOrPartner() {
        _onlyFactoryAdminOrPartner();
        _;
    }

    modifier onlyFactoryAdmin() {
        _onlyFactoryAdmin();
        _;
    }

    constructor(address _factoryAdmin, address _dexAdmin) {
        require(_factoryAdmin != address(0), "PF: invalid admin");
        require(_dexAdmin != address(0), "PF: invalid dex admin");

        factoryAdmin = _factoryAdmin;
        dexAdmin = _dexAdmin;
    }

    /// @notice Allows Factory admin or whitlisted partner to create Pool with API and chainlink support
    /// @param _commodityToken commodity token address
    /// @param _stableToken stable token address
    /// @param _dexSettings check ./lib/Lib.sol
    /// @param _stableFeedInfo check ./lib/Lib.sol feed and heartbeat of stable token of pool
    /// @param _chainlinkInfo check ./lib/Lib.sol
    /// @param _chainlinkDepositAmount amount of link tokens that will be used to pay as fee to make request to API
    /// @param _apiInfo check ./lib/Lib.sol
    function createLinkFeedWithApiPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo calldata _stableFeedInfo,
        ChainlinkLib.ChainlinkApiInfo calldata _chainlinkInfo,
        uint256 _chainlinkDepositAmount,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyFactoryAdminOrPartner {
        require(chainlinkWithApiFeedSwaps.length < 1000, "PF: out of limit");
        //overwritting dex admin just in case sent address was invalid admin
        //suggested by hacken
        _dexSettings.dexAdmin = dexAdmin;
        address swap = subFactory.createLinkFeedWithApiPool(
            _commodityToken,
            _stableToken,
            _dexSettings,
            _stableFeedInfo
        );

        IPoolExtras swapExtras = IPoolExtras(swap);
        emit LinkFeedWithApiSwapCreated(msg.sender, address(swap));

        //Depositing chainlink tokens to swap contract
        TransferHelper.safeTransferFrom(
            _chainlinkInfo.chainlinkToken,
            msg.sender,
            address(swap),
            _chainlinkDepositAmount
        );

        //set chainlink related information
        swapExtras.initChainlinkAndPriceInfo(_chainlinkInfo, _apiInfo);

        //transfer ownership of pool to creator
        Ownable(swap).transferOwnership(msg.sender);

        chainlinkWithApiFeedSwaps.push(address(swap));
    }

    /// @notice Allows Factory admin or whitlisted partner to create PoolChainlink
    /// @param _commodityToken commodity token address
    /// @param _stableToken stable token address
    /// @param _dexSettings check ./lib/Lib.sol
    /// @param _commodityFeedInfo check ./lib/Lib.sol feed and heartbeat of commodity token of pool
    /// @param _stableFeedInfo check ./lib/Lib.sol feed and heartbeat of stable token of pool
    function createChainlinkPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo calldata _commodityFeedInfo,
        SwapLib.FeedInfo calldata _stableFeedInfo
    ) external onlyFactoryAdminOrPartner {
        require(chainlinkFeedSwaps.length < 1000, "PF: out of limit");
        //overwritting dex admin just in case sent address was invalid admin
        //suggested by hacken
        _dexSettings.dexAdmin = dexAdmin;
        PoolChainlink _clSwap = new PoolChainlink(
            _commodityToken,
            _stableToken,
            _dexSettings,
            _commodityFeedInfo,
            _stableFeedInfo
        );
        emit LinkFeedSwapCreated(msg.sender, address(_clSwap));

        _clSwap.transferOwnership(msg.sender);
        chainlinkFeedSwaps.push(address(_clSwap));
    }
    
    /// @notice Allows Factory Admin to set new dexAdmin 
    /// @param _newAdmin new factory admin
    function changeDexAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != dexAdmin && _newAdmin != address(0),
            "PF: invalid admin"
        );
        dexAdmin = _newAdmin;
        emit DexAdminChanged(_newAdmin);
    }

    /// @notice Allows Factory Admin to set new Factory Admin
    /// @param _newAdmin new factory admin
    function changeFactoryAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != factoryAdmin && _newAdmin != address(0),
            "PF: invalid admin"
        );
        factoryAdmin = _newAdmin;
    }

    /// @return returns addresses of Pools with API + Chainlink price feed support
    function getChainlinkWithApiFeedSwaps()
        external
        view
        returns (address[] memory)
    {
        return chainlinkWithApiFeedSwaps;
    }

    /// @return returns addresses of Pools with Chainlink price feed support only
    function getChainlinkFeedSwaps() external view returns (address[] memory) {
        return chainlinkFeedSwaps;
    }

    /// @notice Allows Factory admin to add or remove a partner from whitelist
    /// @param _partner partner address to be whitelisted
    /// @param _value true: add to whitelist, false: remove from whitelist
    function setWhiteListPartner(address _partner, bool _value)
        external
        onlyFactoryAdmin
    {
        require(whitelistedPartners[_partner] != _value, "PF: no change");
        whitelistedPartners[_partner] = _value;
        emit PartnerWhitelisted(_partner, _value);
    }

    /// @param _partner address to check if whitelisted
    /// @return true: whitelisted, false:not-whitelisted
    function isWhiteListedPartner(address _partner)
        external
        view
        returns (bool)
    {
        return whitelistedPartners[_partner];
    }

    /// @notice Allows Factory admin to set SubFactory address(that helps in deploying pool with API+ chainlink support)
    /// @param _subFactory new SubFactory address
    function setSubFactory(address _subFactory) external onlyFactoryAdmin {
        require(_subFactory != address(0x00), "PF: invalid address");
        subFactory = IPoolFactoryExtended(_subFactory);
    }

    // internal functions

    function _onlyFactoryAdmin() internal view {
        require(msg.sender == factoryAdmin, "PF: not admin");
    }

    function _onlyFactoryAdminOrPartner() internal view {
        require(
            msg.sender == factoryAdmin || whitelistedPartners[msg.sender],
            "PF: not admin/partner"
        );
    }
}
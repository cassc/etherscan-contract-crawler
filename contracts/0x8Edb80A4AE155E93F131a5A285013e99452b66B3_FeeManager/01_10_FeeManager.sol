// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract FeeManager is AccessControlUpgradeable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyAdmin 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    uint256 public constant FEE_PERCENT_PRECISION = 1e18; // = 1%
    uint256 public constant MAX_PLATFORM_FEE_PERCENT = 20e18; // 20%

    uint256 public platformFeePercent;
    address public feeCollector;
    
    uint256 public discountedFeePercent;

    EnumerableSet.AddressSet private discountedTokens;

    function initialize(address _admin, address _feeCollector) 
        public initializer
    {
        __AccessControl_init_unchained();
        __FeeManager_init_unchained(_admin, _feeCollector);
    }

    function __FeeManager_init_unchained(address _admin, address _feeCollector)
        internal initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        feeCollector = _feeCollector;
    }

    function setPlatformFeePercent(uint256 _platformFeePercent)
        external onlyAdmin
    {
        require(_platformFeePercent <= MAX_PLATFORM_FEE_PERCENT, "platform fee is too high");
        require(_platformFeePercent != platformFeePercent, "same value");
        platformFeePercent = _platformFeePercent;
    }

    function setFeeCollector(address _feeCollector) 
        external onlyAdmin
    {
        require(_feeCollector != address(0), "invalid address");
        require(_feeCollector != feeCollector, "same address");
        feeCollector = _feeCollector;
    }

    function setDiscountedFeePercent(uint256 _discountedFeePercent)
        external onlyAdmin
    {
        require(_discountedFeePercent < platformFeePercent, "discounted fee is too high");
        discountedFeePercent = _discountedFeePercent;
    }

    function addDiscountedToken(address _token)
        external onlyAdmin
    {
        require(_token != address(0), "invalid address");
        discountedTokens.add(_token);
    }

    function removeDiscountedToken(address _token)
        external onlyAdmin
    {
        discountedTokens.remove(_token);
    }

    function getDiscountedTokens() external view returns (address[] memory _result)
    {
        _result = new address[](discountedTokens.length());
        for(uint256 i; i < discountedTokens.length(); i++) {
            _result[i] = discountedTokens.at(i);
        }
    }

    function calculateFee(address _token, uint256 _amount)
        external view returns (uint256 _feeAmount)
    {
        uint256 _feePercent = discountedTokens.contains(_token) ? discountedFeePercent : platformFeePercent;
        _feeAmount = _amount.mul(_feePercent)
            .div(FEE_PERCENT_PRECISION).div(100);
    }

    function getFeeCollector()
        external view returns (address)
    {
        return feeCollector;
    }

    uint256[48] private __gap;
}
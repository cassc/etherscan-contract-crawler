// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Presale01.sol";
import ".././Library/SafeMath.sol";
import ".././Library/Ownable.sol";
import ".././Interface/IERC20.sol";
import ".././Interface/IPresaleFactory.sol";
import ".././Interface/IUniswapV2Locker.sol";
import ".././Library/TransferHelper.sol";
import ".././Library/EnumerableSet.sol";


contract PresaleGenerator01 is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPresaleFactory public PRESALE_FACTORY;
    IPresaleSettings public PRESALE_SETTINGS;
    EnumerableSet.AddressSet private admins;
    uint256 public percentFee;

    struct PresaleParams {
        uint256 amount;
        uint256 tokenPrice;
        uint256 maxSpendPerBuyer;
        uint256 hardcap;
        uint256 softcap;
        uint256 startTime;
        uint256 endTime;
    }

    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }

    constructor(address _presaleFactory, address _presaleSettings) public {
        PRESALE_FACTORY = IPresaleFactory(_presaleFactory);
        PRESALE_SETTINGS = IPresaleSettings(_presaleSettings);
        admins.add(msg.sender);
        percentFee = 0;
    }
    
    function createPresale (
      address payable _presaleOwner,
      IERC20 _presaleToken,
      IERC20 _baseToken,
      uint256[7] memory uint_params,
      bool is_white_list,
      address payable _operator,
      uint256[] memory _distributionTime,
      uint256[] memory _unlockRate,
      bool _isRefund,
      uint256[] memory _refundInfo,
      address _wethAddress
    ) public payable {
        
        PresaleParams memory params;
        params.amount = uint_params[0];
        params.tokenPrice = uint_params[1];
        params.maxSpendPerBuyer = uint_params[2];
        params.hardcap = uint_params[3];
        params.softcap = uint_params[4];
        params.startTime = uint_params[5];
        params.endTime = uint_params[6];
        
        // Charge ETH fee for contract creation
        require(msg.value == PRESALE_SETTINGS.getEthCreationFee(), "FEE NOT MET.");
        require(params.amount >= 10000, "MIN DIVIS."); // minimum divisibility

        uint256 rateWithdrawRemaining;
        for(uint256 i = 0 ; i < _distributionTime.length ; i++) {
            rateWithdrawRemaining += _unlockRate[i];
            if(_distributionTime[i] <= block.timestamp) {
                revert("DISTRIBUTION TIME INVALID.");
            }
        } 

        if(_distributionTime.length > 0 && rateWithdrawRemaining != 1000) {
            revert("TOTAL RATE WITHDRAW REMAINING MUST EQUAL 100%.");
        }

        require(params.endTime.sub(params.startTime) > 0 && params.startTime > block.timestamp, "INVALID TIME SALE START/END.");
        require(params.tokenPrice.mul(params.hardcap) > 0, "INVALID PARAMS."); // ensure no overflow for future calculations
        Presale01 newPresale = (new Presale01){value: msg.value}(address(this), _wethAddress, address(PRESALE_SETTINGS));
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), params.amount);
        newPresale.init1(_presaleOwner, params.amount, params.tokenPrice, params.maxSpendPerBuyer, params.hardcap, params.softcap, params.startTime, params.endTime);
        newPresale.init2(_baseToken, _presaleToken, PRESALE_SETTINGS.getBaseFee(), PRESALE_SETTINGS.getTokenFee(), PRESALE_SETTINGS.getEthAddress(), PRESALE_SETTINGS.getTokenAddress());
        require(_refundInfo[0] >= 0 && _refundInfo[0] <= 1000, "INVALID REFUND FEE."); 
        newPresale.init3(is_white_list, _operator, percentFee, _distributionTime, _unlockRate, _isRefund, _refundInfo, owner());
        PRESALE_FACTORY.registerPresale(address(newPresale));
    }

    function updatePresaleFactory(address _presaleFactoryAddr) external onlyAdmin {
        require(_presaleFactoryAddr != address(0), "INVALID ADDRESS.");
        PRESALE_FACTORY = IPresaleFactory(_presaleFactoryAddr);
    }

    function updatePresaleSetting(address _presaleSetting) external onlyAdmin {
        require(_presaleSetting != address(0), "INVALID ADDRESS.");
        PRESALE_SETTINGS = IPresaleSettings(_presaleSetting);
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }

    function updatePercentFee(uint16 _percentFee) external onlyAdmin {
        percentFee = _percentFee;
    }

    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS.");
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }
}
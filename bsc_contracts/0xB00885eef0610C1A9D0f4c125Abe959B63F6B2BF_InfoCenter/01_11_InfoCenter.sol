// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFundCreator.sol";
import "./interfaces/IInfoCenter.sol";
import "./interfaces/IEDEFundQUtils.sol";
import "../core/interfaces/IVault.sol";
import "../oracle/interfaces/IDataFeed.sol";

contract InfoCenter is Ownable, IInfoCenter {
    using SafeMath for uint256;
    address public override stableToken;


    mapping (address => bool) public validVaults;
    mapping (address => address) public vaultPositionRouter;
    mapping (address => address) public vaultRouter;
    mapping (address => address) public vaultOrderbook;
    // mapping (address => address) public vaultElpManager;
    mapping (address => mapping (address => bool) ) public override routerApprovedContract;
    mapping (address => uint256[]) public managersFund;
    mapping (uint256 => address) public fundIdToAddress;

    IDataFeed dataFeed;
    IFundCreator fundCreator;
    IFundCreator fQUtilCreator;

    struct FundInfo {
        uint256 fundID;
        address manager;
        address fundAddress;
        uint256 fundTYpe;
    }
    FundInfo[] createdFund;


    function setVaultFacilities(address _vault, address _dest, uint256 _setId) public onlyOwner {
        if (_setId == 0)
            vaultRouter[_vault] = _dest;
        else if (_setId == 1)
            vaultPositionRouter[_vault] = _dest;
        else if (_setId == 2)
            vaultOrderbook[_vault] = _dest;
    }

    function setVaultStatus(address _vault, bool _status) external onlyOwner {
        validVaults[_vault] = _status;
    }

    function setStableToken(address _stableToken) external onlyOwner {
        stableToken = _stableToken;
    }

    function closeFund(address _router, address _contract) external onlyOwner {
        routerApprovedContract[_router][_contract] = false;
    }

    function setDataFeed(address _dataFee) external onlyOwner {
        dataFeed = IDataFeed(_dataFee);
    }
    
    function setFundCreator(address _fundCreator) external onlyOwner {
        fundCreator = IFundCreator(_fundCreator);
    }

    function setFQUtilCreator(address _fqundCreator) external onlyOwner {
        fQUtilCreator = IFundCreator(_fqundCreator);
    }

    function ownFunds(address _account) public view returns (uint256[] memory, address[] memory) {
        address[] memory _adds = new address[](managersFund[_account].length);
        for(uint i = 0; i < managersFund[_account].length; i++)
            _adds[i] = fundIdToAddress[managersFund[_account][i]];
        return (managersFund[_account], _adds);
    }

    function createFund(
                    uint8 _fundType,
                    address _validVault,
                    address[] memory _validFundingTokens,
                    address[] memory _validTradingTokens, uint256[] memory _mFeeSetting) public returns (address) {
        address _fundManager = msg.sender;
        require(validVaults[_validVault], "invalid trading vaults");
        require(_fundType > 0 && _fundType < 3, "invalid Fund Type");
        for (uint8 i = 0; i < _validFundingTokens.length; i++ )
            require(IVault(_validVault).whitelistedTokens(_validFundingTokens[i]), "not supported token");
        for (uint8 i = 0; i < _validTradingTokens.length; i++ )
            require(IVault(_validVault).whitelistedTokens(_validTradingTokens[i]), "not supported token");

        address _qUtils = _fundType == 2 ? fQUtilCreator.createQFUtil(_fundManager, address(this)): address(0);
        // EDEFund _newEdeFund = new EDEFund(_fundManager, address(_newQUtils), address(this), _validVault, _validFundingTokens, _validTradingTokens, _mFeeSetting);
        address fundAdd = fundCreator.createFund(_fundManager, _qUtils, address(this), _validVault, _validFundingTokens, _validTradingTokens, _mFeeSetting);
        if(_qUtils != address(0)) IEDEFundQUtils(_qUtils).setCorFund(fundAdd);
        
        if (fundAdd != address(0)){
            uint256 fundID = createdFund.length;
            createdFund.push(FundInfo(fundID, _fundManager, fundAdd, 0));
            managersFund[_fundManager].push(fundID);
            routerApprovedContract[vaultRouter[_validVault]][fundAdd] = true;
            fundIdToAddress[fundID] = fundAdd;
        }

        return fundAdd;
    }

    function getData(uint256 _sourceId, int256 _para) public override view returns (bool, int256){
        if (_sourceId == 0) return (true, _para);
        (int256 _data, uint256 updTime) = dataFeed.getRoundData(_sourceId, uint256(_para));
        if (updTime == 0) return (false, 0);
        else return (true, _data);
    }
}
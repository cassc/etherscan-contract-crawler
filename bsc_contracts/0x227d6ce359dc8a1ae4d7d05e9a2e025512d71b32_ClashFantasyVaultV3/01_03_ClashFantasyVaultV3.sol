// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IClashFantasyVaults {
    function withdraw(address _to, uint256 _amount) external;
}

contract ClashFantasyVaultV3 is Initializable {
    address private adminContract;
    address private externalContract;
    IClashFantasyVaults private contractVaultOne;
    IClashFantasyVaults private contractVaultTwo;

    uint256 private taxAmount;
    uint256 private primaryVaultToggle;

    struct WithdrawHistory {
        uint256 tax;
        uint256 amountRetired;
        uint256 amountReceived;
    }

    mapping(address => WithdrawHistory[]) private withdrawHistoryArr;
    uint256 private hasNftsTaxMax;

    IClashFantasyVaults private contractVaultThree;

    modifier onlyAdminOwner() {
        require(
            adminContract == msg.sender,
            "Only the contract admin owner can call this function"
        );
        _;
    }

    modifier onlyExternal() {
        require(externalContract == msg.sender, "contract invalid: Vault");
        _;
    }

    function initialize(
        IClashFantasyVaults _contractVaultOne,
        IClashFantasyVaults _contractVaultTwo,
        address _externalContract
    ) public initializer {
        adminContract = msg.sender;
        contractVaultOne = _contractVaultOne;
        contractVaultTwo = _contractVaultTwo;
        externalContract = _externalContract;
        taxAmount = 30;
        primaryVaultToggle = 1;
    }

    function setTaxAmount(uint256 _taxAmount) public onlyAdminOwner {
        taxAmount = _taxAmount;
    }
    
    function setHasNftsTaxMax(uint256 _hasNftsTaxMax) public onlyAdminOwner {
        hasNftsTaxMax = _hasNftsTaxMax;
    }

    function setPrimaryVaultToggle(uint256 _primaryVaultToggle) public onlyAdminOwner {
        primaryVaultToggle = _primaryVaultToggle;
    }

    function setExternalContract(address _address) public onlyAdminOwner {
        externalContract = _address;
    }

    function setVaults(IClashFantasyVaults _address, uint256 _typeOf) public onlyAdminOwner {
        if(_typeOf == 1){
            contractVaultOne = _address;
        }
        if(_typeOf == 2){
            contractVaultTwo = _address;
        }
        if(_typeOf == 3){
            contractVaultThree = _address;
        }
    }

    function getWidthdrawHistory(address _from) public view returns (WithdrawHistory[] memory) {
        return withdrawHistoryArr[_from];
    }

    function getTaxAmount() public view returns(uint256) {
        return taxAmount;
    }

    function withdraw(address _to, uint256 _amount, uint256 _hasNfts) public onlyExternal {
        uint256 preTaxAmount = taxAmount;
        if(_hasNfts != 0) {
            if( _hasNfts >= hasNftsTaxMax ) {
                preTaxAmount = preTaxAmount - hasNftsTaxMax;
            }else{
                preTaxAmount = preTaxAmount - _hasNfts;
            }
        }
        
        uint256 _tax = (_amount * preTaxAmount) / 100;
        uint256 _rest = _amount - _tax;

        if(primaryVaultToggle == 1){
            contractVaultOne.withdraw(_to, _rest);
        }
        if(primaryVaultToggle == 2){
            contractVaultTwo.withdraw(_to, _rest);
        }
        if(primaryVaultToggle == 3){
            contractVaultThree.withdraw(_to, _rest);
        }

        withdrawHistoryArr[_to].push(WithdrawHistory(preTaxAmount, _amount, _rest));
    }
}
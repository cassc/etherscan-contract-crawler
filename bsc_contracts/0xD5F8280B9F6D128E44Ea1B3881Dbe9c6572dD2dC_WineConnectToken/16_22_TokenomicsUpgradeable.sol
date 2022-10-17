// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TokenomicsUpgradeable is Initializable {

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint256 internal constant ZEROES = 10**18;
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 1000000000000 * ZEROES;
    uint256 internal constant NUMBER_OF_TOKENS_TO_SWAP_TO_LIQUIDITY = TOTAL_SUPPLY / 5000;
    address internal constant BURN_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    uint256 internal _reflectedSupply;

    enum FeeType { Liquidity, Rfi, Marketing, Event }

    struct Fee {
        FeeType name;
        uint256 value;
    }

    Fee[] internal buyFees;
    Fee[] internal sellFees;

    address internal marketingWallet;
    address internal eventWallet;
    
    uint256 internal sumOfFeesBuy;
    uint256 internal sumOfFeesSell;

    function __Tokenomics_init(address marketingAdr_, address eventAddr_) internal onlyInitializing {
        __Tokenomics_init_unchained(marketingAdr_, eventAddr_);
    }

    function __Tokenomics_init_unchained(address marketingAdr_, address eventAddr_) internal onlyInitializing {
        _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY));
        _addFees();

        marketingWallet = marketingAdr_;
        eventWallet = eventAddr_;
    }

    function _addBuyFee(FeeType name, uint256 value) private onlyInitializing {
        buyFees.push( Fee(name, value) );
        sumOfFeesBuy += value;
    }

    function _addSellFee(FeeType name, uint256 value) private onlyInitializing {
        sellFees.push( Fee(name, value) );
        sumOfFeesSell += value;
    }

    function _addFees() private onlyInitializing {
        _addBuyFee(FeeType.Rfi, 20);
        _addBuyFee(FeeType.Liquidity, 20);
        _addBuyFee(FeeType.Marketing, 30);
        _addBuyFee(FeeType.Event, 30);

        _addSellFee(FeeType.Rfi, 20);
        _addSellFee(FeeType.Liquidity, 20);
        _addSellFee(FeeType.Marketing, 30);
        _addSellFee(FeeType.Event, 30);
    }

    function _getBuyFeesCount() internal view returns (uint256){ 
        return buyFees.length; 
    }

    function _getSellFeesCount() internal view returns (uint256){ 
        return sellFees.length; 
    }

    function _getBuyFeeStruct(uint256 index) private view returns(Fee storage){
        require( index >= 0 && index < buyFees.length, "FeesSettings._getFeeStruct: Buy fee index out of bounds");
        return buyFees[index];
    }

    function _getSellFeeStruct(uint256 index) private view returns(Fee storage){
        require( index >= 0 && index < sellFees.length, "FeesSettings._getFeeStruct: Sell fee index out of bounds");
        return sellFees[index];
    }

    function _getFeeReceiver(FeeType name) internal view returns(address) {
        if ( name == FeeType.Marketing )
            return marketingWallet;
        else if ( name == FeeType.Event )
            return eventWallet;
        else 
            return address(this);
    }

    function _getBuyFee(uint256 index) internal view returns (FeeType, uint256, address){
        Fee memory fee = _getBuyFeeStruct(index);
        address receiver = _getFeeReceiver(fee.name);

        return ( fee.name, fee.value, receiver );
    }

    function _getSellFee(uint256 index) internal view returns (FeeType, uint256, address){
        Fee memory fee = _getSellFeeStruct(index);
        address receiver = _getFeeReceiver(fee.name);

        return ( fee.name, fee.value, receiver );
    }

    function updateBuyFeeValue(uint256 index, uint256 value) public virtual {
        Fee storage fee = _getBuyFeeStruct(index);

        sumOfFeesBuy -= fee.value;
        sumOfFeesBuy += value;

        fee.value = value;
    }

    function updateSellFeeValue(uint256 index, uint256 value) public virtual {
        Fee storage fee = _getSellFeeStruct(index);

        sumOfFeesSell -= fee.value;
        sumOfFeesSell += value;

        fee.value = value;
    }

    function updateMarketingWallet(address wallet) public virtual {
        marketingWallet = wallet;
    }

    function updateEventWallet(address wallet) public virtual {
        eventWallet = wallet;
    }

    function getSellFee(uint256 index) public view returns(FeeType, uint256, address) {
        return _getSellFee(index);
    }

    function getBuyFee(uint256 index) public view returns(FeeType, uint256, address) {
        return _getBuyFee(index);
    }

    function getBuySumOfFees() public view returns(uint256) {
        return sumOfFeesBuy;
    }

    function getSellSumOfFees() public view returns(uint256) {
        return sumOfFeesSell;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
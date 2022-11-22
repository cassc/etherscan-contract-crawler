// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Values is Ownable {

    event FeesUpdated(Fees oldFees, Fees newFees);

    error FeeNotFound();
    error FeeAlreadyAdded();

    struct Fee {
        address to;
        string name;
        uint percent;
    }

    struct Fees {
        Fee[] fees;
        uint reflection;
        uint sum;
        uint sumButReflection;
    }

    Fees public fees;
    Fees emptyFees;

    mapping(address => bool) _isBlacklisted;
    mapping(address => bool) excludedFromTaxes;

    IUniswapV2Router02 internal router;
    IUniswapV2Pair internal pair;

    uint public collectedTokenNumberToSwap = 10000 * 10**18;


    constructor(address _investmentAddress, address _marketingAddress, address _buybackAddress, address _teamAddress, address _routerAddress){
        router = IUniswapV2Router02(_routerAddress);
        address pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        pair = IUniswapV2Pair(pairAddress);

        setExcludeFromTaxes(address(this), true);
        setExcludeFromTaxes(owner(), true);

        _addFee("investment", _investmentAddress, 3);
        _addFee("marketing", _marketingAddress, 3);
        _addFee("buyback", _buybackAddress, 3);
        _addFee("team", _teamAddress, 2);
        _recalculateSum();
    }

    function _addFee(string memory _name, address _to, uint _percent) internal {
        int index = _getFeeIndex(_name);
        if(index != -1){
            revert FeeAlreadyAdded();
        }

        fees.fees.push(Fee(_to, _name, _percent));
    }

    function _recalculateSum() internal {
        Fees storage _fee = fees;

        uint sum = _fee.reflection;
        for(uint i = 0; i < _fee.fees.length; i++){
            sum += _fee.fees[i].percent;
        }

        _fee.sum = sum;
        _fee.sumButReflection = sum - _fee.reflection;

        fees = _fee;
    }

    function _getFeeIndex(string memory _name) view internal returns (int index){

        for(uint i = 0; i < fees.fees.length; i++){
            if(keccak256(bytes(fees.fees[i].name)) == keccak256(bytes(_name))){
                index = int(i);
                return index;
            }
        }

        index = -1;
    }

    function getFeeNames() view public returns (string[] memory names){
        names = new string[](fees.fees.length);
        for(uint i = 0; i < fees.fees.length; i++){
            names[i] = fees.fees[i].name;
        }
    }

    function getFeePercent(string memory _name) view public returns (uint percent) {
        percent = fees.fees[uint(_getFeeIndex(_name))].percent;
    }

    function getFeeAddress(string memory _name) view public returns (address to) {
        to = fees.fees[uint(_getFeeIndex(_name))].to;
    }

    function setFeePercent(string memory _name, uint _percent) external onlyOwner {
        int index = _getFeeIndex(_name);
        if(index == -1){
            revert FeeNotFound();
        }
        handleCollectedFees();

        fees.fees[uint(index)].percent = _percent;
        _recalculateSum();
    }

    function setFeeAddress(string memory _name, address _to) external onlyOwner {
        int index = _getFeeIndex(_name);
        if(index == -1){
            revert FeeNotFound();
        }

        fees.fees[uint(index)].to = _to;
    }

    function addFee(string memory _name, address _to, uint _percent) external onlyOwner {
        handleCollectedFees();
        _addFee(_name, _to, _percent);
        _recalculateSum();
    }

    function setReflectionFee(uint fee) public onlyOwner {
        handleCollectedFees();
        fees.reflection = fee;
        _recalculateSum();
    }

    function setCollectedTokenNumberToSwap(uint tokenNumber) public onlyOwner {
        collectedTokenNumberToSwap = tokenNumber * 10**18;
    }

    function setBlacklist(address addr, bool blacklisted) public onlyOwner {
        _isBlacklisted[addr] = blacklisted;
    }

    function isBlacklisted(address addr) public view returns(bool blacklisted) {
        blacklisted = _isBlacklisted[addr];
    }

    function setExcludeFromTaxes(address addr, bool excluded) public onlyOwner{
        excludedFromTaxes[addr] = excluded;
    }

    function swapToBnb(uint amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function handleCollectedFees() public virtual;
}
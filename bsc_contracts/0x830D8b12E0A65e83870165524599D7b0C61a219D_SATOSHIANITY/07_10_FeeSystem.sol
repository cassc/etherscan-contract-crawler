pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces.sol";

abstract contract FeeSystem is Ownable {
    event FeePercentChanged(string name, uint percent);
    event FeeAddressChanged(string name, address to);
    event FeeAdded(string name, address to, uint percent);
    event ReflectionPercentChanged(uint percent);
    event CollectedTokenAmountToSwapChanged(uint tokenAmount);
    event FeeExclusionChanged(address addr, bool excluded);
    event CollectedTokensSwappedToBnb(uint tokenAmount);

    error FeeNotFound();
    error FeeAlreadyAdded();

    struct Fee {
        address to;
        string name;
        uint percent;
    }

    struct Fees {
        Fee[] fees;
        uint reflectionPercent;
        uint feePercentSum;
        uint feePercentSumWithoutReflection;
    }

    Fees public fees;

    IUniswapV2Router02 internal immutable router;
    IUniswapV2Pair internal immutable pair;
    address internal immutable pairAddress;

    mapping(address => bool) public isExcludedFromFees;
    uint public collectedTokenAmountToSwap = 10000 * 10**18;

    constructor(address _routerAddress){
        router = IUniswapV2Router02(_routerAddress);
        pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        pair = IUniswapV2Pair(pairAddress);
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

        uint feePercentSum = _fee.reflectionPercent;
        for(uint i = 0; i < _fee.fees.length; i++){
            feePercentSum += _fee.fees[i].percent;
        }

        _fee.feePercentSum = feePercentSum;
        _fee.feePercentSumWithoutReflection = feePercentSum - _fee.reflectionPercent;

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
        emit FeePercentChanged(_name, _percent);
    }

    function setFeeAddress(string memory _name, address _to) external onlyOwner {
        int index = _getFeeIndex(_name);
        if(index == -1){
            revert FeeNotFound();
        }

        fees.fees[uint(index)].to = _to;
        emit FeeAddressChanged(_name, _to);
    }

    function setReflectionFee(uint _fee) public onlyOwner {
        handleCollectedFees();
        fees.reflectionPercent = _fee;
        _recalculateSum();
        emit ReflectionPercentChanged(_fee);
    }

    function setCollectedTokenAmountToSwap(uint _tokenAmount) public onlyOwner {
        collectedTokenAmountToSwap = _tokenAmount * 10**18;
        emit CollectedTokenAmountToSwapChanged(collectedTokenAmountToSwap);
    }

    function setExcludeFromFees(address _addr, bool _excluded) public onlyOwner{
        isExcludedFromFees[_addr] = _excluded;
        emit FeeExclusionChanged(_addr, _excluded);
    }


    function addFee(string memory _name, address _to, uint _percent) external onlyOwner {
        handleCollectedFees();
        _addFee(_name, _to, _percent);
        _recalculateSum();
        emit FeeAdded(_name, _to, _percent);
    }

    function swapToBnb(uint _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );

        emit CollectedTokensSwappedToBnb(_amount);
    }

    function handleCollectedFees() public onlyOwner {
        Fees memory _fee = fees;
        uint256 collectedFees = address(this).balance;

        if(collectedFees > 0){
            uint256 oneUnit = collectedFees / _fee.feePercentSumWithoutReflection;
            for(uint i = 0; i < _fee.fees.length; i++){
                uint transferAmount = oneUnit * _fee.fees[i].percent;
                payable(_fee.fees[i].to).transfer(transferAmount);
            }
        }
    }
}
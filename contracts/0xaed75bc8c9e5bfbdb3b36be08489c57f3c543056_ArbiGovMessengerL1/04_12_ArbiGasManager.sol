pragma solidity ^0.8.13;
import "src/arbi-fed/Governable.sol";


contract ArbiGasManager is Governable{
    address public gasClerk;
    address public refundAddress;
    mapping(bytes32 => uint) public functionGasLimit;
    uint public defaultGasLimit;
    uint public maxSubmissionCostCeiling;
    uint public maxSubmissionCost;
    uint public gasPriceCeiling;
    uint public gasPrice;

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }


    constructor(address _gov, address _gasClerk) Governable(_gov){
        gasClerk = _gasClerk;
        refundAddress = _gasClerk;
        defaultGasLimit = 10**6; //Same gas stipend as Optimism bridge
        maxSubmissionCost = 0.01 ether;
        gasPriceCeiling = 10**10; //10 gWEI
        gasPrice = 10**1; //1 gWEI
    }

    error OnlyGasClerk();
    error MaxSubmissionCostAboveCeiling();
    error GasPriceAboveCeiling();

    modifier onlyGasClerk(){
        if(msg.sender != gasClerk) revert OnlyGasClerk();
        _;
    }

    function setDefaultGasLimit(uint newDefaultGasLimit) external onlyGasClerk {
        defaultGasLimit = newDefaultGasLimit; 
    }

    function setFunctionGasLimit(address contractAddress, bytes4 functionSelector, uint gasLimit) external onlyGasClerk {
        bytes32 hash = keccak256(abi.encodePacked(functionSelector, contractAddress));
        functionGasLimit[hash] = gasLimit; 
    }

    function setMaxSubmissionCost(uint newMaxSubmissionCost) external onlyGasClerk {
        if(newMaxSubmissionCost > maxSubmissionCostCeiling) revert MaxSubmissionCostAboveCeiling();
        maxSubmissionCost = newMaxSubmissionCost;
    }

    function setGasPrice(uint newGasPrice) external onlyGasClerk {
        if(newGasPrice > gasPriceCeiling) revert GasPriceAboveCeiling();
        gasPrice = newGasPrice;
    }

    function getGasParams(address contractAddress, bytes4 functionSelector) public view returns(L2GasParams memory){
        L2GasParams memory gasParams;
        gasParams._maxSubmissionCost = maxSubmissionCost;
        gasParams._gasPriceBid = gasPrice;
        bytes32 hash = keccak256(abi.encodePacked(functionSelector, contractAddress));
        uint gasLimit = functionGasLimit[hash]; 
        if(gasLimit == 0) gasLimit = defaultGasLimit;
        gasParams._maxGas = gasLimit;
        return gasParams;
    }

    function setRefundAddress(address newRefundAddress) external onlyGov {
        refundAddress = newRefundAddress;
    }

    function setSubmissionCostCeiling(uint newSubmissionCostCeiling) external onlyGov {
       maxSubmissionCostCeiling = newSubmissionCostCeiling; 
    }

    function setGasPriceCeiling(uint newGasPriceCeiling) external onlyGov {
       gasPriceCeiling = newGasPriceCeiling; 
    }

    function setGasClerk(address newGasClerk) external onlyGov {
        gasClerk = newGasClerk;
    }
}
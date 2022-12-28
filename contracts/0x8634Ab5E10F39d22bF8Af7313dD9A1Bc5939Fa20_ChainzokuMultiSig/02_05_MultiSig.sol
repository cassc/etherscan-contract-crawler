// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Initialize.sol";

contract MultiSig is Initialize, Ownable{

    mapping(address => bool) public admins;
    mapping(address => bool) public contracts;
    mapping(string => mapping(address => uint256)) public transactions;
    mapping(string => mapping(address => address[])) public transactionsCallers;
    uint256 public adminsLength = 0;
    uint256 public minSigner = 0;

    constructor(address[] memory _multiSigAddress, uint256 _minSigner){
        require(_minSigner > 0 && _minSigner <= _multiSigAddress.length, "MultiSig: minSigner error");

        for(uint256 i = 0; i < _multiSigAddress.length; i++){
            admins[_multiSigAddress[i]] = true;
        }

        adminsLength = _multiSigAddress.length;
        minSigner = _minSigner;
    }

    modifier isMultiSigSender() {
        require(admins[_msgSender()] == true, "MultiSig: caller is not the valid address");
        _;
    }

    modifier isContractOrSig() {
        require(admins[_msgSender()] == true || contracts[_msgSender()] == true, "MultiSig: caller is not the valid address");
        _;
    }

    function init(address[] memory _contracts) public onlyOwner isNotInitialized{
        contracts[address(this)] = true;

        for(uint256 i = 0; i < _contracts.length; i++){
            contracts[_contracts[i]] = true;
        }
    }

    function addContract(address _address) public isMultiSigSender{
        require(contracts[_address] == false, "MultiSig: Contract already activated");
        validate("addContract");

        contracts[_address] = true;
    }
    function removeContract(address _address) public isMultiSigSender{
        require(contracts[_address] == true, "MultiSig: Contract not activated");
        validate("removeContract");

        contracts[_address] = false;
    }

    function addSign(address _address) public isMultiSigSender{
        require(admins[_address] == false, "MultiSig: Admin already activated");
        validate("addSign");

        admins[_address] = true;
        adminsLength += 1;
    }
    function removeSign(address _address) public isMultiSigSender{
        require(admins[_address] == true, "MultiSig: Admin not activated");
        validate("removeSign");

        admins[_address] = false;
        adminsLength -= 1;
    }
    function changeMinSigner(uint256 _minSigner) public isMultiSigSender{
        require(_minSigner > 0 && _minSigner <= adminsLength, "MultiSig: minSigner error");
        validate("changeMinSigner");

        minSigner = _minSigner;
    }

    function submitTx(string memory method, address _caller) public isMultiSigSender{

        for(uint256 i = 0; i < transactionsCallers[method][_caller].length; i++){
            require(transactionsCallers[method][_caller][i] != _msgSender(), "MultiSig: call already send");
        }

        transactions[method][_caller] += 1;
        transactionsCallers[method][_caller].push(_msgSender());
    }

    function revokeTx(string memory method, address _caller) public isMultiSigSender {
        _revokeTx(method,_caller);
    }
    function _revokeTx(string memory method, address _caller) internal {
        delete transactions[method][_caller];

        for(uint256 i = 0; i < transactionsCallers[method][_caller].length; i++){
            delete transactionsCallers[method][_caller][i];
        }
    }

    function isValid(string memory method, address _caller) public view returns(bool){
        return transactions[method][_caller] >= minSigner;
    }
    function missingValidator(string memory method, address _caller) public view returns(int256){
        return int256(minSigner) - int256(transactions[method][_caller]);
    }

    function validate(string memory method) public isContractOrSig{
        require(isValid(method, _msgSender()), "MultiSig: missing validator");
        _revokeTx(method,_msgSender());
    }

    function destroy() public isMultiSigSender {
        validate("SelfDestroy");

        selfdestruct(payable(owner()));
    }
}
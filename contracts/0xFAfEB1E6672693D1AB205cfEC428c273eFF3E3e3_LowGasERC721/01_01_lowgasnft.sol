pragma solidity ^0.8.0;

contract LowGasERC721 {
    address private _owner;
    mapping(address => uint256) private _walletBalances;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function mintNFT(address wallet) public {
        if (_walletBalances[wallet] > 0) {
            _walletBalances[wallet]++;
        } else {
            _walletBalances[wallet] = 1;
        }
    }

    function claimNFT(address wallet) public onlyOwner returns (bool success) {
        require(_walletBalances[wallet] > 0, "Wallet does not exist or balance is zero");
        _walletBalances[wallet]--;
        return true;
    }

    function getBalance(address wallet) public view returns (uint256) {
        return _walletBalances[wallet];
    }
}
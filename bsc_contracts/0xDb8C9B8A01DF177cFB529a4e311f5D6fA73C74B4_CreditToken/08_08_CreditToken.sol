// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract CreditToken is Ownable2Step, ERC20Burnable {

    struct Minter {
        uint quota; // mint额度
        uint usedQuota; // 已使用的额度
    }

    uint256 private immutable _cap;

    mapping(address => Minter) public minters;

    event AddMinter(address minter, uint quota);
    event UpdateMinter(address minter, uint oldQuota, uint newQuota);
    event RemoveMinter(address minter, uint quota, uint usedQuota);

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Only minter can call");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 cap_) ERC20(name_, symbol_) {
        require(cap_ > 0, "CreditToken: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

     /**
     * @dev Add a new minter.
     * @param _account Address of the minter
     * @param _quota mint quota of the minter
     */
    function addMinter(address _account, uint _quota) public onlyOwner {
        require(_account != address(0), "illegal minter");
        Minter storage minter = minters[_account];
        require(minter.quota == 0, "already minter");
        minter.quota = _quota;
        minter.usedQuota = 0;
        emit AddMinter(_account, _quota);
    }

    /**
     * @dev update a minter.
     * @param _account Address of the minter
     * @param _newQuota new mint quota of the minter
     */
    function updateMinter(address _account, uint _newQuota) public onlyOwner {
        Minter storage minter = minters[_account];
        require(minter.quota > 0, "not minter");
        require(minter.usedQuota <= _newQuota, "illegal quota");
        emit UpdateMinter(_account, minter.quota, _newQuota);
        minter.quota = _newQuota;
    }

    /**
     * @dev Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) public onlyOwner {
        Minter storage minter = minters[_account];
        require(minter.quota > 0, "not minter");
        emit RemoveMinter(_account, minter.quota, minter.usedQuota);
        minter.quota = 0;
        minter.usedQuota = 0;
    }


    /**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) public onlyMinter returns (uint) {
        require(_amount + totalSupply() <= cap(), "CreditToken: cap exceeded");
        Minter storage minter = minters[msg.sender];
        uint deltaQuota = minter.quota - minter.usedQuota;
        if (deltaQuota < _amount) {
            _amount = deltaQuota;
        }
        minter.usedQuota += _amount;
        _mint(_to, _amount);
        return _amount;
    }

    /**
     * @dev Return if the `_account` is a minter or not.
     * @param _account Address to check
     * @return True if the `_account` is minter
     */
    function isMinter(address _account) public view returns (bool) {
        return minters[_account].quota > 0;
    }
}
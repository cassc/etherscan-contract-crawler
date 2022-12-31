// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Buffer is Initializable, ReentrancyGuard {
    uint256 public totalReceived;
    uint256 public montageFee;
    uint256 public royaltyFeePercent;
    uint256 private totalShares;
    mapping(uint256 => uint256) public shareDetails;
    uint256 private shareDetailLength = 0;
    string private validKey;

    address public marketWallet; // wallet address for market fee
    address public owner;

    event UpdateFeeCheck(uint256 feePercent);
    event WithdrawnCheck(address to, uint256 amount);
    event UpdateSharesCheck(uint256[] share);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }
    //============ Function to Receive ETH ============
    receive() external payable {
        totalReceived += msg.value;
        montageFee = msg.value * shareDetails[4] / totalShares;
        _transfer(marketWallet, montageFee);
        montageFee  = 0;
    }
    //============ Function to Transfer Ownership ============
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    //============ Function to Update Royalty Shares ============
    function updateRoyaltyShares(uint256[] calldata _share) external onlyOwner {
        require(_share.length == shareDetailLength, "Shares info length is invalid");
        uint256 totalTmp = 0;
        for (uint256 i =0; i < _share.length; i++) {
            shareDetails[i] = _share[i];
            totalTmp += _share[i];
        }
        require(totalTmp > 0, "Sum of shares must be greater than 0");
        totalShares = totalTmp;

        emit UpdateSharesCheck(_share);
    }
    //============ Function to Update Valid Key ============
    function updateValidKey(string calldata _valid) external onlyOwner {
        validKey = _valid;
    }
    //============ Function to Withdraw ETH ============
    function withdraw(string calldata _validKey, uint256 _shareAmount) external nonReentrant {
        require(keccak256(abi.encodePacked(_validKey)) == keccak256(abi.encodePacked(validKey)), "Wrong validation Key.");
        address account = msg.sender;
        if (_shareAmount > 0) {
            _transfer(account, _shareAmount);
        }
        emit WithdrawnCheck(account, _shareAmount);
    }
    //============ Function to Initialize Contract ============
    function initialize(
        address _owner,
        uint256[] calldata _shares, // array of share percentage for every group
        address _marketWallet
    ) public payable initializer {
        shareDetailLength = _shares.length;
        require(shareDetailLength == 5, "Shares info length is invalid");
        for (uint256 i = 0; i < shareDetailLength; i++) {
            totalShares += _shares[i];
            shareDetails[i] = _shares[i];
        }
        require(totalShares > 0, "Sum of shares must be greater than 0");

        marketWallet = _marketWallet;
        owner = _owner;
        royaltyFeePercent = 1000;
    }
    //============ Function to Update Royalty Fee Percentage ============
    function updateFeePercent(uint256 _royaltyFeePercent) public onlyOwner {
        require(
            _royaltyFeePercent <= 10000,
            "Your royalty percentage is set as over 100%."
        );
        royaltyFeePercent = _royaltyFeePercent;
        emit UpdateFeeCheck(royaltyFeePercent);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    //============ Function to Transfer ETH to Address ============
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}
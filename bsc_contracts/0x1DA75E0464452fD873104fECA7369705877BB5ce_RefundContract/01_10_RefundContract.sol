// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IERC20BurnableUpgradeable.sol";

contract RefundContract is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Holder {
        address holderAddress;
        uint256 refundAmount;
        uint256 baseNVEAmount;
        bool isWithdraw;
        uint256 withdrawAt;
    }

    address public tokenAddr;
    address public refundTokenAddr;
    address[] private holders;
    address[] private withdrawList;

    mapping(address => uint256) private receivedAmount;
    mapping(address => Holder) private holderList;

    modifier onlyWhitelist() {
        require(isWhitelist(_msgSender()), "Refund: Your address not in the whitelist.");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _tokenAddr, address _refundTokenAddr) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        tokenAddr = _tokenAddr;
        refundTokenAddr = _refundTokenAddr;
    }

    function isWhitelist(address _holderAddress) public view returns (bool) {
        return contains(holders, _holderAddress);
    }

    function isWithdraw(address _holderAddress) public view returns (bool) {
        return contains(withdrawList, _holderAddress);
    }

    function getReceivedAmount(address _holderAddress) public view returns (uint256) {
        return receivedAmount[_holderAddress];
    }

    function getHoldersData() public view returns (address[] memory) {
        return holders;
    }

    function getReceivedData() public view returns (address[] memory) {
        return withdrawList;
    }

    function getHolderData(address _holderAddress) public view returns (uint256, uint256, bool, uint256) {
        require(_holderAddress != address(0), "Refund: Holder address can't include address 0");
        Holder storage holderStruct = holderList[_holderAddress];

        return (
            holderStruct.baseNVEAmount,
            holderStruct.refundAmount,
            holderStruct.isWithdraw,
            holderStruct.withdrawAt
        );
    }

    function refund() external nonReentrant onlyWhitelist {
        require(_msgSender() != address(0), "Refund: Holder address can't include address 0.");
        Holder storage holderStruct = holderList[_msgSender()];

        require(!holderStruct.isWithdraw, "Refund: You already got refund.");
        uint256 baseNVEBalances = IERC20Upgradeable(tokenAddr).balanceOf(_msgSender());
        if (baseNVEBalances != 0) {
            require(baseNVEBalances >= holderStruct.baseNVEAmount, "Refund: Your NVE balance is different with snapshot on 17/10/2022.");
            require(IERC20Upgradeable(tokenAddr).transferFrom(_msgSender(), address(this), baseNVEBalances), "Refund: Transfer NVE to contract failed.");
        }

        require(IERC20Upgradeable(refundTokenAddr).balanceOf(address(this)) >= holderStruct.refundAmount, "Refund: Contract don't have enough balance to transfer.");
        IERC20Upgradeable(refundTokenAddr).safeTransfer(_msgSender(), holderStruct.refundAmount);

        holderStruct.refundAmount = 0;
        holderStruct.isWithdraw = true;
        holderStruct.withdrawAt = block.timestamp;
        withdrawList.push(_msgSender());
        receivedAmount[_msgSender()] = holderStruct.refundAmount;
    }

    function updateHolderList(address _holderAddress, uint256 _refundAmount, uint256 _baseNVEAmount, bool isRemove) public onlyOwner {
        require(_holderAddress != address(0), "Refund: Holder address can't include address 0.");

        if (isRemove) {
            delete holderList[_holderAddress];
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == _holderAddress) {
                    delete holders[i];
                    holders.pop();
                }
            }
        } else {
            require(!contains(holders, _holderAddress), "Refund: You already added this address.");
            Holder storage holderStruct = holderList[_holderAddress];

            holders.push(_holderAddress);
            holderStruct.holderAddress = _holderAddress;
            holderStruct.refundAmount = _refundAmount;
            holderStruct.baseNVEAmount = _baseNVEAmount;
        }
    }

    function updateHolderInfo(address _holderAddress, uint256 _amount) external onlyOwner {
        require(_holderAddress != address(0), "Refund: Holder address can't include address 0.");
        require(contains(holders, _holderAddress), "Refund: This address not in the list.");

        Holder storage holderStruct = holderList[_holderAddress];
        uint256 baseNVEBalances = IERC20Upgradeable(tokenAddr).balanceOf(_holderAddress);

        if (_amount != 0) {
            holderStruct.baseNVEAmount = _amount;
        } else if (holderStruct.baseNVEAmount != baseNVEBalances) {
            holderStruct.baseNVEAmount = baseNVEBalances;
        }
    }

    function setTokenAddress(address _newTokenAddr) external onlyOwner {
        tokenAddr = _newTokenAddr;
    }

    function seRefundTokenAddress(address _refundTokenAddr) external onlyOwner {
        refundTokenAddr = _refundTokenAddr;
    }

    function withdrawToken(address _tokenAddr, address _beneficiary) external onlyOwner nonReentrant {
        require(_tokenAddr != address(0), "Refund: Token address can't include address 0");
        require(_beneficiary != address(0), "Refund: Beneficiary address can't include address 0");

        uint256 balances = IERC20Upgradeable(_tokenAddr).balanceOf(address(this));
        IERC20Upgradeable(_tokenAddr).safeTransfer(_beneficiary, balances);
    }

    function burnRemainingToken() external onlyOwner {
        uint256 balances = IERC20Upgradeable(tokenAddr).balanceOf(address(this));
        IERC20BurnableUpgradeable(tokenAddr).burn(balances);
    }

    function contains(address[] memory _listData, address _holder) internal pure returns (bool) {
        bool isHave = false;
        for (uint256 i = 0; i < _listData.length; i++) {
            if (_listData[i] == _holder) {
                isHave = true;
            }
        }
        return isHave;
    }
}
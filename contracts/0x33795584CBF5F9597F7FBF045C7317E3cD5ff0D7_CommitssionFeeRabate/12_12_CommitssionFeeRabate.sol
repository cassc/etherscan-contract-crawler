// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
//import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract CommitssionFeeRabate is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    string private _name;

    address public operator;

    mapping(address => uint256) public historyClaim;

    bytes32 public merkleTreeRoot;

    uint256 public startTime;

    uint256 public endTime;

    uint256 private constant LIMIT = 1000000000000000000;

    event SetOperator(address newOperator);

    event SetMerkleTreeRootSuccess(uint256 day, bytes32 merkleTreeRoot);

    event ClaimAmount(address to, uint256 transferAmount);

    event EmergencyWithdraw(address to, uint256 amount);

    address private refundAddress;

    receive() external payable {}

    modifier onlyOperator() {
        require(
            msg.sender == operator,
            "OKXGasAirDrop: not the operator address."
        );
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(
        string memory name_,
        address newOperator,
        address newRefundAddr
    ) public initializer {
        require(
            newOperator != address(0) && newRefundAddr != address(0),
            "init params error!"
        );
        __Ownable_init();
        __UUPSUpgradeable_init();

        _name = name_;
        operator = newOperator;
        refundAddress = newRefundAddr;
        __ReentrancyGuard_init();
        emit SetOperator(newOperator);
    }

    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit SetOperator(newOperator);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function getHistoryClaim(address userAddress)
        external
        view
        returns (uint256)
    {
        return historyClaim[userAddress];
    }

    function setMerkleTreeByDay(uint256 day, bytes32 root)
        external
        onlyOperator
    {
        merkleTreeRoot = root;
        emit SetMerkleTreeRootSuccess(day, root);
    }

    function setEventDate(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_startTime < _endTime, "startTime should less-than endTime");
        startTime = _startTime;
        endTime = _endTime;
    }

    function claim(uint256 amount, bytes32[] calldata proof)
        external
        nonReentrant
    {
        //start time and end time
        uint256 currentTime = block.timestamp;
        require(
            currentTime >= startTime && startTime > 0,
            "the event doesn't start"
        );
        require(currentTime < endTime, "the event has expired");

        //check LIMIT amount 检查兜底金额逻辑
        require(amount <= LIMIT, "The withdrawal limit has been reached!");

        uint256 historyAmount = historyClaim[msg.sender];

        //require(historyAmount+amount <= LIMIT,"The withdrawal limit has been reached!");

        //检查是否在默克尔树的证明路径内
        bool isVerify = _verifyProof(proof, msg.sender, amount);

        require(isVerify, "merkle tree verify failed!");

        //本次领取金额
        uint256 currentTransferAmount = amount - historyAmount;

        require(currentTransferAmount > 0, "you don't have claim amount!");
        require(
            address(this).balance >= currentTransferAmount,
            "Current balance is insufficient"
        );
        //转移补贴
        (bool success, ) = address(msg.sender).call{
            value: currentTransferAmount
        }("");
        if (!success) {
            revert("claim amount failed!");
        }
        //记录到累计领取金额中
        historyClaim[msg.sender] = historyAmount + currentTransferAmount;

        emit ClaimAmount(msg.sender, currentTransferAmount);
    }

    function _verifyProof(
        bytes32[] memory proof,
        address account,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        return MerkleProofUpgradeable.verify(proof, merkleTreeRoot, leaf);
    }

    //取走剩余金额
    function withdraw(uint256 amount) external onlyOwner {
        //payable(to).transfer(amount);
        (bool success, ) = address(refundAddress).call{value: amount}("");
        if (!success) {
            revert("withdraw amount failed!");
        }
        emit EmergencyWithdraw(refundAddress, amount);
    }

    function resetHistoryAmount(address[] calldata list) external onlyOwner {
        uint256 size = list.length;
        for (uint256 i = 0; i < size; ) {
            delete historyClaim[list[i]];

            unchecked {
                ++i;
            }
        }
    }
}
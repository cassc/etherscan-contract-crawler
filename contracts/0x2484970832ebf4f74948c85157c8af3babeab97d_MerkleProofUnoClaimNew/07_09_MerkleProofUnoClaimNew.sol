// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IMerkleProofUnoClaimOld} from "./interfaces/IMerkleProofUnoClaimOld.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";

contract MerkleProofUnoClaimNew is Ownable, ReentrancyGuard {
    address public immutable claimToken;
    // uint128 public constant cohortStartTime = 1633046401;
    bytes32 public merkleRoot;

    IMerkleProofUnoClaimOld oldClaimContract;

    struct UserInfo {
        uint128 claimedAmount;
        uint128 lastClaimTime;
    }

    mapping(address => UserInfo) private newUserInfo;

    constructor(address _token, IMerkleProofUnoClaimOld _oldClaimContract) {
        claimToken = _token;
        oldClaimContract = _oldClaimContract;
    }

    function userInfo(address _account) public view returns (UserInfo memory) {
        UserInfo memory actualInfo;

        actualInfo.claimedAmount = oldClaimContract.userInfo(_account).claimedAmount + newUserInfo[_account].claimedAmount;
        actualInfo.lastClaimTime = newUserInfo[_account].lastClaimTime > 0
            ? newUserInfo[_account].lastClaimTime
            : oldClaimContract.userInfo(_account).lastClaimTime;

        return actualInfo;
    }

    function airdropUNO(
        uint128 _index,
        address _account,
        uint128 _amount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        require(msg.sender == _account, "UnoRe: No msg sender.");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(uint256(_index), _account, uint256(_amount)));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "UnoRe: Invalid proof.");
        require(userInfo(_account).claimedAmount < _amount, "UnoRe: Claimed already.");

        uint128 amountForClaim = _amount - userInfo(_account).claimedAmount;
        TransferHelper.safeTransfer(claimToken, _account, amountForClaim);

        // Update claimed amount.
        newUserInfo[_account].claimedAmount += amountForClaim;
        newUserInfo[_account].lastClaimTime = uint128(block.timestamp);

        emit LogAirdropUNO(_index, _account, _amount, amountForClaim);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner nonReentrant {
        require(_merkleRoot != bytes32(0), "UnoRe: Zero merkleRoot bytes.");
        merkleRoot = _merkleRoot;
        emit LogSetMerkleRoot(address(this), _merkleRoot);
    }

    function setOldClaimContract(IMerkleProofUnoClaimOld _oldContract) external onlyOwner nonReentrant {
        IMerkleProofUnoClaimOld oldContractStored = oldClaimContract;
        oldClaimContract = _oldContract;
        emit LogSetOldClaimContract(address(oldContractStored), address(_oldContract));
    }

    function emergencyWithdraw(
        address _currency,
        address _to,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_to != address(0), "UnoRe: zero address reward");
        if (_currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                emit LogEmergencyWithdraw(address(this), _currency, _to, _amount);
            } else {
                if (address(this).balance > 0) {
                    uint256 withdrawAmount = address(this).balance;
                    TransferHelper.safeTransferETH(_to, withdrawAmount);
                    emit LogEmergencyWithdraw(address(this), _currency, _to, withdrawAmount);
                }
            }
        } else {
            if (IERC20Metadata(_currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(_currency, _to, _amount);
                emit LogEmergencyWithdraw(address(this), _currency, _to, _amount);
            } else {
                if (IERC20Metadata(_currency).balanceOf(address(this)) > 0) {
                    uint256 withdrawAmount = IERC20Metadata(_currency).balanceOf(address(this));
                    TransferHelper.safeTransfer(_currency, _to, withdrawAmount);
                    emit LogEmergencyWithdraw(address(this), _currency, _to, withdrawAmount);
                }
            }
        }
    }

    // This event is triggered whenever a call to #claim succeeds.
    event LogAirdropUNO(uint128 _index, address _account, uint128 _totalClaimAmount, uint128 _claimAmount);
    event LogSetMerkleRoot(address indexed _contract, bytes32 _merkleRoot);
    event LogSetOldClaimContract(address _oldContractStored, address _oldContract);
    event LogEmergencyWithdraw(address indexed _from, address indexed _currency, address _to, uint256 _amount);
}
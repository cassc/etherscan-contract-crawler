// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract AASTGClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint public constant VEST_DURATION = 26 weeks;
    uint public constant VEST_START_TIME = 1679155200;

    bytes32 immutable public MERKLE_ROOT;
    IERC20 immutable public stgToken;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public redeemed;

    event Redeemed(address _sender, uint _stgAmount);

    constructor(address _stgToken, bytes32 _merkleRoot) {
        require(_stgToken != address(0x0), "AASTGClaim: _token cannot be 0x0");
        stgToken = IERC20(_stgToken);
        MERKLE_ROOT = _merkleRoot;
    }

    function withdrawFees(address _account, uint256 _amount) external onlyOwner {
        stgToken.safeTransfer(_account, _amount);
    }

    // needs to be called first time a user redeems, sets the balance[_user] so subsequent vests dont require providing proof
    function redeemWithProof(address _user, uint256 _amount, bytes32[] calldata _proof) external {
        require(balance[_user] == 0, "AASTGClaim: User has already proven balance");

        bytes32 leaf = _leafEncode(_user, _amount);
        require(_verify(leaf, _proof), "AASTGClaim: Invalid merkle proof");

        balance[_user] = _amount;

        redeem(_user);
    }

    function redeem(address _user) public nonReentrant {
        require(balance[_user] > 0, "AASTGClaim: userHasNoBalance");
        require(block.timestamp > VEST_START_TIME, "AASTGClaim: vesting not started");

        uint256 vestSinceStart = block.timestamp.sub(VEST_START_TIME);
        if(vestSinceStart > VEST_DURATION){
            vestSinceStart = VEST_DURATION;
        }

        uint256 totalRedeemable = balance[_user].mul(vestSinceStart).div(VEST_DURATION);
        uint256 newRedeemable = totalRedeemable.sub(redeemed[_user]);
        require(newRedeemable > 0, "AASTGClaim: nothing to redeem");

        redeemed[_user] = totalRedeemable;

        stgToken.safeTransfer(_user, newRedeemable);

        emit Redeemed(_user, newRedeemable);
    }

    function redeemable(address _user) external view returns (uint256) {
        require(balance[_user] > 0, "AASTGClaim: userHasNoBalance");
        require(block.timestamp > VEST_START_TIME, "AASTGClaim: vesting not started");

        uint256 vestSinceStart = block.timestamp.sub(VEST_START_TIME);
        if(vestSinceStart > VEST_DURATION){
            vestSinceStart = VEST_DURATION;
        }

        uint256 totalRedeemable = balance[_user].mul(vestSinceStart).div(VEST_DURATION);
        uint256 newRedeemable = totalRedeemable.sub(redeemed[_user]);
        return newRedeemable;
    }

    function _leafEncode(address _account, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, MERKLE_ROOT, _leaf);
    }
}
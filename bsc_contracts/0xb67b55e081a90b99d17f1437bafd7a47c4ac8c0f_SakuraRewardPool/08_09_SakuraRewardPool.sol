// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IBEP20} from "../shared/IBEP20.sol";

contract SakuraRewardPool is
    Ownable,
    Pausable,
    EIP712("SakuraRewardPool", "1")
{
    struct PrizeConfig {
        uint256 fund;
        uint256 maxSupply;
    }

    event ApprovalSignerUpdated(address signer);
    event UserClaimed(address wallet, uint256 showId, uint256 prize);
    event PrizeConfigUpdated(uint256[] prizes, PrizeConfig[] configs);
    event RewardTokenUpdated(address token);
    event Withdraw(address wallet, uint256 amount);

    address public approvalSigner;
    IBEP20 public rewardToken;
    mapping(uint256 => PrizeConfig) public prizeConfig;
    // showId => (wallet => prize)
    mapping(uint256 => mapping(address => uint256)) public claimedEachShow;
    // showId => prize => supply
    mapping(uint256 => mapping(uint256 => uint256)) public prizeSupplyEachShow;
    bytes32 private constant _claimSigTypeHash =
        keccak256(
            "Claim(uint256 showId,uint256 expireAt,address wallet,uint256 prize)"
        );

    function setApprovalSigner(address signer) external onlyOwner {
        approvalSigner = signer;
        emit ApprovalSignerUpdated(signer);
    }

    function setPrizeConfig(
        uint256[] calldata prizes,
        PrizeConfig[] calldata configs
    ) external onlyOwner {
        require(
            prizes.length == configs.length,
            "Prizes and config length mismatch"
        );
        for (uint256 i = 0; i < configs.length; i++) {
            require(prizes[i] != 0, "Prize cannot be zero");
            require(configs[i].fund != 0, "Fund cannot be zero");
            require(configs[i].maxSupply != 0, "MaxSupply cannot be zero");
            prizeConfig[prizes[i]] = configs[i];
        }
        emit PrizeConfigUpdated(prizes, configs);
    }

    function setRewardToken(address token) external onlyOwner {
        rewardToken = IBEP20(token);
        emit RewardTokenUpdated(token);
    }

    function withdraw(uint256 amount) external onlyOwner {
        emit Withdraw(_msgSender(), amount);
        bool result = rewardToken.transfer(_msgSender(), amount);
        require(result, "BEP20 transfer failed");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claim(
        uint256 showId,
        uint256 expireAt,
        uint256 prize,
        bytes calldata signature
    ) external whenNotPaused {
        address wallet = _msgSender();
        require(
            _verifyClaimSignature(showId, expireAt, wallet, prize, signature),
            "Signature invalid"
        );
        require(expireAt > block.timestamp, "Signature has expired");
        require(
            claimedEachShow[showId][wallet] == 0,
            "User has claimed once on the show"
        );
        PrizeConfig memory config = prizeConfig[prize];
        require(config.fund > 0, "Prize not defined");
        require(
            prizeSupplyEachShow[showId][prize] < config.maxSupply,
            "Prizes have run out"
        );

        claimedEachShow[showId][wallet] = prize;
        prizeSupplyEachShow[showId][prize] += 1;
        emit UserClaimed(wallet, showId, prize);
        bool result = rewardToken.transfer(wallet, config.fund);
        require(result, "BEP20 transfer failed");
    }

    function _verifyClaimSignature(
        uint256 showId,
        uint256 expireAt,
        address wallet,
        uint256 prize,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(_claimSigTypeHash, showId, expireAt, wallet, prize)
            )
        );
        return ECDSA.recover(digest, signature) == approvalSigner;
    }
}
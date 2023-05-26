// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

enum RewardType {
    ERC721,
    ERC1155
}

struct Reward {
    address contractAddress;
    RewardType rewardType;
    uint256 token;
}

interface IKrystals {
    function burnTokens(uint256[] memory) external;

    function getTier(uint256) external view returns (uint256);

    function lockedTokens(uint256) external view returns (bool);
}

interface ITraits {
    function tokenize(
        address,
        uint256[] calldata,
        uint256[] calldata
    ) external;
}

struct Voucher {
    uint256[] krystals;
    uint256[] traitIds;
    uint256[] traitAmounts;
    uint256[] rewardIds;
    bytes signature;
}

contract Dekrystalizer is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    IKrystals public immutable krystalsContract;
    ITraits public immutable traitsContract;
    mapping(uint256 => Reward) public rewards;

    address public signer;
    address public vault;

    error NotAllowed();
    error InvalidSignature();

    constructor(address krystals, address traits) {
        krystalsContract = IKrystals(krystals);
        traitsContract = ITraits(traits);
    }

    function dekrystalize(Voucher memory voucher) public nonReentrant {
        checkSignature(voucher);
        krystalsContract.burnTokens(voucher.krystals);
        traitsContract.tokenize(
            msg.sender,
            voucher.traitIds,
            voucher.traitAmounts
        );

        for (uint256 i = 0; i < voucher.rewardIds.length; i++) {
            uint256 id = voucher.rewardIds[i];
            Reward memory r = rewards[id];

            if (r.rewardType == RewardType.ERC1155) {
                IERC1155 c = IERC1155(r.contractAddress);
                c.safeTransferFrom(vault, msg.sender, r.token, 1, "");
            } else if (r.rewardType == RewardType.ERC721) {
                IERC721 c = IERC721(r.contractAddress);
                c.transferFrom(vault, msg.sender, r.token);
            }
        }
    }

    function getTiers(uint256[] memory krystals)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](krystals.length);
        for (uint256 i = 0; i < krystals.length; i++) {
            ret[i] = krystalsContract.getTier(krystals[i]);
        }
        return ret;
    }

    function getLockedStatus(uint256[] memory krystals)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory ret = new bool[](krystals.length);
        for (uint256 i = 0; i < krystals.length; i++) {
            ret[i] = krystalsContract.lockedTokens(krystals[i]);
        }
        return ret;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setupReward(
        uint256 id,
        address contractAddress,
        RewardType rewardType,
        uint256 token
    ) external onlyOwner {
        rewards[id] = Reward(contractAddress, rewardType, token);
    }

    function setupRewards(uint256[] calldata ids, Reward[] calldata _rewards)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            rewards[id] = _rewards[i];
        }
    }

    function deleteReward(uint256 id) external onlyOwner {
        delete rewards[id];
    }

    function checkSignature(Voucher memory voucher) private view {
        if (
            signer !=
            ECDSA
                .toEthSignedMessageHash(
                    abi.encodePacked(
                        msg.sender,
                        voucher.krystals.length,
                        voucher.traitIds.length,
                        voucher.krystals,
                        voucher.traitIds,
                        voucher.traitAmounts,
                        voucher.rewardIds
                    )
                )
                .recover(voucher.signature)
        ) revert InvalidSignature();
    }
}
import "hardhat/console.sol";

// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time

// inheritance
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "../basic/GameFiTokenERC1155.sol";
import "../../../interface/core/token/custom/IGameFiBoxERC1155.sol";

// external interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../../interface/other/IHookContract.sol";

/**
 * @author Alex Kaufmann
 * @dev ERC1155 token contract for in-game loot boxes.
 */
contract GameFiBoxERC1155 is ERC721HolderUpgradeable, ERC1155HolderUpgradeable, GameFiTokenERC1155, IGameFiBoxERC1155 {
    address private _hookContract;

    mapping(uint256 => RewardSet[]) internal _rewardSetByBox;

    /**
     * @dev Sets a contract to be called when boxes are opened.
     * @param newHookContract Hook contract address.
     */
    function setHookContract(address newHookContract) external override onlyOwner {
        _hookContract = newHookContract;

        emit SetHookContract(_msgSender(), newHookContract, block.timestamp);
    }

    /**
     * @dev Sets item drop rules for a specific box.
     * Requirements:
     *
     * - `rewardSet` length cannot be more than 50.
     *
     * @param tokenId Target box token.
     * @param rewardSet Array of drop rules.
     */
    function setupRewardSet(uint256 tokenId, RewardSet[] memory rewardSet) external override onlyOwner {
        require(rewardSet.length > 0 && rewardSet.length <= 50, "GameFiBoxERC1155: wrong rewardSet length");

        delete _rewardSetByBox[tokenId];

        for (uint256 i = 0; i < rewardSet.length; i++) {
            // pre-validate rewardSet elem
            require(rewardSet[i].token != address(0), "GameFiBoxERC1155: zero token address");
            require(
                rewardSet[i].reiterations > 0 && rewardSet[i].reiterations <= 50,
                "GameFiBoxERC1155: wrong reiterations amount"
            );
            require(
                rewardSet[i].standart == TokenStandart.ERC20 || rewardSet[i].standart == TokenStandart.ERC1155,
                "GameFiBoxERC1155: wrong token standart"
            );
            require(
                rewardSet[i].tokenIds.length == rewardSet[i].amounts.length &&
                    rewardSet[i].amounts.length == rewardSet[i].probabilities.length,
                "GameFiBoxERC1155: different arrays length"
            );
            require(
                rewardSet[i].tokenIds.length > 0 && rewardSet[i].tokenIds.length < 50,
                "GameFiBoxERC1155: wrong arrays length"
            );

            // add rewardSet elem
            uint256 probabilitiesSum = 0;
            for (uint256 j = 0; j < rewardSet[i].tokenIds.length; j++) {
                probabilitiesSum += rewardSet[i].probabilities[j];
            }
            _rewardSetByBox[tokenId].push(rewardSet[i]);

            // post-validate rewardSet elem
            require(probabilitiesSum == 100_00, "GameFiBoxERC1155: probability sum must be equal 10000");
        }

        emit SetupRewardSet({sender: _msgSender(), tokenId: tokenId, rewardSet: rewardSet, timestamp: block.timestamp});
    }

    /**
     * @dev Opens a box from which objects fall out according to the established rules.
     * Requirements:
     *
     * - `boxAmount` length cannot be more than 0.
     *
     * @param tokenId Target box token.
     * @param boxAmount How many cases to open. (Important! Consider gas costs).
     */
    function openBox(uint256 tokenId, uint256 boxAmount, address rewardTarget) external override {
        require(boxAmount > 0, "GameFiBoxERC1155: wrong box amount");

        _burn(_msgSender(), tokenId, boxAmount);

        // try use a special hook
        uint256 externalEntropy = 0;
        if (_hookContract != address(0)) {
            externalEntropy = IHookContract(_hookContract).onBoxOpened(_msgSender(), tokenId, boxAmount);
        }

        // for every box
        for (uint256 k = 0; k < boxAmount; k++) {
            // for every reward set
            for (uint256 i = 0; i < _rewardSetByBox[tokenId].length; i++) {
                // for every reiteration
                for (uint256 j = 0; j < _rewardSetByBox[tokenId][i].reiterations; j++) {
                    (RewardSet memory actualizedRewardSet, uint256 higherBoundary) = _actualizeRewardSet(
                        _rewardSetByBox[tokenId][i]
                    );

                    // get random number
                    uint256 randomValue = _pseudoRandom(tokenId, k, i, j, externalEntropy) % higherBoundary;

                    // for every tokenIds
                    uint256 lowerBoundary;
                    for (uint256 l = 0; l < actualizedRewardSet.probabilities.length; l++) {
                        if (
                            randomValue >= lowerBoundary &&
                            randomValue < lowerBoundary + actualizedRewardSet.probabilities[l]
                        ) {
                            _reward(rewardTarget, actualizedRewardSet, l);

                            break;
                        } else {
                            lowerBoundary += actualizedRewardSet.probabilities[l];
                        }
                    }
                }
            }
        }

        emit OpenBox(_msgSender(), tokenId, boxAmount, block.timestamp);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(GameFiTokenERC1155, IERC165Upgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return (interfaceId == type(IGameFiBoxERC1155).interfaceId || super.supportsInterface(interfaceId));
    }

    /**
     * @dev Returns reward rules by specific token.
     * @param tokenId Target box token.
     * @return rewardSet array of drop rules
     */
    function getBoxRewards(uint256 tokenId) external view returns (RewardSet[] memory rewardSet) {
        return _rewardSetByBox[tokenId];
    }

    function _reward(
        address target,
        RewardSet memory rewardSet,
        uint256 index
    ) internal {
        if (rewardSet.standart == TokenStandart.ERC20) {
            IERC20Upgradeable(rewardSet.token).transfer(target, rewardSet.amounts[index]);
        } else if (rewardSet.standart == TokenStandart.ERC1155) {
            IERC1155Upgradeable(rewardSet.token).safeTransferFrom(
                address(this),
                target,
                rewardSet.tokenIds[index],
                rewardSet.amounts[index],
                "0x"
            );
        } else {
            revert();
        }

        emit BoxReward(
            _msgSender(),
            rewardSet.token,
            rewardSet.tokenIds[index],
            rewardSet.amounts[index],
            block.timestamp
        );
    }

    function _actualizeRewardSet(RewardSet memory originalRewardSet)
        internal
        view
        returns (RewardSet memory actualizedRewardSet, uint256 higherBoundary)
    {
        actualizedRewardSet = RewardSet({
            standart: originalRewardSet.standart,
            token: originalRewardSet.token,
            reiterations: originalRewardSet.reiterations,
            tokenIds: new uint256[](0),
            amounts: new uint256[](0),
            probabilities: new uint256[](0)
        });

        higherBoundary = 0;
        for (uint256 i = 0; i < originalRewardSet.amounts.length; i++) {
            uint256 realAmount = 2**255;
            // TODO
            // if (originalRewardSet.standart == TokenStandart.ERC20) {
            //     realAmount = IERC20Upgradeable(originalRewardSet.token).balanceOf(address(this));
            // } else if (originalRewardSet.standart == TokenStandart.ERC1155) {
            //     realAmount = IERC1155Upgradeable(originalRewardSet.token).balanceOf(address(this), originalRewardSet.tokenIds[i]);
            // } else {
            //     revert();
            // }

            if (realAmount >= originalRewardSet.amounts[i]) {
                // actualizedRewardSet.tokenIds.push(originalRewardSet.tokenIds[i]);
                // actualizedRewardSet.amounts.push(originalRewardSet.amounts[i]);
                // actualizedRewardSet.probabilities.push(originalRewardSet.probabilities[i]);
                higherBoundary += originalRewardSet.probabilities[i];
            }
        }

        return (originalRewardSet, higherBoundary);
    }

    function _pseudoRandom(
        uint256 salt1,
        uint256 salt2,
        uint256 salt3,
        uint256 salt4,
        uint256 salt5
    ) internal view returns (uint256) {
        return (
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        block.gaslimit,
                        salt1,
                        salt2,
                        salt3,
                        salt4,
                        salt5
                    )
                )
            )
        );
    }
}
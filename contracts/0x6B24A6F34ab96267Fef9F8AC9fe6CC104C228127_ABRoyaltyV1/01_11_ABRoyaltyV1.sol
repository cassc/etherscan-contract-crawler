//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title ABRoyaltyV1 Contract
 * @author Anotherblock Technical Team
 * @notice This contract is responsible for depositing & claiming Music Streaming royalty from anotherblock.io
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IABDropManager.sol';
import './interfaces/IERC721AB.sol';
import './ABErrors.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ABRoyaltyV1 is Ownable, ReentrancyGuard, ABErrors {
    using SafeERC20 for IERC20;

    // AnotherblockV1 address
    address public anotherblock;

    // Last TokenId allowed to claim the current payout for a given Drop ID
    mapping(uint256 => uint256) public lastTokenIdAllowed;

    // Total ETH deposited for a given Drop ID
    mapping(uint256 => uint256) public totalDeposited;

    // Total amount claimed for a given Token ID
    mapping(uint256 => uint256) public claimedAmounts;

    // Total amount not to be claimed for a given Token ID (mint post-deposit)
    mapping(uint256 => uint256) public ignoreAmounts;

    // Event emitted once royalties had been deposited and overdue paid to right holders
    event Deposited(
        uint256[] dropIds,
        uint256[] amounts,
        uint256[] overdues,
        address[] rightHolders
    );

    // Event emitted once user has claimed its royalties
    event Claimed(uint256[] dropIds, uint256[] amounts, address beneficiary);

    /**
     * @notice
     *  ABRoyaltyV1 contract constructor
     *
     * @param _anotherblock : Anotherblock contract address
     **/
    constructor(address _anotherblock) {
        anotherblock = _anotherblock;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Claim the amount of reward (in ETH or in Current Payout ERC20),
     *  for all the Token ID minted of all the given `_dropIds`
     *
     * @param _dropIds : Array containing all the drop that the user wishes to claim for
     * @param _to : used to delegate claim on behalf of an address
     */
    function claim(uint256[] memory _dropIds, address _to)
        external
        nonReentrant
    {
        // Check that _to is not the Zero-address
        if (_to == address(0)) revert ZeroAddress();

        uint256[] memory amountsPerDrop = new uint256[](_dropIds.length);
        uint256[] memory tokenIds;
        uint256 rewardPerToken;
        uint256 claimableEthAmount = 0;
        bool claimed = false;

        // Iterate over all Drop IDs
        for (uint256 i = 0; i < _dropIds.length; ++i) {
            IABDropManager.Drop memory drop = IABDropManager(anotherblock)
                .drops(_dropIds[i]);

            // Retrieve the Token Ids owned by the user
            tokenIds = IERC721AB(drop.nft).tokensOfOwner(_to);

            // Retrieve the amount of reward per token
            rewardPerToken =
                totalDeposited[_dropIds[i]] /
                drop.tokenInfo.supply;

            if (drop.currencyPayout == address(0)) {
                // Iterate over all users' token IDs
                for (uint256 j = 0; j < tokenIds.length; ++j) {
                    // Ensure the Token ID is eligible for claim and correspond to dropIds[i]
                    if (
                        tokenIds[j] >= drop.firstTokenIndex &&
                        tokenIds[j] <= lastTokenIdAllowed[_dropIds[i]]
                    ) {
                        uint256 amountPerToken = rewardPerToken -
                            claimedAmounts[tokenIds[j]] -
                            ignoreAmounts[tokenIds[j]];

                        claimableEthAmount += amountPerToken;

                        amountsPerDrop[i] += amountPerToken;

                        claimedAmounts[tokenIds[j]] = rewardPerToken;
                    }
                }
            } else {
                uint256 claimableAmount = 0;

                // Iterate over all users' token IDs
                for (uint256 j = 0; j < tokenIds.length; ++j) {
                    // Ensure the Token ID is eligible for claim
                    if (
                        tokenIds[j] >= drop.firstTokenIndex &&
                        tokenIds[j] <= lastTokenIdAllowed[_dropIds[i]]
                    ) {
                        uint256 amountPerToken = rewardPerToken -
                            claimedAmounts[tokenIds[j]] -
                            ignoreAmounts[tokenIds[j]];

                        claimableAmount += amountPerToken;

                        amountsPerDrop[i] += amountPerToken;

                        claimedAmounts[tokenIds[j]] = rewardPerToken;
                    }
                }
                if (claimableAmount > 0) {
                    claimed = true;
                    IERC20(drop.currencyPayout).safeTransfer(
                        _to,
                        claimableAmount
                    );
                }
            }
        }
        // Emit Claimed Event
        emit Claimed(_dropIds, amountsPerDrop, _to);

        // Check if there are something to claim (revert if not)
        if (claimableEthAmount == 0 && !claimed) {
            revert NothingToClaim();
        } else if (claimableEthAmount != 0) {
            // Pay the claimable amount to `_to`
            payable(_to).transfer(claimableEthAmount);
        }
    }

    //
    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

    /**
     * @notice
     *  Deposit `_amounts` of rewards (in ETH) for the given `_dropIds` to the contract
     *  Only the contract owner can perform this operation
     *
     * @param _dropIds : array containing the drop identifiers
     * @param _amounts : array containing the amount of ETH for each drop
     * @param _rightHolders : array containing the address of the right holders (to send overdue if needed)
     */
    function depositRewards(
        uint256[] memory _dropIds,
        uint256[] memory _amounts,
        address[] memory _rightHolders
    ) public payable onlyOwner {
        uint256 overdue;
        uint256[] memory overdues = new uint256[](_dropIds.length);
        uint256 uneligibleSupply;
        uint256 newlyMintedQuantity;
        uint256 totalETHAmount = 0;

        for (uint256 i = 0; i < _dropIds.length; ++i) {
            IABDropManager.Drop memory drop = IABDropManager(anotherblock)
                .drops(_dropIds[i]);

            if (lastTokenIdAllowed[_dropIds[i]] != 0) {
                newlyMintedQuantity =
                    drop.firstTokenIndex +
                    drop.sold -
                    1 -
                    lastTokenIdAllowed[_dropIds[i]];

                // For each newly minted token, assign the corresponding ignoreAmounts
                for (uint256 j = 0; j < newlyMintedQuantity; j++) {
                    ignoreAmounts[drop.firstTokenIndex + drop.sold - j - 1] =
                        totalDeposited[_dropIds[i]] /
                        drop.tokenInfo.supply;
                }
            }
            // Update the mapping storing the amount of ETH deposited per drop
            totalDeposited[_dropIds[i]] += _amounts[i];

            // Update the mapping storing the last token ID allowed to claim reward for this payout
            lastTokenIdAllowed[_dropIds[i]] =
                drop.firstTokenIndex +
                drop.sold -
                1;

            // Calculate the uneligible supply (token not minted)
            uneligibleSupply = drop.tokenInfo.supply - drop.sold;

            overdue = 0;
            if (drop.currencyPayout == address(0)) {
                totalETHAmount += _amounts[i];
            } else {
                IERC20(drop.currencyPayout).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
            }

            if (uneligibleSupply > 0) {
                // Calculate the overdue (Total Reward for all uneligible tokens)
                overdue =
                    (_amounts[i] * uneligibleSupply) /
                    drop.tokenInfo.supply;

                // Check if payout is in ETH
                if (drop.currencyPayout == address(0)) {
                    // Transfer the ETH overdue to the right holder address
                    payable(_rightHolders[i]).transfer(overdue);
                } else {
                    // Transfer the currency overdue to the right holder address
                    IERC20(drop.currencyPayout).safeTransfer(
                        _rightHolders[i],
                        overdue
                    );
                }
            }

            // Add the amount of overdue for this drop to the array (for Event log purpose)
            overdues[i] = overdue;
        }

        if (msg.value != totalETHAmount) revert IncorrectDeposit();

        // Emit event upon deposit
        emit Deposited(_dropIds, _amounts, overdues, _rightHolders);
    }

    /**
     * @notice
     *  Withdraw funds from this contract to Anotherblock Treasury address
     *  Only the contract owner can perform this operation
     *
     */
    function emergencyWithdraw() external onlyOwner {
        payable(IABDropManager(anotherblock).treasury()).transfer(
            address(this).balance
        );
    }

    /**
     * @notice
     *  Withdraw ERC20 from this contract to Anotherblock Treasury address
     *  Only the contract owner can perform this operation
     *
     */
    function emergencyWithdrawERC20(address _erc20) external onlyOwner {
        IERC20(_erc20).safeTransfer(
            IABDropManager(anotherblock).treasury(),
            IERC20(_erc20).balanceOf(address(this))
        );
    }
}
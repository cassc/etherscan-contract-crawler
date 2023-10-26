// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./libraries/TransferHelper.sol";

contract Campaign is
Initializable,
OwnableUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // campaign_id
    mapping(uint24 => CampaignInfo) private campaignInfos;
    // task_id -> campaign_id
    mapping(uint24 => uint24) private taskToCampaignId;
    // task_id, user address -> claimed
    mapping(uint24 => mapping(address => uint8)) private claimedTasks;
    // task_id -> isMultipleClaimed
    mapping(uint24 => uint8) private multipleClaim;
    // address -> boolean
    mapping(address => uint8) private isOperator;

    address private chappyToken;
    address private cookieToken;
    address private cutReceiver;
    address[] private admins;
    uint24 private newCampaignId;
    uint24 private newTaskId;
    uint16 private sharePercent; // 10000 = 100%
    uint72 private nonce;
    address private bananaToken;

    mapping(uint48 => uint8) private checkClaimedHL;

    error InvalidSignature();
    error UnavailableCampaign(uint24);
    error ClaimedTask(uint24);
    error InsufficentFund(uint24);
    error Unauthorized();
    error InvalidTime();
    error InvalidNumber();
    error SentNativeFailed();
    error NativeNotAllowed();
    error InvalidInput();
    error InvalidValue();
    error InvalidTip();
    error AlreadyOperators(address);
    error NotOperators(address);
    error ExceededTipAmount(address);

    event ChangeAdmin(address[]);
    event ChangeToken(address);
    event AddOperator(address);
    event RemoveOperator(address);
    event CreateCampaign(uint24, uint24[]);
    event AddTasks(uint24, uint24[]);
    event ChangeCutReceiver(address);
    event ChangeSharePercent(uint16);
    event FundCampaign(uint24, uint256);
    event WithdrawFundCampaign(uint24, uint256);
    event ClaimReward(uint24[][]);

    struct CampaignInfo {
        address rewardToken;
        address owner;
        uint256 amount;
        uint32 startAt;
        uint32 endAt;
    }

    struct CampaignInput {
        address rewardToken;
        uint256 amount;
        uint32 startAt;
        uint32 endAt;
    }

    function _checkAdmins() internal view {
        address[] memory memAdmins = admins;
        bool checked = false;
        for (uint16 idx = 0; idx < memAdmins.length; ++idx) {
            if (memAdmins[idx] == msg.sender) {
                checked = true;
                break;
            }
        }
        if (checked == false) {
            revert Unauthorized();
        }
    }

    function _checkOperator() internal view {
        bool checked = false;
        if (isOperator[msg.sender] == 1 || msg.sender == owner()) {
            checked = true;
        }
        if (checked == false) {
            revert Unauthorized();
        }
    }

    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    modifier byOperator() {
        _checkOperator();
        _;
    }

    function initialize(
        address operatorAddress,
        address chappyTokenAddress,
        address cookieTokenAddress,
        address cutReceiverAddress,
        address[] memory newAdmins,
        uint16 newSharePercent
    ) external initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        if (newSharePercent > 10000) {
            revert InvalidNumber();
        }
        isOperator[operatorAddress] = 1;
        admins = newAdmins;
        chappyToken = chappyTokenAddress;
        cookieToken = cookieTokenAddress;
        sharePercent = newSharePercent;
        cutReceiver = cutReceiverAddress;
    }

    function addOperator(address operatorAddress) external onlyOwner {
        if (isOperator[operatorAddress] == 1) {
            revert AlreadyOperators(operatorAddress);
        }
        isOperator[operatorAddress] = 1;
        emit AddOperator(operatorAddress);
    }

    function removeOperator(address operatorAddress) external onlyOwner {
        if (isOperator[operatorAddress] == 0) {
            revert NotOperators(operatorAddress);
        }
        isOperator[operatorAddress] = 0;
        emit RemoveOperator(operatorAddress);
    }

    function changeAdmins(address[] calldata newAdmins) external byOperator {
        admins = newAdmins;
        emit ChangeAdmin(newAdmins);
    }

    function changeTokenPlatform(address newToken) external byOperator {
        chappyToken = newToken;
        emit ChangeToken(newToken);
    }

    function changeCookieToken(address newToken) external byOperator {
        cookieToken = newToken;
        emit ChangeToken(newToken);
    }

    function changeBananaToken(address newToken) external byOperator {
        bananaToken = newToken;
        emit ChangeToken(newToken);
    }

    function createCampaign(
        bytes calldata data
    ) external payable onlyAdmins nonReentrant {
        (
        address rewardToken,
        uint256 amount,
        uint32 startAt,
        uint32 endAt,
        uint8[] memory isMultipleClaim
        ) = abi.decode(data,
            (
            address,
            uint256,
            uint32,
            uint32,
            uint8[]
            ));
        if (startAt >= endAt && endAt != 0) {
            revert InvalidTime();
        }
        if (
            rewardToken == address(0) && msg.value != amount
        ) {
            revert InvalidValue();
        }
        if (rewardToken != address(0) && msg.value != 0) {
            revert InvalidValue();
        }
        address clonedRewardToken = rewardToken;
        uint256 cutAmount = 0;
        uint256 actualAmount = 0;
        if (rewardToken != address(0)) {
            cutAmount = mulDiv(amount, sharePercent, 10000);
            actualAmount = uncheckSubtract(amount, cutAmount);
        } else {
            cutAmount = mulDiv(msg.value, sharePercent, 10000);
            actualAmount = uncheckSubtract(msg.value, cutAmount);
        }
        CampaignInfo memory campaignInfo = CampaignInfo(
            clonedRewardToken,
            msg.sender,
            actualAmount,
            startAt,
            endAt
        );
        uint24 taskId = newTaskId;
        uint24 campaignId = newCampaignId;
        campaignInfos[campaignId] = campaignInfo;
        uint24[] memory taskIds = new uint24[](isMultipleClaim.length);
        for (uint24 idx; idx < isMultipleClaim.length;) {
            if (isMultipleClaim[idx] == 1) {
                multipleClaim[taskId] = 1;
            }
            taskToCampaignId[taskId] = campaignId;
            taskIds[idx] = taskId;
        unchecked{++taskId;}
        unchecked{++idx;}
        }
        newTaskId = taskId;
    unchecked{++newCampaignId;}
        if (clonedRewardToken == address(0)) {
            if (msg.value != amount) {
                revert InvalidInput();
            }
            TransferHelper.safeTransferETH(cutReceiver, cutAmount);
        } else {
            if (msg.value != 0 ether) {
                revert NativeNotAllowed();
            }
            TransferHelper.safeTransferFrom(clonedRewardToken, msg.sender, address(this), actualAmount);
            TransferHelper.safeTransferFrom(clonedRewardToken, msg.sender, cutReceiver, cutAmount);
        }
        emit CreateCampaign(campaignId, taskIds);
    }

    function addTasks(
        bytes calldata data
    ) external onlyAdmins {
        (uint24 campaignId, uint8[] memory isMultipleClaim) = abi.decode(data, (uint24, uint8[]));
        CampaignInfo storage campaign = campaignInfos[campaignId];
        if (campaign.owner != msg.sender) {
            revert Unauthorized();
        }
        uint24 taskId = newTaskId;
        uint24[] memory taskIds = new uint24[](isMultipleClaim.length);
        for (uint24 idx; idx < isMultipleClaim.length;) {
            if (isMultipleClaim[idx] == 1) {
                multipleClaim[taskId] = 1;
            }
            taskToCampaignId[taskId] = campaignId;
            taskIds[idx] = taskId;
        unchecked{++taskId;}
        unchecked{++idx;}
        }
        newTaskId = taskId;
        emit AddTasks(campaignId, taskIds);
    }

    function changeCutReceiver(
        address receiver
    ) external byOperator nonReentrant {
        cutReceiver = receiver;
        emit ChangeCutReceiver(receiver);
    }

    function changeSharePercent(
        uint16 newSharePpercent
    ) external byOperator nonReentrant {
        if (newSharePpercent > 10000) {
            revert InvalidNumber();
        }
        sharePercent = newSharePpercent;
        emit ChangeSharePercent(newSharePpercent);
    }

    function fundCampaign(
        uint24 campaignId,
        uint256 amount
    ) external payable nonReentrant {
        CampaignInfo storage campaign = campaignInfos[campaignId];
        if (campaign.owner != msg.sender) {
            revert Unauthorized();
        }
        if (campaign.rewardToken == address(0) && msg.value != amount) {
            revert InvalidValue();
        }
        if (campaign.rewardToken != address(0) && msg.value != 0) {
            revert InvalidValue();
        }
        uint256 actualAmount = 0;
        if (campaign.rewardToken == address(0)) {
            if (msg.value != amount) {
                revert InvalidInput();
            }
            uint256 cutAmount = mulDiv(msg.value, sharePercent, 10000);
            actualAmount = uncheckSubtract(msg.value, cutAmount);
            campaign.amount = uncheckAdd(campaign.amount, actualAmount);
            if (cutAmount != 0) {
                TransferHelper.safeTransferETH(cutReceiver, cutAmount);
            }
        } else {
            uint256 cutAmount = mulDiv(amount, sharePercent, 10000);
            actualAmount = uncheckSubtract(amount, cutAmount);
            campaign.amount = uncheckAdd(campaign.amount, actualAmount);
            TransferHelper.safeTransferFrom(campaign.rewardToken, msg.sender, address(this), actualAmount);
            if (cutAmount != 0) {
                TransferHelper.safeTransferFrom(campaign.rewardToken, msg.sender, cutReceiver, cutAmount);
            }
        }
        emit FundCampaign(campaignId, actualAmount);
    }

    function withdrawFundCampaign(
        bytes calldata data,
        bytes calldata signature
    ) external nonReentrant {
        (uint24 campaignId, uint256 amount) = abi.decode(data, (uint24, uint256));
        bytes32 messageHash = getMessageHash(msg.sender, data);
        if (verifySignatureAndUpdateNonce(messageHash, signature) == false) {
            revert InvalidSignature();
        }
        CampaignInfo storage campaign = campaignInfos[campaignId];
        if (amount > campaign.amount) {
            revert InsufficentFund(campaignId);
        }
        campaign.amount = uncheckSubtract(campaign.amount, amount);
        if (campaign.owner != msg.sender) {
            revert Unauthorized();
        }
        if (campaign.rewardToken == address(0)) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(campaign.rewardToken, address(msg.sender), amount);
        }
        emit WithdrawFundCampaign(campaignId, amount);
    }

    function claimMergeReward(
        bytes calldata data,
        bytes calldata signature
    ) external nonReentrant payable {
        (
        uint24[][] memory taskIds,
        uint256[] memory rewards,
        uint256 valueC,
        address[] memory tipToken,
        address[] memory tipRecipient,
        uint256[] memory tipAmount,
        uint48 hlNonce
        ) = abi.decode(data, (uint24[][], uint256[], uint256, address[], address[], uint256[], uint48));
        if (valueC != msg.value) {
            revert InvalidValue();
        }
        if (tipToken.length != tipRecipient.length) {
            revert InvalidInput();
        }
        if (tipToken.length != tipAmount.length) {
            revert InvalidInput();
        }
        if (verifySignatureAndUpdateNonce(getMessageHash(msg.sender, data), signature) == false) {
            revert InvalidSignature();
        }
        uint256[] memory accRewardPerToken = new uint256[](taskIds.length);
        address[] memory addressPerToken = new address[](taskIds.length);
        uint8 tokenRewardCounter = 0;
        //        uint8 checkClaimCookie = 0;
        for (uint24 idx; idx < taskIds.length;) {
            uint24 campaignId = taskToCampaignId[taskIds[idx][0]];
            CampaignInfo memory campaign = campaignInfos[campaignId];
            if (campaign.startAt > block.timestamp) {
                revert UnavailableCampaign(campaignId);
            }
            if (rewards[idx] > campaign.amount) {
                revert InsufficentFund(campaignId);
            }
            //        todo uncomment checkClaimCookie, all claim is transfer
            //            if (campaign.rewardToken == cookieToken || campaign.rewardToken == bananaToken) {
            //                checkClaimCookie = 1;
            //            }
            for (uint24 id; id < taskIds[idx].length;) {
                uint24 taskId = taskIds[idx][id];
                if (
                    claimedTasks[taskId][msg.sender] == 1 &&
                    multipleClaim[taskId] != 1
                ) {
                    revert ClaimedTask(taskId);
                }
                claimedTasks[taskId][msg.sender] = 1;
            unchecked{++id;}
            }
            campaignInfos[campaignId].amount = uncheckSubtract(campaign.amount, rewards[idx]);
            if (tokenRewardCounter == 0 || addressPerToken[tokenRewardCounter - 1] != campaign.rewardToken) {
                accRewardPerToken[tokenRewardCounter] = rewards[idx];
                addressPerToken[tokenRewardCounter] = campaign.rewardToken;
            unchecked{++tokenRewardCounter;}
            } else {
                accRewardPerToken[tokenRewardCounter - 1] += rewards[idx];
            }
        unchecked{++idx;}
        }
        for (uint24 idx; idx < tokenRewardCounter;) {
            wrapLoop(
                tipToken,
                tipRecipient,
                tipAmount,
                addressPerToken[idx],
                accRewardPerToken[idx]
            );
        unchecked{++idx;}
        }
        //        todo uncomment checkClaimCookie, all claim is transfer
        if (msg.value > 0) {
            TransferHelper.safeTransferETH(cutReceiver, msg.value);
        }
        checkClaimedHL[hlNonce] = 1;
        emit ClaimReward(taskIds);
    }

    function getCookieToken() public
    view
    returns (address){
        return cookieToken;
    }

    function claimReward(
        bytes calldata data,
        bytes calldata signature
    ) external nonReentrant payable {
        (
        uint24[][] memory taskIds,
        uint256[] memory rewards,
        uint256 valueC,
        address[] memory tipToken,
        address[] memory tipRecipient,
        uint256[] memory tipAmount,
        uint48 hlNonce
        ) = abi.decode(data, (uint24[][], uint256[], uint256, address[], address[], uint256[], uint48));
        if (valueC != msg.value) {
            revert InvalidValue();
        }
        if (tipToken.length != tipRecipient.length) {
            revert InvalidInput();
        }
        if (tipToken.length != tipAmount.length) {
            revert InvalidInput();
        }
        if (verifySignatureAndUpdateNonce(getMessageHash(msg.sender, data), signature) == false) {
            revert InvalidSignature();
        }
        //        todo uncomment checkClaimCookie, all claim is transfer
        //        uint8 checkClaimCookie = 0;
        for (uint24 idx; idx < taskIds.length;) {
            uint24 campaignId = taskToCampaignId[taskIds[idx][0]];
            CampaignInfo memory campaign = campaignInfos[campaignId];
            if (campaign.startAt > block.timestamp) {
                revert UnavailableCampaign(campaignId);
            }
            if (rewards[idx] > campaign.amount) {
                revert InsufficentFund(campaignId);
            }
            if (idx > 0 && campaign.rewardToken == campaignInfos[taskToCampaignId[taskIds[idx - 1][0]]].rewardToken) {
                revert InvalidInput();
            }
            //        todo uncomment checkClaimCookie, all claim is transfer
            //            if (campaign.rewardToken == cookieToken || campaign.rewardToken == bananaToken) {
            //                checkClaimCookie = 1;
            //            }
            for (uint24 id; id < taskIds[idx].length;) {
                uint24 taskId = taskIds[idx][id];
                if (
                    claimedTasks[taskId][msg.sender] == 1 &&
                    multipleClaim[taskId] != 1
                ) {
                    revert ClaimedTask(taskId);
                }
                claimedTasks[taskId][msg.sender] = 1;
            unchecked{++id;}
            }
            campaignInfos[campaignId].amount = uncheckSubtract(campaign.amount, rewards[idx]);
            wrapLoop(
                tipToken,
                tipRecipient,
                tipAmount,
                campaign.rewardToken,
                rewards[idx]
            );
        unchecked{++idx;}
        }
        //        todo uncomment checkClaimCookie, all claim is transfer
        //        if (checkClaimCookie == 1) {
        if (msg.value > 0) {
            TransferHelper.safeTransferETH(cutReceiver, msg.value);
        }
        //        } else {
        //            if (msg.value != 0) {
        //                revert NativeNotAllowed();
        //            }
        //        }
        checkClaimedHL[hlNonce] = 1;
        emit ClaimReward(taskIds);
    }

    function wrapLoop(
        address[] memory tipToken,
        address[] memory tipRecipient,
        uint256[] memory tipAmount,
        address rewardToken,
        uint256 reward
    ) private {
        uint totalTipPerToken = 0;
        for (uint tipId; tipId < tipToken.length;) {
            if (rewardToken == tipToken[tipId] && reward >= tipAmount[tipId]) {
                if (rewardToken == address(0)) {
                    TransferHelper.safeTransferETH(tipRecipient[tipId], tipAmount[tipId]);
                } else {
                    TransferHelper.safeTransfer(rewardToken, tipRecipient[tipId], tipAmount[tipId]);
                }
                totalTipPerToken += tipAmount[tipId];
            }
        unchecked{++tipId;}
        }
        if (reward < totalTipPerToken) {
            revert ExceededTipAmount(rewardToken);
        }
        if (reward > totalTipPerToken) {
            if (rewardToken == address(0)) {
                TransferHelper.safeTransferETH(msg.sender, reward - totalTipPerToken);
            } else {
                TransferHelper.safeTransfer(rewardToken, msg.sender, reward - totalTipPerToken);
            }
        }
    }

    function uncheckSubtract(uint a, uint b) pure private returns (uint) {
    unchecked {return a - b;}
    }

    function uncheckAdd(uint a, uint b) pure private returns (uint) {
    unchecked {return a + b;}
    }

    function checkOperator(address operator) external view returns (uint8) {
        return isOperator[operator];
    }

    function getCookieAddress() external view returns (address) {
        return cookieToken;
    }

    function getBananaAddress() external view returns (address) {
        return bananaToken;
    }

    function getChappyAddress() external view returns (address) {
        return chappyToken;
    }

    function getNonce() external view returns (uint72) {
        return nonce;
    }

    function getCampaignInfo(
        uint24 campaignId
    ) external view returns (CampaignInfo memory) {
        return campaignInfos[campaignId];
    }

    function getTaskInCampaign(uint24 taskId) external view returns (uint24) {
        return taskToCampaignId[taskId];
    }

    function checkClaimedTasks(
        uint24[] calldata taskIds,
        address[] memory users,
        uint48[] calldata hlNonces
    ) external view returns (uint24[] memory) {
        if (taskIds.length != users.length) {
            revert InvalidInput();
        }
        uint24[] memory checkIndex = new uint24[](users.length);
        for (uint16 idx; idx < taskIds.length; ++idx) {
            uint24 taskId = taskIds[idx];
            if (claimedTasks[taskId][users[idx]] == 1 && checkClaimedHL[hlNonces[idx]] == 1) {
                checkIndex[idx] = 1;
            } else {
                checkIndex[idx] = 0;
            }
        }
        return checkIndex;
    }

    function getMessageHash(address user, bytes calldata data) private view returns (bytes32) {
        return keccak256(abi.encodePacked(nonce, user, data));
    }

    function verifySignatureAndUpdateNonce(
        bytes32 messageHash,
        bytes memory signature
    ) private returns (bool) {
        ++nonce;
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            messageHash
        );
        address signer = getSignerAddress(ethSignedMessageHash, signature);
        return isOperator[signer] == 1;
    }

    function getSignerAddress(
        bytes32 messageHash,
        bytes memory signature
    ) private pure returns (address) {
        return ECDSAUpgradeable.recover(messageHash, signature);
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
    unchecked {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0;
        // Least significant 256 bits of the product
        uint256 prod1;
        // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            return prod0 / denominator;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
        // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.

        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 twos = denominator & (~denominator + 1);
        assembly {
        // Divide denominator by twos.
            denominator := div(denominator, twos)

        // Divide [prod1 prod0] by twos.
            prod0 := div(prod0, twos)

        // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
            twos := add(div(sub(0, twos), twos), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * twos;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^8
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^16
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^32
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^64
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^128
        inverse *= 2 - denominator * inverse;
        // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inverse;
        return result;
    }
    }
}
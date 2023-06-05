// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ERC721SingleTokenDistributorInterface {
    function claim(uint256 ticketTokenId) external;

    function claimBulk(uint256[] calldata ticketTokenIds) external;

    function streamTotalSupply() external view returns (uint256);

    function getTotalClaimedBulk(uint256[] calldata ticketTokenIds)
        external
        view
        returns (uint256);

    function calculateClaimableAmount(uint256 ticketTokenId)
        external
        view
        returns (uint256 claimableAmount);
}

abstract contract ERC721SingleTokenDistributor is
    OwnableUpgradeable,
    ReentrancyGuard,
    ERC721SingleTokenDistributorInterface
{
    using Address for address;
    using Address for address payable;

    struct Entitlement {
        uint256 totalClaimed;
        uint256 lastClaimedAt;
    }

    // Config
    address public claimToken;
    address public ticketToken;

    // Map of ticket token ID -> entitlement
    mapping(uint256 => Entitlement) public entitlements;

    // Total amount claimed by all holders
    uint256 public streamTotalClaimed;

    /* EVENTS */

    event Claim(address claimer, uint256 ticketTokenId, uint256 releasedAmount);

    event ClaimBulk(
        address claimer,
        uint256[] ticketTokenIds,
        uint256 releasedAmount
    );

    function __ERC721SingleTokenDistributor_init(
        address _claimToken,
        address _ticketToken
    ) internal onlyInitializing {
        __Context_init();
        __Ownable_init();
        __ERC721SingleTokenDistributor_init_unchained(
            _claimToken,
            _ticketToken
        );
    }

    function __ERC721SingleTokenDistributor_init_unchained(
        address _claimToken,
        address _ticketToken
    ) internal onlyInitializing {
        claimToken = _claimToken;
        ticketToken = _ticketToken;
    }

    /* PUBLIC */

    receive() external payable {
        require(msg.value > 0);
        require(claimToken == address(0));
    }

    function claim(uint256 ticketTokenId) public nonReentrant {
        /* CHECKS */

        _beforeClaim(ticketTokenId);

        require(
            IERC721(ticketToken).ownerOf(ticketTokenId) == _msgSender(),
            "DISTRIBUTOR/NOT_NFT_OWNER"
        );

        uint256 claimableAmount = calculateClaimableAmount(ticketTokenId);
        require(claimableAmount > 0, "DISTRIBUTOR/NOTHING_TO_CLAIM");

        /* EFFECTS */

        entitlements[ticketTokenId].totalClaimed += claimableAmount;
        entitlements[ticketTokenId].lastClaimedAt = block.timestamp;

        streamTotalClaimed += claimableAmount;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(claimableAmount);
        } else {
            IERC20(claimToken).transfer(_msgSender(), claimableAmount);
        }

        /* LOGS */

        emit Claim(_msgSender(), ticketTokenId, claimableAmount);
    }

    function claimBulk(uint256[] calldata ticketTokenIds) public nonReentrant {
        uint256 totalClaimableAmount;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            _beforeClaim(ticketTokenIds[i]);

            /* CHECKS */
            require(
                IERC721(ticketToken).ownerOf(ticketTokenIds[i]) == _msgSender(),
                "DISTRIBUTOR/NOT_NFT_OWNER"
            );

            /* EFFECTS */
            uint256 claimableAmount = calculateClaimableAmount(
                ticketTokenIds[i]
            );

            if (claimableAmount > 0) {
                entitlements[ticketTokenIds[i]].totalClaimed += claimableAmount;
                entitlements[ticketTokenIds[i]].lastClaimedAt = block.timestamp;

                totalClaimableAmount += claimableAmount;
            }
        }

        streamTotalClaimed += totalClaimableAmount;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(totalClaimableAmount);
        } else {
            IERC20(claimToken).transfer(_msgSender(), totalClaimableAmount);
        }

        /* LOGS */

        emit ClaimBulk(_msgSender(), ticketTokenIds, totalClaimableAmount);
    }

    /* READ ONLY */

    function streamTotalSupply() public view returns (uint256) {
        return streamTotalClaimed + IERC20(claimToken).balanceOf(address(this));
    }

    function getTotalClaimedBulk(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256)
    {
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimed += entitlements[ticketTokenIds[i]].totalClaimed;
        }

        return totalClaimed;
    }

    function getTotalClaimableBulk(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256)
    {
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimable += calculateClaimableAmount(ticketTokenIds[i]);
        }

        return totalClaimable;
    }

    function calculateClaimableAmount(uint256 ticketTokenId)
        public
        view
        virtual
        returns (uint256 claimableAmount);

    // INTERNAL

    function _beforeClaim(uint256 ticketTokenId) internal virtual;
}
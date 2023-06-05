// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ERC721MultiTokenDistributorInterface {
    function claim(uint256 ticketTokenId) external;

    function claim(uint256 ticketTokenId, address claimToken) external;

    function claimBulk(uint256[] calldata ticketTokenIds) external;

    function claimBulk(uint256[] calldata ticketTokenIds, address claimToken)
        external;

    function streamTotalSupply() external view returns (uint256);

    function streamTotalSupply(address claimToken)
        external
        view
        returns (uint256);

    function getTotalClaimedBulk(uint256[] calldata ticketTokenIds)
        external
        view
        returns (uint256);

    function getTotalClaimedBulk(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) external view returns (uint256);

    function calculateClaimableAmount(uint256 ticketTokenId, address claimToken)
        external
        view
        returns (uint256 claimableAmount);
}

abstract contract ERC721MultiTokenDistributor is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuard,
    ERC721MultiTokenDistributorInterface
{
    using Address for address;
    using Address for address payable;

    struct Entitlement {
        uint256 totalClaimed;
        uint256 lastClaimedAt;
    }

    // Config
    address public ticketToken;

    // Map of ticket token ID -> claim token address -> entitlement
    mapping(uint256 => mapping(address => Entitlement)) public entitlements;

    // Map of claim token address -> Total amount claimed by all holders
    mapping(address => uint256) public streamTotalClaimed;

    /* EVENTS */

    event Claim(
        address claimer,
        uint256 ticketTokenId,
        address claimToken,
        uint256 releasedAmount
    );

    event ClaimBulk(
        address claimer,
        uint256[] ticketTokenIds,
        address claimToken,
        uint256 releasedAmount
    );

    function __ERC721MultiTokenDistributor_init(address _ticketToken)
        internal
        onlyInitializing
    {
        __Context_init();
        __ERC721MultiTokenDistributor_init_unchained(_ticketToken);
    }

    function __ERC721MultiTokenDistributor_init_unchained(address _ticketToken)
        internal
        onlyInitializing
    {
        ticketToken = _ticketToken;
    }

    /* PUBLIC */

    receive() external payable {
        require(msg.value > 0);
    }

    function claim(uint256 ticketTokenId) public {
        claim(ticketTokenId, address(0));
    }

    function claim(uint256 ticketTokenId, address claimToken)
        public
        nonReentrant
    {
        /* CHECKS */

        _beforeClaim(ticketTokenId, claimToken);

        require(
            IERC721(ticketToken).ownerOf(ticketTokenId) == _msgSender(),
            "DISTRIBUTOR/NOT_NFT_OWNER"
        );

        uint256 claimableAmount = calculateClaimableAmount(
            ticketTokenId,
            claimToken
        );
        require(claimableAmount > 0, "DISTRIBUTOR/NOTHING_TO_CLAIM");

        /* EFFECTS */

        entitlements[ticketTokenId][claimToken].totalClaimed += claimableAmount;
        entitlements[ticketTokenId][claimToken].lastClaimedAt = block.timestamp;

        streamTotalClaimed[claimToken] += claimableAmount;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(claimableAmount);
        } else {
            IERC20(claimToken).transfer(_msgSender(), claimableAmount);
        }

        /* LOGS */

        emit Claim(_msgSender(), ticketTokenId, claimToken, claimableAmount);
    }

    function claimBulk(uint256[] calldata ticketTokenIds) public nonReentrant {
        claimBulk(ticketTokenIds, address(0));
    }

    function claimBulk(uint256[] calldata ticketTokenIds, address claimToken)
        public
        nonReentrant
    {
        uint256 totalClaimableAmount;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            _beforeClaim(ticketTokenIds[i], claimToken);

            /* CHECKS */
            require(
                IERC721(ticketToken).ownerOf(ticketTokenIds[i]) == _msgSender(),
                "DISTRIBUTOR/NOT_NFT_OWNER"
            );

            /* EFFECTS */
            uint256 claimableAmount = calculateClaimableAmount(
                ticketTokenIds[i],
                claimToken
            );

            if (claimableAmount > 0) {
                entitlements[ticketTokenIds[i]][claimToken]
                    .totalClaimed += claimableAmount;
                entitlements[ticketTokenIds[i]][claimToken]
                    .lastClaimedAt = block.timestamp;

                totalClaimableAmount += claimableAmount;
            }
        }

        streamTotalClaimed[claimToken] += totalClaimableAmount;

        /* INTERACTIONS */

        if (claimToken == address(0)) {
            payable(address(_msgSender())).sendValue(totalClaimableAmount);
        } else {
            IERC20(claimToken).transfer(_msgSender(), totalClaimableAmount);
        }

        /* LOGS */

        emit ClaimBulk(
            _msgSender(),
            ticketTokenIds,
            claimToken,
            totalClaimableAmount
        );
    }

    /* READ ONLY */

    function streamTotalSupply() public view returns (uint256) {
        return streamTotalSupply(address(0));
    }

    function streamTotalSupply(address claimToken)
        public
        view
        returns (uint256)
    {
        if (claimToken == address(0)) {
            return streamTotalClaimed[claimToken] + address(this).balance;
        }

        return
            streamTotalClaimed[claimToken] +
            IERC20(claimToken).balanceOf(address(this));
    }

    function getTotalClaimedBulk(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256)
    {
        return getTotalClaimedBulk(ticketTokenIds, address(0));
    }

    function getTotalClaimedBulk(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) public view returns (uint256) {
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimed += entitlements[ticketTokenIds[i]][claimToken]
                .totalClaimed;
        }

        return totalClaimed;
    }

    function getTotalClaimableBulk(
        uint256[] calldata ticketTokenIds,
        address claimToken
    ) public view returns (uint256) {
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalClaimable += calculateClaimableAmount(
                ticketTokenIds[i],
                claimToken
            );
        }

        return totalClaimable;
    }

    function calculateClaimableAmount(uint256 ticketTokenId, address claimToken)
        public
        view
        virtual
        returns (uint256 claimableAmount);

    // INTERNAL

    function _beforeClaim(uint256 ticketTokenId, address claimToken)
        internal
        virtual;
}
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721EmissionReleaseExtension {
    function hasERC721EmissionReleaseExtension() external view returns (bool);

    function setEmissionRate(uint256 newValue) external;

    function setEmissionTimeUnit(uint64 newValue) external;

    function setEmissionStart(uint64 newValue) external;

    function setEmissionEnd(uint64 newValue) external;

    function releasedAmountUntil(uint64 calcUntil)
        external
        view
        returns (uint256);

    function emissionAmountUntil(uint64 calcUntil)
        external
        view
        returns (uint256);
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721EmissionReleaseExtension is
    IERC721EmissionReleaseExtension,
    Initializable,
    ERC165Storage,
    Ownable,
    ERC721MultiTokenStream
{
    // Number of tokens released every `emissionTimeUnit`
    uint256 public emissionRate;

    // Time unit to release tokens, users can only claim once every `emissionTimeUnit`
    uint64 public emissionTimeUnit;

    // When emission and calculating tokens starts
    uint64 public emissionStart;

    // When to stop calculating the tokens released
    uint64 public emissionEnd;

    /* INIT */

    function __ERC721EmissionReleaseExtension_init(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        __ERC721EmissionReleaseExtension_init_unchained(
            _emissionRate,
            _emissionTimeUnit,
            _emissionStart,
            _emissionEnd
        );
    }

    function __ERC721EmissionReleaseExtension_init_unchained(
        uint256 _emissionRate,
        uint64 _emissionTimeUnit,
        uint64 _emissionStart,
        uint64 _emissionEnd
    ) internal onlyInitializing {
        emissionRate = _emissionRate;
        emissionTimeUnit = _emissionTimeUnit;
        emissionStart = _emissionStart;
        emissionEnd = _emissionEnd;

        _registerInterface(type(IERC721EmissionReleaseExtension).interfaceId);
    }

    /* ADMIN */

    function setEmissionRate(uint256 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        emissionRate = newValue;
    }

    function setEmissionTimeUnit(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        emissionTimeUnit = newValue;
    }

    function setEmissionStart(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        emissionStart = newValue;
    }

    function setEmissionEnd(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        emissionEnd = newValue;
    }

    /* PUBLIC */

    function hasERC721EmissionReleaseExtension() external pure returns (bool) {
        return true;
    }

    function releasedAmountUntil(uint64 calcUntil)
        public
        view
        virtual
        returns (uint256)
    {
        return
            emissionRate *
            // Intentionally rounded down:
            ((calcUntil - emissionStart) / emissionTimeUnit);
    }

    function emissionAmountUntil(uint64 calcUntil)
        public
        view
        virtual
        returns (uint256)
    {
        return ((calcUntil - emissionStart) * emissionRate) / emissionTimeUnit;
    }

    /* INTERNAL */

    function _totalStreamReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        streamTotalSupply_;
        ticketTokenId_;
        claimToken_;

        if (block.timestamp < emissionStart) {
            return 0;
        } else if (emissionEnd > 0 && block.timestamp > emissionEnd) {
            return releasedAmountUntil(emissionEnd);
        } else {
            return releasedAmountUntil(uint64(block.timestamp));
        }
    }

    function _beforeClaim(
        uint256 ticketTokenId,
        address claimToken,
        address owner_
    ) internal virtual override {
        owner_;

        require(emissionStart < block.timestamp, "STREAM/NOT_STARTED");

        require(
            entitlements[ticketTokenId][claimToken].lastClaimedAt <
                block.timestamp - emissionTimeUnit,
            "STREAM/TOO_EARLY"
        );
    }
}
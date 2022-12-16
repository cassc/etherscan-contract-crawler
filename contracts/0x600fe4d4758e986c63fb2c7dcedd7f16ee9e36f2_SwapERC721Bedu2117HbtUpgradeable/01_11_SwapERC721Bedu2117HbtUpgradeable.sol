// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Bedu2117Upgradeable.sol";

contract SwapERC721Bedu2117HbtUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Swap contract config params
    uint256 private constant _TOKEN_LIMIT_PER_CLAIM_TRANSACTION = 30;
    address private _erc721Bedu2117CitAddress;
    address private _erc721Bedu2117HbtAddress;

    // Swap contract stats params
    uint256 private _usedCitTokenCount;

    // Mapping for used Cit token ids by addresses
    mapping(uint256 => address) private _usedCitTokenIds;
    // Mapping for received Hbt tokens
    mapping(address => uint256) private _receivedHbtTokens;

    // Auto pause timestamp
    uint256 private _pauseAfterTimestamp;

    // Emitted when `account` claim tokens
    event TokenClaimed(address indexed account, uint256 tokenCount);

    // Emitted when `pauseAfterTimestamp` updated
    event PauseAfterTimestampUpdated(uint256 pauseAfterTimestamp);

    function initialize(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) public virtual initializer {
        __SwapERC721Bedu2117Hbt_init(
            erc721Bedu2117CitAddress_,
            erc721Bedu2117HbtAddress_
        );
    }

    function __SwapERC721Bedu2117Hbt_init(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721Bedu2117Hbt_init_unchained(
            erc721Bedu2117CitAddress_,
            erc721Bedu2117HbtAddress_
        );
    }

    function __SwapERC721Bedu2117Hbt_init_unchained(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) internal initializer {
        require(erc721Bedu2117CitAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(erc721Bedu2117HbtAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        _erc721Bedu2117CitAddress = erc721Bedu2117CitAddress_;
        _erc721Bedu2117HbtAddress = erc721Bedu2117HbtAddress_;
        _pause();
    }

    function config() external view virtual returns (
        address erc721Bedu2117CitAddress,
        address erc721Bedu2117HbtAddress,
        uint256 tokenLimitPerClaimTransaction,
        uint256 pauseAfterTimestamp,
        uint256 currentTimestamp
    ) {
        return (
            _erc721Bedu2117CitAddress,
            _erc721Bedu2117HbtAddress,
            _TOKEN_LIMIT_PER_CLAIM_TRANSACTION,
            _pauseAfterTimestamp,
            block.timestamp
        );
    }

    function stats() external view virtual returns (uint256 usedCitTokenCount) {
        return _usedCitTokenCount;
    }

    function checkCitTokensUsageAddressesBatch(uint256[] memory citTokenIds_) external view virtual returns (address[] memory citTokenIdUsageAddresses) {
        citTokenIdUsageAddresses = new address[](citTokenIds_.length);
        for (uint256 i = 0; i < citTokenIds_.length; ++i) {
            citTokenIdUsageAddresses[i] = _usedCitTokenIds[citTokenIds_[i]];
        }
        return (
            citTokenIdUsageAddresses
        );
    }

    function receivedHbtTokens(address account_) external view virtual returns (uint256) {
        return _receivedHbtTokens[account_];
    }

    function getHolderCitTokensUsage(address citHolder_) public view virtual returns (uint256[] memory citTokenIds, bool[] memory citTokenIdUsages) {
        require(citHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        uint256 citHolderBalance = IERC721Bedu2117Upgradeable(_erc721Bedu2117CitAddress).balanceOf(citHolder_);
        citTokenIds = new uint256[](citHolderBalance);
        citTokenIdUsages = new bool[](citHolderBalance);
        for (uint256 i = 0; i < citHolderBalance; ++i) {
            citTokenIds[i] = IERC721Bedu2117Upgradeable(_erc721Bedu2117CitAddress).tokenOfOwnerByIndex(citHolder_, i);
            citTokenIdUsages[i] = _usedCitTokenIds[citTokenIds[i]] != address(0);
        }
        return (
            citTokenIds,
            citTokenIdUsages
        );
    }

    function getHolderNotUsedCitTokenIds(address citHolder_, uint256 maxTokenCount_) public view virtual returns (uint256[] memory notUsedCitTokenIds) {
        (uint256[] memory citTokenIds, bool[] memory citTokenIdUsages) = getHolderCitTokensUsage(citHolder_);
        uint256 notUsedCitTokenCount;
        for (uint256 i = 0; i < citTokenIdUsages.length; ++i) {
            notUsedCitTokenCount += citTokenIdUsages[i] ? 0 : 1;
        }
        uint256 tokensToReturn = notUsedCitTokenCount > maxTokenCount_
            ? maxTokenCount_
            : notUsedCitTokenCount;
        notUsedCitTokenIds = new uint256[](tokensToReturn);
        if (tokensToReturn != 0) {
            uint256 notUsedCitTokenIndex;
            for (uint256 i = 0; i < citTokenIdUsages.length; ++i) {
                if (!citTokenIdUsages[i]) {
                    notUsedCitTokenIds[notUsedCitTokenIndex] = citTokenIds[i];
                    notUsedCitTokenIndex++;
                    if (notUsedCitTokenIndex >= tokensToReturn) {
                        break;
                    }
                }
            }
        }
        return notUsedCitTokenIds;
    }

    function checkBeforeClaimByCitHolder(address citHolder_) public view virtual returns (uint256[] memory notUsedCitTokenIds) {
        // validate params
        require(citHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        // check contracts params
        require(!paused(), "SwapERC721Bedu2117: contract is paused");
        (bool mintingEnabled, ,) = IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).getContractWorkModes();
        require(mintingEnabled, "SwapERC721Bedu2117: erc721 minting is disabled");
        require(IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).isTrustedMinter(address(this)), "SwapERC721Bedu2117: erc721 wrong trusted minter");
        notUsedCitTokenIds = getHolderNotUsedCitTokenIds(citHolder_, _TOKEN_LIMIT_PER_CLAIM_TRANSACTION);
        require(notUsedCitTokenIds.length != 0, "SwapERC721Bedu2117: CIT holder has no tokens to use");
        return notUsedCitTokenIds;
    }

    function claimTokensByCitHolder() external virtual nonReentrant whenNotPaused {
        _claimTokensByCitHolder(_msgSender());
    }


    function paused() public view virtual override returns (bool) {
        return (block.timestamp > _pauseAfterTimestamp) || super.paused();
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function setPauseAfterTimestamp(uint256 pauseAfterTimestamp_) external virtual onlyOwner {
        _pauseAfterTimestamp = pauseAfterTimestamp_;
        emit PauseAfterTimestampUpdated(pauseAfterTimestamp_);
    }

    function _claimTokensByCitHolder(address citHolder_) internal virtual {
        // check before claim and get not used cit token ids
        uint256[] memory notUsedCitTokenIds = checkBeforeClaimByCitHolder(citHolder_);
        // update cit tokens usage and calculate tokenCount
        uint256 tokenCount;
        for (uint256 i = 0; i < notUsedCitTokenIds.length; ++i) {
            if (_usedCitTokenIds[notUsedCitTokenIds[i]] == address(0)) {
                _usedCitTokenIds[notUsedCitTokenIds[i]] = citHolder_;
                tokenCount++;
            }
        }
        require(tokenCount != 0, "SwapERC721Bedu2117: no CIT tokens for use");
        // update received tokens
        _receivedHbtTokens[citHolder_] += tokenCount;
        // update stats params
        _usedCitTokenCount += tokenCount;
        // mint HBT tokens
        IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).mintTokenBatchByTrustedMinter(citHolder_, tokenCount);
        emit TokenClaimed(citHolder_, tokenCount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721AUpgradeableOwnable} from "./utils/ERC721AUpgradeableOwnable.sol";
import {I_RICH_KIDZ_CLUB} from "./Interfaces/I_RICH_KIDZ_CLUB.sol";
import {I_RICH_KIDZ_COIN} from "./Interfaces/I_RICH_KIDZ_COIN.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Math.sol";

import {IChainlinkPriceFeed} from "./Interfaces/ChainlinkPriceFeed.sol";

contract RICH_KIDZ_CLUB_ERC721A is ERC721AUpgradeableOwnable, I_RICH_KIDZ_CLUB {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using MerkleProof for bytes32[];

    uint256 public constant MAX_SUPPLY = 7424;

    uint256 private constant PRECISION = 1 gwei;
    uint256 private constant ETH_DECIMALS = 1 ether;
    uint256 public constant MIN_STAKING_PERIOD = 30 days;
    uint256 private constant FIAT_TOKEN_DECIMALS = 10 ** 6;
    uint256 private constant PRICE_FEED_DECIMALS = 10 ** 8;
    uint256 private constant MONTH = 30 days;
    uint256 private constant PERCENT = 100;

    uint64 private constant BITPOS_WL = 32;

    I_RICH_KIDZ_COIN public immutable RKC;
    // Mainnet Ethereum
         IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant USDT =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    IChainlinkPriceFeed public constant ETH_ORACLE =
        IChainlinkPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); 

/*     IERC20 public constant USDC =
        IERC20(0x92B6d70E1745B264FAF7599e647e56b183D8Dc26);
    IERC20 public constant USDT =
        IERC20(0x92B6d70E1745B264FAF7599e647e56b183D8Dc26);

    IChainlinkPriceFeed public constant ETH_ORACLE =
        IChainlinkPriceFeed(0x0715A7794a1dc8e42615F059dD6e406A6594651A); */

    Phase internal _currentPhase;

    string private _revealedBaseURI;
    string private _unrevealedBaseURI;
    uint256 private _revealedUntil = 0;

    bytes32 public revealRoot;

    mapping(Phase => PhaseConfig) internal _config;
    mapping(uint256 => StakingStats) internal _staking;

    mapping(uint256 => bool) private _NFTRedeemed;

    uint256[] public prohibitedTokenIds;

    receive() external payable {}

    constructor(I_RICH_KIDZ_COIN rich_kidz_coin) {
        RKC = rich_kidz_coin;
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC721AUpgradeableOwnable_init(
            "RICH KID$ CLUB by CH Pulgarin",
            "RKC"
        );
        prohibitedTokenIds =  [7414,7417,7419];
        _revealedBaseURI = "ipfs://bafybeieno4eu4avapi2ugbxgvjzpfhgph4f2ove4cjpwltseckilsluxmq/revealed/";
        _unrevealedBaseURI = "ipfs://bafybeieno4eu4avapi2ugbxgvjzpfhgph4f2ove4cjpwltseckilsluxmq/unrevealed?tokenId=";
    }

    function isAnyTokenIdProhibited(uint256 startTokenId, uint256 quantity) public view returns (bool) {
        uint256 endTokenId = startTokenId + quantity - 1;
        for (uint256 i = 0; i < prohibitedTokenIds.length; i++) {
            if (prohibitedTokenIds[i] >= startTokenId && prohibitedTokenIds[i] <= endTokenId) {
                return true;
            }
        }
        return false;
    }

    function getTokensOf(
        address owner
    ) external view returns (uint256[] memory, bool[] memory) {
        uint256[] memory tokenList = _NFTOwners[owner];
        bool[] memory isRedeemed = new bool[](tokenList.length);

        for (uint256 i = 0; i < tokenList.length; i++) {
            isRedeemed[i] = _NFTRedeemed[tokenList[i]];
        }

        return (tokenList, isRedeemed);
    }

    function mint(
        address recipient,
        address currency,
        uint256 amount,
        uint256 permittedAmount,
        bytes32[] calldata proof
    ) external payable override {
        require(
            msg.sender == 0xee0161aA817E9d922c2003638969dD32AB9fd63d ||
                !isAnyTokenIdProhibited(_currentIndex, amount),
            "Cannot mint tokenId"
        );
        Phase phase = _currentPhase;
        uint256 supplyAfterMint = totalSupply() + amount;
        if (phase != Phase.PUBLIC)
            _addMintedToAux(recipient, phase, uint64(amount));

        // check whitelist restrictions and supply restrictions
        require(
            _mintAllowed(phase, permittedAmount, supplyAfterMint, proof),
            "mint disallowed"
        );

        // ensure payment is made
        _processPayment(IERC20(currency), _config[phase].mintingFee * amount);

        // now mint
        _mint(recipient, amount);
    }

    function markAsRedeemed(uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i = i.unsafeInc()) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Token does not exist");
            if (!_NFTRedeemed[tokenId]) _NFTRedeemed[tokenId] = true;
        }
    }

    // OWNER
    function allocate(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length, "lengths do not match");
        for (uint256 i = 0; i < recipients.length; i = i.unsafeInc()) {
            _mint(recipients[i], amounts[i]);
        }
        require(totalSupply() <= MAX_SUPPLY, "surpassed MAX_SUPPLY");
    }

    function setPhaseConfig(
        Phase phase,
        PhaseConfig memory config
    ) external override onlyOwner {
        require(phase != Phase.PAUSED, "paused has no config");
         require(config.mintingFee >= ETH_DECIMALS / 10, "fee not set"); 
        require(
            config.maxSupply > totalSupply() && config.maxSupply <= MAX_SUPPLY,
            "maxSupply out of bounds"
        );
        _config[phase] = config;
        emit PhaseConfigured(phase, config);
    }

    function setActivePhase(Phase phase) external override onlyOwner {
        require(_currentPhase != phase, "phase already active");
        if (phase != Phase.PAUSED) {
            PhaseConfig storage config = _config[phase];
             require(config.mintingFee >= ETH_DECIMALS / 10, "fee not set"); 
            require(
                config.maxSupply > totalSupply(),
                "need additional nfts to mint"
            );
            if (phase != Phase.PUBLIC) {
                require(config.root != bytes32(0), "root has to be set");
            }
        }
        _currentPhase = phase;
        emit PhaseChanged(phase);
    }

    function setRevealedUntil(uint256 tokenId) external onlyOwner {
        _revealedUntil = tokenId;
    }

    function setRevealedBaseURI(
        string memory newRevealedBaseURI
    ) external onlyOwner {
        _revealedBaseURI = newRevealedBaseURI;
    }

    function setUnrevealedBaseURI(
        string memory newUnrevealedURI
    ) external onlyOwner {
        _unrevealedBaseURI = newUnrevealedURI;
    }

    function setRevealRoot(bytes32 root) external onlyOwner {
        require(revealRoot != root);
        revealRoot = root;
    }

    function ownerRetrieve(address token) external onlyOwner {
        if (token == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
            USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
            USDT.safeTransfer(msg.sender, USDT.balanceOf(address(this)));
            msg.sender.call{value: address(this).balance}("");
            return;
        }
        if (token == address(0)) {
            msg.sender.call{value: address(this).balance}("");
            return;
        }
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    // INTERNAL

    function _processPayment(IERC20 currency, uint256 feeInWei) internal {
        if (currency == USDT || currency == USDC) {
            require(msg.value == 0, "send either token or ETH");
            // 18 eth     24 eth                32 usd                14 usd         6 usd
            uint256 fiatFee = (feeInWei *
                FIAT_TOKEN_DECIMALS *
                getLatestEthPrice()) /
                ETH_DECIMALS /
                PRICE_FEED_DECIMALS;
            currency.safeTransferFrom(msg.sender, address(this), fiatFee);
        } else {
            require(
                // overflow does not happen, both sides have dollarValue * 10 ** (18 + 6)
                msg.value >= feeInWei,
                "insufficient eth sent"
            );
        }
    }

    function _addMintedToAux(
        address minter,
        Phase phase,
        uint64 amount
    ) internal {
        uint64 aux = _getAux(minter);
        if (phase == Phase.FF) {
            _setAux(minter, aux + amount);
        } else {
            _setAux(minter, aux + (amount << BITPOS_WL));
        }
    }

    // INTERNAL VIEW
    function _mintAllowed(
        Phase phase,
        uint256 permittedAmount,
        uint256 totalSupplyAfter,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        PhaseConfig storage config = _config[phase];

        if (totalSupplyAfter > config.maxSupply) return false;

        if (phase != Phase.PUBLIC) {
            // in paused phase, _verifyProof will evaluate to false
            if (!_verifyProof(msg.sender, permittedAmount, config.root, proof))
                return false;

            // in WL phase and FF phase, everyone address has a minting limit, defined in the merkle tree
            return mintedInPhase(msg.sender, phase) <= permittedAmount;
        }
        return true;
    }

    function mintedInPhase(
        address who,
        Phase phase
    ) public view returns (uint256) {
        // phase can only be FF or WL
        uint64 aux = _getAux(who);
        if (phase == Phase.FF) return aux & type(uint32).max;

        return (aux >> 32) & type(uint32).max;
    }

    function _verifyProof(
        address who,
        uint256 amount,
        bytes32 root,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        return proof.verify(root, keccak256(abi.encodePacked(who, amount)));
    }

    // returns usd price with 8 decimals
    function getLatestEthPrice() public view returns (uint256) {
        uint256 price = uint256(ETH_ORACLE.latestAnswer());
        require(price > PRICE_FEED_DECIMALS, "price feed invalid");
        // adjust price feed for token decimals
        return price;
    }

    // VIEW
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId does not exist");
        if (tokenId > _revealedUntil) {
            return
                string(
                    abi.encodePacked(_unrevealedBaseURI, _toString(tokenId))
                );
        }
        bool isRedeemed = _NFTRedeemed[tokenId];
        if (isRedeemed)
            return
                string(
                    abi.encodePacked(
                        _revealedBaseURI,
                        _toString(tokenId),
                        "/NFTRedeemed"
                    )
                );
        else
            return
                string(
                    abi.encodePacked(
                        _revealedBaseURI,
                        _toString(tokenId),
                        "/NFTNoRedeemed"
                    )
                );
    }

    function getActivePhase() external view returns (Phase phase) {
        if (amountOfCurrentlyMintableNfts() == 0) {
            return Phase.PAUSED;
        }
        return _currentPhase;
    }

    function getPhaseConfig(
        Phase phase
    ) external view returns (PhaseConfig memory) {
        return _config[phase];
    }

    function getStakingStats(
        uint256 tokenId
    ) external view returns (StakingStats memory stk) {
        require(_exists(tokenId), "nft not minted");
        if (isStaked(tokenId)) {
            stk = _staking[tokenId];
        } else {
            stk = StakingStats(
                _staking[tokenId].baseRate,
                0,
                0,
                0,
                0,
                address(0)
            );
        }
    }

    function amountOfCurrentlyMintableNfts() public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 currentMaxSupply = _config[_currentPhase].maxSupply;

        return
            currentMaxSupply > currentSupply
                ? currentMaxSupply - currentSupply
                : 0;
    }

    // STAKING
    function stake(
        uint256[] calldata tokenIds,
        uint256[] calldata lengths,
        bool isRestake
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 length = lengths[i];

            StakingStats storage stk = _staking[tokenId];

            if (isRestake) {
                require(stk.staker == msg.sender, "staker == sender");
            } else {
                require(ownerOf(tokenId) == msg.sender, "owner == sender");
                _transferForStaking(msg.sender, address(this), tokenId, true);
            }

            uint72 rate = stk.baseRate;

            stk.staker = msg.sender;
            stk.lastUpdate = uint40(block.timestamp);
            stk.bonus = uint104(_calculateBonus(length, rate));
            stk.end = uint40(block.timestamp + length);
            stk.minStaking = uint40(block.timestamp + MONTH);

            emit Staked(msg.sender, tokenId, length);
        }
    }

    function unstake(uint256[] calldata tokenIds, bool claimRewards) external {
        if (claimRewards) getRewardFor(msg.sender, tokenIds);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakingStats storage stk = _staking[tokenId];

            require(stk.staker == msg.sender, "sender not staker");
            require(block.timestamp >= stk.minStaking, "too early");

            _transferForStaking(address(this), msg.sender, tokenId, false);

            delete stk.staker;

            emit Unstaked(msg.sender, tokenId);
        }
    }

    function getRewardFor(address staker, uint256[] calldata tokenIds) public {
        require(staker != address(0), "address staker");
        uint256 sum;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakingStats storage stk = _staking[tokenIds[i]];
            require(stk.staker == staker, "only tokenIds from `staker`");

            uint256 claimableAmount = _calculateClaimableAmount(stk);

            stk.lastUpdate = uint40(block.timestamp);
            sum += claimableAmount;
        }
        RKC.mint(staker, sum);

        emit RewardClaimed(staker, sum);
    }

    function revealTypes(
        uint256[] calldata tokenIds,
        uint256[] calldata baseRates,
        bytes32[][] calldata proofs
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i = i.unsafeInc()) {
            require(
                proofs[i].verify(
                    revealRoot,
                    keccak256(abi.encodePacked(tokenIds[i], baseRates[i]))
                ),
                "invalid proof"
            );
            _staking[tokenIds[i]].baseRate = uint72(baseRates[i]);
        }
    }

    function revealTypesAndStake(
        uint256[] calldata tokenIds,
        uint256[] calldata baseRates,
        bytes32[][] calldata proofs,
        uint256[] calldata lengths
    ) external {
        revealTypes(tokenIds, baseRates, proofs);
        stake(tokenIds, lengths, false);
    }

    function getRewardsAndRestake(
        uint256[] calldata tokenIds,
        uint256[] calldata lengths
    ) external {
        getRewardFor(msg.sender, tokenIds);
        stake(tokenIds, lengths, true);
    }

    function _calculateClaimableAmount(
        StakingStats storage stk
    ) internal view returns (uint256) {
        uint256 end = stk.end;
        // staking has ended
        if (end <= block.timestamp) {
            uint256 lastUpdated = stk.lastUpdate;
            if (lastUpdated < end) {
                return stk.bonus + stk.baseRate * (end - lastUpdated);
            }
            return 0;
        } else {
            return stk.baseRate * (block.timestamp - stk.lastUpdate);
        }
    }

    function _calculateBonus(
        uint256 length,
        uint256 rate
    ) internal pure returns (uint256) {
        require(rate != 0, "unrevealed nft");
        uint256 bonusPercentage;
        if (length == 3 * MONTH) bonusPercentage = 20;
        else if (length == 6 * MONTH) bonusPercentage = 40;
        else if (length == 9 * MONTH) bonusPercentage = 60;
        else if (length == 12 * MONTH) bonusPercentage = 80;
        else if (length != 1 * MONTH) revert("Invalid staking length");

        return (length * rate * bonusPercentage) / PERCENT;
    }

    // EXTERNAL VIEW
    function isStaked(uint256 tokenId) public view returns (bool) {
        return _staking[tokenId].staker != address(0);
    }

    function isRevealed(uint256 tokenId) external view returns (bool) {
        return _staking[tokenId].baseRate != 0;
    }

    function getClaimableAmount(
        uint256 tokenId
    ) external view returns (uint256 claimableAmount) {
        require(isStaked(tokenId), "Nft not staked");
        claimableAmount = _calculateClaimableAmount(_staking[tokenId]);
    }

    function getStaker(uint256 tokenId) external view returns (address staker) {
        require(isStaked(tokenId), "Nft not staked");
        staker = _staking[tokenId].staker;
    }

    function bonusAvailable(uint256 tokenId) public view returns (bool) {
        StakingStats storage stk = _staking[tokenId];
        return
            isStaked(tokenId) &&
            stk.lastUpdate < stk.end &&
            stk.end <= block.timestamp;
    }
}
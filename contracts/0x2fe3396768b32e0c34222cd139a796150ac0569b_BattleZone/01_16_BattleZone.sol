// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ECDSA} from "@solady/utils/ECDSA.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721} from "@oz/token/ERC721/IERC721.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";
import {IERC721Receiver} from "@oz/token/ERC721/IERC721Receiver.sol";

contract BattleZone is
    IBattleZone,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;

    uint256 public constant SECONDS_IN_DAY = 1 days;
    uint256 public constant ACCELERATED_YIELD_DAYS = 2 days;
    uint256 public constant ACCELERATED_YIELD_MULTIPLIER = 2;
    uint256 public constant MAX_TOOL_BOXES_STAKED = 3;

    /// @notice Staker information
    struct Staker {
        uint256 currentYield;
        uint256 accumulatedAmount;
        uint256 lastCheckpoint;
        uint256[] stakedBots;
        uint256[] stakedBattery;
    }

    /// @notice Beep Boop Box NFT
    IERC721 public beepBoopBotNft;

    /// @notice Battery NFT
    IERC721 public batteryNft;

    /// @notice Toolbox NFT
    IERC721 public toolboxNft;

    /// @notice Accelerated yield time
    uint256 public acceleratedYield;

    /// @notice For rarity based rewards
    address public signerAddress;

    /// @notice Launch staking with the bonus
    bool public stakingLaunched;

    /// @notice Pause all deposits
    bool public depositPaused;

    mapping(address => uint256) public baseYieldRate;
    mapping(address => mapping(uint256 => uint256)) private _rarityBasedYield;

    mapping(address => Staker) private _stakers;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;

    /// @notice The toolboxes associated to a bot
    mapping(uint256 => uint256[]) beepBoopBotToolboxes;

    /// @notice The beep boop asigned to the toolbox
    mapping(uint256 => uint256) private _beepBoopBotOfToolboxId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _beepBoopBot, address _signer)
        external
        initializer
    {
        beepBoopBotNft = IERC721(_beepBoopBot);
        baseYieldRate[_beepBoopBot] = 1500e18;
        signerAddress = _signer;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function deposit(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenRarities,
        bytes calldata signature
    ) public validContract(contractAddress) {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");
        require(contractAddress != address(toolboxNft), "Use deposit toolbox");

        // validate the source of truth of the rarity
        if (tokenRarities.length > 0) {
            require(tokenIds.length == tokenRarities.length, "Array mismatch");
            require(
                _validateSignature(
                    signature,
                    contractAddress,
                    tokenIds,
                    tokenRarities
                ),
                "Bad signature"
            );
        }

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            IERC721(contractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );

            // set rarity if it exists
            if (tokenRarities.length > 0) {
                uint256 tokenRarity = tokenRarities[i];
                if (tokenRarity != 0) {
                    _rarityBasedYield[contractAddress][tokenId] = tokenRarity;
                }
            }

            _ownerOfToken[contractAddress][tokenId] = msg.sender;
            newYield += getTokenYield(contractAddress, tokenId);

            if (contractAddress == address(beepBoopBotNft)) {
                user.stakedBots.push(tokenId);
            } else if (contractAddress == address(batteryNft)) {
                user.stakedBattery.push(tokenId);
            }
        }

        accumulate(msg.sender);
        user.currentYield = newYield;

        emit Deposit(msg.sender, contractAddress, tokenIds.length);
    }

    function withdraw(address contractAddress, uint256[] memory tokenIds)
        public
        validContract(contractAddress)
    {
        require(contractAddress != address(toolboxNft), "Use deposit toolbox");

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(contractAddress).ownerOf(tokenIds[i]) == address(this),
                "Not the owner"
            );

            _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

            if (user.currentYield != 0) {
                uint256 tokenYield = getTokenYield(
                    contractAddress,
                    tokenIds[i]
                );
                newYield -= tokenYield;
            }

            if (contractAddress == address(beepBoopBotNft)) {
                user.stakedBots = _shiftElementToEnd(
                    user.stakedBots,
                    tokenIds[i]
                );
                user.stakedBots.pop();
            } else if (contractAddress == address(batteryNft)) {
                user.stakedBattery = _shiftElementToEnd(
                    user.stakedBattery,
                    tokenIds[i]
                );
                user.stakedBattery.pop();
            }

            IERC721(contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }

        accumulate(msg.sender);
        user.currentYield = newYield;

        emit Withdraw(msg.sender, contractAddress, tokenIds.length);
    }

    /**
     * @notice Deposit
     */
    function depositToolboxes(
        uint256 beepBoopTokenId,
        uint256[] memory toolboxTokenIds
    ) public {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");
        require(
            ownerOf(address(beepBoopBotNft), beepBoopTokenId) == msg.sender,
            "Beep boop not staked"
        );

        address toolboxNft_ = address(toolboxNft);
        require(toolboxNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 netIncrease;

        for (uint256 i; i < toolboxTokenIds.length; i++) {
            uint256 toolboxTokenId = toolboxTokenIds[i];
            IERC721(toolboxNft_).safeTransferFrom(
                msg.sender,
                address(this),
                toolboxTokenId
            );
            uint256 beforeToolboxCount = beepBoopBotToolboxes[beepBoopTokenId]
                .length;
            require(
                beforeToolboxCount + 1 <= MAX_TOOL_BOXES_STAKED,
                "Max batteries staked for bot"
            );
            beepBoopBotToolboxes[beepBoopTokenId].push(toolboxTokenId);
            netIncrease += getTokenYield(toolboxNft_, toolboxTokenId);
            _ownerOfToken[toolboxNft_][toolboxTokenId] = msg.sender;
            _beepBoopBotOfToolboxId[toolboxTokenId] = beepBoopTokenId;
        }

        accumulate(msg.sender);
        user.currentYield += netIncrease;

        emit Deposit(msg.sender, toolboxNft_, toolboxTokenIds.length);
    }

    function withdrawToolboxes(uint256[] memory toolboxTokenIds) public {
        address toolboxNft_ = address(toolboxNft);
        require(toolboxNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < toolboxTokenIds.length; i++) {
            uint256 toolboxTokenId = toolboxTokenIds[i];
            uint256 toolboxBeepBoopId = _beepBoopBotOfToolboxId[toolboxTokenId];
            require(
                IERC721(toolboxNft_).ownerOf(toolboxTokenId) == address(this),
                "Not the owner"
            );
            require(
                ownerOf(address(beepBoopBotNft), toolboxBeepBoopId) ==
                    msg.sender,
                "Not the bot owner"
            );

            _ownerOfToken[toolboxNft_][toolboxTokenId] = address(0);

            // reduce yield
            if (user.currentYield != 0) {
                uint256 tokenYield = getTokenYield(toolboxNft_, toolboxTokenId);
                newYield -= tokenYield;
            }

            // remove toolbox from beep bop
            beepBoopBotToolboxes[toolboxBeepBoopId] = _shiftElementToEnd(
                beepBoopBotToolboxes[toolboxBeepBoopId],
                toolboxTokenId
            );
            beepBoopBotToolboxes[toolboxBeepBoopId].pop();

            // return it back
            IERC721(toolboxNft_).safeTransferFrom(
                address(this),
                msg.sender,
                toolboxTokenId
            );
        }

        accumulate(msg.sender);
        user.currentYield = newYield;

        emit Withdraw(msg.sender, toolboxNft_, toolboxTokenIds.length);
    }

    modifier validContract(address contract_) {
        require(
            (contract_ != address(0) && contract_ == address(beepBoopBotNft)) ||
                contract_ == address(toolboxNft) ||
                contract_ == address(batteryNft),
            "Unknown contract"
        );
        _;
    }

    function getAccumulatedAmount(address staker)
        external
        view
        returns (uint256)
    {
        return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function getTokenYield(address contractAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 tokenYield = _rarityBasedYield[contractAddress][tokenId];
        if (tokenYield == 0) {
            tokenYield = baseYieldRate[contractAddress];
        }
        return tokenYield;
    }

    function getStakerYield(address staker) public view returns (uint256) {
        return _stakers[staker].currentYield;
    }

    function getStakerTokens(address staker)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 toolBoxIdx;
        uint256[] memory stakedBots = _stakers[staker].stakedBots;
        uint256[] memory stakedToolboxes = new uint256[](
            MAX_TOOL_BOXES_STAKED * stakedBots.length
        );
        for (uint256 i; i < stakedBots.length; ++i) {
            uint256[] memory botToolboxes = beepBoopBotToolboxes[stakedBots[i]];
            for (uint256 t; t < botToolboxes.length; t++) {
                stakedToolboxes[toolBoxIdx++] = botToolboxes[t];
            }
        }
        assembly {
            mstore(stakedToolboxes, toolBoxIdx)
        }
        return (stakedBots, _stakers[staker].stakedBattery, stakedToolboxes);
    }

    function isRaritiesSet(address contractAddress, uint256[] memory tokenIds)
        public
        view
        returns (bool[] memory)
    {
        unchecked {
            bool[] memory rarities = new bool[](tokenIds.length);
            for (uint256 t; t < tokenIds.length; ++t) {
                rarities[t] =
                    _rarityBasedYield[contractAddress][tokenIds[t]] > 0;
            }
            return rarities;
        }
    }

    function _shiftElementToEnd(uint256[] memory list, uint256 tokenId)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 tokenIndex = 0;
        uint256 lastTokenIndex = list.length - 1;
        uint256 length = list.length;

        for (uint256 i = 0; i < length; i++) {
            if (list[i] == tokenId) {
                tokenIndex = i + 1;
                break;
            }
        }
        require(tokenIndex != 0, "msg.sender is not the owner");

        tokenIndex -= 1;

        if (tokenIndex != lastTokenIndex) {
            list[tokenIndex] = list[lastTokenIndex];
            list[lastTokenIndex] = tokenId;
        }
        return list;
    }

    function _validateSignature(
        bytes calldata signature,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenRarities
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(contractAddress, tokenIds, tokenRarities)
        );
        address receivedAddress = dataHash.toEthSignedMessageHash().recover(signature);
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    function getCurrentReward(address staker) public view returns (uint256) {
        Staker memory user = _stakers[staker];
        if (user.lastCheckpoint == 0) {
            return 0;
        }
        if (
            user.lastCheckpoint < acceleratedYield &&
            block.timestamp < acceleratedYield
        ) {
            return
                (((block.timestamp - user.lastCheckpoint) * user.currentYield) /
                    SECONDS_IN_DAY) * ACCELERATED_YIELD_MULTIPLIER;
        }
        if (
            user.lastCheckpoint < acceleratedYield &&
            block.timestamp > acceleratedYield
        ) {
            uint256 currentReward;
            currentReward +=
                (((acceleratedYield - user.lastCheckpoint) *
                    user.currentYield) / SECONDS_IN_DAY) *
                ACCELERATED_YIELD_MULTIPLIER;
            currentReward +=
                ((block.timestamp - acceleratedYield) * user.currentYield) /
                SECONDS_IN_DAY;
            return currentReward;
        }
        return
            ((block.timestamp - user.lastCheckpoint) * user.currentYield) /
            SECONDS_IN_DAY;
    }

    /**
     * @dev Used prior to mutating rewards, to save what has been accumulated so far
     */
    function accumulate(address staker) internal {
        _stakers[staker].accumulatedAmount += getCurrentReward(staker);
        _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
     * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
     */
    function ownerOf(address contractAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        return _ownerOfToken[contractAddress][tokenId];
    }

    function setBatteryNft(address _battery, uint256 baseReward)
        public
        onlyOwner
    {
        batteryNft = IERC721(_battery);
        baseYieldRate[_battery] = baseReward;
    }

    function setToolboxNft(address toolboxNft_, uint256 baseReward)
        public
        onlyOwner
    {
        toolboxNft = IERC721(toolboxNft_);
        baseYieldRate[toolboxNft_] = baseReward;
    }

    /**
     * @dev Function allows admin withdraw ERC721 in case of emergency.
     */
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds)
        public
        onlyOwner
    {
        require(tokenIds.length <= 50, "50 is max per tx");
        depositPaused = true;
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
            if (
                receiver != address(0) &&
                IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)
            ) {
                IERC721(tokenAddress).transferFrom(
                    address(this),
                    receiver,
                    tokenIds[i]
                );
                emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
            }
        }
    }

    /**
     * @dev Function allows to pause deposits if needed. Withdraw remains active.
     */
    function toggleDeposits() public onlyOwner {
        depositPaused = !depositPaused;
    }

    /**
     * @dev Function allows to pause deposits if needed. Withdraw remains active.
     */
    function updateSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    function launchStaking() public onlyOwner {
        require(!stakingLaunched, "Staking has been launched already");
        stakingLaunched = true;
        acceleratedYield = block.timestamp + ACCELERATED_YIELD_DAYS;
    }

    function updateBaseYield(address _contract, uint256 _yield)
        public
        onlyOwner
    {
        baseYieldRate[_contract] = _yield;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
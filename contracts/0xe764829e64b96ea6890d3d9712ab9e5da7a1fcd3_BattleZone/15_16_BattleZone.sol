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
    mapping(uint256 => uint256[]) beepBoopBotToolboxes; // unused

    /// @notice The beep boop asigned to the toolbox
    mapping(uint256 => uint256) private _beepBoopBotOfToolboxId; // unused

    /// @notice Temporary gating of withdrawals
    mapping(address => bool) private withdrawGated;

    /// @notice Staked exo suits
    IERC721 public exoSuitNft;
    mapping(uint256 => uint256) beepBoopBotExoSuit;
    mapping(uint256 => uint256) private _beepBoopBotOfExoSuit;

    /// @notice Stake batteries
    mapping(address => uint256[]) userToolboxes;

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
        require(contractAddress != address(exoSuitNft), "Use deposit exosuit");

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

        // refactor toolbox yield
        if (contractAddress == address(beepBoopBotNft)) {
            uint256 beforeYield = _calculateToolboxYield(
                userToolboxes[msg.sender].length,
                user.stakedBots.length
            );
            uint256 afterYield = _calculateToolboxYield(
                userToolboxes[msg.sender].length,
                user.stakedBots.length + tokenIds.length
            );
            newYield += afterYield - beforeYield;
        } else if (contractAddress == address(batteryNft)) {
            require(
                user.stakedBattery.length + tokenIds.length <= 20,
                "Maximum of 20 batteries can be staked"
            );
        }

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
        require(contractAddress != address(toolboxNft), "Use withdraw toolbox");
        require(contractAddress != address(exoSuitNft), "Use withdraw exosuit");
        require(!withdrawGated[msg.sender], "Unable to withdraw");

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        // refactor toolbox yield
        if (contractAddress == address(beepBoopBotNft)) {
            uint256 beforeYield = _calculateToolboxYield(
                userToolboxes[msg.sender].length,
                user.stakedBots.length
            );
            uint256 afterYield = _calculateToolboxYield(
                userToolboxes[msg.sender].length,
                user.stakedBots.length - tokenIds.length
            );
            newYield -= beforeYield - afterYield;
        }

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
                require(
                    beepBoopBotExoSuit[tokenIds[i]] == 0,
                    "Must Unstake Exo Suit"
                );
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
    function depositToolboxes(uint256[] memory toolboxTokenIds) public {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");

        address toolboxNft_ = address(toolboxNft);
        require(toolboxNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 netIncrease;

        // get number of bots
        uint256 numBots = user.stakedBots.length;
        require(numBots > 0, "Must have a bot staked");

        uint256 numToolboxes = userToolboxes[msg.sender].length;

        for (uint256 i; i < toolboxTokenIds.length; i++) {
            uint256 toolboxTokenId = toolboxTokenIds[i];
            IERC721(toolboxNft_).safeTransferFrom(
                msg.sender,
                address(this),
                toolboxTokenId
            );
            userToolboxes[msg.sender].push(toolboxTokenId);
            _ownerOfToken[toolboxNft_][toolboxTokenId] = msg.sender;
        }

        uint256 beforeYield = _calculateToolboxYield(numToolboxes, numBots);
        uint256 afterYield = _calculateToolboxYield(
            numToolboxes + toolboxTokenIds.length,
            numBots
        );
        netIncrease = afterYield - beforeYield;

        accumulate(msg.sender);
        user.currentYield += netIncrease;

        emit Deposit(msg.sender, toolboxNft_, toolboxTokenIds.length);
    }

    function _calculateToolboxYield(uint256 numToolboxes, uint256 numBots)
        private
        view
        returns (uint256 total)
    {
        uint256 botsPerToolbox = (numToolboxes / MAX_TOOL_BOXES_STAKED);
        return
            (numBots < botsPerToolbox ? numBots : botsPerToolbox) *
            baseYieldRate[address(toolboxNft)];
    }

    function withdrawToolboxes(uint256[] memory toolboxTokenIds) public {
        address toolboxNft_ = address(toolboxNft);
        require(toolboxNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        uint256 numToolboxes = userToolboxes[msg.sender].length;
        uint256 beforeYield = _calculateToolboxYield(
            numToolboxes,
            user.stakedBots.length
        );

        for (uint256 i; i < toolboxTokenIds.length; i++) {
            uint256 toolboxTokenId = toolboxTokenIds[i];
            require(
                ownerOf(address(toolboxNft_), toolboxTokenId) == msg.sender,
                "Not the owner"
            );

            _ownerOfToken[toolboxNft_][toolboxTokenId] = address(0);

            // remove toolbox from beep bop
            userToolboxes[msg.sender] = _shiftElementToEnd(
                userToolboxes[msg.sender],
                toolboxTokenId
            );
            userToolboxes[msg.sender].pop();

            // return it back
            IERC721(toolboxNft_).safeTransferFrom(
                address(this),
                msg.sender,
                toolboxTokenId
            );
        }

        if (user.currentYield != 0) {
            uint256 afterYield = _calculateToolboxYield(
                numToolboxes - toolboxTokenIds.length,
                user.stakedBots.length
            );
            newYield -= beforeYield - afterYield;
        }

        accumulate(msg.sender);
        user.currentYield = newYield;

        emit Withdraw(msg.sender, toolboxNft_, toolboxTokenIds.length);
    }

    /**
     * @notice Deposit
     */
    function depositExoSuit(uint256 beepBoopTokenId, uint256 beepBoopExoSuitId)
        public
    {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");
        require(
            ownerOf(address(beepBoopBotNft), beepBoopTokenId) == msg.sender,
            "Beep boop not staked"
        );

        address exoSuitNft_ = address(exoSuitNft);
        require(exoSuitNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 netIncrease;

        IERC721(exoSuitNft_).safeTransferFrom(
            msg.sender,
            address(this),
            beepBoopExoSuitId
        );
        require(
            beepBoopBotExoSuit[beepBoopTokenId] == 0,
            "Bot already has an exo suit"
        );
        beepBoopBotExoSuit[beepBoopTokenId] = beepBoopExoSuitId;
        netIncrease += getTokenYield(exoSuitNft_, beepBoopExoSuitId);
        _ownerOfToken[exoSuitNft_][beepBoopExoSuitId] = msg.sender;
        _beepBoopBotOfExoSuit[beepBoopExoSuitId] = beepBoopTokenId;

        accumulate(msg.sender);
        user.currentYield += netIncrease;

        emit Deposit(msg.sender, exoSuitNft_, 1);
    }

    function withdrawExoSuit(uint256 exoSuitTokenId) public {
        address exoSuitNft_ = address(exoSuitNft);
        require(exoSuitNft_ != address(0), "!disabled");

        Staker storage user = _stakers[msg.sender];
        uint256 newYield = user.currentYield;

        uint256 exoSuitBeepBoopId = _beepBoopBotOfExoSuit[exoSuitTokenId];
        require(
            IERC721(exoSuitNft_).ownerOf(exoSuitTokenId) == address(this),
            "Exo suit not staked"
        );
        require(
            ownerOf(address(beepBoopBotNft), exoSuitBeepBoopId) == msg.sender,
            "Not the bot owner"
        );

        _ownerOfToken[exoSuitNft_][exoSuitTokenId] = address(0);

        // reduce yield
        if (user.currentYield != 0) {
            uint256 tokenYield = getTokenYield(exoSuitNft_, exoSuitTokenId);
            newYield -= tokenYield;
        }

        // remove suit from beep bop
        delete beepBoopBotExoSuit[exoSuitBeepBoopId];

        // return it back
        IERC721(exoSuitNft_).safeTransferFrom(
            address(this),
            msg.sender,
            exoSuitTokenId
        );

        accumulate(msg.sender);
        user.currentYield = newYield;

        emit Withdraw(msg.sender, exoSuitNft_, 1);
    }

    modifier validContract(address contract_) {
        require(
            (contract_ != address(0) && contract_ == address(beepBoopBotNft)) ||
                contract_ == address(toolboxNft) ||
                contract_ == address(batteryNft) ||
                contract_ == address(exoSuitNft),
            "Unknown contract"
        );
        _;
    }

    function getAccumulatedAmount(address staker)
        external
        view
        returns (uint256)
    {
        if (withdrawGated[staker] == true) {
            return 0;
        }
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
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory stakedBots = _stakers[staker].stakedBots;
        uint256[] memory stakedExoSuits = new uint256[](stakedBots.length);
        for (uint256 i; i < stakedBots.length; ++i) {
            stakedExoSuits[i] = beepBoopBotExoSuit[stakedBots[i]];
        }
        return (
            stakedBots,
            _stakers[staker].stakedBattery,
            userToolboxes[staker],
            stakedExoSuits
        );
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
        address receivedAddress = dataHash.toEthSignedMessageHash().recover(
            signature
        );
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

    function setExoSuitNft(address _battery, uint256 baseReward)
        public
        onlyOwner
    {
        exoSuitNft = IERC721(_battery);
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

    function withdrawGatedAsAdmin(
        address gatedAddress,
        address contractAddress,
        address destAddress
    ) public validContract(contractAddress) onlyOwner {
        require(withdrawGated[gatedAddress], "Gated addresses only");
        uint256[] memory tokenIds;
        (
            uint256[] memory bots,
            uint256[] memory batteries,
            uint256[] memory toolboxes,
            uint256[] memory exosuits
        ) = getStakerTokens(gatedAddress);
        // reset the token balance
        if (contractAddress == address(beepBoopBotNft)) {
            tokenIds = bots;
            delete _stakers[gatedAddress].stakedBots;
        } else if (contractAddress == address(batteryNft)) {
            tokenIds = batteries;
            delete _stakers[gatedAddress].stakedBattery;
        } else if (contractAddress == address(toolboxNft)) {
            tokenIds = toolboxes;
            delete userToolboxes[gatedAddress];
        } else if (contractAddress == address(exoSuitNft)) {
            tokenIds = exosuits;
        }
        // transfer out nft
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId == 0) {
                continue;
            }
            _ownerOfToken[contractAddress][tokenId] = address(0);
            if (contractAddress == address(exoSuitNft)) {
                uint256 exoSuitBeepBoopId = _beepBoopBotOfExoSuit[tokenId];
                if (exoSuitBeepBoopId != 0) {
                    delete beepBoopBotExoSuit[exoSuitBeepBoopId];
                }
            }
            IERC721(contractAddress).safeTransferFrom(
                address(this),
                destAddress,
                tokenId
            );
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

    function setWithdrawalGate(address[] memory addresses, bool toggle)
        public
        onlyOwner
    {
        for (uint256 i; i < addresses.length; ++i) {
            address address_ = addresses[i];
            withdrawGated[address_] = toggle;
        }
    }

    function updateBaseYield(address _contract, uint256 _yield)
        public
        onlyOwner
    {
        baseYieldRate[_contract] = _yield;
    }

    /**
     * @notice Do not use this function unless you know what you are doing
     */
    function updateUserYield(
        address[] memory addresses,
        uint256[] memory yields
    ) public onlyOwner {
        require(addresses.length == yields.length);
        for (uint256 i; i < addresses.length; ++i) {
            address user = addresses[i];
            accumulate(user);
            _stakers[user].currentYield = yields[i];
        }
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
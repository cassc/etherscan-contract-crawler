// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./base/BaseCitiNFT.sol";
import "../contracts-generated/Versioned.sol";

/**
 * @dev Parameters needed for a single auction/sale stage
 */
struct AuctionInfo {
    // Inclusive block timestamp from when the auction starts
    uint64 startTimestamp;
    
    // Inclusive block timestamp from when the auction ends
    uint64 endTimestamp;

    // Interval (in seconds) of the auction price drop
    uint64 priceDropIntervalSeconds;

    // Total supply of this stage
    uint32 totalSupply;

    // Per address allowance of this stage
    // 0 means no allowance limit
    uint24 allowance;

    // Flags for internal use only, should be set to 0 when adding the stage
    uint8 flags;

    // Root of the merkle tree for whitelisted addresses
    bytes32 merkleRoot;
    
    // Custom details info not used by the contract directly
    string details;
}

/**
 * @dev Parameters for the linear price drop function
 */
struct LinearPriceInfo {
    // How much the price drops per interval (wei)
    // Max value = 1208925.819614629174706176 ETH
    uint80 dropPerInterval;

    // Auction starting price (wei)
    // Max value = 309485009.821345068724781056 ETH
    uint88 startPrice;
    
    // Auction resting price (wei)
    uint88 endPrice;
}

/**
 * @dev Parameters for the manual price drop function
 */
struct ManualPriceInfo {
    // Price in each drop interval (wei)
    uint128[] prices;
}

/**
 * @dev Implementation of a multi-stages dutch auction system
 */
contract DutchAuctionV2 is PausableUpgradeable, 
                         AccessControlUpgradeable, 
                         ReentrancyGuardUpgradeable,
                         Versioned 
{
    /// @custom:oz-renamed-from __gap
    uint256[950] private _gap_;

    using AddressUpgradeable for address payable;
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint8 public constant FLAG_IS_WL = 1 << 0;
    uint8 public constant FLAG_LINEAR_PRICE = 1 << 1;
    uint8 public constant FLAG_MANUAL_PRICE = 1 << 2;
    
    // Reference of the NFT contract
    BaseCitiNFT private _nftContract;
    
    // All stages of the auction
    AuctionInfo[] internal _stages;

    // Mapping from stage index to total minted
    mapping(uint256 => uint256) private _totalMinted;
    
    // Mapping from stage index to (mapping from address to number of mints)
    mapping(uint256 => mapping(address => uint256)) private _mints;
    
    // Mapping from stage index to linear price info for the corresponding stages
    mapping(uint256 => LinearPriceInfo) internal _linearPrices;

    // Mapping from stage index to manual price info for the corresponding stages
    mapping(uint256 => ManualPriceInfo) internal _manualPrices;

    /**
     * @dev Emitted when `info` is added to the stages array at `index`
     */
    event StageAdded(uint256 indexed index, AuctionInfo info, uint256 startPrice, uint256 endPrice);

    /**
     * @dev Emitted when `info` is removed from the stages array at `index`
     */
    event StageRemoved(uint256 indexed index, AuctionInfo info);

    /**
     * @dev Emitted when all the stages are removed
     */
    event StagesCleared(uint256 numStages);

    /**
     * @dev Emitted when `tokenId` is minted/sold in `stage` to `recipient` at `soldPrice`, from `nftContract`.
     */
    event NFTMinted(uint256 indexed stage, uint256 indexed tokenId, 
                    address indexed recipient, uint256 soldPrice,
                    BaseCitiNFT nftContract);

    /**
     * @dev Emitted when `amount` of ETH are withdrawn to `recipient`
     */
    event Withdraw(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    
    /**
     * @dev Initialize the auction contract for the `nft` contract.
     * `admin` receives {DEFAULT_ADMIN_ROLE} and {PAUSER_ROLE}, assumes msg.sender if not specified.
     */
    function initialize(BaseCitiNFT nft, address admin) 
        virtual
        initializer 
        public 
    {
        require(Utils.isKnownNetwork(), "unknown network");
        require(address(nft) != address(0), "bad NFT contract");
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        if (admin == address(0)) {
            admin = _msgSender();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        _nftContract = nft;
    }

    /**
     * @dev Returns the nft contract ref.
     */
    function nftContract() 
        public 
        view 
        returns (BaseCitiNFT) 
    {
        return _nftContract;
    }

    /**
     * @dev Pause the contract, requires `PAUSER_ROLE`
     */
    function pause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _pause();
    }

    /**
     * @dev Unpause the contract, requires `PAUSER_ROLE`
     */
    function unpause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _unpause();
    }

    /**
     * @dev Admin function to clear all the stages, requires `DEFAULT_ADMIN_ROLE`
     *
     * Requires no mints has happened in any of the stages.
     *
     * Emits {StagesCleared}
     */
    function adminClearStages() 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        uint256 count = _stages.length;
        for (uint256 index = 0; index < count; index++) {
            require(_totalMinted[index] == 0, "already minted");
            delete _linearPrices[index];
            delete _manualPrices[index];
        }
        delete _stages;
        emit StagesCleared(count);
    }

    /**
     * @dev Admin function to remove the last stage, requires `DEFAULT_ADMIN_ROLE`
     *
     * Requires the said stage to be not minted.
     *
     * Emits {StageRemoved}
     */
    function adminRemoveLastStage() 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        uint256 count = _stages.length;
        require(count != 0, "no stage");
        uint256 index = count - 1;
        require(_totalMinted[index] == 0, "already minted");    
        AuctionInfo memory info = _stages[index];
        _stages.pop();
        delete _linearPrices[index];
        delete _manualPrices[index];
        emit StageRemoved(index, info);
    }
    
    function _addStage(AuctionInfo memory stageInfo, uint8 additionalFlag, uint256 startPrice, uint256 endPrice)
        internal
    {
        require(stageInfo.totalSupply > 0, "bad supply");
        require(stageInfo.endTimestamp > stageInfo.startTimestamp, "bad duration");
        require(stageInfo.startTimestamp < MAX_UINT, "bad start time");

        if (_stages.length > 0) {
            require(stageInfo.startTimestamp > _stages[_stages.length - 1].endTimestamp, "overlap");
        }

        stageInfo.flags = additionalFlag;
        if (stageInfo.merkleRoot != 0) {
            stageInfo.flags |= FLAG_IS_WL;
        }
        _stages.push(stageInfo);
        emit StageAdded(_stages.length - 1, stageInfo, startPrice, endPrice);
    }

    /**
     * @dev Admin function to add a new stage, requires `DEFAULT_ADMIN_ROLE`
     *
     * Requires the added stage to happen after the last existing stage.
     *
     * Emits {StageAdded}
     */
    function adminAddStageLinearPrice(AuctionInfo memory stageInfo, LinearPriceInfo memory priceInfo) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(priceInfo.startPrice >= priceInfo.endPrice, "end px higher than start");
        
        // Disabled for now to support NFT drop
        // require(priceInfo.startPrice > 0, "bad start px");
        // require(priceInfo.endPrice > 0, "bad end px");                

        if (priceInfo.startPrice == priceInfo.endPrice) {
            require(stageInfo.priceDropIntervalSeconds == 0, "expect zero interval");
            require(priceInfo.dropPerInterval == 0, "expect zero drop px");
        } else {
            require(stageInfo.priceDropIntervalSeconds > 0, "expect non-zero interval");
            require(priceInfo.dropPerInterval > 0, "expect non-zero drop px");
        }

        _addStage(stageInfo, FLAG_LINEAR_PRICE, priceInfo.startPrice, priceInfo.endPrice);
        _linearPrices[_stages.length - 1] = priceInfo;
    }

    /**
     * @dev Admin function to add a new stage, requires `DEFAULT_ADMIN_ROLE`
     *
     * Requires the added stage to happen after the last existing stage.
     *
     * Emits {StageAdded}
     */
    function adminAddStageManualPrice(AuctionInfo memory stageInfo, ManualPriceInfo memory priceInfo) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(priceInfo.prices.length > 1, "empty manual price");
        
        uint256 numPrices = priceInfo.prices.length;
        uint128 startPrice = priceInfo.prices[0];
        uint128 endPrice = priceInfo.prices[numPrices - 1];
        uint128 currentPrice = startPrice;
        for (uint256 index = 1; index < numPrices; index++) {
            require(priceInfo.prices[index] <= currentPrice, "end px higher than start");
            currentPrice = priceInfo.prices[index];
        }

        if (startPrice == endPrice) {
            require(stageInfo.priceDropIntervalSeconds == 0, "expect zero interval");
        } else {
            require(stageInfo.priceDropIntervalSeconds > 0, "expect non-zero interval");
        }
        _addStage(stageInfo, FLAG_MANUAL_PRICE, startPrice, endPrice);
        _manualPrices[_stages.length - 1] = priceInfo;
    }

    /**
     * @dev Return if/which stage is active based on `timestamp`
     */
    function currentStage(uint256 timestamp) 
        public 
        view 
        returns (bool, uint256, AuctionInfo memory) 
    {
        for (uint256 index = 0; index < _stages.length; ++index) {
            if (timestamp >= _stages[index].startTimestamp && timestamp <= _stages[index].endTimestamp) {
                return (true, index, _stages[index]);
            }
        }
        return (false, MAX_UINT, AuctionInfo(0, 0, 0, 0, 0, 0, 0, ""));
    }

    /**
     * @dev Get the linear price info for a given stage
     */
    function getLinearPriceInfo(uint256 stage)
        public
        view
        returns (LinearPriceInfo memory)
    {
        return _linearPrices[stage];    
    }

    /**
     * @dev Get the manual price info for a given stage
     */
    function getManualPriceInfo(uint256 stage)
        public
        view
        returns (ManualPriceInfo memory)
    {
        return _manualPrices[stage];    
    }

    /**
     * @dev Admin function to withdraw `amount` of ETH to `recipient`, requires `DEFAULT_ADMIN_ROLE`
     *
     * Emits {Withdraw}
     */
    function adminWithdraw(address payable recipient, uint256 amount) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(recipient != address(0), "bad recipient");
        recipient.sendValue(amount);
        emit Withdraw(recipient, amount);
    }

    /**
     * @dev Admin function to withdraw all the ETH to `recipient`, requires `DEFAULT_ADMIN_ROLE`
     *
     * Emits {withdraw}
     */
    function adminWithdrawAll(address payable recipient) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        adminWithdraw(recipient, address(this).balance);
    }

    /**
     * @dev Modifier requiring `stage` is a valid stage index
     */
    modifier validStage(uint256 stage) {
        require(stage < _stages.length, "bad stage");
        _;
    }

    /**
     * @dev Calculate the current price at `timestamp` in `stage`
     *
     * Requires `stage` is currently active
     */
    function getPrice(uint256 stage, uint256 timestamp) 
        public 
        view 
        validStage(stage) 
        returns (uint256) 
    {
        uint256 startTimestamp = _stages[stage].startTimestamp;
        uint256 endTimestamp = _stages[stage].endTimestamp;
        uint8 flags = _stages[stage].flags;

        if (flags & FLAG_LINEAR_PRICE != 0) {
            // linear price
            uint256 startPrice = _linearPrices[stage].startPrice;
            uint256 endPrice = _linearPrices[stage].endPrice;        
            if (startPrice == endPrice) {
                return startPrice;
            }
            if (timestamp < startTimestamp) {
                return startPrice;
            } else if (timestamp > endTimestamp) {
                return endPrice;
            } else {
                uint256 intervals = (timestamp - startTimestamp) / _stages[stage].priceDropIntervalSeconds;
                uint256 drop = intervals * _linearPrices[stage].dropPerInterval;
                if (startPrice > drop) {
                    return MathUpgradeable.max(startPrice - drop, endPrice);
                } else {
                    return endPrice;
                }
            }
        } else if (flags & FLAG_MANUAL_PRICE != 0) {
            // manual price
            uint256 numPrices = _manualPrices[stage].prices.length;
            uint256 startPrice = _manualPrices[stage].prices[0];
            uint256 endPrice = _manualPrices[stage].prices[numPrices - 1];
            if (startPrice == endPrice) {
                return startPrice;
            }
            if (timestamp < startTimestamp) {
                return startPrice;
            } else if (timestamp > endTimestamp) {
                return endPrice;
            } else {
                uint256 intervals = (timestamp - startTimestamp) / _stages[stage].priceDropIntervalSeconds;
                return _manualPrices[stage].prices[MathUpgradeable.min(intervals, numPrices - 1)];
            }
        } else {
            require(false, "unsupported price model");
            return 0;
        }
    }

    /**
     * @dev Allow admin account to mint remaining tokens from a given stage after it has finished
     * 
     * Note that this function bypasses the allowance, whitelist and payment checks
     * Emits {NFTMinted} per token
     */
    function adminMintRemainingTokens(uint256 stage, address recipient, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
        validStage(stage)
        whenHasSupply(stage, amount)
        whenNotPaused
    {
        require(amount > 0, "invalid amount");
        require(recipient != address(0), "bad recipient");
        require(block.timestamp > _stages[stage].endTimestamp, "not finished");

        _totalMinted[stage] += amount;
        if (_stages[stage].allowance > 0) {
            _mints[stage][recipient] += amount;
        }
        
        for (uint256 index = 0; index < amount; index++) {
            uint256 tokenId = _nftContract.safeMint(recipient);
            emit NFTMinted(stage, tokenId, recipient, 0, _nftContract);
        }
    }
    
    /**
     * @dev Mint `amount` of NFTs in `stage`, with optional `whitelistProof`
     *
     * Requires `stage` is currently active
     * Emits {NFTMinted} per token
     */
    function mintNFT(uint256 stage, bytes32[] calldata whitelistProof, uint256 amount) 
        external
        payable
        nonReentrant
        validStage(stage)
        whenInStage(stage)
        whenHasSupply(stage, amount)
        whenHasAllowance(stage, amount)
        whenNotPaused
    {    
        require(amount > 0, "invalid amount");
        address sender = _msgSender();
        
        {
            if (_stages[stage].flags & FLAG_IS_WL != 0) {
                bytes32 leaf = keccak256(abi.encodePacked(sender));
                require(MerkleProofUpgradeable.verify(whitelistProof, _stages[stage].merkleRoot, leaf), "not in WL");
            }
        }

        uint256 currentPrice = getPrice(stage, block.timestamp);
        require(msg.value >= currentPrice * amount, "px too low");

        {
            _totalMinted[stage] += amount;
            if (_stages[stage].allowance > 0) {
                _mints[stage][sender] += amount;
            }
        }
        
        for (uint256 index = 0; index < amount; index++) {
            uint256 tokenId = _nftContract.safeMint(sender);
            emit NFTMinted(stage, tokenId, sender, currentPrice, _nftContract);
        }
        
        // handle refund last after all the states are modified
        uint256 refund = msg.value - currentPrice * amount;
        if (refund > 0) {
            payable(sender).sendValue(refund);
        }
    }

    /**
     * @dev Return total mints in `stage`
     */
    function totalMinted(uint256 stage) 
        public 
        view 
        validStage(stage) 
        returns (uint256) 
    {
        return _totalMinted[stage];
    }

    /**
     * @dev Return the allowance for `account` in `stage`
     */
    function allowance(uint256 stage, address account) 
        public 
        view validStage(stage) 
        returns (uint256) 
    {
        if (_stages[stage].allowance > 0) {
            return uint256(_stages[stage].allowance) - _mints[stage][account];
        } else {
            return MAX_UINT;
        }
    }
    
    /**
     * @dev Return the entire stage array
     */
    function stages() 
        public 
        view 
        returns (AuctionInfo[] memory) 
    {
        return _stages;
    }

    /**
     * @dev Modifier requiring `stage` is active based on the current block timestamp
     */
    modifier whenInStage(uint256 stage) 
    {
        require(block.timestamp >= _stages[stage].startTimestamp, "not started");
        require(block.timestamp <= _stages[stage].endTimestamp, "auction over");
        _;
    }

    /**
     * @dev Modifier requiring `stage` has enough supply for `amount`
     */
    modifier whenHasSupply(uint256 stage, uint256 amount) 
    {
        require(_totalMinted[stage] + amount <= _stages[stage].totalSupply, "not enough supply");
        _;
    }
    
    /**
     * @dev Modifier requiring the caller has enough allowance in `stage` for `amount`
     */
    modifier whenHasAllowance(uint256 stage, uint256 amount) 
    {
        require(allowance(stage, _msgSender()) >= amount, "not enough allowance");
        _;
    }
}
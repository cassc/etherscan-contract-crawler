// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {MerkleProofUpgradeable as MerkleProof} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./interfaces/INereusShapeshiftersMarket.sol";
import "./deBridge/IDeNFT.sol";

contract NereusShapeshiftersMarket is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    INereusShapeshiftersMarket
{
    using StringsUpgradeable for uint256;
    // address of NFT collection to be distributed
    address private _nftContractAddress;

    // received token ids by the contract
    mapping(uint256 => uint256) private _allowedTokenIds;
    // amount of tokens available for distribution
    uint256 public _availableTokensAmount;

    // sales wave configuration
    mapping(uint256 => SaleWave) private _saleWaves;
    // counter of sale waves added to contract
    uint256 private _saleWavesCounter;
    // id of current sale wave set
    uint256 private _currentSaleWave;

    // mapping for salewave to tokennumber to price
    mapping(uint256 => mapping(uint256 => uint256))
        private _saleWaveTokenPrices;

    // correlation between sales waves and claimed amount per address
    mapping(uint256 => mapping(address => uint256)) private _saleWavesClaimed;

    string private constant URI_SUFFIX = ".json";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Contract initializer
    function initialize(address nftContractAddress) public initializer {
        _nftContractAddress = nftContractAddress;
        _saleWavesCounter = 1;
        _availableTokensAmount = 10000;

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __Context_init();
    }

    modifier isSalesAllowed(uint256 amount) {
        require(
            _saleWaves[_currentSaleWave].active,
            "NereusShapeshiftersMarket: sales not active at the moment"
        );
        require(
            amount > 0,
            "NereusShapeshiftersMarket: specified amount should be more than zero"
        );
        require(
            _availableTokensAmount >= amount,
            "NereusShapeshiftersMarket: requested amount exceed NFTs balance on contract"
        );
        require(
            _saleWaves[_currentSaleWave].totalWaveAllocation >=
                _saleWaves[_currentSaleWave].wavePurchased + amount,
            "NereusShapeshiftersMarket: amount of tokens allocated per wave reached."
        );
        _;
    }

    /**
     * Returns current sales wave information
     */
    function getCurrentSaleWave() external view returns (SaleWave memory) {
        return _saleWaves[_currentSaleWave];
    }

    /**
     * Allows to add sale wave price per each NFT allowed for user in the wave
     */
    function addSalesWaveTokenPrices(
        uint256 waveId,
        SaleWaveTokenPrice[] calldata wavePrices
    ) public onlyOwner {
        for (uint256 i = 0; i < wavePrices.length; i++) {
            _saleWaveTokenPrices[waveId][
                wavePrices[i].tokenNumber
            ] = wavePrices[i].price;
        }
    }

    /**
     * Allows to add new sale wave
     */
    function addSaleWave(
        SaleWaveTokenPrice[] calldata wavePrices,
        uint256 claimAllowance,
        uint256 waveAllocation
    ) external onlyOwner returns (uint256) {
        require(
            claimAllowance > 0,
            "NereusShapeshiftersMarket: claim allowance should be more than 0"
        );
        require(
            waveAllocation > 0,
            "NereusShapeshiftersMarket: total wave allocation should be more than 0"
        );
        require(
            wavePrices.length == claimAllowance,
            "NereusShapeshiftersMarket: provided wave prices amount should be equal claim allowance per wave."
        );

        uint256 saleWaveId = _saleWavesCounter;

        addSalesWaveTokenPrices(saleWaveId, wavePrices);

        _saleWaves[saleWaveId] = SaleWave(
            false,
            "",
            claimAllowance,
            waveAllocation,
            0,
            saleWaveId,
            true
        );
        _saleWavesCounter++;

        emit SalesWaveAdded(saleWaveId, false);

        return saleWaveId;
    }

    /**
     * Returns amount that should be used to pay for buy
     * wallet - address to get price
     * amount - amount of nfts to purchase
     */
    function getWavePriceForAddress(address wallet, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 claimedAmountPerUser = _saleWavesClaimed[_currentSaleWave][
            wallet
        ];

        if (
            _saleWaves[_currentSaleWave].claimAllowance <
            claimedAmountPerUser + amount
        ) {
            return 0;
        }

        uint256 requiredValue = 0;

        // calculate required eth amount to proceed payment
        for (
            uint256 i = claimedAmountPerUser + 1;
            i <= claimedAmountPerUser + amount;
            i++
        ) {
            requiredValue += _saleWaveTokenPrices[_currentSaleWave][i];
        }

        return requiredValue;
    }

    /**
     * Allows to add new sale wave
     */
    function addWhitelistableSaleWave(
        SaleWaveTokenPrice[] calldata wavePrices,
        bytes32 merkleRoot,
        uint256 claimAllowance,
        uint256 waveAllocation
    ) external onlyOwner returns (uint256) {
        require(
            claimAllowance > 0,
            "NereusShapeshiftersMarket: claim allowance should be more than 0"
        );
        require(
            waveAllocation > 0,
            "NereusShapeshiftersMarket: total wave allocation should be more than 0"
        );

        uint256 saleWaveId = _saleWavesCounter;

        addSalesWaveTokenPrices(saleWaveId, wavePrices);

        _saleWaves[saleWaveId] = SaleWave(
            true,
            merkleRoot,
            claimAllowance,
            waveAllocation,
            0,
            saleWaveId,
            true
        );
        _saleWavesCounter++;

        emit SalesWaveAdded(saleWaveId, true);

        return saleWaveId;
    }

    /**
     * Allows to update whitelistable wave whitelist
     */
    function updateWaveWhitelist(uint256 saleWaveId, bytes32 merkleRoot)
        external
    {
        require(
            _saleWaves[saleWaveId].isWhitelistable,
            "NereusShapeshiftersMarket: selected wave is not whitelistable"
        );
        _saleWaves[saleWaveId].merkleRoot = merkleRoot;
    }

    /**
     * Turns on sale wave
     * saleWaveId - sale wave id to turn on
     * should: receive existing and active sale wave
     */
    function setCurrentSaleWave(uint256 saleWaveId) external onlyOwner {
        require(
            _saleWaves[saleWaveId].active,
            "NereusShapeshiftersMarket: specified sale wave does not exists or not active"
        );
        _currentSaleWave = saleWaveId;
        emit SalesWaveSet(_currentSaleWave);
    }

    /**
     * Performs buy specied amount of tokens from those which is on hold in the contract
     * Uses current sale wave to determine the price
     * erc20BuyToken - token used to buy NFTs
     * amount - amount of NFTs to buy from contract
     * _merkleProof - proof of being in whitelist
     * should: receive allowed erc20 token for buy
     * should: have allowance of erc20 by user set to NFT price * purchase amount
     * if whitelist wave should: address to be whitelisted, address requested amount does not exceed allowance per wave
     */
    function buy(uint256 amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        isSalesAllowed(amount)
        whenNotPaused
    {
        require(
            !isContract(_msgSender()),
            "NereusShapeshiftersMarket: msg sender can not be smart contract"
        );

        if (_saleWaves[_currentSaleWave].isWhitelistable) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProof.verify(
                    _merkleProof,
                    _saleWaves[_currentSaleWave].merkleRoot,
                    leaf
                ),
                "NereusShapeshiftersMarket: address is not whitelisted."
            );
        }

        uint256 claimedAmountPerUser = _saleWavesClaimed[_currentSaleWave][
            _msgSender()
        ];

        // check if requested amount can be processed for current user on this wave
        require(
            _saleWaves[_currentSaleWave].claimAllowance >=
                claimedAmountPerUser + amount,
            "NereusShapeshiftersMarket: wave amount per address exceeded."
        );

        uint256 requiredValue = 0;

        // calculate required eth amount to proceed payment
        for (
            uint256 i = claimedAmountPerUser + 1;
            i <= claimedAmountPerUser + amount;
            i++
        ) {
            requiredValue += _saleWaveTokenPrices[_currentSaleWave][i];
        }
        // checks if supplied amount more or equal
        require(
            msg.value >= requiredValue,
            "NereusShapeshiftersMarket: not enough value supplied to complete transaction"
        );

        if (msg.value > requiredValue) {
            (bool success, ) = payable(_msgSender()).call{
                value: msg.value - requiredValue
            }("");
            require(
                success,
                "NereusShapeshiftersMarket: Error sending change back"
            );
        }

        // batch transfer of specific amount of tokens from contract address to buyer address
        uint256[] memory tokenIds = new uint256[](amount);
        string[] memory tokenUris = new string[](amount);
        for (uint256 i = 0; i < amount; i++) {
            (uint256 tokenId, string memory tokenURI) = generateSingleItem();
            tokenIds[i] = tokenId;
            tokenUris[i] = tokenURI;

            emit NFTPurchased(
                _msgSender(),
                tokenId,
                tokenURI,
                _currentSaleWave
            );
        }

        IDeNFT(_nftContractAddress).mintMany(msg.sender, tokenIds, tokenUris);

        _saleWavesClaimed[_currentSaleWave][_msgSender()] += amount;
        _saleWaves[_currentSaleWave].wavePurchased += amount;
    }

    /**
     * Lets minter ability to DeNFTBridge
     */
    function revokeOwnerAndMinters() external onlyOwner {
        IDeNFT(_nftContractAddress).revokeOwnerAndMinters();
        emit CollectionRevokeOwnerAndMinters();
    }

    /**
    * Allows to pause sales
     */
    function pauseSales() external onlyOwner {
        _pause();
    }

    /**
    * allows to unpause sales
     */
    function unpauseSales() external onlyOwner {
        _unpause();
    }

    /**
     * Generate and buy single item
     */
    function generateSingleItem()
        private
        returns (uint256 tokenId, string memory tokenURI)
    {
        uint256 randomValue = getRandom(_availableTokensAmount);
        tokenId = tokenAt(randomValue);
        tokenURI = string(abi.encodePacked(tokenId.toString(), URI_SUFFIX));

        _allowedTokenIds[randomValue] = tokenAt(_availableTokensAmount - 1);
        _allowedTokenIds[_availableTokensAmount - 1] = 0;
        _availableTokensAmount -= 1;

        return (tokenId, tokenURI);
    }

    /**
     * Withdraw balalnce from contract address to owner
     */
    function withdrawBalance() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(
            balance > 0,
            "NereusShapeshiftersMarket: balance is empty"
        );
        payable(owner()).transfer(balance);

        emit BalanceWithdrawn(balance);
    }

    /**
     * Validates if specified address is a smart contract
     */
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
     * Gets random value from 0 to range limit
     */
    function getRandom(uint256 rangeLimit) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(_msgSender())))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / rangeLimit) * rangeLimit));
    }

    /**
     * Gets token at specified index
     */
    function tokenAt(uint256 i) private view returns (uint256) {
        if (_allowedTokenIds[i] > 0) {
            return _allowedTokenIds[i];
        } else {
            return i;
        }
    }

    /**
     * Returns allowed remaining amount for address to purchase NFTs
     */
    function getUserRemainingWaveAllowance(address userWallet)
        external
        view
        returns (uint256)
    {
        return
            _saleWaves[_currentSaleWave].claimAllowance -
            _saleWavesClaimed[_currentSaleWave][userWallet];
    }

    /**
     * Is user whitelisted in current sales wave
     */
    function isUserInWaveWhitelist(
        address userWallet,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        if (!_saleWaves[_currentSaleWave].isWhitelistable) {
            return true;
        }

        bytes32 leaf = keccak256(abi.encodePacked(userWallet));
        return
            MerkleProof.verify(
                _merkleProof,
                _saleWaves[_currentSaleWave].merkleRoot,
                leaf
            );
    }
}
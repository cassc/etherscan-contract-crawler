// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IGenesisNFT} from "../interfaces/IGenesisNFT.sol";
import {INativeToken} from "../interfaces/INativeToken.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {WeightedPoolUserData} from "@balancer-labs/v2-interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
import {IBalancerQueries} from "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";
import {SafeCast} from "../libraries/utils/SafeCast.sol";
// solhint-disable-next-line no-global-import
import "../libraries/balancer/ERC20Helpers.sol"; // Custom (pragma ^0.8.0) ERC20 helpers for Balancer tokens

/// @title GenesisNFT
/// @author leNFT
/// @notice This contract manages the creation and minting of Genesis NFTs
/// @dev Interacts with a balancer pool to provide liquidty on mint
contract GenesisNFT is
    ERC165Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    IGenesisNFT,
    ReentrancyGuardUpgradeable
{
    uint256 private constant LP_LE_AMOUNT = 4e22; // 40000 LE
    uint256 private constant LP_ETH_AMOUNT = 1e17; // 0.1 ETH
    uint256 private constant MAX_CAP = 1337; // 1337 NFTs
    uint256 private constant PRICE = 25e16; // 0.25 ETH
    uint256 private constant MAX_LOCKTIME = 180 days;
    uint256 private constant MIN_LOCKTIME = 14 days;
    uint256 private constant NATIVE_TOKEN_FACTOR = 400000; // Controls the amount of native tokens minted per NFT

    IAddressProvider private immutable _addressProvider;
    address payable private _devAddress;
    DataTypes.BalancerDetails private _balancerDetails;
    uint256 private _maxLTVBoost;
    CountersUpgradeable.Counter private _tokenIdCounter;
    // Mapping from owner to create loan operator approvals
    mapping(address => mapping(address => bool)) private _loanOperatorApprovals;
    // NFT token id to bool that's true if NFT is being used to increase a loan's max LTV
    mapping(uint256 => bool) private _locked;
    // NFT token id to information about its mint
    mapping(uint256 => DataTypes.MintDetails) private _mintDetails;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyMarket() {
        _requireOnlyMarket();
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        _requireTokenExists(tokenId);
        _;
    }

    modifier validPool() {
        _requireValidPool();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IAddressProvider addressProvider) {
        _addressProvider = addressProvider;
        _disableInitializers();
    }

    /// @notice Initializes the contract with the specified parameters
    /// @param maxLTVBoost max LTV boost factor
    /// @param devAddress Address of the developer
    function initialize(
        uint256 maxLTVBoost,
        address payable devAddress
    ) external initializer {
        __ERC721_init("leNFT Genesis", "LEGEN");
        __ERC721Enumerable_init();
        __ERC165_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        _maxLTVBoost = maxLTVBoost;
        _devAddress = devAddress;

        // Start from token_id 1 in order to reserve '0' for the null token
        _tokenIdCounter.increment();
    }

    /// @notice Sets an approved address as a loan operator for the caller
    /// @dev This approval allows for the use of the genesis NFT by the loan operator in a loan
    /// @param operator Address to set approval for
    /// @param approved True if the operator is approved, false to revoke approval
    function setLoanOperatorApproval(address operator, bool approved) external {
        _loanOperatorApprovals[msg.sender][operator] = approved;
    }

    /// @notice Checks if an address is approved as a loan operator for an owner
    /// @param owner Address of the owner
    /// @param operator Address of the operator
    /// @return True if the operator is approved, false otherwise
    function isLoanOperatorApproved(
        address owner,
        address operator
    ) public view returns (bool) {
        return _loanOperatorApprovals[owner][operator];
    }

    /// @notice Returns the URI for a given token ID
    /// @param tokenId ID of the token
    /// @return The token's URI
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable)
        tokenExists(tokenId)
        returns (string memory)
    {
        require(_exists(tokenId), "G:TU:INVALID_TOKEN_ID");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": "Genesis NFT #',
                            Strings.toString(tokenId),
                            '",',
                            '"description": "leNFT Genesis Collection NFT.",',
                            '"image": ',
                            '"data:image/svg+xml;base64,',
                            Base64.encode(svg(tokenId)),
                            '",',
                            '"attributes": [',
                            string(
                                abi.encodePacked(
                                    '{ "trait_type": "locked", "value": "',
                                    _locked[tokenId] ? "true" : "false",
                                    '" },',
                                    '{ "trait_type": "unlock_timestamp", "value": "',
                                    Strings.toString(
                                        getUnlockTimestamp(tokenId)
                                    ),
                                    '" },',
                                    '{ "trait_type": "lp_amount", "value": "',
                                    Strings.toString(
                                        _mintDetails[tokenId].lpAmount
                                    ),
                                    '" }'
                                )
                            ),
                            "]",
                            "}"
                        )
                    )
                )
            );
    }

    /// @notice Returns the SVG present in the token's metadata
    /// @param tokenId ID of the token
    /// @return _svg The token's SVG
    function svg(
        uint256 tokenId
    ) public view tokenExists(tokenId) returns (bytes memory _svg) {
        require(_exists(tokenId), "G:S:INVALID_TOKEN_ID");
        {
            _svg = abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" style="width:100%;background:#f8f1f1;fill:#000;font-family:monospace">',
                "<defs>",
                '<filter id="a">',
                '<feGaussianBlur in="SourceGraphic" stdDeviation="2" result="blur"/>',
                "<feMerge>",
                '<feMergeNode in="blur"/>',
                '<feMergeNode in="SourceGraphic"/>',
                "</feMerge>",
                "</filter>",
                "</defs>",
                '<text x="50%" y="25%" text-anchor="middle" font-size="16" stroke="black" letter-spacing="2">',
                '<tspan dy="0">leNFT</tspan>',
                '<animate attributeName="textLength" from="0" to="40%" dur="1.8s" fill="freeze"/>',
                '<animate attributeName="lengthAdjust" to="spacing" dur="1.4s" fill="freeze"/>',
                "</text>"
            );
        }

        {
            _svg = abi.encodePacked(
                _svg,
                '<circle cx="50%" cy="60%" r="60" fill="none" stroke="#',
                _getCircleColor(tokenId),
                '" stroke-width="2" filter="url(#a)"/>',
                '<text x="50%" y="17%" text-anchor="middle" font-size="28">',
                '<tspan dy="180">',
                Strings.toString(tokenId),
                "</tspan>",
                "</text>",
                '<text font-size="16" fill="#',
                _getCircleColor(tokenId),
                '" stroke="#',
                _getCircleColor(tokenId),
                '" letter-spacing="4" rotate="180 180 180 180 180 180 180">'
            );
        }

        {
            _svg = abi.encodePacked(
                _svg,
                '<textPath href="#b" startOffset="0%">',
                "SISENEG",
                '<animate attributeName="startOffset" from="100%" to="0%" dur="15s" repeatCount="indefinite"/>',
                "</textPath>",
                "</text>",
                "<defs>",
                '<path id="b" d="M130 240a70 70 0 1 0 140 0 70 70 0 1 0-140 0"/>',
                "</defs>",
                "</svg>"
            );
        }
    }

    function _getCircleColor(
        uint256 tokenId
    ) internal view returns (string memory) {
        // Linear interpolation between black (0x000000) and gold (0xFFD700)
        uint256 colorValue = (uint256(0xFFD700) *
            _mintDetails[tokenId].locktime) / MAX_LOCKTIME;

        // Convert to hexadecimal color value && Cast string to bytes
        bytes memory b = bytes(Strings.toHexString(colorValue));

        // Create a new bytes array to hold the string without the prefix
        bytes memory result = new bytes(b.length - 2);

        // remove the 0x prefix
        for (uint i = 2; i < b.length; i++) {
            result[i - 2] = b[i];
        }
        // Convert to hexadecimal color value
        return string(result);
    }

    /// @notice Returns the maximum number of tokens that can be minted
    /// @return The maximum number of tokens
    function getCap() public pure returns (uint256) {
        return MAX_CAP;
    }

    /// @notice Returns the max LTV boost factor
    /// @return The max LTV boost factor
    function getMaxLTVBoost() external view returns (uint256) {
        return _maxLTVBoost;
    }

    /// @notice Sets the Max LTV boost factor
    /// @param newMaxLTVBoost The new Max LTV boost factor
    function setMaxLTVBoost(uint256 newMaxLTVBoost) external onlyOwner {
        _maxLTVBoost = newMaxLTVBoost;
    }

    /// @notice Returns the active state of the specified Genesis NFT
    /// @param tokenId ID of the token
    /// @return The active state
    function getLockedState(
        uint256 tokenId
    ) external view tokenExists(tokenId) returns (bool) {
        return _locked[tokenId];
    }

    /// @notice Sets the active state of the specified Genesis NFT to true
    /// @param tokenId ID of the token
    function lockGenesisNFT(
        address onBehalfOf,
        address caller,
        uint256 tokenId
    ) external override tokenExists(tokenId) onlyMarket returns (uint256) {
        // If the caller is not the user we are borrowing on behalf Of, check if the caller is approved
        if (onBehalfOf != caller) {
            require(
                isLoanOperatorApproved(onBehalfOf, caller),
                "VL:VB:GENESIS_NOT_AUTHORIZED"
            );
        }

        // Require that the NFT is owned by the user we are locking on behalf of
        require(ownerOf(tokenId) == onBehalfOf, "VL:VB:GENESIS_NOT_OWNED");

        //Require that the NFT is not being used
        require(_locked[tokenId] == false, "VL:VB:GENESIS_LOCKED");

        // Set the NFT to be locked
        _locked[tokenId] = true;

        return _maxLTVBoost;
    }

    function unlockGenesisNFT(
        uint256 tokenId
    ) external override tokenExists(tokenId) onlyMarket {
        delete _locked[tokenId];
    }

    /// @notice Calculates the native token reward for a given amount and lock time
    /// @param amount Amount of tokens to be minted
    /// @param locktime Lock time for lock in seconds
    /// @return The native token reward
    function getCurrentLEReward(
        uint256 amount,
        uint256 locktime
    ) public view returns (uint256) {
        require(_tokenIdCounter.current() <= MAX_CAP, "G:GNTR:MINT_OVER");
        require(locktime >= MIN_LOCKTIME, "G:GNTR:LOCKTIME_TOO_LOW");
        require(locktime <= MAX_LOCKTIME, "G:GNTR:LOCKTIME_TOO_HIGH");

        return
            ((amount * locktime * (MAX_CAP - (_tokenIdCounter.current() / 2))) /
                NATIVE_TOKEN_FACTOR) * 1e18;
    }

    /// @notice Sets the details of the balancer subsidized trading pool
    /// @param balancerDetails Addresses of the balancer contracts
    function setBalancerDetails(
        DataTypes.BalancerDetails calldata balancerDetails
    ) external onlyOwner {
        _balancerDetails = balancerDetails;
    }

    /// @notice Returns the number of tokens that have been minted
    /// @return The number of tokens
    function mintCount() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    /// @notice Mint new Genesis NFTs with locked LE tokens and LP tokens
    /// @param locktime The time for which the tokens yielded by the genesis NFT are locked for
    /// @param amount The amount of tokens to mint
    function mint(
        uint256 locktime,
        uint256 amount
    ) external payable nonReentrant validPool {
        // Make sure amount is bigger than 0
        require(amount > 0, "G:M:AMOUNT_0");
        // Make sure locktimes are within limits
        require(locktime >= MIN_LOCKTIME, "G:M:LOCKTIME_TOO_LOW");
        require(locktime <= MAX_LOCKTIME, "G:M:LOCKTIME_TOO_HIGH");

        // Make sure there are enough tokens to mint
        require(
            _tokenIdCounter.current() + amount <= getCap() + 1,
            "G:M:CAP_EXCEEDED"
        );

        // Get the native token address to save on gas
        address nativeToken = _addressProvider.getNativeToken();

        // Make sure the user sent enough ETH
        require(msg.value == PRICE * amount, "G:M:INSUFFICIENT_ETH");

        // Get the amount of ETH to deposit to the pool
        uint256 ethAmount = LP_ETH_AMOUNT * amount;
        uint256 leAmount = LP_LE_AMOUNT * amount;

        // Mint LE tokens
        uint256 totalRewards = getCurrentLEReward(amount, locktime);
        INativeToken(nativeToken).mintGenesisTokens(leAmount + totalRewards);

        // Mint WETH tokens
        address weth = _addressProvider.getWETH();
        IWETH(weth).deposit{value: ethAmount}();

        // Approve the vault to spend LE & WETH tokens
        IERC20Upgradeable(nativeToken).approve(
            _balancerDetails.vault,
            leAmount
        );
        IERC20Upgradeable(weth).approve(_balancerDetails.vault, ethAmount);

        // Deposit tokens to the pool and get the LP amount
        uint256 oldLPBalance = IERC20Upgradeable(_balancerDetails.pool)
            .balanceOf(address(this));
        // avoid stack too deep errors
        {
            (IERC20[] memory tokens, , ) = IVault(_balancerDetails.vault)
                .getPoolTokens(_balancerDetails.poolId);

            uint256[] memory maxAmountsIn = new uint256[](2);
            uint256[] memory amountsToEncode = new uint256[](2);

            amountsToEncode[
                _findTokenIndex(tokens, IERC20(nativeToken))
            ] = leAmount;
            amountsToEncode[_findTokenIndex(tokens, IERC20(weth))] = ethAmount;
            maxAmountsIn[0] = type(uint256).max;
            maxAmountsIn[1] = type(uint256).max;
            bytes memory userData;

            if (IERC20Upgradeable(_balancerDetails.pool).totalSupply() == 0) {
                userData = abi.encode(
                    WeightedPoolUserData.JoinKind.INIT,
                    amountsToEncode
                );
            } else {
                userData = abi.encode(
                    WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    amountsToEncode,
                    "0"
                );
            }

            // Call the Vault to join the pool
            IVault(_balancerDetails.vault).joinPool(
                _balancerDetails.poolId,
                address(this),
                address(this),
                IVault.JoinPoolRequest({
                    assets: _asIAsset(tokens),
                    maxAmountsIn: maxAmountsIn,
                    userData: userData,
                    fromInternalBalance: false
                })
            );
        }

        uint256 lpAmount = IERC20Upgradeable(_balancerDetails.pool).balanceOf(
            address(this)
        ) - oldLPBalance;

        // Approve the voting escrow to spend LE tokens so they can be locked
        address votingEscrow = _addressProvider.getVotingEscrow();
        IERC20Upgradeable(nativeToken).approve(votingEscrow, totalRewards);

        IVotingEscrow(votingEscrow).createLock(
            msg.sender,
            totalRewards,
            block.timestamp + locktime
        );

        // Send the rest of the ETH to the dev address
        (bool sent, ) = _devAddress.call{value: PRICE * amount - ethAmount}("");
        require(sent, "G:M:ETH_TRANSFER_FAIL");

        uint256 tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIdCounter.current();

            // Add mint details
            _mintDetails[tokenId] = DataTypes.MintDetails(
                SafeCast.toUint40(block.timestamp),
                SafeCast.toUint40(locktime),
                SafeCast.toUint128(lpAmount / amount)
            );

            //Increase supply
            _tokenIdCounter.increment();

            // Mint genesis NFT
            _safeMint(msg.sender, tokenId);

            emit Mint(msg.sender, tokenId);
        }
    }

    /// @notice Get the current price for minting Genesis NFTs
    /// @return The current price in wei
    function getPrice() external pure returns (uint256) {
        return PRICE;
    }

    /// @notice Get the unlock timestamp for a specific Genesis NFT
    /// @param tokenId The ID of the Genesis NFT to check
    /// @return The unlock timestamp for the specified token
    function getUnlockTimestamp(
        uint256 tokenId
    ) public view tokenExists(tokenId) returns (uint256) {
        return _mintDetails[tokenId].timestamp + _mintDetails[tokenId].locktime;
    }

    /// @notice Burn Genesis NFTs and unlock LP tokens and LE tokens
    /// @param tokenIds The IDs of the Genesis NFTs to burn
    function burn(uint256[] calldata tokenIds) external validPool nonReentrant {
        // Make sure we are burning at least one token
        require(tokenIds.length > 0, "G:B:0_TOKENS");
        uint256 lpAmountSum;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //Require the caller owns the token
            require(msg.sender == ownerOf(tokenIds[i]), "G:B:NOT_OWNER");
            // Token can only be burned after locktime is over
            require(
                block.timestamp >= getUnlockTimestamp(tokenIds[i]),
                "G:B:NOT_UNLOCKED"
            );

            // Add the LP amount to the sum
            lpAmountSum += _mintDetails[tokenIds[i]].lpAmount;

            // Burn genesis NFT
            _burn(tokenIds[i]);
            emit Burn(tokenIds[i]);
        }
        // Get the native token address to save on gas
        address nativeTokenAddress = _addressProvider.getNativeToken();

        // Withdraw LP tokens from the pool
        (IERC20[] memory tokens, , ) = IVault(_balancerDetails.vault)
            .getPoolTokens(_balancerDetails.poolId);

        uint256 oldLEBalance = IERC20Upgradeable(nativeTokenAddress).balanceOf(
            address(this)
        );

        uint256[] memory minAmountsOut = new uint256[](2);
        // Call the Vault to exit the pool
        IVault(_balancerDetails.vault).exitPool(
            _balancerDetails.poolId,
            address(this),
            payable(address(this)),
            IVault.ExitPoolRequest({
                assets: _asIAsset(tokens),
                minAmountsOut: minAmountsOut,
                userData: abi.encode(
                    WeightedPoolUserData
                        .ExitKind
                        .EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                    lpAmountSum,
                    _findTokenIndex(tokens, IERC20(nativeTokenAddress))
                ),
                toInternalBalance: false
            })
        );

        uint256 withdrawAmount = IERC20Upgradeable(nativeTokenAddress)
            .balanceOf(address(this)) - oldLEBalance;
        uint256 burnTokens = LP_LE_AMOUNT * tokenIds.length;
        if (withdrawAmount > burnTokens) {
            // Send the rest of the LE tokens to the owner of the Genesis NFT
            IERC20Upgradeable(nativeTokenAddress).transfer(
                msg.sender,
                withdrawAmount - burnTokens
            );
        } else {
            burnTokens = withdrawAmount;
        }
        if (burnTokens > 0) {
            INativeToken(nativeTokenAddress).burnGenesisTokens(burnTokens);
        }
    }

    /// @notice Get the current value of the LP tokens locked in the contract
    /// @param tokenIds The tokens ids of the genesis NFTs associated with the LP tokens
    /// @return The value of the LP tokens in wei
    function getLPValueInLE(
        uint256[] calldata tokenIds
    ) external validPool returns (uint256) {
        uint256 lpAmountSum;
        IVault vault = IVault(_balancerDetails.vault);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Make sure the token exists
            require(_exists(tokenIds[i]), "G:GLPVLE:NOT_FOUND");
            // Add the LP amount to the sum
            lpAmountSum += _mintDetails[tokenIds[i]].lpAmount;
        }

        (IERC20[] memory tokens, , ) = vault.getPoolTokens(
            _balancerDetails.poolId
        );
        uint256[] memory minAmountsOut = new uint256[](2);
        uint256 leIndex = _findTokenIndex(
            tokens,
            IERC20(_addressProvider.getNativeToken())
        );
        // Calculate the value of the LP tokens in LE tokens
        (, uint256[] memory amountsOut) = IBalancerQueries(
            _balancerDetails.queries
        ).queryExit(
                _balancerDetails.poolId,
                address(this),
                address(this),
                IVault.ExitPoolRequest({
                    assets: _asIAsset(tokens),
                    minAmountsOut: minAmountsOut,
                    userData: abi.encode(
                        WeightedPoolUserData
                            .ExitKind
                            .EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                        lpAmountSum,
                        leIndex
                    ),
                    toInternalBalance: false
                })
            );

        uint256 burnTokens = LP_LE_AMOUNT * tokenIds.length;
        if (amountsOut[leIndex] > burnTokens) {
            return amountsOut[leIndex] - burnTokens;
        }

        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable) {
        require(_locked[tokenId] == false, "G:BTT:TOKEN_LOCKED");
        ERC721EnumerableUpgradeable._beforeTokenTransfer(
            from,
            to,
            tokenId,
            batchSize
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721EnumerableUpgradeable,
            ERC165Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _requireOnlyMarket() internal view {
        require(
            msg.sender == _addressProvider.getLendingMarket(),
            "G:NOT_MARKET"
        );
    }

    function _requireTokenExists(uint256 tokenId) internal view {
        require(_exists(tokenId), "G:TOKEN_NOT_FOUND");
    }

    function _requireValidPool() internal view {
        require(_balancerDetails.pool != address(0), "G:M:BALANCER_NOT_SET");
        (IERC20[] memory tokens, , ) = IVault(_balancerDetails.vault)
            .getPoolTokens(_balancerDetails.poolId);
        // Make sure there are only two assets in the pool
        require(tokens.length == 2, "G:M:INVALID_POOL_LENGTH");
        // Make sure those two assets are the native token and WETH
        IERC20 nativeToken = IERC20(_addressProvider.getNativeToken());
        IERC20 weth = IERC20(_addressProvider.getWETH());
        for (uint i = 0; i < 2; i++) {
            require(
                tokens[i] == nativeToken || tokens[i] == weth,
                "G:B:INVALID_POOL_TOKENS"
            );
        }
    }
}
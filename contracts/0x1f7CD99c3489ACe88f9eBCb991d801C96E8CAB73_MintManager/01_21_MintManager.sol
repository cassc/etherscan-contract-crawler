// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { OptimizedFeeList }  from "./libraries/OptimizedFeeList.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IMintable.sol";
import "./SafeOwnable.sol";

// @title Mints NFT tokens in exchange for BabyDoge, BNB or approved stable coins.
// `stableCollector` collects BNB and Stable coins.
// BabyDoge payment is split in 2 parts:
//     1st part is swapped to `targetStableCoin`,
//     2nd part is transferred directly to `babyDogeCollector`
// Owner sets stable coins, that are allowed to be used as payment tokens.
// Owner sets custom Partners' ERC20 tokens, that will be allowed to be used as payment tokens.
// Partner token payment may be split into 3 shares
//     1) admin share - will be swapped to `targetStableCoin`
//     2) partner share - will be transferred directly to partner wallet
//     3) burn share - will be transferred directly to DEAD wallet (burned)
// BNB, BabyDoge and Partners';' tokens prices are dynamically generated based on current BNB/BabyDoge prices
// Mint should be approved by `validator`.
// Owner sets validator.
contract MintManager is EIP712, SafeOwnable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using OptimizedFeeList for OptimizedFeeList.FeesList;
    using SafeERC20 for IERC20;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct MintData {
        IMintable nftContract;
        uint256 tokenId;
        string individualURI;
        uint256 deadline;
        Sig sig;
    }

    struct TokenInData {
        address partnerWallet;
        uint16 adminShare;
        uint16 partnerShare;
        uint8 stableCoinOnlyDecimals;
    }

    // struct for view function
    struct TokenMintPrice {
        address token;
        uint256 mintPrice;
    }

    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address nftContract,address account,uint256 tokenId,string individualURI,uint256 deadline)");
    address private constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    IERC20 public immutable babyDogeToken;
    IRouter public immutable router;
    address private immutable WETH;

    address public validator;
    address public targetStableCoin;
    address public stableCollector;
    uint80 public stableMintPrice;
    uint8 public targetStableCoinDecimals;
    address public babyDogeCollector;
    uint16 public toStableCollectorShare;

    EnumerableSet.AddressSet private approvedStableCoins;   // List of approved stableCoins that can be used for payment
    EnumerableSet.AddressSet private approvedTokensIn;      // List of approved Tokens that can be used for payment

    // ERC20 token address => TokenInData. Contains distribution data for custom tokens IN
    mapping(address => TokenInData) public tokensInData;

    event StableCoinApproved(address stableCoin, bool isApproved);
    event TokenInSet(
        address indexed token,
        uint16 adminShare,
        uint16 partnerShare,
        address partnerWallet
    );
    event TokenInRemoved(address indexed token);
    event MintSettingsUpdate(
        address stableCollector,
        uint80 stableMintPrice,
        uint16 toStableCollectorShare,
        address babyDogeCollector,
        address targetStableCoin
    );
    event ValidatorUpdated(address);

    /*
     * @param _babyDogeToken BabyDoge token address
     * @param _stableCollector Collector of BNB and Stable Coins fees
     * @param _babyDogeCollector Address, which will collect BabyDoge fees without swapping
     * @param _targetStableCoin StableCoin, to which portion of BayDoge tokens will be swapped
     * @param _router Router address
     * @param paymentStableCoins List of payment stable coins to be initially approved as payment tokens
     * @param _stableMintPrice Mint price in stable coins
     * @param _toStableCollectorShare Mint price in BabyDoge tokens
     * @param _validator Validator address
     */
    constructor(
        address _babyDogeToken,
        address _stableCollector,
        address _babyDogeCollector,
        address _targetStableCoin,
        address _router,
        address[] memory paymentStableCoins,
        uint80 _stableMintPrice,
        uint16 _toStableCollectorShare,
        address _validator
    ) EIP712("MintManager", "1") {
        require(
            address(0) != _babyDogeToken
            && address(0) != _stableCollector
            && address(0) != _targetStableCoin
            && address(0) != _router
            && (address(0) != _babyDogeCollector || _toStableCollectorShare == 10_000),
                "invalid address"
        );
        require(_stableMintPrice > 0, "Invalid mint prices");
        require(_toStableCollectorShare > 0 && _toStableCollectorShare <= 10_000, "Invalid share");

        babyDogeToken = IERC20(_babyDogeToken);
        stableCollector = _stableCollector;
        babyDogeCollector = _babyDogeCollector;
        targetStableCoin = _targetStableCoin;
        targetStableCoinDecimals = IERC20Metadata(_targetStableCoin).decimals();
        router = IRouter(_router);
        WETH = IRouter(_router).WETH();

        // Approving BabyDoge to Router
        IERC20(_babyDogeToken).approve(_router, type(uint256).max);

        for (uint i = 0; i < paymentStableCoins.length; i++) {
            require(paymentStableCoins[i] != address(0), "Invalid payment stable coin");
            approvedStableCoins.add(paymentStableCoins[i]);
            tokensInData[paymentStableCoins[i]].stableCoinOnlyDecimals = IERC20Metadata(paymentStableCoins[i]).decimals();
        }

        stableMintPrice = _stableMintPrice;
        toStableCollectorShare = _toStableCollectorShare;


        require(address(0) != _validator, "invalid validator");
        validator = _validator;
    }


    /*
     * @notice Mints token with approved token ID and token URI
     * @param paymentToken Payment token address. Any address for BNB payment
     * @param mintData Array of mint data
     *** nftContract NFT contract address
     *** tokenId Token ID index
     *** deadline Deadline, till which the signature is valid
     *** sig Signature, that approves MintData
     * @dev Signature must be generated by the validator
     * @dev msg.value Should be slightly higher than actual `bnbMintPrice` just in case. Leftover will be returned
     * @dev Signature must be generated by the validator
     */
    function mint (
        address paymentToken,
        MintData[] calldata mintData
    ) external payable nonReentrant {
        uint256 mintNumber = mintData.length;
        // process payment
        if (msg.value > 0) {
            uint256 _bnbMintPrice = bnbMintPrice() * mintNumber;
            require(msg.value >= _bnbMintPrice, "Invalid msg.value");
            (bool success,) = stableCollector.call{ value: _bnbMintPrice }("");
            require(success, "Couldn't collect BNB");

            if (msg.value > _bnbMintPrice) {
                (bool returned,) = msg.sender.call{ value: msg.value - _bnbMintPrice }("");
                require(returned, "Couldn't return BNB");
            }
        } else if (paymentToken == address(babyDogeToken)) {
            address[] memory path = _getTokenSwapPath(paymentToken);
            uint256 _babyDogeMintPrice = _getTokenMintPrice(path) * mintNumber;
            uint256 toStables = _babyDogeMintPrice * toStableCollectorShare / 10_000;
            uint256 toBabyDogeCollector = _babyDogeMintPrice - toStables;

            if (toStables > 0) {
                babyDogeToken.safeTransferFrom(msg.sender, address(this), toStables);

                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    babyDogeToken.balanceOf(address(this)),
                    0,
                    path,
                    stableCollector,
                    block.timestamp
                );
            }

            if (toBabyDogeCollector > 0) {
                babyDogeToken.safeTransferFrom(msg.sender, babyDogeCollector, toBabyDogeCollector);
            }
        } else if (tokensInData[paymentToken].stableCoinOnlyDecimals != 0) {
            IERC20(paymentToken).safeTransferFrom(
                msg.sender,
                stableCollector,
                _getStableCoinMintPrice(paymentToken) * mintNumber
            );
        } else {
            uint16 adminShare = tokensInData[paymentToken].adminShare;
            require(adminShare > 0, "Invalid payment token");
            uint16 partnerShare = tokensInData[paymentToken].partnerShare;

            address[] memory path = _getTokenSwapPath(paymentToken);
            uint256 mintPrice = _getTokenMintPrice(path) * mintNumber;

            uint256 toStables = mintPrice * adminShare / 10_000;
            uint256 toPartners = 0;
            uint256 toBurn = 0;
            if (adminShare + partnerShare == 10_000) {
                toPartners = mintPrice - toStables;
            } else {
                toPartners = mintPrice * partnerShare / 10_000;
                toBurn = mintPrice - (toStables + toPartners);
            }

            if (toStables > 0) {
                IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), toStables);
                if (IERC20(paymentToken).allowance(address(this), address(router)) < toStables) {
                    IERC20(paymentToken).approve(address(router), type(uint256).max);
                }
                router.swapExactTokensForTokens(toStables, 0, path, stableCollector, block.timestamp);
            }

            if (toPartners > 0) {
                IERC20(paymentToken).safeTransferFrom(
                    msg.sender,
                    tokensInData[paymentToken].partnerWallet,
                    toPartners
                );
            }

            if (toBurn > 0) {
                IERC20(paymentToken).safeTransferFrom(msg.sender, DEAD_WALLET, toBurn);
            }
        }

        for (uint i = 0; i < mintData.length; i++) {
            require(bytes(mintData[i].individualURI).length > 0, "Invalid individualURI");
            require (mintData[i].deadline > block.timestamp, 'Overdue order');

            // check signature
            bytes32 mintHash = buildMintHash(
                address(mintData[i].nftContract),
                msg.sender,
                mintData[i].tokenId,
                mintData[i].individualURI,
                mintData[i].deadline
            );
            (address recoveredAddress, ) = ECDSA.tryRecover(
                mintHash,
                mintData[i].sig.v,
                mintData[i].sig.r,
                mintData[i].sig.s
            );
            require(recoveredAddress == validator && recoveredAddress != address(0), 'Bad signature');

            mintData[i].nftContract.mint(
                msg.sender,
                mintData[i].tokenId,
                mintData[i].individualURI
            );
        }
    }


    /*
     * @notice Allows stable coin to be used as payment token
     * @param _stableCoin Stable coin address
     * @param _approved `true` - allow stable coin to be used as payment token. `false` - forbid
     * @dev Can be called only by the Owner
     */
    function approveStableCoin(address _stableCoin, bool _approved) external onlyOwner {
        require(_stableCoin != address(0), "Invalid payment stable coin");
        if (_approved) {
            require(approvedStableCoins.add(_stableCoin), "Already added");
            tokensInData[_stableCoin].stableCoinOnlyDecimals = IERC20Metadata(_stableCoin).decimals();
        } else {
            require(approvedStableCoins.remove(_stableCoin), "Already removed");
            tokensInData[_stableCoin].stableCoinOnlyDecimals = 0;
        }
        emit StableCoinApproved(_stableCoin, _approved);
    }


    /*
     * @notice Allows ERC20 token to be used as payment token / Modifies existing ERC20 custom token data
     * @param token ERC20 token to be approved as TokenIn
     * @param adminShare Admin share in basis points, where 10 000 = 100%
     * @param partnerShare Partners share in basis points, where 10 000 = 100%
     * The rest will be burned
     * @param partnerWallet Address destination of partners share
     * @dev Can be called only by the Owner
     */
    function setTokenIn(
        address token,
        uint16 adminShare,
        uint16 partnerShare,
        address partnerWallet
    ) external onlyOwner {
        require(token != address(0), "Invalid payment token");
        require(partnerWallet != address(0), "Invalid partner wallet");
        require(adminShare > 0, "Invalid adminShare");
        require(adminShare + partnerShare <= 10_000, "Invalid shares amounts");

        approvedTokensIn.add(token);

        tokensInData[token].partnerWallet = partnerWallet;
        tokensInData[token].adminShare = adminShare;
        tokensInData[token].partnerShare = partnerShare;

        emit TokenInSet(token, adminShare, partnerShare, partnerWallet);
    }


    /*
     * @notice Allows ERC20 token to be used as payment token
     * @param token ERC20 token to be approved as TokenIn
     * @dev Can be called only by the Owner
     */
    function removeTokenIn(address token) external onlyOwner {
        require(approvedTokensIn.remove(token), "Already removed");
        delete tokensInData[token];

        emit TokenInRemoved(token);
    }


    /*
     * @notice Updates Mint settings (prices and payment receivers)
     * @param _stableCollector Collector of BNB
     * @param _babyDogeCollector Collector of BabyDoge tokens #2
     * @param _stableMintPrice Price to mint token and pay with Stable coins
     * @param _toStableCollectorShare Share (in basis points, where 10000 = 100%) of BabyDoge payment, which will go to stableCollector
     * @dev Can be called only by the Owner
     */
    function setMintSettings(
        address _stableCollector,
        address _babyDogeCollector,
        address _targetStableCoin,
        uint80 _stableMintPrice,
        uint16 _toStableCollectorShare
    ) external onlyOwner {
        require(
            address(0) != _stableCollector
            && address(0) != _targetStableCoin
            && (address(0) != _babyDogeCollector || _toStableCollectorShare == 10_000),
            "invalid address"
        );
        require(_stableMintPrice > 0, "Invalid mint prices");
        require(_toStableCollectorShare > 0 && _toStableCollectorShare <= 10_000, "Invalid share");

        stableCollector = _stableCollector;
        babyDogeCollector = _babyDogeCollector;
        targetStableCoin = _targetStableCoin;
        targetStableCoinDecimals = IERC20Metadata(_targetStableCoin).decimals();

        stableMintPrice = _stableMintPrice;
        toStableCollectorShare = _toStableCollectorShare;

        emit MintSettingsUpdate(
            _stableCollector,
            _stableMintPrice,
            _toStableCollectorShare,
            _babyDogeCollector,
            _targetStableCoin
        );
    }


    /*
     * @notice Updates validator address
     * @param _validator Address of Mint orders' signer
     * @dev Can be called only by the Owner
     */
    function setValidator(address _validator) external onlyOwner {
        require(address(0) != _validator, "invalid validator");
        require(validator != _validator, "Already set");
        validator = _validator;
        emit ValidatorUpdated(_validator);
    }


    /**
     * @param _stableCoin Stable Coin address
     * @return Is Stable Coin approved to be used as payment token?
     */
    function isApprovedStableCoin(address _stableCoin) public view returns (bool) {
        return approvedStableCoins.contains(_stableCoin);
    }


    /**
     * @param _token ERC20 token address
     * @return Is ERC20 token approved to be used as payment token?
     */
    function isApprovedTokenIn(address _token) public view returns (bool) {
        return approvedTokensIn.contains(_token);
    }


    /**
     * @return List of approved Stable Coins
     */
    function getApprovedStableCoins() public view returns (address[] memory) {
        return approvedStableCoins.values();
    }


    /**
     * @return List of approved custom ERC20 tokens IN
     */
    function getApprovedTokensIn() public view returns (address[] memory) {
        return approvedTokensIn.values();
    }


    /**
     * @return List of ALL tokens that can be used as tokensIn
     */
    function getMintPrices() external view returns (TokenMintPrice[] memory) {
        uint256 numberOfStableCoins = approvedStableCoins.length();
        uint256 numberOfCustomTokens = approvedTokensIn.length();
        uint256 length = 2 + numberOfStableCoins + numberOfCustomTokens;
        TokenMintPrice[] memory prices = new TokenMintPrice[](length);

        prices[0] = TokenMintPrice({
            token: WETH,
            mintPrice: bnbMintPrice()
        });
        prices[1] = TokenMintPrice({
            token: address(babyDogeToken),
            mintPrice: babyDogeMintPrice()
        });
        uint256 index = 2;

        //stable coins
        for (uint i = 0; i < numberOfStableCoins; i++) {
            address token = approvedStableCoins.at(i);
            prices[index] = TokenMintPrice({
                token: token,
                mintPrice: _getStableCoinMintPrice(token)
            });

            index++;
        }

        //custom tokens
        for (uint i = 0; i < numberOfCustomTokens; i++) {
            address tokenAddress = approvedTokensIn.at(i);
            prices[index] = TokenMintPrice({
                token: tokenAddress,
                mintPrice: customTokenMintPrice(tokenAddress)
            });

            index++;
        }

        return prices;
    }


    /**
     * @return Mint price in custom ERC20 tokens
     */
    function customTokenMintPrice(address token) public view returns(uint256) {
        return _getTokenMintPrice(
            _getTokenSwapPath(token)
        );
    }


    /**
     * @return Mint price in BabyDoge tokens
     */
    function babyDogeMintPrice() public view returns(uint256) {
        return customTokenMintPrice(address(babyDogeToken));
    }


    /**
     * @return Mint price in BNB
     */
    function bnbMintPrice() public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = targetStableCoin;
        return router.getAmountsIn(stableMintPrice, path)[0];
    }


    /*
     * @notice Built hash for mint order
     * @param nftContract NFT contract address
     * @param account Future owner address
     * @param tokenId Token ID index
     * @param individualURI Individual token URI
     * @param deadline Deadline, until which order is valid
     * @dev May be used on off-chain to build order hash
     */
    function buildMintHash(
        address nftContract,
        address account,
        uint256 tokenId,
        string calldata individualURI,
        uint256 deadline
    ) public view returns (bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(
            MINT_TYPEHASH,
            nftContract,
            account,
            tokenId,
            keccak256(bytes(individualURI)),
            deadline
        )));
    }


    /**
     * @return path ERC20 token swap path [Token -> WBNB -> targetStableCoin]
     */
    function _getTokenSwapPath(address token) private view returns(address[] memory path) {
        path = new address[](3);
        path[0] = token;
        path[1] = WETH;
        path[2] = targetStableCoin;
    }


    /**
     * @return Mint price in custom ERC20 tokens
     */
    function _getTokenMintPrice(address[] memory path) internal view returns(uint256) {
        return router.getAmountsIn(stableMintPrice, path)[0];
    }


    /**
     * @notice Calculates mint price of single NFT for specific stablecoin
     * @param token Stablecoin address
     * @return mintPrice Mint price stablecoins to mint single NFT
     */
    function _getStableCoinMintPrice(address token) internal view returns (uint256 mintPrice) {
        return uint256(stableMintPrice)
            * 10**tokensInData[token].stableCoinOnlyDecimals
            / 10**targetStableCoinDecimals;
    }
}
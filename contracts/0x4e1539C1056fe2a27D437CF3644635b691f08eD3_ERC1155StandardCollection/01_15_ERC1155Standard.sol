// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//       .;dkkkkkkkkkkkkkkkkkkd'      .:xkkkkkkkkd,           .:dk0XXXXXXXK0xdl,.    .lxkkkkkkkkkkkkkkkkkk:.,okkkkkkko.    .cxkkkkkkxc.      ;dkkkkkko.    //
//      ;xNMMMMMMMMMMMMMMMMMMMX:    .:kNWMMMMMMMMWx.        .l0NWWWWWMMMMMMMMMWNO;..lKWMMMMMMMMMMMMMMMMMMMKkKWMMMMMMMK,  .c0WMMMMMMMMX:   .;xXWMMMMMNo.    //
//    .,lddddddddddddddddxKMMMK;   .,lddddddx0WMMMX;      .;llc::;;::cox0XWMMMMMWXdcoddddddddddddddddONMW0ddddddxXMMMK, .:odddddONMMMMO' .,lddddd0WWd.     //
//    ..                 .dWWKl.   .         :XMMMWx.    ...            .,oKWMMMMWx.                 ,KMNc      .kMMM0, ..      .xWMMMWx'.      'kNk.      //
//    ..                 .dKo'    ..         .xWMMMK;  ..       .'..       ,OWWMMWx.                 ,Okc'      .kMMMK,  ..      ,0MMMMXl.     .dNO'       //
//    ..      .:ooo;......,'      .           :XMMMWd. .      .l0XXOc.      ;xKMWNo.      ,looc'......'...      .kMMMK,   ..      cXMMM0,     .oNK;        //
//    ..      '0MMMk.            ..           .kWMMMK,.'      ;KMMMWNo.     .;kNkc,.     .dWMMK:        ..      .kMMMK,    ..     .dWMXc      cXK:         //
//    ..      '0MMMXkxxxxxxxxd'  .     .:.     cXMMMWd,'      '0MMMMM0l;;;;;;:c;. ..     .dWMMW0xxxxxxxxx;      .kMMMK,     ..     'ONd.     :KXc          //
//    ..      '0MMMMMMMMMMMMMNc ..     :O:     .kMMMMK:.       'd0NWMWWWWWWWNXOl'...     .dWMMMMMMMMMMMMWl      .kMMMK,      .      :d'     ;0No.          //
//    ..      .lkkkkkkkkkKWMMNc .     .dNd.     cNMMMWo..        .':dOXWMMMMMMMWXk:.      :xkkkkkkkk0NMMWl      .kMMMK,       .      .     'ONd.           //
//    ..                .oNMXd...     '0M0'     .kMMMM0, ..           .;o0NMMMMMMWx.                ,0MN0:      .kMMMK,       ..          .kW0'            //
//    ..                 cKk,  .      lNMNl      cNMMMNo  .',..          .;xXWMMMWx.                'O0c'.      .kMMMK,        ..        .xWMO.            //
//    ..      .,ccc,.....,,.  ..     .kMMMk.     .OMMMW0;'d0XX0xc,.         :d0MMWx.      ':cc:'....';. ..      .kMMMK,         ..      .oNMMO.            //
//    ..      '0MMMk.         ..     ,kKKKk'      lNMMMN0KWWWMMMWNKl.         cXMWx.     .dWMMX:        ..      .kMMMK,         ..      .OMMMO.            //
//    ..      '0MMMk'..........       .....       'OMMKo:::::cxNMMMKl'.       .OMWx.     .dWMMXc..........      .kMMMK:.........,'      .OMMMO.            //
//    ..      '0MMMNXKKKKKKKKd.                    lNM0'      ;XMMMWN0c       .OMWd.     .dWMMWXKKKKKKKK0c      .kMMMWXKKKKKKKKK0:      .OMMMO.            //
//    ..      'OWWWWWWWWWWMMNc      'llc'   .      '0MNc      .kWMMMMX:       ,KXx:.     .oNWWWWWWWWWWMMWl      .xWWWWWWWWWWWMMMN:      .OMMMO.            //
//    ..       ,:::::::::cOWO.     .xWWO'   .       oNMO'      .lkOOx;.     .'cd,...      .::::::::::dXMWl       '::::::::::xWMMX:      .OMMWx.            //
//    ..                  dNl      ,0Xd.    ..      ,0MNo.        .        ..'.   ..                 ,0WK:                  :NWOo,      .OWKo.             //
//    .'                 .oO,     .co,       ..     .oOc....             ...      ..                 ,xo,..                 ckl..'.     'dd'               //
//     .............................         ..........       .   ..   .          .....................  .....................   .........                 //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC1155Marketplace.sol";

error AlreadyInitialized();
error BurnNotEnabled();
error ChunkAlreadyProcessed();
error InvalidSender();
error OverTransactionLimit();
error UserAlreadyMinted();

/**
 * @dev This is an implementation of ERC1155 that allows for the creator to sell tokens in a variety of ways. From the ERC1155
 * implementation, each token already has the option to get added with wallet mint limits and token mint limits.
 *
 * First, each tokenId has the ability to sell to users through a restricted sale or whitelist/allowlist option
 * but addresses are only able to do this if they have never minted that token before. This option requires a
 * signature from the owner or the dual signer.
 *
 * Second, each tokenId has the ability to sell through an open sale that has the option to have a certain signature
 * limit and a transaction limit. This requires a valid signature from the owner and the dual signer.
 *
 * Third, each tokenId can open to a general sale at anytime which only has a transaction limit. It does not require a
 * valid signature which makes it more gas efficient than the second method, but requires the owner to send in a transaction.
 *
 * All of these selling mechanisms also allow for both a simple sale or a descending dutch auction.
 */
contract ERC1155StandardCollection is ERC1155Marketplace {
    using ECDSA for bytes32;
    using Strings for uint256;

    bool private hasInit = false;
    bool public burnable;
    bool private requireOwnerOnAllowlist;

    // Compiler will pack this into two 256bit words.
    struct SaleData {
        uint128 price;
        uint128 endPrice;
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint64 txLimit;
    }

    // For tokens that are open to a general sale.
    mapping(uint256 => SaleData) public generalSaleData;

    // So the owner does not repeat airdrops
    mapping(uint256 => bool) processedChunksForOwnerMint;

    event OwnerMinted(uint256 chunk);
    event TokenBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice,
        bytes32 saleHash
    );
    event MintOpen(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint256 endPrice,
        uint256 txLimit
    );
    event MintClosed(uint256 indexed tokenId);

    constructor(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) ERC1155() {
        _init(bools, addresses, uints, strings, signatures);
    }

    function init(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) external {
        _init(bools, addresses, uints, strings, signatures);
    }

    function _init(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) internal {
        if(hasInit) revert AlreadyInitialized();
        hasInit = true;

        burnable = bools[0];

        _owner = _msgSender();
        _initWithdrawSplits(
            addresses[0], // royalty address
            addresses[1], // revenue share address
            addresses[2], // referral address
            addresses[3], // partnership address
            uints[0], // payout BPS
            uints[1], // owner secondary BPS
            uints[2], // revenue share BPS
            uints[3], // referral BPS
            uints[4], // partnership BPS
            signatures
        );
        dualSignerAddress = addresses[4];

        _setName(strings[0]);
        _setSymbol(strings[1]);
    }

    /**
     * @dev updates the name of the collection
     */
    function updateName(string memory name) external onlyOwner {
        _setName(name);
    }

    /**
     * @dev updates the symbol of the collection
     */
    function updateSymbol(string memory symbol) external onlyOwner {
        _setSymbol(symbol);
    }

    /**
     * @dev Allows user to burn an amount of tokens if burn is enabled
     */
    function burnTokens(uint256 tokenId, uint256 amount) external {
        if (!burnable) revert BurnNotEnabled();
        _burn(_msgSender(), tokenId, amount);
    }

    /**
     * @dev This function does a best effort to Owner mint. If a given tokenId is
     * over the token supply amount, it will mint as many are available and stop at the limit.
     * This is necessary so that a given transaction does not fail if another public mint
     * transaction happens to take place just before this one that would cause the amount of
     * minted tokens to go over a token limit.
     */
    function ownerMint(
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 chunkId
    ) external onlyOwner {
        if (processedChunksForOwnerMint[chunkId]) {
            revert ChunkAlreadyProcessed();
        }
        if (
            receivers.length != tokenIds.length ||
            receivers.length != amounts.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 buyLimit = _totalRemainingMints(tokenIds[i]);
            if (buyLimit == 0) {
                continue;
            }

            if (amounts[i] > buyLimit) {
                _mint(receivers[i], tokenIds[i], buyLimit, "");
            } else {
                _mint(receivers[i], tokenIds[i], amounts[i], "");
            }
        }
        processedChunksForOwnerMint[chunkId] = true;
        emit OwnerMinted(chunkId);
    }

    /**
     * @dev Hash that the owner or alternate wallet must sign to enable {mint} for all users
     */
    function _hashForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    allowedAddress,
                    tokenId,
                    version,
                    nonce,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order that we need to check against the signature to see who the signer is.
     * see {_hashForMint} to see the hash that needs to be signed.
     */
    function _hashToCheckForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMintAllow(
                    allowedAddress,
                    tokenId,
                    version,
                    nonce,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash that the owner or approved alternate signer then sign that the approved buyer
     * can use in order to call the {mintAllow} method.
     */
    function hashToSignForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForMintAllow(
                allowedAddress,
                tokenId,
                version,
                nonce,
                amount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev With a hash signed by the method {hashToSignForMintAllow} an approved user with the owner or dual signature
     * can mint at a price up to the quantity specified by the signature. These are all considered primary sales
     * and will be split according to the withdrawal splits defined in the contract.
     */
    function mintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256 buyAmount,
        uint256[4] memory pricesAndTimestamps,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);

        if (buyAmount > amount || buyAmount == 0) revert InvalidBuyAmount();
        if (version != ownerVersion) revert InvalidVersion();
        if (allowedAddress != _msgSender()) revert InvalidSender();

        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();
        if (_totalMinted(_msgSender(), tokenId) > 0) revert UserAlreadyMinted();

        bytes32 hash = _hashToCheckForMintAllow(
            allowedAddress,
            tokenId,
            version,
            nonce,
            amount,
            pricesAndTimestamps
        );
        if (hash.recover(signature) != owner()) {
            if (requireOwnerOnAllowlist || dualSignerAddress == address(0)) {
                revert MustHaveOwnerSignature();
            }
            if (hash.recover(dualSignature) != dualSignerAddress) {
                revert MustHaveDualSignature();
            }
        }

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, hash);
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    /**
     * @dev Hash that the owner or alternate wallet must sign to enable {mint} for all users
     */
    function _hashForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    tokenId,
                    version,
                    amount,
                    sigAmount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order that we need to check against the signature to see who the signer is.
     * see {_hashForMint} to see the hash that needs to be signed.
     */
    function _hashToCheckForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMint(
                    tokenId,
                    version,
                    amount,
                    sigAmount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash that the owner and approved alternate signer then sign that any buyer
     * can use in order to call the {mintWithSignature} method.
     */
    function hashToSignForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForMint(
                tokenId,
                version,
                amount,
                sigAmount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev With a hash signed by the method {hashToSignForMint} any user with the owner and dual signature
     * can mint at a price up to the quantity specified by the signature. These are all considered primary sales
     * and will be split according to the withdrawal splits defined in the contract.
     */
    function mintWithSignature(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 buyAmount,
        uint256 sigAmount,
        uint256[4] calldata pricesAndTimestamps,
        bytes calldata signature,
        bytes calldata dualSignature
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (buyAmount == 0 || (amount != 0 && buyAmount > amount)) {
            revert InvalidBuyAmount();
        }
        if (version != ownerVersion) revert InvalidVersion();
        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForMint(
            tokenId,
            version,
            amount,
            sigAmount,
            pricesAndTimestamps
        );

        _verifySignaturesAndUpdateHash(
            hash,
            owner(),
            sigAmount,
            buyAmount,
            signature,
            dualSignature
        );

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, hash);
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    /**
     * @dev Allows the owner to open the {generalMint} method to the public for a certain tokenId
     * this method is to allow buyers to save gas on minting by not requiring a signature.
     */
    function openMint(
        uint256 tokenId,
        uint128 price,
        uint128 endPrice,
        uint64 startTimestamp,
        uint64 endTimestamp,
        uint64 txLimit
    ) external onlyOwner {
        generalSaleData[tokenId].price = price;
        generalSaleData[tokenId].endPrice = endPrice;
        generalSaleData[tokenId].startTimestamp = startTimestamp;
        generalSaleData[tokenId].endTimestamp = endTimestamp;
        generalSaleData[tokenId].txLimit = txLimit;

        emit MintOpen(
            tokenId,
            startTimestamp,
            endTimestamp,
            price,
            endPrice,
            txLimit
        );
    }

    /**
     * @dev Allows the owner to close the {generalMint} method to the public for a certain tokenId.
     */
    function closeMint(uint256 tokenId) external onlyOwner {
        generalSaleData[tokenId].startTimestamp = 0;
        generalSaleData[tokenId].endTimestamp = 0;
        emit MintClosed(tokenId);
    }

    /**
     * @dev Allows any user to buy a certain tokenId. This buy transaction is still limited by the
     * wallet mint limit, token supply limit, and transaction limit set for the tokenId. These are
     * all considered primary sales and will be split according to the withdrawal splits defined in the contract.
     */
    function mint(uint256 tokenId, uint256 buyAmount) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (
            generalSaleData[tokenId].txLimit != 0 &&
            buyAmount > generalSaleData[tokenId].txLimit
        ) {
            revert OverTransactionLimit();
        }

        uint256[4] memory pricesAndTimestamps = [
            uint256(generalSaleData[tokenId].price),
            uint256(generalSaleData[tokenId].endPrice),
            uint256(generalSaleData[tokenId].startTimestamp),
            uint256(generalSaleData[tokenId].endTimestamp)
        ];
        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, "");
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }
}
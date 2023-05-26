// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interface/ILiqdRentalVault.sol";
import "./interface/ILiqdRentalWallet.sol";
import "./library/NftTransferLibrary.sol";
import "./library/TokenTransferLibrary.sol";

contract LiqdRentalVault is
    ILiqdRentalVault,
    Ownable,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder
{
    using ECDSA for bytes32;

    // events
    event RentalCreated(
        address lender,
        address borrower,
        address collection,
        uint256 tokenId,
        uint32 expireAt,
        NftTransferLibrary.NftTokenType nftTokenType
    );
    event RentalClosed(uint256 rentalId);

    // variables
    address public dao;

    // currency & fee settings
    mapping(address => uint16) public platformFeeByCurrency; // 100 = 1%
    mapping(address => bool) public isAvailableCurrency;

    // signature
    mapping(bytes => bool) public isSignatureUsed;
    mapping(bytes => bool) public isSignatureCancelled;

    // rental
    address public rentalImplementation;
    address public override invokeVerifier;
    mapping(address => uint256[]) public rentalIdsByLender;
    mapping(address => uint256[]) public rentalIdsByBorrower;
    mapping(uint256 => Rental) public rentals;
    mapping(uint256 => RentalSignatures) public rentalSignatures;
    mapping(address => mapping(uint256 => address)) public rentalWallet;
    uint256 public totalRentals;

    constructor(
        address _dao,
        address _rentalImplementation
    ) Ownable() ReentrancyGuard() {
        dao = _dao;
        rentalImplementation = _rentalImplementation;
    }

    function setSignatureCancelled(
        bytes32 payloadHash,
        bytes memory sig
    ) external {
        require(
            payloadHash.toEthSignedMessageHash().recover(sig) == msg.sender,
            "INVALID_SIGNATURE"
        );
        isSignatureCancelled[sig] = true;
    }

    function totalRentalIdsByLender(
        address lender
    ) external view returns (uint256) {
        return rentalIdsByLender[lender].length;
    }

    function totalRentalIdsByBorrower(
        address borrower
    ) external view returns (uint256) {
        return rentalIdsByBorrower[borrower].length;
    }

    function queryRental(
        uint256 rentalId
    ) external view override returns (Rental memory) {
        return rentals[rentalId];
    }

    function setRentalImplementation(
        address _rentalImplementation
    ) external onlyOwner {
        rentalImplementation = _rentalImplementation;
    }

    function setInvokeVerifier(address _verifier) external onlyOwner {
        invokeVerifier = _verifier;
    }

    /// @notice Set platform fee by owner
    /// @param _currency the currency of loan
    /// @param _platformFee platform fee for each currency
    function setPlatformFeeByCurrency(
        address _currency,
        uint16 _platformFee
    ) external onlyOwner {
        require(_platformFee < 1000, "TOO_HIGH_PLATFORM_FEE");
        isAvailableCurrency[_currency] = true;
        platformFeeByCurrency[_currency] = _platformFee;
    }

    /// @notice Remove currency
    /// @param _currency the currency of loan
    function removeAvailableCurrency(address _currency) external onlyOwner {
        require(isAvailableCurrency[_currency] == true, "CURRENCY_NOT_EXIST");
        isAvailableCurrency[_currency] = false;
        platformFeeByCurrency[_currency] = 0;
    }

    /// @notice borrower creates rental request
    /// lender accepts the request
    /// anyone can call this function, but for eth payment, the caller should be borrower
    /// @param _request rental request from borrower
    /// @param _lenderSig rental accept signature from lender
    /// @param _borrowerSig rental request signature from borrower
    function acceptBorrowerRentalRequest(
        TokenRentalRequestFromBorrower memory _request,
        bytes memory _lenderSig,
        bytes memory _borrowerSig
    ) external payable nonReentrant {
        require(_request.lender != _request.borrower, "SAME_LENDER_BORROWER");
        require(isAvailableCurrency[_request.payCurrency], "INVALID_CURRENCY");
        require(_request.expireAt >= _blockTimestamp(), "REQUEST_EXPIRED");
        require(_request.rentalDuration >= 0, "INVALID_RENTAL_DURATION");
        if (_request.payCurrency == TokenTransferLibrary.ETH()) {
            require(msg.value == _request.payAmount, "INVALID_PAY_AMOUNT");
        }

        // always check borrower signature
        _checkValidSignature(_borrowerSig);
        bytes32 _payloadHash = keccak256(
            abi.encode(
                _request.lender,
                _request.borrower,
                _request.collection,
                _request.tokenId,
                _request.nftTokenType,
                _request.payCurrency,
                _request.payAmount,
                _request.rentalDuration,
                _request.expireAt,
                _request.createdAt
            )
        );
        require(
            _payloadHash.toEthSignedMessageHash().recover(_borrowerSig) ==
                _request.borrower,
            "INVALID_BORROWER_SIGNATURE"
        );

        if (msg.sender != _request.lender) {
            // if caller is not lender, need to check lender signature
            _checkValidSignature(_lenderSig);
            require(
                _payloadHash.toEthSignedMessageHash().recover(_lenderSig) ==
                    _request.lender,
                "INVALID_LENDER_SIGNATURE"
            );
        }

        // mark signature as used
        isSignatureUsed[_lenderSig] = true;
        isSignatureUsed[_borrowerSig] = true;

        // receive nft from lender
        NftTransferLibrary.transferNft(
            _request.lender,
            address(this),
            _request.collection,
            _request.tokenId,
            _request.nftTokenType
        );

        // transfer rental fee to lender
        uint256 platformFee = (_request.payAmount *
            platformFeeByCurrency[_request.payCurrency]) / 10000;
        TokenTransferLibrary.transfer(
            _request.borrower,
            _request.lender,
            _request.payCurrency,
            _request.payAmount - platformFee
        );

        if (platformFee > 0) {
            // transfer platform fee to dao
            TokenTransferLibrary.transfer(
                _request.borrower,
                dao,
                _request.payCurrency,
                platformFee
            );
        }

        // create rental
        _createRental(
            _request.lender,
            _request.borrower,
            _request.collection,
            _request.tokenId,
            _request.nftTokenType,
            _blockTimestamp() + _request.rentalDuration,
            _lenderSig,
            _borrowerSig
        );
    }

    /// @notice lender creates rental request
    /// borrower accepts the request
    /// only borrower can call this function
    /// @param _request rental request from lender
    /// @param _lenderSig rental request signature from lender
    function acceptLenderRentalRequest(
        TokenRentalRequestFromLender memory _request,
        bytes memory _lenderSig
    ) external payable nonReentrant {
        address borrower = msg.sender;

        require(_request.lender != borrower, "SAME_LENDER_BORROWER");
        require(isAvailableCurrency[_request.payCurrency], "INVALID_CURRENCY");
        require(_request.expireAt >= _blockTimestamp(), "REQUEST_EXPIRED");
        require(_request.rentalDuration >= 0, "INVALID_RENTAL_DURATION");
        if (_request.payCurrency == TokenTransferLibrary.ETH()) {
            require(msg.value == _request.payAmount, "INVALID_PAY_AMOUNT");
        }

        // check lender signature
        _checkValidSignature(_lenderSig);
        bytes32 _payloadHash = keccak256(
            abi.encode(
                _request.lender,
                _request.collection,
                _request.tokenId,
                _request.nftTokenType,
                _request.payCurrency,
                _request.payAmount,
                _request.rentalDuration,
                _request.expireAt,
                _request.createdAt
            )
        );
        require(
            _payloadHash.toEthSignedMessageHash().recover(_lenderSig) ==
                _request.lender,
            "INVALID_LENDER_SIGNATURE"
        );

        // mark signature as used
        isSignatureUsed[_lenderSig] = true;

        // receive nft from lender
        NftTransferLibrary.transferNft(
            _request.lender,
            address(this),
            _request.collection,
            _request.tokenId,
            _request.nftTokenType
        );

        // transfer rental fee to lender
        uint256 platformFee = (_request.payAmount *
            platformFeeByCurrency[_request.payCurrency]) / 10000;
        TokenTransferLibrary.transfer(
            borrower,
            _request.lender,
            _request.payCurrency,
            _request.payAmount - platformFee
        );

        if (platformFee > 0) {
            // transfer platform fee to dao
            TokenTransferLibrary.transfer(
                borrower,
                dao,
                _request.payCurrency,
                platformFee
            );
        }

        // create rental
        _createRental(
            _request.lender,
            borrower,
            _request.collection,
            _request.tokenId,
            _request.nftTokenType,
            _blockTimestamp() + _request.rentalDuration,
            _lenderSig,
            "0x"
        );
    }

    /// @notice borrwer creates rental request for collection
    /// lender accepts the request
    /// anyone can call this function, but for eth payment, the caller should be borrower
    /// @param _lender lender address
    /// @param _tokenId nft tokenId for rental
    /// @param _request collection rental request
    /// @param _lenderSig collection rental accept signature from lender
    /// @param _borrowerSig collection rental request signature from borrower
    function acceptBorrowerCollectionRentalRequest(
        address _lender,
        uint256 _tokenId,
        CollectionRentalRequestFromBorrower memory _request,
        bytes memory _lenderSig,
        bytes memory _borrowerSig
    ) external payable nonReentrant {
        require(_lender != _request.borrower, "SAME_LENDER_BORROWER");
        require(isAvailableCurrency[_request.payCurrency], "INVALID_CURRENCY");
        require(_request.expireAt >= _blockTimestamp(), "REQUEST_EXPIRED");
        require(_request.rentalDuration >= 0, "INVALID_RENTAL_DURATION");
        if (_request.payCurrency == TokenTransferLibrary.ETH()) {
            require(msg.value == _request.payAmount, "INVALID_PAY_AMOUNT");
        }

        // always check borrower signature
        _checkValidSignature(_borrowerSig);
        bytes32 _borrowerPayloadHash = keccak256(
            abi.encode(
                _request.borrower,
                _request.collection,
                _request.nftTokenType,
                _request.payCurrency,
                _request.payAmount,
                _request.rentalDuration,
                _request.expireAt,
                _request.createdAt
            )
        );
        require(
            _borrowerPayloadHash.toEthSignedMessageHash().recover(
                _borrowerSig
            ) == _request.borrower,
            "INVALID_BORROWER_SIGNATURE"
        );

        if (msg.sender != _lender) {
            // if caller is not lender, need to check lender signature
            _checkValidSignature(_lenderSig);
            bytes32 _lenderPayloadHash = keccak256(
                abi.encode(
                    _lender,
                    _tokenId,
                    _request.borrower,
                    _request.collection,
                    _request.nftTokenType,
                    _request.payCurrency,
                    _request.payAmount,
                    _request.rentalDuration,
                    _request.expireAt,
                    _request.createdAt
                )
            );
            require(
                _lenderPayloadHash.toEthSignedMessageHash().recover(
                    _lenderSig
                ) == _lender,
                "INVALID_LENDER_SIGNATURE"
            );
        }

        // mark signature as used
        isSignatureUsed[_lenderSig] = true;
        isSignatureUsed[_borrowerSig] = true;

        // receive nft from lender
        NftTransferLibrary.transferNft(
            _lender,
            address(this),
            _request.collection,
            _tokenId,
            _request.nftTokenType
        );

        // transfer rental fee to lender
        uint256 platformFee = (_request.payAmount *
            platformFeeByCurrency[_request.payCurrency]) / 10000;
        TokenTransferLibrary.transfer(
            _request.borrower,
            _lender,
            _request.payCurrency,
            _request.payAmount - platformFee
        );

        if (platformFee > 0) {
            // transfer platform fee to dao
            TokenTransferLibrary.transfer(
                _request.borrower,
                dao,
                _request.payCurrency,
                platformFee
            );
        }

        // create rental
        _createRental(
            _lender,
            _request.borrower,
            _request.collection,
            _tokenId,
            _request.nftTokenType,
            _blockTimestamp() + _request.rentalDuration,
            _lenderSig,
            _borrowerSig
        );
    }

    /// @notice return nft back to lender and close the position
    /// @param _rentalId rental ID to close
    function closeRental(uint256 _rentalId) external {
        require(_rentalId < totalRentals, "INVALID_RENTAL_ID");

        Rental storage rental = rentals[_rentalId];
        require(rental.expireAt < _blockTimestamp(), "RENTAL_NOT_EXPIRED");
        require(rental.status == RentalStatus.INRENT, "RENTAL_ALREADY_CLOSED");

        rental.status = RentalStatus.EXPIRED;
        delete rentalWallet[rental.collection][rental.tokenId];

        ILiqdRentalWallet(rental.wallet).withdrawNft();

        // transfer nft to lender
        NftTransferLibrary.transferNft(
            address(this),
            rental.lender,
            rental.collection,
            rental.tokenId,
            rental.nftTokenType
        );

        emit RentalClosed(_rentalId);
    }

    function _createRental(
        address lender,
        address borrower,
        address collection,
        uint256 tokenId,
        NftTransferLibrary.NftTokenType nftTokenType,
        uint32 expireAt,
        bytes memory lenderSig,
        bytes memory borrowerSig
    ) internal {
        address wallet = Clones.clone(rentalImplementation);

        // transfer nft to wallet
        NftTransferLibrary.transferNft(
            address(this),
            wallet,
            collection,
            tokenId,
            nftTokenType
        );

        ILiqdRentalWallet(wallet).initialize(
            borrower,
            collection,
            tokenId,
            nftTokenType,
            totalRentals
        );

        rentals[totalRentals] = Rental({
            lender: lender,
            borrower: borrower,
            wallet: wallet,
            collection: collection,
            tokenId: tokenId,
            expireAt: expireAt,
            nftTokenType: nftTokenType,
            status: RentalStatus.INRENT
        });
        rentalWallet[collection][tokenId] = wallet;
        rentalSignatures[totalRentals] = RentalSignatures({
            lenderSignature: lenderSig,
            borrowerSignature: borrowerSig
        });
        rentalIdsByLender[lender].push(totalRentals);
        rentalIdsByBorrower[borrower].push(totalRentals);
        totalRentals++;

        emit RentalCreated(
            lender,
            borrower,
            collection,
            tokenId,
            expireAt,
            nftTokenType
        );
    }

    function _checkValidSignature(bytes memory signature) internal view {
        require(!isSignatureUsed[signature], "SIGNATURE_ALREADY_USED");
        require(!isSignatureCancelled[signature], "SIGNATURE_CANCELLED");
    }

    function _blockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    /// @notice Ability to withdraw NFT which was airdropped/sent by mistake to lending contract by transferring it into DAO account
    /// @param _contractAddress NFT contract address
    /// @param _tokenId NFT token id
    /// @param _nftTokenType NFT token type (0 - ERC721, 1 - ERC1155, 2 - CryptoPunks)
    function withdrawNft(
        address _contractAddress,
        uint256 _tokenId,
        NftTransferLibrary.NftTokenType _nftTokenType
    ) external {
        require(
            rentalWallet[_contractAddress][_tokenId] == address(0),
            "NFT_IN_RENTAL"
        );

        NftTransferLibrary.transferNft(
            address(this),
            dao,
            _contractAddress,
            _tokenId,
            _nftTokenType
        );
    }

    /// @notice Ability to withdraw any ERC20 token which was airdropped/sent by mistake to lending contract by transferring it into DAO account
    /// @param _tokenAddress ERC20 token address
    function withdrawToken(address _tokenAddress) external {
        TokenTransferLibrary.transfer(
            address(this),
            dao,
            _tokenAddress,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }
}
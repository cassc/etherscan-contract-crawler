// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PWNLOAN is ERC1155, Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * Necessary msg.sender for all LOAN related manipulations
     */
    address public PWN;

    /**
     * Incremental LOAN ID counter
     */
    uint256 public id;

    /**
     * EIP-1271 valid signature magic value
     */
    bytes4 constant internal EIP1271_VALID_SIGNATURE = 0x1626ba7e;

    /**
     * EIP-712 offer struct type hash
     */
    bytes32 constant internal OFFER_TYPEHASH = keccak256(
        "Offer(address collateralAddress,uint8 collateralCategory,uint256 collateralAmount,uint256 collateralId,address loanAssetAddress,uint256 loanAmount,uint256 loanYield,uint32 duration,uint40 expiration,address lender,bytes32 nonce)"
    );

    /**
     * EIP-712 flexible offer struct type hash
     */
    bytes32 constant internal FLEXIBLE_OFFER_TYPEHASH = keccak256(
        "FlexibleOffer(address collateralAddress,uint8 collateralCategory,uint256 collateralAmount,bytes32 collateralIdsWhitelistMerkleRoot,address loanAssetAddress,uint256 loanAmountMax,uint256 loanAmountMin,uint256 loanYieldMax,uint32 durationMax,uint32 durationMin,uint40 expiration,address lender,bytes32 nonce)"
    );

    /**
     * Construct defining a LOAN which is an acronym for: ... (TODO)
     * @param status 0 == none/dead || 2 == running/accepted offer || 3 == paid back || 4 == expired
     * @param borrower Address of the borrower - stays the same for entire lifespan of the token
     * @param duration Loan duration in seconds
     * @param expiration Unix timestamp (in seconds) setting up the default deadline
     * @param collateral Asset used as a loan collateral. Consisting of another `Asset` struct defined in the MultiToken library
     * @param asset Asset to be borrowed by lender to borrower. Consisting of another `Asset` struct defined in the MultiToken library
     * @param loanRepayAmount Amount of LOAN asset to be repaid
     */
    struct LOAN {
        uint8 status;
        address borrower;
        uint32 duration;
        uint40 expiration;
        MultiToken.Asset collateral;
        MultiToken.Asset asset;
        uint256 loanRepayAmount;
    }

    /**
     * Construct defining an Offer
     * @param collateralAddress Address of an asset used as a collateral
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155)
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 1
     * @param collateralId Token id of an asset used as a collateral, in case of ERC20 should be 0
     * @param loanAssetAddress Address of an asset which is lended to borrower
     * @param loanAmount Amount of tokens which is offered as a loan to borrower
     * @param loanYield Amount of tokens which acts as a lenders loan interest. Borrower has to pay back borrowed amount + yield.
     * @param duration Loan duration in seconds
     * @param expiration Offer expiration timestamp in seconds
     * @param lender Address of a lender. This address has to sign an offer to be valid.
     * @param nonce Additional value to enable identical offers in time. Without it, it would be impossible to make again offer, which was once revoked.
     */
    struct Offer {
        address collateralAddress;
        MultiToken.Category collateralCategory;
        uint256 collateralAmount;
        uint256 collateralId;
        address loanAssetAddress;
        uint256 loanAmount;
        uint256 loanYield;
        uint32 duration;
        uint40 expiration;
        address lender;
        bytes32 nonce;
    }

    /**
     * Construct defining an Flexible offer
     * @param collateralAddress Address of an asset used as a collateral
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155)
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 1
     * @param collateralIdsWhitelistMerkleRoot Root of a merkle tree constructed on array of whitelisted collateral ids
     * @param loanAssetAddress Address of an asset which is lended to borrower
     * @param loanAmountMax Max amount of tokens which is offered as a loan to borrower
     * @param loanAmountMin Min amount of tokens which is offered as a loan to borrower
     * @param loanYieldMax Amount of tokens which acts as a lenders loan interest for max duration.
     * @param durationMax Max loan duration in seconds
     * @param durationMin Min loan duration in seconds
     * @param expiration Offer expiration timestamp in seconds
     * @param lender Address of a lender. This address has to sign a flexible offer to be valid.
     * @param nonce Additional value to enable identical offers in time. Without it, it would be impossible to make again offer, which was once revoked.
     */
    struct FlexibleOffer {
        address collateralAddress;
        MultiToken.Category collateralCategory;
        uint256 collateralAmount;
        bytes32 collateralIdsWhitelistMerkleRoot;
        address loanAssetAddress;
        uint256 loanAmountMax;
        uint256 loanAmountMin;
        uint256 loanYieldMax;
        uint32 durationMax;
        uint32 durationMin;
        uint40 expiration;
        address lender;
        bytes32 nonce;
    }

    /**
     * Construct defining an Flexible offer concrete values
     * @param collateralId Selected collateral id to be used as a collateral.
     * @param loanAmount Selected loan amount to be borrowed from lender.
     * @param duration Selected loan duration. Shorter duration reflexts into smaller loan yield for a lender.
     * @param merkleInclusionProof Proof of inclusion, that selected collateral id is whitelisted. This proof should create same hash as the merkle tree root given in flexible offer.
     */
    struct FlexibleOfferValues {
        uint256 collateralId;
        uint256 loanAmount;
        uint32 duration;
        bytes32[] merkleInclusionProof;
    }

    /**
     * Mapping of all LOAN data by loan id
     */
    mapping (uint256 => LOAN) public LOANs;

    /**
     * Mapping of revoked offers by offer struct typed hash
     */
    mapping (bytes32 => bool) public revokedOffers;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event LOANCreated(uint256 indexed loanId, address indexed lender, bytes32 indexed offerHash);
    event OfferRevoked(bytes32 indexed offerHash);
    event PaidBack(uint256 loanId);
    event LOANClaimed(uint256 loanId);

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyPWN() {
        require(msg.sender == PWN, "Caller is not the PWN");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /*
     * PWN LOAN constructor
     * @dev Creates the PWN LOAN token contract - ERC1155 with extra use case specific features
     * @dev Once the PWN contract is set, you'll have to call `this.setPWN(PWN.address)` for this contract to work
     * @param _uri Uri to be used for finding the token metadata
     */
    constructor(string memory _uri) ERC1155(_uri) Ownable() {

    }

    /**
     * All contracts of this section can only be called by the PWN contract itself - once set via `setPWN(PWN.address)`
     */

    /**
     * revokeOffer
     * @notice Revoke an offer
     * @dev Offer is revoked by lender or when offer is accepted by borrower to prevent accepting it twice
     * @param _offerHash Offer typed struct hash
     * @param _signature Offer typed struct signature
     * @param _sender Address of a message sender (lender)
     */
    function revokeOffer(
        bytes32 _offerHash,
        bytes calldata _signature,
        address _sender
    ) external onlyPWN {
        require(ECDSA.recover(_offerHash, _signature) == _sender, "Sender is not an offer signer");
        require(revokedOffers[_offerHash] == false, "Offer is already revoked or has been accepted");

        revokedOffers[_offerHash] = true;

        emit OfferRevoked(_offerHash);
    }

    /**
     * create
     * @notice Creates the PWN LOAN token - ERC1155 with extra use case specific features from simple offer
     * @dev Contract wallets need to implement EIP-1271 to validate signature on the contract behalf
     * @param _offer Offer struct holding plain offer data
     * @param _signature Offer typed struct signature signed by lender
     * @param _sender Address of a message sender (borrower)
     */
    function create(
        Offer memory _offer,
        bytes memory _signature,
        address _sender
    ) external onlyPWN {
        bytes32 offerHash = keccak256(abi.encodePacked(
            "\x19\x01", _eip712DomainSeparator(), hash(_offer)
        ));

        _checkValidSignature(_offer.lender, offerHash, _signature);
        _checkValidOffer(_offer.expiration, offerHash);

        revokedOffers[offerHash] = true;

        uint256 _id = ++id;

        LOAN storage loan = LOANs[_id];
        loan.status = 2;
        loan.borrower = _sender;
        loan.duration = _offer.duration;
        loan.expiration = uint40(block.timestamp) + _offer.duration;
        loan.collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId
        );
        loan.asset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offer.loanAmount,
            0
        );
        loan.loanRepayAmount = _offer.loanAmount + _offer.loanYield;

        _mint(_offer.lender, _id, 1, "");

        emit LOANCreated(_id, _offer.lender, offerHash);
    }

    /**
     * createFlexible
     * @notice Creates the PWN LOAN token - ERC1155 with extra use case specific features from flexible offer
     * @dev Contract wallets need to implement EIP-1271 to validate signature on the contract behalf
     * @param _offer Flexible offer struct holding plain flexible offer data
     * @param _offerValues Concrete values of a flexible offer set by borrower
     * @param _signature FlexibleOffer typed struct signature signed by lender
     * @param _sender Address of a message sender (borrower)
     */
    function createFlexible(
        FlexibleOffer memory _offer,
        FlexibleOfferValues memory _offerValues,
        bytes memory _signature,
        address _sender
    ) external onlyPWN {
        bytes32 offerHash = keccak256(abi.encodePacked(
            "\x19\x01", _eip712DomainSeparator(), hash(_offer)
        ));

        _checkValidSignature(_offer.lender, offerHash, _signature);
        _checkValidOffer(_offer.expiration, offerHash);

        // Flexible collateral id
        if (_offer.collateralIdsWhitelistMerkleRoot != bytes32(0x00)) {
            // Whitelisted collateral id
            bytes32 merkleTreeLeaf = keccak256(abi.encodePacked(_offerValues.collateralId));
            require(MerkleProof.verify(_offerValues.merkleInclusionProof, _offer.collateralIdsWhitelistMerkleRoot, merkleTreeLeaf), "Selected collateral id is not contained in whitelist");
        } // else: Any collateral id - collection offer

        // Flexible amount
        require(_offer.loanAmountMin <= _offerValues.loanAmount && _offerValues.loanAmount <= _offer.loanAmountMax, "Loan amount is not in offered range");

        // Flexible duration
        require(_offer.durationMin <= _offerValues.duration && _offerValues.duration <= _offer.durationMax, "Loan duration is not in offered range");

        revokedOffers[offerHash] = true;

        uint256 _id = ++id;

        LOAN storage loan = LOANs[_id];
        loan.status = 2;
        loan.borrower = _sender;
        loan.duration = _offerValues.duration;
        loan.expiration = uint40(block.timestamp) + _offerValues.duration;
        loan.collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offerValues.collateralId
        );
        loan.asset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offerValues.loanAmount,
            0
        );
        loan.loanRepayAmount = countLoanRepayAmount(
            _offerValues.loanAmount,
            _offerValues.duration,
            _offer.loanYieldMax,
            _offer.durationMax
        );

        _mint(_offer.lender, _id, 1, "");

        emit LOANCreated(_id, _offer.lender, offerHash);
    }

    /**
     * repayLoan
     * @notice Function to make proper state transition
     * @param _loanId ID of the LOAN which is paid back
     */
    function repayLoan(uint256 _loanId) external onlyPWN {
        require(getStatus(_loanId) == 2, "Loan is not running and cannot be paid back");

        LOANs[_loanId].status = 3;

        emit PaidBack(_loanId);
    }

    /**
     * claim
     * @notice Function that would set the LOAN to the dead state if the token is in paidBack or expired state
     * @param _loanId ID of the LOAN which is claimed
     * @param _owner Address of the LOAN token owner
     */
    function claim(
        uint256 _loanId,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _loanId) == 1, "Caller is not the loan owner");
        require(getStatus(_loanId) >= 3, "Loan can't be claimed yet");

        LOANs[_loanId].status = 0;

        emit LOANClaimed(_loanId);
    }

    /**
     * burn
     * @notice Function that would burn the LOAN token if the token is in dead state
     * @param _loanId ID of the LOAN which is burned
     * @param _owner Address of the LOAN token owner
     */
    function burn(
        uint256 _loanId,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _loanId) == 1, "Caller is not the loan owner");
        require(LOANs[_loanId].status == 0, "Loan can't be burned at this stage");

        delete LOANs[_loanId];
        _burn(_owner, _loanId, 1);
    }

    /**
     * countLoanRepayAmount
     * @notice Count a loan repay amount of flexible offer based on a loan amount and duration.
     * @notice The smaller the duration is, the smaller is the lenders yield.
     * @notice Loan repay amount is decreasing linearly from maximum duration and is fixing loans APR.
     * @param _loanAmount Selected amount of loan asset by borrower
     * @param _duration Selected loan duration by borrower
     * @param _loanYieldMax Yield for maximum loan duration set by lender in an offer
     * @param _durationMax Maximum loan duration set by lender in an offer
     */
    function countLoanRepayAmount(
        uint256 _loanAmount,
        uint32 _duration,
        uint256 _loanYieldMax,
        uint32 _durationMax
    ) public pure returns (uint256) {
        return _loanAmount + _loanYieldMax * _duration / _durationMax;
    }

    /*----------------------------------------------------------*|
    |*  ## VIEW FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    /**
     * getStatus
     * @dev used in contract calls & status checks and also in UI for elementary loan status categorization
     * @param _loanId LOAN ID checked for status
     * @return a status number
     */
    function getStatus(uint256 _loanId) public view returns (uint8) {
        if (LOANs[_loanId].expiration > 0 && LOANs[_loanId].expiration < block.timestamp && LOANs[_loanId].status != 3) {
            return 4;
        } else {
            return LOANs[_loanId].status;
        }
    }

    /**
     * getExpiration
     * @dev utility function to find out exact expiration time of a particular LOAN
     * @dev for simple status check use `this.getStatus(did)` if `status == 4` then LOAN has expired
     * @param _loanId LOAN ID to be checked
     * @return unix time stamp in seconds
     */
    function getExpiration(uint256 _loanId) external view returns (uint40) {
        return LOANs[_loanId].expiration;
    }

    /**
     * getDuration
     * @dev utility function to find out loan duration period of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return loan duration period in seconds
     */
    function getDuration(uint256 _loanId) external view returns (uint32) {
        return LOANs[_loanId].duration;
    }

    /**
     * getBorrower
     * @dev utility function to find out a borrower address of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return address of the borrower
     */
    function getBorrower(uint256 _loanId) external view returns (address) {
        return LOANs[_loanId].borrower;
    }

    /**
     * getCollateral
     * @dev utility function to find out collateral asset of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getCollateral(uint256 _loanId) external view returns (MultiToken.Asset memory) {
        return LOANs[_loanId].collateral;
    }

    /**
     * getLoanAsset
     * @dev utility function to find out loan asset of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getLoanAsset(uint256 _loanId) external view returns (MultiToken.Asset memory) {
        return LOANs[_loanId].asset;
    }

    /**
     * getLoanRepayAmount
     * @dev utility function to find out loan repay amount of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Amount of loan asset to be repaid
     */
    function getLoanRepayAmount(uint256 _loanId) external view returns (uint256) {
        return LOANs[_loanId].loanRepayAmount;
    }

    /**
     * isRevoked
     * @dev utility function to find out if offer is revoked
     * @param _offerHash Offer typed struct hash
     * @return True if offer is revoked
     */
    function isRevoked(bytes32 _offerHash) external view returns (bool) {
        return revokedOffers[_offerHash];
    }

    /*--------------------------------*|
    |*  ## SETUP FUNCTIONS            *|
    |*--------------------------------*/

    /**
     * setPWN
     * @dev An essential setup function. Has to be called once PWN contract was deployed
     * @param _address Identifying the PWN contract
     */
    function setPWN(address _address) external onlyOwner {
        PWN = _address;
    }

    /**
     * setUri
     * @dev An non-essential setup function. Can be called to adjust the LOAN token metadata URI
     * @param _newUri setting the new origin of LOAN metadata
     */
    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

    /*--------------------------------*|
    |*  ## PRIVATE FUNCTIONS          *|
    |*--------------------------------*/

    /**
     * _eip712DomainSeparator
     * @notice Compose EIP712 domain separator
     * @dev Domain separator is composing to prevent repay attack in case of an Ethereum fork
     */
    function _eip712DomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PWN")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    /**
     * _checkValidSignature
     * @notice
     * @param _lender Address of a lender. This address has to sign an offer to be valid.
     * @param _offerHash Hash of an offer EIP-712 data struct
     * @param _signature Signed offer data
     */
    function _checkValidSignature(
        address _lender,
        bytes32 _offerHash,
        bytes memory _signature
    ) private view {
        if (_lender.code.length > 0) {
            require(IERC1271(_lender).isValidSignature(_offerHash, _signature) == EIP1271_VALID_SIGNATURE, "Signature on behalf of contract is invalid");
        } else {
            require(ECDSA.recover(_offerHash, _signature) == _lender, "Lender address didn't sign the offer");
        }
    }

    /**
     * _checkValidOffer
     * @notice
     * @param _expiration Offer expiration timestamp in seconds
     * @param _offerHash Hash of an offer EIP-712 data struct
     */
    function _checkValidOffer(
        uint40 _expiration,
        bytes32 _offerHash
    ) private view {
        require(_expiration == 0 || block.timestamp < _expiration, "Offer is expired");
        require(revokedOffers[_offerHash] == false, "Offer is revoked or has been accepted");
    }

    /**
     * hash offer
     * @notice Hash offer struct according to EIP-712
     * @param _offer Offer struct to be hashed
     * @return Offer struct hash
     */
    function hash(Offer memory _offer) private pure returns (bytes32) {
        return keccak256(abi.encode(
            OFFER_TYPEHASH,
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId,
            _offer.loanAssetAddress,
            _offer.loanAmount,
            _offer.loanYield,
            _offer.duration,
            _offer.expiration,
            _offer.lender,
            _offer.nonce
        ));
    }

    /**
     * hash offer
     * @notice Hash flexible offer struct according to EIP-712
     * @param _offer FlexibleOffer struct to be hashed
     * @return FlexibleOffer struct hash
     */
    function hash(FlexibleOffer memory _offer) private pure returns (bytes32) {
        // Need to divide encoding into smaller parts because of "Stack to deep" error

        bytes memory encodedOfferCollateralData = abi.encode(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralIdsWhitelistMerkleRoot
        );

        bytes memory encodedOfferLoanData = abi.encode(
            _offer.loanAssetAddress,
            _offer.loanAmountMax,
            _offer.loanAmountMin,
            _offer.loanYieldMax
        );

        bytes memory encodedOfferOtherData = abi.encode(
            _offer.durationMax,
            _offer.durationMin,
            _offer.expiration,
            _offer.lender,
            _offer.nonce
        );

        return keccak256(abi.encodePacked(
            FLEXIBLE_OFFER_TYPEHASH,
            encodedOfferCollateralData,
            encodedOfferLoanData,
            encodedOfferOtherData
        ));
    }
}
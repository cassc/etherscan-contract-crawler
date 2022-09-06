// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.10;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/* 
    @title SwopXLendingAssets 
    it is for borrowers and lenders to sign messages
*/
contract SwopXLendingAssets is EIP712 {

    constructor()  EIP712("SwopXLending","1.0"){
 
    }

   /*
    * @notice: The _hashLending function is called in the submit function
    * The lender needs to sign :  
    * @param nonce uint256  
    * @param paymentContract address of the utility token address ERC20
    * @param offeredTime uint256 is the timestamp on which an offer will expire
    * @param totalPrincipal is the total loan amount  
    * @param totalInterest is the total interest of the loan amount
    * @param nftcontract address is the NFT contract address ERC721
    * @param nftOwner is the address of the NFT owner
    * @param nftTokenId uint256 is the NFT token ID 
    * @param gist bytes32 is the root of a merkle tree (merkletreejs) that contrains payments
    * @retrun bytes32
    */
    function _hashLending(uint256 nonce,address paymentContract,
        uint256 offeredTime,uint256 totalPrincipal,uint256 totalInterest,
        address nftcontract,address nftOwner,
        uint256 nftTokenId,bytes32 gist) 
        public view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Landing(uint256 nonce,address paymentContract,uint256 offeredTime,uint256 totalPrincipal,uint256 totalInterest,address nftcontract,address nftOwner,uint256 nftTokenId,bytes32 gist)"),
            nonce,
            paymentContract,
            offeredTime,
            totalPrincipal,
            totalInterest,
            nftcontract,
            nftOwner,
            nftTokenId,            
            gist
        )));
    }

    /*
    * @notice: The _hashBorrower function is called in the submit and extendTheTime functions
    * The borrower needs to sign :  
    * @param nonce uint256  
    * @param nftcontract address is the NFT contract address ERC721
    * @param nftTokenId uint256 is the NFT token ID 
    * @param gist bytes32 is the root of a merkle tree (merkletreejs) that contrains payments
    * @retrun bytes32
    */
    function _hashBorrower(uint256 nonce,address nftcontract,uint256 nftTokenId, bytes32 gist) 
        public view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Borrowing(uint256 nonce,address nftcontract,uint256 nftTokenId,bytes32 gist)"),
            nonce,
            nftcontract,
            nftTokenId,           
            gist
        )));
    }

    /*
    * @notice: The _hashextend function is called in the extendTheTime function
    * Inorder to extend the loan time, the lender needs to sign :  
    * @param nonce uint256  
    * @param nftcontract address is the NFT contract address ERC721
    * @param nftTokenId uint256 is the NFT token ID 
    * @param offerTime uint256 is the timestamp on which an offer will expire
    * @param totalInterest is a new total interest of the old loan amount
    * @param gist bytes32 is the root of a merkle tree (merkletreejs) that contrains payments
    * @retrun bytes32
    */
    function _hashextend(uint256 nonce,address nftcontract,
    uint256 nftTokenId, uint256 offerTime, uint256 totalInterest, bytes32 gist) 
    internal view returns (bytes32)
 
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Extending(uint256 nonce,address nftcontract,uint256 nftTokenId,uint256 offerTime,uint256 totalInterest,bytes32 gist)"),
            nonce,
            nftcontract,
            nftTokenId,
            offerTime,
            totalInterest,
            gist
        )));
    }

    function _verify(address signer, bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }

}

/* 
    @title SwopXLending 
    it is for borrow utility tokens against NFTs
*/
contract SwopXLending is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard, IERC721Receiver, SwopXLendingAssets, Pausable {
    /********************************************************************************************/
    /*                                        VARIABLES                                         */
    /********************************************************************************************/
    
    address immutable receiverAddress = address(this);
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    // _IdCounter, is used to keep track of a new loan. Every new loan is counted
    // it is increased in the counter function
    Counters.Counter private _IdCounter;
    // _nftCounter, is used to keep track of a new NFTs. Every new loan is counted, there is two NFTs are created for (the borrower and lender)
    // it is increased in the nftCounter function
    Counters.Counter private _nftCounter; 
    // txfee is only fee for startting a new loan and is called in submit function  
    uint256 private txfee;
    // txInterestfee is fee for paying the interest fee. It is called in make payment, pre payment, and default functions
    uint256 private txInterestfee;
    // string private _baseMetadata; // it is added onto ERC721 

    struct LendingAssets {
        address paymentContract;    // ERC20 address 
        uint256 listingTime;        // start time stamp
        uint256 totalPrincipal;     // loan amount
        uint256 totalInterest;      // laon interest 
        uint256 totalInterestPaid;  // total paid of interest
        uint256 totalAmountLoan;    // laon amount + loan interest
        uint256 totalAmountPaid;    // total paid of amount and interest
        uint256 termId;             // Loan term in schedule 
        bool isPaid;                // If the loan is paid
        uint256 lenderNonce;        // Nonce of lender sign
        uint256 borrowerNonce;      // Nonce of borrowr sign
        address nftcontract;        // NFT contract 
        uint256 nftTokenId;         // NFT token ID
        bytes32 gist;               // Root of merkle tree
    }

    // Receipt is to keep track of the nft id
    struct Receipt {
        uint256 lenderToken;        // Lender NFT receipt
        uint256 borrowerToken;      // borrower NFT receipt
    }

    mapping(uint256 => LendingAssets) private _assets;
    mapping(uint256 => Receipt) private _receipt;

    // payment contract address has to be added by the admin/owner of the contract
    // WETH, WBTC, USDT, USDC
    mapping(IERC20=> bool) private erc20Addrs;

    // mapping each address and nonce that is used to sign a message => a boolean
    // A sign can be canceled using the cancel function before run the submit function
    mapping(address => mapping(uint256 => bool)) private identifiedSignature;

    /********************************************************************************************/
    /*                                       EVENTS                                             */
    /********************************************************************************************/
    
    // AssetsLog event is called in the submit function for starting a new lending/borowing  
    event AssetsLog(
        uint256 counter,
        address indexed owner,
        uint256 borrowerNonce,
        uint256 lenderNonce,
        address indexed tokenAddress,
        uint256 tokenId,
        address indexed lender,
        address currentAddress,
        uint256 totalPrincipal,
        uint256 totalInterest,
        uint256 totalAmountLoan,
        bytes32 gist
    );
    
    // CancelLog event is called in the cancel function for canceling a sign
    event CancelLog(address indexed lender, uint256 nonce, bool IsUninterested);
    
    // WithdrawLog event is called in the withdraw function for withdraing fees
    event WithdrawLog(address indexed contracts, address indexed account, uint amount);
    
    // ExtendTimeLog event is called in the extendTheTime function for extending the laon term schedule
    event ExtendTimeLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address lender,address borrower, uint256 currentTerm, uint256 totalAmountLoan, bytes32 gist  );
    
    // PrePayLog event is called in the makePrePayment function 
    event PrePayLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, uint256 paidAmount, uint256 currentTerm, uint256 fee, bytes32 [] preProof, bool isPaid);

    // PayLog and PaymentLog event are called in the makePayment function 
    event PayLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, uint256 paidAmount, uint256 currentTerm, uint256 fee,bytes32 [] proof);

    event PaymentLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, bool isPaid);

    // DefaultLog event is called in the default function 
    event DefaultLog(uint256 indexed counterId, address nftcontract, uint256 tokenId, address indexed lender, uint256 fee);
        
    // FeeLog event is called in the resetTxFee function 
    event FeeLog(address account, uint256 loanFee, uint256 interestFee );
    
    // CryptoLog FeeLog event is called in the addToken function
    event CryptoLog(address contracts, bool isSupported);
    
    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/
    
    /*
    * @notice: only owner of the contract is allowed to change fees
    * _fee is 2% of the laon amount and only runs in the submit function 
    * _txInterestfee is 10% of the loan interest's fees 
    */
    constructor() ERC721("SwopX Lending", "SLPR") {
        txfee = 200;
        txInterestfee = 1000;
    }

    /********************************************************************************************/
    /*                                       MODIFIER FUNCTIONS                            */
    /********************************************************************************************/
  
    /*
    * A cryptocurrency address has to be supported
    */
    modifier supportInterface(address _contract) {
        require(erc20Addrs[IERC20(_contract)] == true,"Contract address is not Supported ");
        _;
    }

    /*
    * No zero address is allowed
    */
    modifier zeroAddress(address _contract) {
        require( _contract != address(0) , "Zero Address");
        _;
    }

    // /*
    // * if the loan is expired 
    // */
    // modifier timeExpired(uint256 _time) {
    //     require(_time>= block.timestamp,"Expired");
    //     _;
    // }

    /********************************************************************************************/
    /*                                       LOAN CONTRACT FUNCTIONS                            */ 
    /********************************************************************************************/
  
    /*
    * @notice: only owner of the contract is allowed to change fees
    * @param _fee uint256 is the submit fees 
    * @param _txInterestfee interest's fees
    */
    function resetTxFee(uint256 _fee, uint256 _txInterestfee) external onlyOwner { 
        txfee = _fee;
        txInterestfee = _txInterestfee;
        emit FeeLog(msg.sender, txfee, txInterestfee);
    }


    /*
    * @notice: addToken function for adding cryptocurancy contract address 
    * @param _contract address is a contract address  
    * @param _mode bool true/ false 
    */
    function addToken(address _contract, bool _mode) external 
    zeroAddress(_contract) onlyOwner {
        erc20Addrs[IERC20(_contract)] = _mode;
        emit CryptoLog(_contract, _mode) ;
    }

    /*
    * @notice: check if a cryptocurrency address is supported
    */
    function currencyTokens(address _contract) external
    zeroAddress(_contract) view returns(bool){
        return erc20Addrs[IERC20(_contract)];
    }

    /*
    * @notice: _timeExpired is called in make payment, pre payment, and default functions
    * This is to give the borrower 7 days before their NFTs get defaulted or make a payment.
    */
    function _timeExpired(uint256 time) private pure returns(uint256) {
        return 7 days + time;
    }

    /* 
    * @notice: assets to read from the storage on the contract
    *   paymentAddress is the cryptocurrency address 
        listingTime is the start time of the loan
        termId is the current term 
        nftContractAddress is the nft contract address
        nftTokenId is an nft id
        totalPrincipal is the total principal of this loan
        totalInterest is the total interest of this loan
        totalInterestPaid is interest of what the borrower has paid
        totalAmountLoan is totalPrincipal + totalInterest
        totalAmountPaid is what the borrower has paid incloduing principal and interest
        isPaid if the total loan is paid
    */ 
    function assets(uint256 counterId) external view returns (
        address paymentAddress,
        uint256 listingTime,
        uint256 termId,
        address nftContractAddress, uint256 nftTokenId,
        uint256 totalPrincipal, uint256 totalInterest, uint256 totalInterestPaid,
        uint256 totalAmountLoan, uint256 totalAmountPaid, bool isPaid) {

        paymentAddress = _assets[counterId].paymentContract;
        listingTime = _assets[counterId].listingTime;
        termId = _assets[counterId].termId;
        nftContractAddress = _assets[counterId].nftcontract;
        nftTokenId = _assets[counterId].nftTokenId;
        totalPrincipal = _assets[counterId].totalPrincipal;
        totalInterest = _assets[counterId].totalInterest;
        totalInterestPaid = _assets[counterId].totalInterestPaid;
        totalAmountLoan = _assets[counterId].totalAmountLoan;
        totalAmountPaid = _assets[counterId].totalAmountPaid;
        isPaid = _assets[counterId].isPaid;
    }
   
   /* 
    * @notice: returns the token id of lending protocol id. 
    */  
    function receipt(uint256 counterId) external view returns (
        uint256 lenderToken,
        uint256 borrowerToken) {
            lenderToken = _receipt[counterId].lenderToken;
            borrowerToken = _receipt[counterId].borrowerToken;
        }
      
    /* 
    * @notice: a counter of the protocol to track a loan is in the contract
    */  
    function counter() private returns(uint256 counterId){
        counterId = _IdCounter.current();
        _IdCounter.increment();
    }

    /* 
    * @notice: a counter of the NFT receipts 
    */  
    function nftCounter() private returns(uint256 counterId){
        counterId = _nftCounter.current();
        _nftCounter.increment();
    }

    /*
    * @auditors the function does not accept the ZEROAddress modifer due to 
        "the stack too deep, try removing local variables" 
    * @notice: The submit function is called by the borrowers if they 
    * agree on the lending schedule loan. The schedule is signed by the
    * lender.
    * @param nonce uint256 ID is an array of the lender's and borrower's nonces 
    * @param _paymentAddress address is the crypto address
    * @param _lender address
    * @param _nftcontract address
    * @param _nftTokenId uint256
    * @param _loanAmounLoanCost is an arry of uint256
    * @param _offeredTime uint256
    * @param _gist bytes32
    * @param signature bytes
    */
   function submit(uint256 [2] calldata nonces , address _paymentAddress, address _lender, 
                address _nftcontract, 
                uint256 _nftTokenId,
                 uint256 [3] calldata _loanAmounLoanCost,
                uint256 _offeredTime, bytes32 _gist, bytes calldata borrowerSignature, bytes calldata lenderSignature) 
        external whenNotPaused nonReentrant supportInterface(_paymentAddress) 
       {
        LendingAssets memory _m = LendingAssets({
        paymentContract: address(_paymentAddress),
        listingTime: clockTimeStamp(),
        totalPrincipal:_loanAmounLoanCost[0],
        totalInterest: _loanAmounLoanCost[1],
        totalInterestPaid:0,
        totalAmountLoan:_loanAmounLoanCost[0] + _loanAmounLoanCost[1],
        totalAmountPaid:0,
        termId:1,
        isPaid:false,
        borrowerNonce: nonces[0],
        lenderNonce: nonces[1],
        nftcontract:_nftcontract,
        nftTokenId:_nftTokenId,
        gist: _gist
        });
        require(IERC721(_m.nftcontract).ownerOf( _m.nftTokenId) == msg.sender ,"Not NFT Owner");
        require(identifiedSignature[_lender][_m.lenderNonce] != true, "Lender is not interested");
        
        require(identifiedSignature[msg.sender][_m.borrowerNonce] != true, "Borrower is not interested");

        require(_offeredTime >= clockTimeStamp(), "offer expired" );
        require(IERC20(_m.paymentContract).allowance(_lender, receiverAddress) >= _m.totalPrincipal, "Not enough allowance" );
        require(_loanAmounLoanCost[2] >= calculatedFee(_m.totalPrincipal),"fee");
        require(_verify(_lender, _hashLending (_m.lenderNonce,_m.paymentContract,_offeredTime,
            _m.totalPrincipal,_m.totalInterest,_m.nftcontract,
            msg.sender,_m.nftTokenId,_m.gist)
            ,lenderSignature),"Invalid lender signature");
        require(_verify(msg.sender, _hashBorrower (_m.borrowerNonce,_m.nftcontract,_m.nftTokenId,_m.gist),borrowerSignature),"Invalid borrower signature");

        uint256 counterId = counter();
        _assets[counterId] = _m;
        identifiedSignature[_lender][_m.lenderNonce] = true;

        identifiedSignature[msg.sender][_m.borrowerNonce] = true;

        _receipt[counterId].lenderToken = nftCounter();
        _receipt[counterId].borrowerToken = nftCounter();        
        Receipt memory _nft = _receipt[counterId];
        _mint(_lender, _nft.lenderToken ) ;
        _setTokenURI(_nft.lenderToken,  string(abi.encodePacked(Strings.toString(_nft.lenderToken), ".json")));
        _mint(msg.sender, _nft.borrowerToken ) ;
        _setTokenURI(_nft.borrowerToken,  string(abi.encodePacked(Strings.toString(_nft.borrowerToken), ".json")));
    
        IERC721(_nftcontract).safeTransferFrom(msg.sender, receiverAddress, _m.nftTokenId);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, owner(), _loanAmounLoanCost[2]);
        IERC20(_m.paymentContract).safeTransferFrom(_lender, msg.sender, _m.totalPrincipal);
        emit AssetsLog(
            counterId,
            msg.sender,
            _m.borrowerNonce,
            _m.lenderNonce,
            _m.nftcontract,
            _m.nftTokenId,
            _lender,
            _m.paymentContract,
            _m.totalPrincipal,
            _m.totalInterest,
            _m.totalAmountLoan, 
            _m.gist);
    }
  

    /*
    * @notice: make payment is a way to pay a loan by a borrower, 
    * the payment has to follow the term's array that is an off chain.
    * At the end of the term both nft receipts will get burned.
    * Backedn needs to listen also to the "Transfer" event
    * when nft receipts get burned.
    * @param _counterId uint256 main id of the loan 
    * @param term_ uint256 the term gets increased everytime the borrower pays its term
    * @param loanTimestampPaymentInterest is an arry of the timestamp, payment, and interest 
    * @param fee_ is 10% that is taking from the current interest
    * @param proof of the _term 
    */
    function makePayment(uint256 _counterId, uint256 term_, 
    uint256[] calldata loanTimestampPaymentInterest, uint256 fee_, bytes32[] calldata proof) external nonReentrant {
        // _termOf[_counterId] = _termId.current();
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];
        require(term_ == _m.termId, "term does not matched");
        require(_verifyTree(_leaf(term_ , loanTimestampPaymentInterest), proof, _m.gist), "Invalid proof");
        require(ownerOf(_nft.borrowerToken) == msg.sender,"Only the Owner of the NFT borrower receipt");
        require(_m.isPaid != true, "is paid already");
        require(_timeExpired(loanTimestampPaymentInterest[0]) >= clockTimeStamp(), "Default");
        uint256 loanPayment = loanTimestampPaymentInterest[1] + loanTimestampPaymentInterest[2];
        require(IERC20(_m.paymentContract).allowance(msg.sender, receiverAddress) >= loanPayment,"Not enough allowance" );
        require(calculatedInterestFee(loanTimestampPaymentInterest[2]) <= fee_, "fees");
        _assets[_counterId].totalInterestPaid += loanTimestampPaymentInterest[2];
        _assets[_counterId].termId++;        
        _assets[_counterId].totalAmountPaid +=  loanPayment ;
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, owner(), fee_);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, ownerOf(_nft.lenderToken),  loanPayment);
        LendingAssets memory _after = _assets[_counterId];

        if (_after.totalAmountPaid >= _after.totalAmountLoan ){
            _burn(_nft.borrowerToken);
            _burn(_nft.lenderToken);
            _assets[_counterId].isPaid = true;
            LendingAssets memory _i = _assets[_counterId];
            IERC721(_m.nftcontract).safeTransferFrom(receiverAddress, msg.sender, _m.nftTokenId);
            emit PaymentLog(_counterId,_m.nftcontract,  _m.nftTokenId,  _i.isPaid );
        }  
        emit PayLog(_counterId,  _m.nftcontract,  _m.nftTokenId, loanPayment, _m.termId, fee_, proof );
        
    }

    /*
    * @notice: make prepayment is an early repayment of a loan by a borrower, verifiying 
    * tow proofs, the perProof which is for the per timestamp and proof which is the current term
    * event does not get the address of the lander 
    * from a burn can identify the addresses of the lender and borrower. 
    * @param _counterId uint256 main id of the lending 
    * @param term_ uint256 each term to pay the pre payment 
    * @param loanTimesPaymentInterest the arry of the term
    * @param preLoanTimes arry of the 0 term
    * @param fee_ of the current interest of the 0's term
    * @param proof of the _term 
    * @param preProof of the 0 term's interest
    */
    function makePrePayment(uint256 _counterId,
    uint256 term_, 
    uint256 [] calldata loanTimesPaymentInterest, 
    uint256 [] calldata preLoanTimes,uint256 fee_, 
    bytes32 [] calldata proof,
    bytes32 [] calldata preProof) 
    external nonReentrant {
        
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];
        require(term_ == _m.termId, "term does not matched");
        require(_verifyTree(_leaf(0 , preLoanTimes), preProof, _m.gist), "Invalid proof");
        require(_verifyTree(_leaf(term_, loanTimesPaymentInterest), proof, _m.gist), "Invalid proof");
        require(preLoanTimes[0]>= clockTimeStamp(),"Expired" );
        require(ownerOf(_nft.borrowerToken) == msg.sender,"Only the Owner of the NFT borrower receipt");
        require(_m.isPaid != true, "is paid already");
        require(_timeExpired(loanTimesPaymentInterest[0]) >= clockTimeStamp(), "Term Time Expired");
        require(calculatedInterestFee(loanTimesPaymentInterest[3]) <= fee_, "fees");
        _assets[_counterId].isPaid = true;
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, owner(), fee_);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, ownerOf(_nft.lenderToken),  loanTimesPaymentInterest[4] + loanTimesPaymentInterest[3]);
        _assets[_counterId].totalAmountPaid +=  loanTimesPaymentInterest[4] + loanTimesPaymentInterest[3] ;
        _burn(_nft.borrowerToken);
        _burn(_nft.lenderToken);
        IERC721(_m.nftcontract).safeTransferFrom(receiverAddress, msg.sender, _m.nftTokenId);
        emit PrePayLog(_counterId,  _m.nftcontract,  _m.nftTokenId, loanTimesPaymentInterest[4] + loanTimesPaymentInterest[3], _m.termId , fee_ ,preProof, true );

    }
   

    /* clockTimeStamp function returns a timestamp
    */
    function clockTimeStamp() private view returns(uint256 x){
        x = block.timestamp;
    }

    /* @notice defaultAsset function the only way for claiming the NFT if the borrowers do not make their payment's term
        * @param _counterId uint256 main id of the lending 
        * @param loanTimesPaymentInterest uint256 is an array of the term schedule time, payment, and interest
        * the term has to match the tern in schedule, so any missing payment causes defaulting
        * @param fee_ uint256 is the fee of the total remain interest.
        * @param proof of the _term array
    */
    function defaultAsset(uint256 _counterId, 
    uint256[] calldata loanTimesPaymentInterest, uint256 fee_, bytes32[] calldata proof) external nonReentrant  {
        
        address contractOwner  = owner();
        uint256 _time = clockTimeStamp();
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];
        require(_m.isPaid != true, "is paid already");
        uint256 term_ = _m.termId ;
        require(_verifyTree(_leaf(term_ , loanTimesPaymentInterest), proof, _m.gist), "Invalid proof");
        require(ownerOf(_nft.lenderToken)== msg.sender,"Only the Owner of the NFT lender receipt");
        require(_timeExpired(loanTimesPaymentInterest[0]) <= _time, "Not default yet");
        require(IERC20(_m.paymentContract).allowance(msg.sender,receiverAddress) >= fee_,"Not enough allowance" );

        uint256 remaining = _m.totalInterest - _m.totalInterestPaid;
        require(fee_ >= calculatedInterestFee(remaining),"fee");
        _burn(_nft.borrowerToken);
        _burn(_nft.lenderToken);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, contractOwner, fee_);
        IERC721(_m.nftcontract).safeTransferFrom(receiverAddress, msg.sender, _m.nftTokenId);
        emit DefaultLog(_counterId, _m.nftcontract, _m.nftTokenId, msg.sender, fee_);
    }


    /* @dev isDefaulted function a way for checking if the nft gets defaulted
        * @param _counterId uint256 main id of the lending 
        * @param loanTimesPaymentInterest the arry of the term
        * @param proof of the _term array
    */
    function isDefaulted(uint256 _counterId, uint256[] calldata loanTimesPaymentInterest, bytes32[] calldata proof) view external returns(bool) {
        LendingAssets memory _m = _assets[_counterId];
        uint256 term_ = _m.termId ;
        require(_verifyTree(_leaf(term_ , loanTimesPaymentInterest), proof, _m.gist), "Invalid proof");
        uint256 _time = clockTimeStamp();
        if (_timeExpired(loanTimesPaymentInterest[0]) <= _time ){
            return true;
        } else{
            return false;
        }
    }

    /*
    * @notice: cancel the signature and the offer by the lender
    * @param nonce uint256 is used once on the backend and once for canceling an offer
    * @param _lender address
    */
    function cancel(uint256 nonce, address _account)  external 
    zeroAddress(_account) {
        require(_account == msg.sender, "Not a sender");
        require(identifiedSignature[_account][nonce] != true, "Not interested");
        identifiedSignature[_account][nonce] = true;
        emit CancelLog(_account, nonce, true);
    }
    

    /*
    * @notice: check if the nonce is used or canceled
    * @param nonce uint256 is used once on the backend and once for canceling an offer
    * @param _lender address
    */
    function isNonceUsed(uint256 nonce, address _lender) external
    zeroAddress(_lender)
    view returns(bool _isNonceUsed){
        _isNonceUsed = identifiedSignature[_lender][nonce];
    }
    
   /* @dev calculatedFee function is only called in submit a loan
    * @param _amount uint256 of calculating the fees
    */
    function calculatedFee(uint256 _amount) public view returns(uint fee) {
        uint _txfee = txfee;
        uint callItFee = _amount * _txfee;
        fee = callItFee / 1e4;
    }

    /* @dev calculatedInterestFee function is called making payment, pre payment, and default functions 
    * @param _amount uint256 of calculating the fees
    */
    function calculatedInterestFee(uint256 _amount) public view returns(uint fee) {
        uint _txfee = txInterestfee;
        uint callItFee = _amount * _txfee;
        fee = callItFee / 1e4;
    }

    /*
    * @notice: borrower needs to submit the lender new proof to extend the time with a new timestamps and payment intereset 
                the offeredTime value has to be not expired with a current time.
    * @param _counterId uint256 Id of the receipt NFT
    * @param totalInterest uint256 new interest  
    * @param currentTerm_ uint256 the cuurent term that already paid 
    * @param _offeredTime uint256  it has to be > then current timestamp
    * @param gist bytes32 new root of the laon schedule
    * @param signature bytes32 is an array of a new sig of the lender and borrower
    */
   function extendTheTime(uint256 [2] calldata nonces, uint256 _counterId, uint256 totalInterest, uint256 currentTerm_, uint256 _offeredTime, bytes32 gist ,
   bytes [2] calldata signatures) 
   nonReentrant external {
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];
        require(_offeredTime >= clockTimeStamp(), "offer expired" );
        require(currentTerm_ == _m.termId,"term does not matched");
        require(ownerOf(_nft.borrowerToken) == msg.sender,"Only the Owner of the NFT borrower receipt");
        
        require(identifiedSignature[ownerOf(_nft.lenderToken)][nonces[1]] != true, "Lender is not interested"); 
        require(identifiedSignature[msg.sender][nonces[0]] != true, "Borrower is not interested");
        
        require(_verify(ownerOf(_nft.lenderToken), _hashextend(nonces[1], _m.nftcontract,_m.nftTokenId,
              _offeredTime, totalInterest, gist), signatures[1]), "Lender signature");
        
        require(_verify(msg.sender, _hashBorrower(nonces[0], _m.nftcontract,_m.nftTokenId, gist), signatures[0]), "Borrower signature");
        
        identifiedSignature[ownerOf(_nft.lenderToken)][nonces[1]] = true;
        identifiedSignature[msg.sender][nonces[0]] = true;

        _assets[_counterId].gist = gist;
        // _assets[_counterId].loanTerm = loanTerm;
        _assets[_counterId].totalAmountLoan = _m.totalPrincipal + totalInterest;
        _assets[_counterId].totalInterest = totalInterest;
        emit ExtendTimeLog(
            _counterId, 
            _m.nftcontract,
            _m.nftTokenId,
           ownerOf(_nft.lenderToken),
            msg.sender,
            _m.termId,
            _m.totalPrincipal,
            gist);
    }

    /*
    * @notice: to withdraw the fees
    * @param _contract address of the erc20 token
    * @param _to address of the receiver address
    * @param _amount uint256 of amount 
    */
    function withdraw(address _contract, address _to) external 
    zeroAddress(_contract) onlyOwner {
        uint _amount = IERC20(_contract).balanceOf(receiverAddress);
        IERC20(_contract).safeTransfer(_to, _amount);
        emit WithdrawLog(_contract, _to, _amount);
    }

    /* no need
    * @notice: to withdraw the ETH
    * @param _contract address of the erc20 token
    * @param _to address of the receiver address
    * @param _amount uint256 of amount 
    */
    // function withdraw(address payable to) external 
    // zeroAddress(to) onlyOwner {
    //     uint256 getBalance = receiverAddress.balance;
    //     to.transfer(getBalance);
    //     emit WithdrawLog(receiverAddress, to, getBalance);
    // }

    /**
     * @dev Returns the total number of loans.
     */
    function totalLoan() public view  returns (uint256) {
        return _IdCounter.current() ;
    }

    /********************************************************************************************/
    /*                                       OpenZeppelin                                       */
    /********************************************************************************************/
    
    // /**
    //  * @dev Returns the total number of tokens in existence.
    //  * Burned tokens will reduce the count.
    //  */
    // function totalSupply() public view  returns (uint256) {
    //     return _nftCounter.current(); 
    // }

    /**
     * @dev Base URI for this token contract . 
     */
    // function baseURI() external view returns (string memory) {
    //     return _baseMetadata;
    // }


    /**
     * @notice Only owner can set URI for this contract . 
     */
    function setURI(string calldata baseURI_) external  onlyOwner {
        _setBaseURI(baseURI_);
    }
    /**
     * @dev Returns (URI) for a token Id.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId)  ;
    }

    /*
    * @notice: burn function is called when all payment made or the nft gets defulted
    * @param tokenId uint256 ID of the token being burned
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /*
    * @notice: _leaf function is called in makePayment, makePerPayment function to verify each Merkle 
    * @param term uint256 ID of term in the payment 
    * @param an arry of two uint256 values, [0] timestamp [1] payment 
    */
    function _leaf(uint256 term, uint256 [] calldata time)
    private pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(term, time));
    }

    /*
    * @notice: Verifies a Merkle proof proving the existence of a leaf in a Merkle tree
    * @param leaf Leaf of Merkle tree
    * @param proof Merkle proof 
    * @param gist Merkle root
    */
    function _verifyTree(bytes32 leaf, bytes32[] memory proof, bytes32 gist)
    private pure returns (bool)
    {
        return MerkleProof.verify(proof, gist, leaf);
    }

    /**
    * Interface of ERC721 token receiver.
    */
    function onERC721Received(address , address , uint256 , bytes memory) external pure override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    /**
     * @dev Returns true if this contract implements the interface defined by
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)     *
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Hook to execute functionality before the token is transferred
     * 'openzeppelin'
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


}
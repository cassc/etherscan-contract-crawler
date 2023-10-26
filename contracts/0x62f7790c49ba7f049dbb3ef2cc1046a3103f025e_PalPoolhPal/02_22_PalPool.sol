//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./utils/Clones.sol";
import "./IPalPool.sol";
import "./PalPoolStorage.sol";
import "./IPalLoan.sol";
//import "./PalLoan.sol";
import "./IPalToken.sol";
import "./IPaladinController.sol";
import "./IPalLoanToken.sol";
import "./interests/InterestInterface.sol";
import "./utils/IERC20.sol";
import "./utils/Admin.sol";
import "./utils/ReentrancyGuard.sol";
import {Errors} from  "./utils/Errors.sol";



/** @title PalPool contract  */
/// @author Paladin
contract PalPool is IPalPool, PalPoolStorage, Admin, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    modifier controllerOnly() {
        //allows only the Controller and the admin to call the function
        require(msg.sender == admin || msg.sender == address(controller), Errors.CALLER_NOT_CONTROLLER);
        _;
    }



    //Functions

    constructor(
        address _palToken,
        address _controller, 
        address _underlying,
        address _interestModule,
        address _delegator,
        address _palLoanToken
    ){
        //Set admin
        admin = msg.sender;

        //Set inital values & modules
        palToken = IPalToken(_palToken);
        controller = IPaladinController(_controller);
        underlying = IERC20(_underlying);
        accrualBlockNumber = block.number;
        interestModule = InterestInterface(_interestModule);
        borrowIndex = 1e18;
        delegator = _delegator;
        palLoanToken = IPalLoanToken(_palLoanToken);
    }

    /**
    * @notice Get the underlying balance for this Pool
    * @dev Get the underlying balance of this Pool
    * @return uint : balance of this pool in the underlying token
    */
    function underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        return underlying.balanceOf(address(this));
    }

    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints palToken for the user
    * @param _amount Amount of underlying to deposit
    * @return bool : amount of minted palTokens
    */
    function deposit(uint _amount) public virtual override nonReentrant returns(uint){
        require(_updateInterest());

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();


        //Find the amount to mint depending on the amount to transfer
        uint _num = _amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

        //Transfer the underlying to this contract
        //The amount of underlying needs to be approved before
        underlying.safeTransferFrom(msg.sender, address(this), _amount);

        //Mint the palToken
        require(palToken.mint(msg.sender, _toMint), Errors.FAIL_MINT);

        //Emit the Deposit event
        emit Deposit(msg.sender, _amount, address(this));

        //Use the controller to check if the minting was successfull
        require(controller.depositVerify(address(this), msg.sender, _toMint), Errors.FAIL_DEPOSIT);

        return _toMint;
    }

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding palToken amount
    * @param _amount Amount of palToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint _amount) public virtual override nonReentrant returns(uint){
        require(_updateInterest());
        require(balanceOf(msg.sender) >= _amount, Errors.INSUFFICIENT_BALANCE);

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Find the amount to return depending on the amount of palToken to burn
        uint _num = _amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn <= underlyingBalance(), Errors.INSUFFICIENT_CASH);

        //Burn the corresponding palToken amount
        require(palToken.burn(msg.sender, _amount), Errors.FAIL_BURN);

        //Make the underlying transfer
        underlying.safeTransfer(msg.sender, _toReturn);

        //Use the controller to check if the burning was successfull
        require(controller.withdrawVerify(address(this), msg.sender, _toReturn), Errors.FAIL_WITHDRAW);

        //Emit the Withdraw event
        emit Withdraw(msg.sender, _amount, address(this));

        return _toReturn;
    }

    /**
    * @dev Create a Borrow, deploy a Loan Pool and delegate voting power
    * @param _delegatee Address to delegate the voting power to
    * @param _amount Amount of underlying to borrow
    * @param _feeAmount Amount of fee to pay to start the loan
    * @return uint : new PalLoanToken Id
    */
    function borrow(address _delegatee, uint _amount, uint _feeAmount) public virtual override nonReentrant returns(uint){
        //Need the pool to have enough liquidity, and the interests to be up to date
        require(_amount <= underlyingBalance(), Errors.INSUFFICIENT_CASH);
        require(_delegatee != address(0), Errors.ZERO_ADDRESS);
        require(_amount > 0, Errors.ZERO_BORROW);
        require(_feeAmount >= minBorrowFees(_amount), Errors.BORROW_INSUFFICIENT_FEES);
        require(_updateInterest());

        address _borrower = msg.sender;

        //Update Total Borrowed & number active Loans
        numberActiveLoans = numberActiveLoans.add(1);
        totalBorrowed = totalBorrowed.add(_amount);

        IPalLoan _newLoan = IPalLoan(Clones.clone(delegator));

        //Send the borrowed amount of underlying tokens to the Loan
        underlying.safeTransfer(address(_newLoan), _amount);

        //And transfer the fees from the Borrower to the Loan
        underlying.safeTransferFrom(_borrower, address(_newLoan), _feeAmount);

        //Start the Loan (and delegate voting power)
        require(_newLoan.initiate(
            address(this),
            _borrower,
            address(underlying),
            _delegatee,
            _amount,
            _feeAmount
        ), Errors.FAIL_LOAN_INITIATE);

        //Add the new Loan to mappings
        loans.push(address(_newLoan));

        //Mint the palLoanToken linked to this new Loan
        uint256 _newTokenId = palLoanToken.mint(_borrower, address(this), address(_newLoan));

        //New Borrow struct for this Loan
        loanToBorrow[address(_newLoan)] = Borrow(
            _newTokenId,
            _delegatee,
            address(_newLoan),
            _amount,
            address(underlying),
            _feeAmount,
            0,
            borrowIndex,
            block.number,
            0,
            false,
            false
        );

        //Check the borrow succeeded
        require(
            controller.borrowVerify(address(this), _borrower, _delegatee, _amount, _feeAmount, address(_newLoan)), 
            Errors.FAIL_BORROW
        );

        //Emit the NewLoan Event
        emit NewLoan(
            _borrower,
            _delegatee,
            address(underlying),
            _amount,
            address(this),
            address(_newLoan),
            _newTokenId,
            block.number
        );

        //Return the PalLoanToken Id
        return _newTokenId;
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param _loan Address of the Loan
    * @param _feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address _loan, uint _feeAmount) public virtual override nonReentrant returns(uint){
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_feeAmount > 0);
        require(_updateInterest());
        
        //Load the Loan Pool contract & get Loan owner
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        _borrow.feesAmount = _borrow.feesAmount.add(_feeAmount);

        //Transfer the new fees to the Loan
        //If success, call the expand function of the Loan
        underlying.safeTransferFrom(_loanOwner, _borrow.loan, _feeAmount);

        require(_palLoan.expand(_feeAmount), Errors.FAIL_LOAN_EXPAND);

        require(
            controller.expandBorrowVerify(address(this), _loan, _feeAmount), 
            Errors.FAIL_LOAN_EXPAND
        );

        emit ExpandLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            address(this),
            _borrow.feesAmount,
            _borrow.loan,
            _borrow.tokenId
        );

        return _feeAmount;
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower.
    * If closed before the minimum required length, penalty fees are taken to the non-used fees
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param _loan Address of the Loan
    */
    function closeBorrow(address _loan) public virtual override nonReentrant {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Get Loan owner from the ERC721 contract
        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Load the Loan contract
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Calculates the amount of fees used
        uint _feesUsed = (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount);
        uint _penaltyFees = 0;
        uint _totalFees = _feesUsed;

        //If the Borrow is closed before the minimum length, calculates the penalty fees to pay
        // -> Number of block remaining to complete the minimum length * current Borrow Rate
        if(block.number < (_borrow.startBlock.add(minBorrowLength))){
            uint _currentBorrowRate = interestModule.getBorrowRate(address(this), underlyingBalance(), totalBorrowed, totalReserve);
            uint _missingBlocks = (_borrow.startBlock.add(minBorrowLength)).sub(block.number);
            _penaltyFees = _missingBlocks.mul(_borrow.amount.mul(_currentBorrowRate)).div(mantissaScale);
            _totalFees = _totalFees.add(_penaltyFees);
        }
    
        //Security so the Borrow can be closed if there are no more fees
        //(if the Borrow wasn't Killed yet, or the loan is closed before minimum time, and already paid fees aren't enough)
        if(_totalFees > _borrow.feesAmount){
            _totalFees = _borrow.feesAmount;
        }

        //Set the Borrow as closed
        _borrow.closed = true;
        _borrow.feesUsed = _totalFees;
        _borrow.closeBlock = block.number;

        //Remove the borrowed tokens + fees from the TotalBorrowed
        //Add to the Reserve the reserveFactor of Penalty Fees (if there is Penalty Fees)
        //And add the fees counted as potential Killer Fees to the Accrued Fees, since no killing was necessary

        numberActiveLoans = numberActiveLoans.sub(1);

        totalBorrowed = numberActiveLoans == 0 ? 0 : totalBorrowed.sub((_borrow.amount).add(_feesUsed)); //If not current active Loan, we can just reset the totalBorrowed to 0

        uint _realPenaltyFees = _totalFees.sub(_feesUsed);
        uint _killerFees = _feesUsed.mul(killerRatio).div(mantissaScale);
        totalReserve = totalReserve.add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));
        accruedFees = accruedFees.add(_killerFees).add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));
        
        //Close and destroy the loan
        _palLoan.closeLoan(_totalFees, _loanOwner);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        require(controller.closeBorrowVerify(address(this), _loanOwner, _borrow.loan), Errors.FAIL_CLOSE_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            _borrow.amount,
            address(this),
            _totalFees,
            _loan,
            _borrow.tokenId,
            false
        );
    }

    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @dev Kill a non-healthy Loan to collect rewards
    * @param _loan Address of the Loan
    */
    function killBorrow(address _loan) public virtual override nonReentrant {
        address killer = msg.sender;
        //Fetch the corresponding Borrow
        //And check that the killer is not the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(!isLoanOwner(_loan, killer), Errors.LOAN_OWNER);
        require(_updateInterest());

        //Get the owner of the Loan through the ERC721 contract
        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount);
        uint _loanHealthFactor = _feesUsed.mul(uint(1e18)).div(_borrow.feesAmount);
        require(_loanHealthFactor >= killFactor, Errors.NOT_KILLABLE);

        //Load the Loan
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Close the Loan, and update storage variables
        _borrow.closed = true;
        _borrow.killed = true;
        _borrow.feesUsed = _borrow.feesAmount;
        _borrow.closeBlock = block.number;

        //Remove the borrowed tokens + fees from the TotalBorrowed
        //Remove the amount paid as killer fees from the Reserve, and any over accrued interest in the Reserve & AccruedFees
        uint _overAccruedInterest = _loanHealthFactor <= mantissaScale ? 0 : _feesUsed.sub(_borrow.feesAmount);
        uint _killerFees = (_borrow.feesAmount).mul(killerRatio).div(mantissaScale);

        numberActiveLoans = numberActiveLoans.sub(1);

        totalBorrowed = numberActiveLoans == 0 ? 0 : totalBorrowed.sub((_borrow.amount).add(_feesUsed)); //If not current active Loan, we can just reset the totalBorrowed to 0

        totalReserve = totalReserve.sub(_killerFees).sub(_overAccruedInterest.mul(reserveFactor).div(mantissaScale));
        accruedFees = accruedFees.sub(_overAccruedInterest.mul(reserveFactor.sub(killerRatio)).div(mantissaScale));

        //Kill the Loan
        _palLoan.killLoan(killer, killerRatio);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        require(controller.killBorrowVerify(address(this), killer, _borrow.loan), Errors.FAIL_KILL_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            _borrow.amount,
            address(this),
            _borrow.feesAmount,
            _loan,
            _borrow.tokenId,
            true
        );
    }



    /**
    * @notice Change the delegatee of a Loan, and delegate him the voting power
    * @dev Change the delegatee in the Borrow struct and in the palLoan, then change the voting power delegation recipient
    * @param _loan Address of the Loan
    * @param _newDelegatee Address of the new voting power recipient
    */
    function changeBorrowDelegatee(address _loan, address _newDelegatee) public virtual override nonReentrant {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(_newDelegatee != address(0), Errors.ZERO_ADDRESS);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Load the Loan Pool contract
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Update storage data
        _borrow.delegatee = _newDelegatee;

        //Call the delegation logic in the palLoan to change the votong power recipient
        require(_palLoan.changeDelegatee(_newDelegatee), Errors.FAIL_LOAN_DELEGATEE_CHANGE);

        //Emit the Event
        emit ChangeLoanDelegatee(
            palLoanToken.ownerOf(_borrow.tokenId),
            _newDelegatee,
            address(underlying),
            address(this),
            _borrow.loan,
            _borrow.tokenId
        );

    }


    /**
    * @notice Return the user's palToken balance
    * @dev Links the PalToken balanceOf() method
    * @param _account User address
    * @return uint256 : user palToken balance (in wei)
    */
    function balanceOf(address _account) public view override returns(uint){
        return palToken.balanceOf(_account);
    }


    /**
    * @notice Return the corresponding balance of the pool underlying token depending on the user's palToken balance
    * @param _account User address
    * @return uint256 : corresponding balance in the underlying token (in wei)
    */
    function underlyingBalanceOf(address _account) external view override returns(uint){
        uint _balance = palToken.balanceOf(_account);
        if(_balance == 0){
            return 0;
        }
        uint _exchRate = _exchangeRate();
        uint _num = _balance.mul(_exchRate);
        return _num.div(mantissaScale);
    }


    /**
    * @notice Return true is the given address is the owner of the palLoanToken for the given palLoan
    * @param _loanAddress Address of the Loan
    * @param _user User address
    * @return bool : true if owner
    */
    function isLoanOwner(address _loanAddress, address _user) public view override returns(bool){
        return palLoanToken.allOwnerOf(idOfLoan(_loanAddress)) == _user;
    }


    /**
    * @notice Return the token Id of the palLoanToken linked to this palLoan
    * @param _loanAddress Address of the Loan
    * @return uint256 : palLoanToken token Id
    */
    function idOfLoan(address _loanAddress) public view override returns(uint256){
        return loanToBorrow[_loanAddress].tokenId;
    }



    /**
    * @notice Return the list of all Loans for this Pool (closed and active)
    * @return address[] : list of Loans
    */
    function getLoansPools() external view override returns(address [] memory){
        //Return the addresses of all loans (old ones and active ones)
        return loans;
    }
    
    /**
    * @notice Return all the Loans for a given address
    * @param _borrower Address of the user
    * @return address : list of Loans
    */
    function getLoansByBorrower(address _borrower) external view override returns(address [] memory){
        return palLoanToken.allLoansOfForPool(_borrower, address(this));
    }

    
    /**
    * @notice Return the stored Borrow data for a given Loan
    * @dev Return the Borrow data for a given Loan
    * @param _loanAddress Address of the palLoan
    * Composants of a Borrow struct
    */
    function getBorrowData(address _loanAddress) external view override returns(
        address _borrower,
        address _delegatee,
        address _loan,
        uint256 _palLoanTokenId,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        uint _startBlock,
        uint _closeBlock,
        bool _closed,
        bool _killed
    ){
        //Return the data inside a Borrow struct
        Borrow memory _borrow = loanToBorrow[_loanAddress];
        return (
            //Get the Loan owner through the ERC721 contract
            palLoanToken.allOwnerOf(_borrow.tokenId),
            _borrow.delegatee,
            _borrow.loan,
            _borrow.tokenId,
            _borrow.amount,
            _borrow.underlying,
            _borrow.feesAmount,
            //Calculate amount of fees used
            _borrow.closed ? _borrow.feesUsed : (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount),
            _borrow.startBlock,
            _borrow.closeBlock,
            _borrow.closed,
            _borrow.killed
        );

    }
    
    /**
    * @notice Get the Borrow Rate for this Pool
    * @dev Get the Borrow Rate from the Interest Module
    * @return uint : Borrow Rate (scale 1e18)
    */
    function borrowRatePerBlock() external view override returns (uint){
        return interestModule.getBorrowRate(address(this), underlyingBalance(), totalBorrowed, totalReserve);
    }
    
    /**
    * @notice Get the Supply Rate for this Pool
    * @dev Get the Supply Rate from the Interest Module
    * @return uint : Supply Rate (scale 1e18)
    */
    function supplyRatePerBlock() external view override returns (uint){
        return interestModule.getSupplyRate(address(this), underlyingBalance(), totalBorrowed, totalReserve, reserveFactor);
    }

    
    /**
    * @dev Calculates the current exchange rate
    * @return uint : current exchange rate (scale 1e18)
    */
    function _exchangeRate() internal view returns (uint){
        uint _totalSupply = palToken.totalSupply();
        //If no palTokens where minted, use the initial exchange rate
        if(_totalSupply == 0){
            return initialExchangeRate;
        }
        else{
            // Exchange Rate = (Cash + Borrows - Reserve) / Supply
            uint _cash = underlyingBalance();
            uint _availableCash = _cash.add(totalBorrowed).sub(totalReserve);
            return _availableCash.mul(1e18).div(_totalSupply);
        }
    }

    /**
    * @notice Get the current exchange rate for the palToken
    * @dev Updates interest & Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateCurrent() external override returns (uint){
        _updateInterest();
        return _exchangeRate();
    }
    
    /**
    * @notice Get the stored exchange rate for the palToken
    * @dev Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateStored() external view override returns (uint){
        return _exchangeRate();
    }

    /**
    * @notice Return the minimum of fees to pay to borrow
    * @dev Fees to pay for a Borrow (for the minimum borrow length)
    * @return uint : minimum amount (in wei)
    */
    function minBorrowFees(uint _amount) public view override returns (uint){
        require(_amount <= underlyingBalance(), Errors.INSUFFICIENT_CASH);
        //Future Borrow Rate with the amount to borrow counted as already borrowed
        uint _borrowRate = interestModule.getBorrowRate(address(this), underlyingBalance().sub(_amount), totalBorrowed.add(_amount), totalReserve);
        uint _minFees = minBorrowLength.mul(_amount.mul(_borrowRate)).div(mantissaScale);
        return _minFees > 0 ? _minFees : 1;
    }

    function isKillable(address _loan) external view override returns(bool){
        Borrow memory __borrow = loanToBorrow[_loan];
        if(__borrow.closed){
            return false;
        }

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = (__borrow.amount.mul(borrowIndex).div(__borrow.borrowIndex)).sub(__borrow.amount);
        uint _loanHealthFactor = _feesUsed.mul(uint(1e18)).div(__borrow.feesAmount);
        return _loanHealthFactor >= killFactor;
    }

    /**
    * @dev Updates Inetrest and variables for this Pool
    * @return bool : Update success
    */
    function _updateInterest() public returns (bool){
        //Get the current block
        //Check if the Pool has already been updated this block
        uint _currentBlock = block.number;
        if(_currentBlock == accrualBlockNumber){
            return true;
        }

        //Get Pool variables from Storage
        uint _cash = underlyingBalance();
        uint _borrows = totalBorrowed;
        uint _reserves = totalReserve;
        uint _accruedFees = accruedFees;
        uint _oldBorrowIndex = borrowIndex;

        //Get the Borrow Rate from the Interest Module
        uint _borrowRate = interestModule.getBorrowRate(address(this), _cash, _borrows, _reserves);

        //Delta of blocks since the last update
        uint _ellapsedBlocks = _currentBlock.sub(accrualBlockNumber);

        /*
        Interest Factor = Borrow Rate * Ellapsed Blocks
        Accumulated Interests = Interest Factor * Borrows
        Total Borrows = Borrows + Accumulated Interests
        Total Reserve = Reserve + Accumulated Interests * Reserve Factor
        Accrued Fees = Accrued Fees + Accumulated Interests * (Reserve Factor - Killer Ratio) -> (available fees should not count potential fees to send to killers)
        Borrow Index = old Borrow Index + old Borrow Index * Interest Factor 
        */
        uint _interestFactor = _borrowRate.mul(_ellapsedBlocks);
        uint _accumulatedInterest = _interestFactor.mul(_borrows).div(mantissaScale);
        uint _newBorrows = _borrows.add(_accumulatedInterest);
        uint _newReserve = _reserves.add(reserveFactor.mul(_accumulatedInterest).div(mantissaScale));
        uint _newAccruedFees = _accruedFees.add((reserveFactor.sub(killerRatio)).mul(_accumulatedInterest).div(mantissaScale));
        uint _newBorrowIndex = _oldBorrowIndex.add(_interestFactor.mul(_oldBorrowIndex).div(1e18));

        //Update storage
        totalBorrowed = _newBorrows;
        totalReserve = _newReserve;
        accruedFees = _newAccruedFees;
        borrowIndex = _newBorrowIndex;
        accrualBlockNumber = _currentBlock;

        return true;
    }

    


    // Admin Functions

    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external override controllerOnly {
        controller = IPaladinController(_newController);
    }

    /**
    * @notice Set a new Interest Module
    * @dev Load a new Interest Module
    * @param _interestModule address of the new Interest Module
    */
    function setNewInterestModule(address _interestModule) external override adminOnly {
        interestModule = InterestInterface(_interestModule);
    }

    /**
    * @notice Set a new Delegator
    * @dev Change Delegator address
    * @param _delegator address of the new Delegator
    */
    function setNewDelegator(address _delegator) external override adminOnly {
        delegator = _delegator;
    }


    /**
    * @notice Set a new Minimum Borrow Length
    * @dev Change Minimum Borrow Length value
    * @param _length new Minimum Borrow Length
    */
    function updateMinBorrowLength(uint _length) external override adminOnly {
        require(_length > 0, Errors.INVALID_PARAMETERS);
        minBorrowLength = _length;
    }


    /**
    * @notice Update the Pool Reserve Factor & Killer Ratio
    * @dev Change Reserve Factor value & Killer Ratio value
    * @param _reserveFactor new % of fees to set as Reserve
    * @param _killerRatio new Ratio of Fees to pay the killer
    */
    function updatePoolFactors(uint _reserveFactor, uint _killerRatio) external override adminOnly {
        require(_reserveFactor > 0 && _killerRatio > 0 && _reserveFactor >= _killerRatio, 
            Errors.INVALID_PARAMETERS
        );
        reserveFactor = _reserveFactor;
        killerRatio = _killerRatio;
    }


    /**
    * @notice Add underlying in the Pool Reserve
    * @dev Transfer underlying token from the admin to the Pool
    * @param _amount Amount of underlying to transfer
    */
    function addReserve(uint _amount) external override adminOnly {
        require(_updateInterest());

        totalReserve = totalReserve.add(_amount);

        //Transfer from the admin to the Pool
        underlying.safeTransferFrom(admin, address(this), _amount);

        emit AddReserve(_amount);
    }

    /**
    * @notice Remove underlying from the Pool Reserve
    * @dev Transfer underlying token from the Pool to the admin
    * @param _amount Amount of underlying to transfer
    */
    function removeReserve(uint _amount) external override adminOnly {
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount <= underlyingBalance() && _amount <= totalReserve, Errors.RESERVE_FUNDS_INSUFFICIENT);

        totalReserve = totalReserve.sub(_amount);

        //Transfer underlying to the admin
        underlying.safeTransfer(admin, _amount);

        emit RemoveReserve(_amount);
    }

    /**
    * @notice Method to allow the Controller (or admin) to withdraw protocol fees
    * @dev Transfer underlying token from the Pool to the controller (or admin)
    * @param _amount Amount of underlying to transfer
    * @param _recipient Address to receive the token
    */
    function withdrawFees(uint _amount, address _recipient) external override controllerOnly {
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount<= accruedFees && _amount <= totalReserve, Errors.FEES_ACCRUED_INSUFFICIENT);

        //Substract from accruedFees (to track how much fees the Controller can withdraw since last time)
        //And also from the REserve, since the fees are part of the Reserve
        accruedFees = accruedFees.sub(_amount);
        totalReserve = totalReserve.sub(_amount);

        //Transfer fees to the recipient
        underlying.safeTransfer(_recipient, _amount);

        emit WithdrawFees(_amount);
    }

}
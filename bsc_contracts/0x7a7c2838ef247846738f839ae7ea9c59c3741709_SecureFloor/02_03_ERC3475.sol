// Copyright (c) [2023], [Qwantum Finance Labs]
// All rights reserved.
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC3475.sol";

interface IPair {
    function symbol() external pure returns (string memory);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function burn(address to) external returns (uint amount0, uint amount1);
    function sync() external;

    function vote(uint256 _ballotId, bool yea, uint256 voteLP) external returns (bool);
    function createBallot(uint256 ruleId, bytes calldata args, uint256 voteLP) external;
    function votingTime() external view returns (uint);
}

interface IWETH {
    function withdraw(uint) external;
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function DMC_token() external pure returns (address);
}

interface IBank {
    function redeem(uint256 offerId, address to, uint256 insuranceAmount, uint256 bondAmount) external;
    function updateFarming(
        uint256 classId,
        address user,
        uint256 userBalance, 
        uint256 userRewardPerTokenPaid, 
        uint256 rewardPerTokenStored,
        uint256 totalBonds
    ) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract ERC3475 is IERC3475 {
    using TransferHelper for address;

    address constant public BURN_ADDRESS = address(0xdEad000000000000000000000000000000000000);

    /**
     * @notice this Struct is representing the Nonce properties as an object
     */
    struct Nonce {
        mapping(uint256 => IERC3475.Values) _values;

        // stores the values corresponding to the dates (issuance and maturity date).
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => uint256)) _allowances;
        mapping(address => uint256) _voteLock;  // voter lock time 
        mapping(address => uint256) _principalAmount;   // principal amount deposited by user

        // supplies of this nonce
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
    }

    /**
     * @notice this Struct is representing the Class properties as an object
     *         and can be retrieved by the classId
     */
    struct Class {
        mapping(uint256 => IERC3475.Values) _values;
        mapping(uint256 => IERC3475.Metadata) _nonceMetadatas;
        mapping(uint256 => Nonce) _nonces;
        // farming
        mapping(address => uint256) _userRewardPerTokenPaid; // user address => _userRewardPerTokenPaid
        mapping(address => uint256) _userBalance; // user address => _userBalance
        uint256 _lastUpdateTime;
        uint256 _rewardPerTokenStored;
    }

    mapping(address => mapping(address => bool)) _operatorApprovals;

    // from classId given
    mapping(uint256 => Class) internal _classes;
    mapping(uint256 => IERC3475.Metadata) _classMetadata;

    // IBO setting
    address public derexToken;  // Derex token that pays as reward by Derex DEX
    address public WETH; 
    address public bank;    // contract that can create, issue and redeem bonds

    event FarmingFailed();
    event Vote(address voter, uint256 classId, uint256 nonceId, uint256 ballotId, bool yea, uint256 votingPower);
    event CreateBallot(address voter, uint256 classId, uint256 nonceId, uint256 ruleId, bytes args, uint256 votingPower);

    /**
     * @notice Here the constructor is just to initialize a class and nonce,
     * in practice, you will have a function to create a new class and nonce
     * to be deployed during the initial deployment cycle
     */
    constructor(address _bank) {
//    function initialize() public virtual {
        require(_bank != address(0));
        bank = _bank;

        // define "symbol of the class";
        _classMetadata[0].title = "symbol";
        _classMetadata[0]._type = "string";
        _classMetadata[0].description = "symbol of the class";
        // total number of nonces (subclasses) in the class
        _classMetadata[1].title = "nonceNumbers";
        _classMetadata[1]._type = "int";
        _classMetadata[1].description = "numbers of nonces";
        //  project token
        _classMetadata[2].title = "token";
        _classMetadata[2]._type = "address";
        _classMetadata[2].description = "project token address";

        // define metadata on nonce
        // Pair token to project token in the liquidity pool (LP).
        _classes[0]._nonceMetadatas[0].title = "pairToken";
        _classes[0]._nonceMetadatas[0]._type = "address";
        _classes[0]._nonceMetadatas[0].description = "pair token in LP";
        // address of DEX router where is pool "token-pairToken". If 0, then create new pool with secure floor
        _classes[0]._nonceMetadatas[1].title = "LPToken";
        _classes[0]._nonceMetadatas[1]._type = "address";
        _classes[0]._nonceMetadatas[1].description = "LP pair address";
        // Wallet that receive project tokens after bond redemption. Burn if address is 0
        _classes[0]._nonceMetadatas[2].title = "projectWallet"; 
        _classes[0]._nonceMetadatas[2]._type = "address";
        _classes[0]._nonceMetadatas[2].description = "project token receiver";
        // Date when bond issued (epoch timestamp)
        _classes[0]._nonceMetadatas[3].title = "issuanceDate";
        _classes[0]._nonceMetadatas[3]._type = "int";
        _classes[0]._nonceMetadatas[3].description = "bond issuance date";
        // percentage with 4 decimals of initial penalty. During the time penalty will decrease. If 0 then withdrawing before release not allowed 
        // penalty = prepaymentPenalty * days to vesting / initial vesting period
        _classes[0]._nonceMetadatas[4].title = "prepaymentPenalty";
        _classes[0]._nonceMetadatas[4]._type = "int";
        _classes[0]._nonceMetadatas[4].description = "dynamic penalty percent";
        // vesting principal
        // epoch timestamp of cliff date (in seconds)
        _classes[0]._nonceMetadatas[5].title = "maturityDate";
        _classes[0]._nonceMetadatas[5]._type = "int";
        _classes[0]._nonceMetadatas[5].description = "cliff date";
        // vesting profits
        // epoch timestamp of cliff date (in seconds)
        _classes[0]._nonceMetadatas[6].title = "maturityProfitDate";
        _classes[0]._nonceMetadatas[6]._type = "int";
        _classes[0]._nonceMetadatas[6].description = "cliff profit date";
    }


    /**
     * @dev Throws if called by any account other than the bank contract.
     */
    modifier onlyBank() {
        require(msg.sender == bank, "onlyBank");
        _;
    }

    // initialize Derex variables
    function initDerex(address _derexRouter) onlyBank external virtual override {
        WETH = IRouter(_derexRouter).WETH();
        derexToken = IRouter(_derexRouter).DMC_token();
        require(WETH != address(0) && derexToken != address(0), "init error");
    }

    // unlock private pool
    function unlockPool(uint256 classId, uint256 nonceId) onlyBank external virtual override {
        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        require(nonce._values[3].uintValue < block.timestamp, "IBO isn't over");
        IPair lp = IPair(nonce._values[1].addressValue);
        uint256 votingPower = nonce._activeSupply;

        lp.createBallot(3, "", votingPower); // switch to public
        bytes memory args = abi.encode(uint256(3),uint256(10000));
        lp.createBallot(2, args, votingPower); // remove buy limit
        args = abi.encode(uint256(4),uint256(10000));
        lp.createBallot(2, args, votingPower); // remove sell limit
    }

    // this bond specific functions
    function createBond(
        address token,  // project token is used as classId
        BondParameters calldata p // parameters of bond
    ) 
    onlyBank 
    external 
    virtual 
    override 
    returns (uint256 classId, uint256 nonceId) 
    {
        classId = uint256(uint160(token));
        nonceId = _classes[classId]._values[1].uintValue;
        _classes[classId]._values[1].uintValue = nonceId + 1;   // number of nonce
        if (nonceId == 0) { // first nonce
            // class settings
            _classes[classId]._values[0].stringValue = IPair(token).symbol();   // bond symbol
            _classes[classId]._values[2].addressValue = token;  // project token
        }

        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        // nonce settings
        nonce._values[0].addressValue = p.pairToken;
        nonce._values[1].addressValue = p.LPToken;
        nonce._values[2].addressValue = p.projectWallet;

        // vesting settings
        nonce._values[3].uintValue = p.issuanceDate;
        nonce._values[4].uintValue = p.prepaymentPenalty;
        nonce._values[5].uintValue = p.maturityDate;
        nonce._values[6].uintValue = p.maturityProfitDate;
        
        emit CreateBond(classId, nonceId, token, p);
    }
    
    // vote on Derex pool
    function vote(uint256 classId, uint256 nonceId, uint256 ballotId, bool yea) external {
        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        require(nonce._values[3].uintValue < block.timestamp, "IBO isn't over");
        IPair lp = IPair(nonce._values[1].addressValue);
        uint256 votingPower = nonce._balances[msg.sender];
        lp.vote(ballotId, yea, votingPower);
        // lock transfer
        _classes[classId]._nonces[nonceId]._voteLock[msg.sender] = block.timestamp + lp.votingTime();
        emit Vote(msg.sender, classId, nonceId, ballotId, yea, votingPower);
    }

    // create proposal on Derex pool
    function createBallot(uint256 classId, uint256 nonceId, uint256 ruleId, bytes calldata args) external {
        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        require(nonce._values[3].uintValue < block.timestamp, "IBO isn't over");
        IPair lp = IPair(nonce._values[1].addressValue);
        uint256 votingPower = nonce._balances[msg.sender];
        lp.createBallot(ruleId, args, votingPower);
        // lock transfer
        _classes[classId]._nonces[nonceId]._voteLock[msg.sender] = block.timestamp + lp.votingTime();
        emit CreateBallot(msg.sender, classId, nonceId, ruleId, args, votingPower);
    }

    function redeemWithPenalty(IERC3475.Transaction calldata _transaction) external {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        uint256 prepaymentPenalty = nonce._values[4].uintValue;
        require(prepaymentPenalty != 0, "Prepayment Penalty disallowed");
        // verify whether _amount of bonds to be redeemed  are sufficient available  for the given nonce of the bonds

        require(
            nonce._balances[msg.sender] >= _transaction.amount,
            "ERC3475: not enough bond to transfer"
        );

        require(nonce._voteLock[msg.sender] < block.timestamp, "Bond is locked");    // voting lock
        
        //transfer balance
        nonce._balances[msg.sender] -= _transaction.amount;
        nonce._activeSupply -= _transaction.amount;
        nonce._redeemedSupply += _transaction.amount;

        //farming
        updateFarming(_transaction.classId, msg.sender);
        _classes[_transaction.classId]._values[3].uintValue -= _transaction.amount; // update total bonds amount
        _classes[_transaction.classId]._userBalance[msg.sender] -= _transaction.amount; // update user's balance of all bonds in this class

        // remove Liquidity
        address projectToken = _classes[_transaction.classId]._values[2].addressValue;
        address pairToken = nonce._values[0].addressValue;
        address lp = nonce._values[1].addressValue;
        lp.safeTransferFrom(address(this), lp, _transaction.amount);
        IPair(lp).burn(address(this));
        // check real amount of receiving tokens to support tokens with fee on transfer
        uint256 pairTokenAmount = IPair(pairToken).balanceOf(address(this));

        // calculate penalty
        uint256 penalty;
        {
        uint256 principalAmount = nonce._principalAmount[msg.sender];
        uint256 profit;
        uint256 issuanceDate = nonce._values[3].uintValue;
        require(issuanceDate <= block.timestamp, "issuanceDate error");
        if (pairTokenAmount > principalAmount) {
            profit = pairTokenAmount - principalAmount;
            pairTokenAmount = principalAmount;
        }
        nonce._principalAmount[msg.sender] = principalAmount - pairTokenAmount; // update principal
        if(nonce._values[5].uintValue > block.timestamp) {  // maturityDate is not reached - take penalty from principal
            // penalty = tokenAmount * penalty% * timeLeft / maxTime
            penalty = pairTokenAmount * prepaymentPenalty * (nonce._values[5].uintValue - block.timestamp) 
            / ((nonce._values[5].uintValue - issuanceDate) * 1000000);
        } 
        if (nonce._values[6].uintValue > block.timestamp) { // maturityProfitDate is not reached - take penalty from profit
            // penalty = tokenAmount * penalty% * timeLeft / maxTime
            penalty += (profit * prepaymentPenalty * (nonce._values[6].uintValue - block.timestamp) 
            / ((nonce._values[6].uintValue - issuanceDate) * 1000000));
        }
            pairTokenAmount = pairTokenAmount + profit - penalty;   // amount for user
        }
        
        if (pairToken == WETH) {
            // pairToken is native coin
            if (penalty > 0) WETH.safeTransfer(lp, penalty);    // transfer penalty to pool
            IWETH(WETH).withdraw(pairTokenAmount);
            msg.sender.safeTransferETH(pairTokenAmount);
        } else {
            if (penalty > 0) pairToken.safeTransfer(lp, penalty);    // transfer penalty to pool
            pairToken.safeTransfer(msg.sender, pairTokenAmount);
        }
        if (penalty > 0) IPair(lp).sync();  // sync pool

        // transfer Derex token if exist
        if (derexToken != address(0) && derexToken != projectToken && derexToken != pairToken) {
            uint256 derexAmount = IPair(derexToken).balanceOf(address(this));
            if (derexAmount != 0) derexToken.safeTransfer(msg.sender, derexAmount);
        }

        {
        // transfer project tokens to project wallet
        uint256 projectTokenAmount = IPair(projectToken).balanceOf(address(this));
        address projectWallet = nonce._values[2].addressValue;
        if (projectWallet == address(0))
            projectToken.safeTransfer(BURN_ADDRESS, projectTokenAmount);   // burn
        else
            projectToken.safeTransfer(projectWallet, projectTokenAmount);
        }
        {
        IERC3475.Transaction[] memory _transactions = new IERC3475.Transaction[](1);
        _transactions[0] = _transaction;
        emit Redeem(msg.sender, msg.sender, _transactions);
        }
    }

    // WRITABLES
    function transferFrom(
        address _from,
        address _to,
        Transaction[] calldata _transactions
    ) public virtual override {
        require(
            _from != address(0),
            "ERC3475: can't transfer from the zero address"
        );
        require(
            _to != address(0),
            "ERC3475:use burn() instead"
        );
        require(
            msg.sender == _from ||
            isApprovedFor(_from, msg.sender),
            "ERC3475:caller-not-owner-or-approved"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            _transferFrom(_from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);
    }

    function transferAllowanceFrom(
        address _from,
        address _to,
        Transaction[] calldata _transactions
    ) public virtual override {
        require(
            _from != address(0),
            "ERC3475: can't transfer allowed amt from zero address"
        );
        require(
            _to != address(0),
            "ERC3475: use burn() instead"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                _transactions[i].amount <= allowance(_from, msg.sender, _transactions[i].classId, _transactions[i].nonceId),
                "ERC3475:caller-not-owner-or-approved"
            );
            _transferAllowanceFrom(msg.sender, _from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);
    }


    function issue(address _to, uint256 _principal, Transaction calldata _transaction)
    onlyBank
    external
    virtual
    override
    {
        IERC3475.Transaction[] memory _transactions = new IERC3475.Transaction[](1);
        _transactions[0] = _transaction;
        require(
            _to != address(0),
            "ERC3475: can't issue to the zero address"
        );
        _issue(_to, _principal, _transaction);

        emit Issue(msg.sender, _to, _transactions);
    }

    function redeem(address _from, Transaction[] calldata _transactions)
    external
    virtual
    override
    {
        require(
            _from != address(0),
            "ERC3475: can't redeem from the zero address"
        );
        // alow owner or approved address to redeem
        require(
            msg.sender == _from ||
            isApprovedFor(_from, msg.sender) ||
            msg.sender == bank,
            "ERC3475: caller-not-owner-or-approved"
        );

        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            //(, uint256 progressRemaining) = getProgress(
            int256 limit = getLimit(
                _transactions[i].classId,
                _transactions[i].nonceId,
                _from
            );
            require(
                //progressRemaining == 0,
                limit >= 0,
                "ERC3475 Error: Not redeemable"
            );
            _redeem(uint256(limit), _from, _transactions[i]);
        }
        emit Redeem(msg.sender, _from, _transactions);
    }

    function burn(address _from, Transaction[] calldata _transactions)
    external
    virtual
    override
    {
        require(
            _from != address(0),
            "ERC3475: can't burn from the zero address"
        );
        require(
            msg.sender == _from ||
            isApprovedFor(_from, msg.sender),
            "ERC3475: caller-not-owner-or-approved"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            _burn(_from, _transactions[i]);
        }
        emit Burn(msg.sender, _from, _transactions);
    }

    function approve(address _spender, Transaction[] calldata _transactions)
    external
    virtual
    override
    {
        for (uint256 i = 0; i < _transactions.length; i++) {
            _classes[_transactions[i].classId]
            ._nonces[_transactions[i].nonceId]
            ._allowances[msg.sender][_spender] = _transactions[i].amount;
        }
    }

    function setApprovalFor(
        address operator,
        bool approved
    ) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, approved);
    }

    // READABLES
    function totalSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return (activeSupply(classId, nonceId) +
        burnedSupply(classId, nonceId) +
        redeemedSupply(classId, nonceId)
        );
    }

    function activeSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._activeSupply;
    }

    function burnedSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._burnedSupply;
    }

    function redeemedSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._redeemedSupply;
    }

    function balanceOf(
        address account,
        uint256 classId,
        uint256 nonceId
    ) public view override returns (uint256) {
        require(
            account != address(0),
            "ERC3475: balance query for the zero address"
        );
        return _classes[classId]._nonces[nonceId]._balances[account];
    }

    function classMetadata(uint256 metadataId)
    external
    view
    override
    returns (Metadata memory) {
        return (_classMetadata[metadataId]);
    }

    function nonceMetadata(uint256 classId, uint256 metadataId)
    external
    view
    override
    returns (Metadata memory) {
        classId = 0;   // all classes have the same nonceMetadata
        return (_classes[classId]._nonceMetadatas[metadataId]);
    }

    function classValues(uint256 classId, uint256 metadataId)
    external
    view
    override
    returns (Values memory) {
        return (_classes[classId]._values[metadataId]);
    }


    function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId)
    external
    view
    override
    returns (Values memory) {
        return (_classes[classId]._nonces[nonceId]._values[metadataId]);
    }

    /** determines the progress till the  redemption of the bonds is valid  (based on the type of bonds class).
     * @notice ProgressAchieved and `progressRemaining` is abstract.
     */
    function getProgress(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256 progressAchieved, uint256 progressRemaining){
        (progressAchieved, progressRemaining) = getProgress(classId, nonceId, msg.sender);
    }

    /** determines the progress till the  redemption of the bonds is valid (based on the type of bonds class and user address).
     * @notice ProgressAchieved and `progressRemaining` is abstract.
     */
    function getProgress(uint256 classId, uint256 nonceId, address user)
    public
    view
    returns (uint256 progressAchieved, uint256 progressRemaining) {
        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        uint256 issuanceDate = nonce._values[3].uintValue;
        uint256 maturityDate;
        if (nonce._principalAmount[user] != 0) { // principalAmount not received yet
            // maturity for principal
            maturityDate = nonce._values[5].uintValue;
        } else {
            // maturity for profit
            maturityDate = nonce._values[6].uintValue;
        }

        // check whether the bond is being already initialized:
        progressAchieved = block.timestamp - issuanceDate;
        progressRemaining = block.timestamp < maturityDate
        ? maturityDate - block.timestamp
        : 0;
    }

    /**
    gets the allowance of the bonds identified by (classId,nonceId) held by _owner to be spend by spender.
     */
    function allowance(
        address _owner,
        address spender,
        uint256 classId,
        uint256 nonceId
    ) public view virtual override returns (uint256) {
        return _classes[classId]._nonces[nonceId]._allowances[_owner][spender];
    }

    /**
    checks the status of approval to transfer the ownership of bonds by _owner  to operator.
     */
    function isApprovedFor(
        address _owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    // return maximum amount of pairToken is allowed to redeem. (0) means "no limit", (-1) means "nothing allowed"
    function getLimit(uint256 classId, uint256 nonceId, address user) public view virtual returns(int256) {
        Nonce storage nonce = _classes[classId]._nonces[nonceId];
        if(nonce._values[5].uintValue > block.timestamp) return -1; // maturityDate is not reached - nothing allowed
        else if (nonce._values[6].uintValue <= block.timestamp) return 0; // maturityProfitDate reached - no limit
        else return int256(nonce._principalAmount[user]); // principalAmount allowed
    }

    // return vote lock time
    function getVoteLock(uint256 classId, uint256 nonceId, address user) public view returns(uint256) {
        return _classes[classId]._nonces[nonceId]._voteLock[user];
    }

    // return principal amounts of user and available amounts of pair tokens in the batch of bonds
    function getUserAmounts(uint256[] calldata classId, uint256[] calldata nonceId, address user) 
    public 
    view 
    returns(uint256[] memory principalAmount, uint256[] memory availableAmount) {
        require(classId.length == nonceId.length, "wrong length");
        principalAmount = new uint256[](classId.length);
        availableAmount = new uint256[](classId.length);
        for (uint i = 0; i < classId.length; i++){
            (principalAmount[i], availableAmount[i]) = getUserAmount(classId[i], nonceId[i], user);
        }
    }

    // return principal amount of user and available amount of pair tokens in the bond
    function getUserAmount(uint256 classId, uint256 nonceId, address user) 
    public 
    view 
    returns(uint256 principalAmount, uint256 availableAmount) {
        principalAmount = _classes[classId]._nonces[nonceId]._principalAmount[user];
        uint256 balance = _classes[classId]._nonces[nonceId]._balances[user];
        address poolAddress = _classes[classId]._nonces[nonceId]._values[1].addressValue;
        address token = _classes[classId]._values[2].addressValue; // project token
        address pairToken = _classes[classId]._nonces[nonceId]._values[0].addressValue;  // pair token
        uint256 totalLP = IPair(poolAddress).totalSupply();
        require(totalLP != 0, "Wrong totalSupply");
        (uint256 money,) = getReserves(pairToken, token, poolAddress);
        availableAmount = uint256(money) * balance / totalLP;    // amount of pair tokens belong to user's bond
    }

    function getFarmingData(uint256 classId, address user)
    external 
    view 
    override
    returns(uint256 userBalance, uint256 userRewardPerTokenPaid, uint256 rewardPerTokenStored, uint256 totalBonds) {
        Class storage c = _classes[classId];
        totalBonds = c._values[3].uintValue;
        uint256 _lastUpdateTime = c._lastUpdateTime;
        if (totalBonds != 0 && _lastUpdateTime != 0) {
            userRewardPerTokenPaid = c._userRewardPerTokenPaid[user];
            rewardPerTokenStored = c._rewardPerTokenStored;
            uint256 _timePassed = block.timestamp - _lastUpdateTime;
            rewardPerTokenStored += (_timePassed * 1 ether * 1e18 / totalBonds);  // 1 token per second
            userBalance = c._userBalance[user];
        }
    }

    // update farming data for user
    function updateFarming(uint256 classId, address user) public {
        Class storage c = _classes[classId];
        uint256 totalBonds = c._values[3].uintValue;
        uint256 _lastUpdateTime = c._lastUpdateTime;
        if (totalBonds != 0 && _lastUpdateTime != 0) {
            uint256 userRewardPerTokenPaid = c._userRewardPerTokenPaid[user];
            uint256 rewardPerTokenStored = c._rewardPerTokenStored;
            if (_lastUpdateTime < block.timestamp) {
                uint256 _timePassed = block.timestamp - _lastUpdateTime;
                rewardPerTokenStored += (_timePassed * 1e36 / totalBonds);  // 1 token per second
                c._rewardPerTokenStored = rewardPerTokenStored;
                c._lastUpdateTime = block.timestamp;
            }
            c._userRewardPerTokenPaid[user] = rewardPerTokenStored;
            uint256 userBalance = c._userBalance[user];
            try IBank(bank).updateFarming(classId, user, userBalance, userRewardPerTokenPaid, rewardPerTokenStored, totalBonds) {}
            catch {emit FarmingFailed();}
        } else {
            c._lastUpdateTime = block.timestamp;
        }
    }

    // INTERNALS
    function _transferFrom(
        address _from,
        address _to,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not enough bond to transfer"
        );

        require(nonce._voteLock[_from] < block.timestamp, "Bond is locked");    // voting lock
        //transfer principals (insurance amount)
        uint256 insuranceAmount = nonce._principalAmount[_from] * _transaction.amount / nonce._balances[_from];
        nonce._principalAmount[_from] -= insuranceAmount;
        nonce._principalAmount[_to] += insuranceAmount;

        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._balances[_to] += _transaction.amount;

        // farming
        updateFarming(_transaction.classId, _from);
        updateFarming(_transaction.classId, _to);
        _classes[_transaction.classId]._userBalance[_from] -= _transaction.amount; // update user's balance of all bonds in this class
        _classes[_transaction.classId]._userBalance[_to] += _transaction.amount; // update user's balance of all bonds in this class
    }

    function _transferAllowanceFrom(
        address _operator,
        address _from,
        address _to,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not allowed amount"
        );
        require(nonce._voteLock[_from] < block.timestamp, "Bond is locked");    // voting lock

        // reducing the allowance and decreasing accordingly.
        nonce._allowances[_from][_operator] -= _transaction.amount;

        //transfer principals (insurance amount)
        uint256 insuranceAmount = nonce._principalAmount[_from] * _transaction.amount / nonce._balances[_from];
        nonce._principalAmount[_from] -= insuranceAmount;
        nonce._principalAmount[_to] += insuranceAmount;

        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._balances[_to] += _transaction.amount;

        // farming
        updateFarming(_transaction.classId, _from);
        updateFarming(_transaction.classId, _to);
        _classes[_transaction.classId]._userBalance[_from] -= _transaction.amount; // update user's balance of all bonds in this class
        _classes[_transaction.classId]._userBalance[_to] += _transaction.amount; // update user's balance of all bonds in this class
    }

    function _issue(
        address _to,
        uint256 _principalAmount,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        nonce._principalAmount[_to] += _principalAmount;

        //transfer balance
        nonce._balances[_to] += _transaction.amount;
        nonce._activeSupply += _transaction.amount;

        //farming
        updateFarming(_transaction.classId, _to);
        _classes[_transaction.classId]._values[3].uintValue += _transaction.amount; // update total bonds amount
        _classes[_transaction.classId]._userBalance[_to] += _transaction.amount; // update user's balance of all bonds in this class
    }


    function _redeem(
        uint256 limit,
        address _from,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        // verify whether _amount of bonds to be redeemed  are sufficient available  for the given nonce of the bonds

        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not enough bond to transfer"
        );

        require(nonce._voteLock[_from] < block.timestamp, "Bond is locked");    // voting lock
        
        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._activeSupply -= _transaction.amount;
        nonce._redeemedSupply += _transaction.amount;

        //farming
        updateFarming(_transaction.classId, _from);
        _classes[_transaction.classId]._values[3].uintValue -= _transaction.amount; // update total bonds amount
        _classes[_transaction.classId]._userBalance[_from] -= _transaction.amount; // update user's balance of all bonds in this class

        // remove Liquidity
        address projectToken = _classes[_transaction.classId]._values[2].addressValue;
        address pairToken = nonce._values[0].addressValue;
        address lp = nonce._values[1].addressValue;
        lp.safeTransfer(lp, _transaction.amount);
        IPair(lp).burn(address(this));
        // check real amount of receiving tokens to support tokens with fee on transfer
        uint256 pairTokenAmount = IPair(pairToken).balanceOf(address(this));

        if (limit > 0) {
            require(limit >= pairTokenAmount, "amount > principal");
            nonce._principalAmount[_from] -= pairTokenAmount; // reduce principal amount
        } else {
            nonce._principalAmount[_from] = 0; // can be redeemed any value
        }
        if (pairToken == WETH) {
            // pairToken is native coin
            IWETH(WETH).withdraw(pairTokenAmount);
            _from.safeTransferETH(pairTokenAmount);
        } else {
            pairToken.safeTransfer(_from, pairTokenAmount);
        }


        // transfer Derex token if exist
        if (derexToken != address(0) && derexToken != projectToken && derexToken != pairToken) {
            uint256 derexAmount = IPair(derexToken).balanceOf(address(this));
            if (derexAmount != 0) derexToken.safeTransfer(_from, derexAmount);
        }

        // transfer project tokens
        uint256 projectTokenAmount = IPair(projectToken).balanceOf(address(this));
        address projectWallet = nonce._values[2].addressValue;
        if (projectWallet == address(0))
            projectToken.safeTransfer(BURN_ADDRESS, projectTokenAmount);    // burn
        else
            projectToken.safeTransfer(projectWallet, projectTokenAmount);   // transfer project tokens to project wallet
    }


    function _burn(
        address _from,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        // verify whether _amount of bonds to be burned are sufficient available for the given nonce of the bonds
        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not enough bond to transfer"
        );

        // principal amount for this part of LP
        uint256 principalAmount = nonce._principalAmount[_from] * _transaction.amount / nonce._balances[_from]; 
        nonce._principalAmount[_from] -= principalAmount; // reduce principal amount

        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._activeSupply -= _transaction.amount;
        nonce._burnedSupply += _transaction.amount;

        //farming
        updateFarming(_transaction.classId, _from);
        _classes[_transaction.classId]._values[3].uintValue -= _transaction.amount; // update total bonds amount
        _classes[_transaction.classId]._userBalance[_from] -= _transaction.amount; // update user's balance of all bonds in this class
    }

    receive() external payable {
        require(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, address pair) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DFGlobalEscrow is Ownable {

    enum Sign {
        NULL,
        REVERT,
        RELEASE
    }

    enum TokenType {
        ETH,
        ERC20
    }

    struct EscrowRecord {
        string referenceId;
        address payable delegator;
        address payable owner;
        address payable recipient;
        address payable agent;
        TokenType tokenType;
        address tokenAddress;
        uint256 fund;
        mapping(address => bool) signer;
        mapping(address => Sign) signed;
        uint256 releaseCount;
        uint256 revertCount;
        bool funded;
        bool disputed;
        bool finalized;
        uint256 withdrawnAmount;
        bool shouldInvest;
    }

    mapping(string => EscrowRecord) _escrow;

    function isSigner(string memory _referenceId, address _signer)
        public
        view
        returns (bool)
    {
        return _escrow[_referenceId].signer[_signer];
    }

    function getSignedAction(string memory _referenceId, address _signer)
        public
        view
        returns (Sign)
    {
        return _escrow[_referenceId].signed[_signer];
    }

    event EscrowInitiated(
        string referenceId,
        address payer,
        uint256 amount,
        TokenType tokenType,
        address payee,
        address trustedParty
    );

    event Signature(
        string referenceId,
        address signer,
        Sign action
    );
    event Finalized(string referenceId, address winner);
    event Disputed(string referenceId, address disputer);
    event Withdrawn(
        string referenceId,
        address payee,
        uint256 amount
    );
    event Funded(
        string indexed referenceId,
        address indexed owner,
        uint256 amount
    );

    modifier multisigcheck(string memory _referenceId, address _party) {
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.finalized, "Escrow should not be finalized");
        require(e.funded, "Escrow is not funded");
        require(e.signer[_party], "Party is not eligible to sign");
        require(
            e.signed[_party] == Sign.NULL,
            "Party has already signed"
        );

        _;

        if (e.releaseCount == 2) {
            transferOwnership(e);
        } else if (e.revertCount == 2) {
            finalize(e);
        } else if (e.releaseCount == 1 && e.revertCount == 1) {
            dispute(e, _party);
        }
    }

    modifier onlyEscrowOwner(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender,
            "Sender must be Escrow's owner"
        );
        _;
    }

    modifier onlyEscrowOwnerOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's owner or delegator"
        );
        _;
    }

    modifier onlyEscrowPartyOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].recipient == msg.sender ||
            _escrow[_referenceId].agent == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's Owner or Recipient or agent or delegator"
        );
        _;
    }

    modifier onlyEscrowOwnerOrRecipientOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].recipient == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's Owner or Recipient or delegator"
        );
        _;
    }

    modifier onlyEscrowAgent(string memory _referenceId) {
        require(_escrow[_referenceId].agent == msg.sender, "Only Escrow Agent can perform action");
        _;
    }

    modifier isFunded(string memory _referenceId) {
        require(
            _escrow[_referenceId].funded == true,
            "Escrow should be funded"
        );
        _;
    }

    function createEscrow(
        string memory _referenceId,
        address payable _owner,
        address payable _recipient,
        address payable _agent,
        TokenType tokenType,
        address erc20TokenAddress,
        uint256 tokenAmount
    ) public payable onlyOwner {
        require(msg.sender != address(0), "Sender should not be null");
        require(_owner != address(0), "Recipient should not be null");
        require(_recipient != address(0), "Recipient should not be null");
        require(_agent != address(0), "Trusted Agent should not be null");
        require(_escrow[_referenceId].owner == address(0), "Duplicate Escrow");

        EscrowRecord storage e = _escrow[_referenceId];
        e.referenceId = _referenceId;
        e.owner = _owner;

        if (e.owner != msg.sender) {
            e.delegator = payable(msg.sender);
        }

        e.recipient = _recipient;
        e.agent = _agent;
        e.tokenType = tokenType;
        e.funded = false;

        if (e.tokenType == TokenType.ETH) {
            e.fund = tokenAmount;
            emit EscrowInitiated(
            _referenceId,
            _owner,
            e.fund,
            TokenType.ETH,
            _recipient,
            _agent
        );
        } else {
            e.tokenAddress = erc20TokenAddress;
            e.fund = tokenAmount;
            emit EscrowInitiated(
            _referenceId,
            _owner,
            e.fund,
            TokenType.ERC20,
            _recipient,
            _agent
        );
        }

        e.disputed = false;
        e.finalized = false;

        e.releaseCount = 0;
        e.revertCount = 0;

        e.signer[_owner] = true;
        e.signer[_recipient] = true;
        e.signer[_agent] = true;
    }

    function fund(string memory _referenceId, uint256 fundAmount)
        public
        payable
        onlyEscrowOwnerOrDelegator(_referenceId)
    {
        require(
            _escrow[_referenceId].owner != address(0),
            "Sender should not be null"
        );
        uint256 escrowFund = _escrow[_referenceId].fund;
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.funded, "Escrow is already funded");
        if (e.tokenType == TokenType.ETH) {
            require(
                msg.value == escrowFund,
                "Must fund for exact ETH-amount in Escrow"
            );
        } else {
            require(msg.value == 0, "cannot accept ethers for erc20 token escrow");
            require(
                fundAmount == escrowFund,
                "Must fund for exact ERC20-amount in Escrow"
            );
            IERC20 erc20Instance = IERC20(e.tokenAddress);
            erc20Instance.transferFrom(msg.sender, address(this), escrowFund);
        }

        e.funded = true;
        emit Funded(_referenceId, msg.sender, escrowFund);
    }

    function release(string memory _referenceId, address _party)
        public
        multisigcheck(_referenceId, _party)
        onlyEscrowPartyOrDelegator(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];

        require(
          _party == e.owner || _party == e.recipient || _party == e.agent,
          "Only owner or recipient or agent can release an escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        emit Signature(_referenceId, _party, Sign.RELEASE);

        e.signed[_party] = Sign.RELEASE;
        e.releaseCount++;
    }

    function reverse(string memory _referenceId, address _party)
        public
        onlyEscrowPartyOrDelegator(_referenceId)
        multisigcheck(_referenceId, _party)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        
        require(
          _party == e.owner || _party == e.recipient || _party == e.agent,
          "Only owner or recipient or agent can reverse an escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        emit Signature(_referenceId, _party, Sign.REVERT);

        e.signed[_party] = Sign.REVERT;
        e.revertCount++;
    }

    function dispute(string memory _referenceId, address _party) public 
    onlyEscrowOwnerOrRecipientOrDelegator(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.finalized, "Cannot dispute on a finalised Escrow");
        require(e.funded, "Escrow is not funded");
        require(
            _party == e.owner || _party == e.recipient,
            "Only owner or recipient can dispute on escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        dispute(e, _party);
    }

    function finalize(string memory _referenceId) public onlyEscrowAgent(_referenceId) {
        finalize(_escrow[_referenceId]);
    }

    function transferOwnership(EscrowRecord storage e) internal {
        e.owner = e.recipient;
        finalize(e);
    }

    function dispute(EscrowRecord storage e, address _party) internal
    {
        emit Disputed(e.referenceId, _party);
        e.disputed = true;
    }

    function finalize(EscrowRecord storage e) internal {
        require(!e.finalized, "Escrow should not be finalized");

        emit Finalized(e.referenceId, e.owner);

        e.finalized = true;
    }

    function withdraw(string memory _referenceId, uint256 _amount)
        public
        onlyEscrowOwner(_referenceId)
        isFunded(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        require(e.finalized, "Escrow should be finalized before withdrawal");
        require(e.withdrawnAmount + _amount <= e.fund, "Cannot withdraw more than the deposit");

        address escrowOwner = e.owner;

        emit Withdrawn(_referenceId, escrowOwner, _amount);

        e.withdrawnAmount = e.withdrawnAmount + _amount;

        if (e.tokenType == TokenType.ETH) {
            require((e.owner).send(_amount));
        } else {
            IERC20 erc20Instance = IERC20(e.tokenAddress);
            require(erc20Instance.transfer(escrowOwner, _amount));
        }
    }
}
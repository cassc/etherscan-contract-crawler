// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IRupeeCash is IERC20 {
    function create_rupeeCash_busd_swap_request(uint amountIn, address destination_address) external returns (uint requestId);
}

contract RupeeCashAdmin is OwnableUpgradeable {

    address public gate_keeper;
    address public exchanger;

    // RupeeCash Swap
    IRupeeCash public RupeeCash;
    IERC20 public BUSD; // = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public JAXRE; // = IERC20(0x86ECE7D9cdA927B3Ec4044Df67B082FA55A1c198);

    enum BrokerStatus { Init, Active, InActive }
    enum AgentStatus { Init, Active, InActive }
    enum TraderStatus { Init, Pending, Active, InActive, Suspended }

    struct Broker {
        uint id;
        uint credit_rating;
        bytes32 email_hash;
        bytes32 mobile_hash;
        address nominee_address;
        BrokerStatus status;
    }

    struct Agent {
        uint id;
        uint broker_debt;
        uint credit_rating;
        bytes32 email_hash;
        bytes32 mobile_hash;
        address broker_address;
        bool is_settle_debt;
        AgentStatus status;
    }

    struct Trader {
        uint debt_to_agent;
        uint credit_rating;
        uint account_type;
        bytes32 email_hash;
        bytes32 mobile_hash;
        address agent_address;
        TraderStatus status;
    }

    mapping (bytes32 => bool) public is_used_mobile_hash;

    mapping(address => bool) public auto_exchange;
    mapping(address => bool) public auto_settlement;

    address public operator;
    address public oracle;
    address public opex_wallet;
    address public community_fee_wallet;

    uint public community_fee; // 1e4

    uint public max_trader_debt_to_agent;
    uint public min_auto_settlement_amount;
    uint public debt_settlement_ratio;

    mapping(address => Broker) public brokers;
    mapping(address => Agent) public agents;

    uint public brokerCount;
    uint public agentCount;

    mapping(uint => address) public broker_addresses;
    mapping(uint => address) public agent_addresses;

    mapping(uint => Trader) public traders;
    uint public traderCount;

    mapping(address => bool) public other_whitelist;
    mapping(address => uint) public autosettlement_amounts;
    mapping(address => AgentStatus) public requested_agent_status;
    mapping(uint => TraderStatus) public requested_trader_status;
    mapping(address => bool) public is_used_address;
    mapping(string => bool) public is_used_tx_hash;
    mapping(uint => uint) public settlements;
    mapping(address => uint) public total_settlement_amounts;

    enum LoanRequestStatus { Init, Approved, Rejected }

    struct LoanRequest {
        uint amount;
        address to;
        LoanRequestStatus status;
    }

    uint public loanRequestCount;
    LoanRequest[] public loanRequests;

    event Set_Gate_Keeper(address _gate_keeper);
    event Set_Other_Whitelisted(address account, bool flag);
    event Set_Exchanger(address exchanger);
    event Add_Broker(address broker_address, Broker broker);
    event Add_Trader(uint traderId, address agent);
    event Add_Trader_Request(uint traderId, Trader trader);
    event Approve_Trader(uint traderId, Trader trader);
    event Set_Operator(address operator);
    event Set_Oracle(address oracle);
    event Set_Opex_Wallet(address opex_wallet);
    event Set_Max_Trader_Debt_To_Agent(uint debt);
    event Set_Min_Auto_Settlement_Amount(uint amount);
    event Set_Broker_Status(BrokerStatus status);
    event Loan_To_Agent(address broker, address agent, uint debt);
    event Repay_Broker_Debt(address agent, address broker, uint amount);
    event Set_Debt_Settlement_Ratio(uint ratio);
    event Set_My_Autosettlement_Amount(address account, uint amount);
    event Add_Agent(address agent_address, Agent agent);
    event Set_Agent(address agent_address, Agent agent);
    event Set_Agent_Status(address agent, AgentStatus status);
    event Set_Trader_Status(uint traderId, TraderStatus status);
    event Edit_Trader(uint traderId, Trader trader);
    event Request_Loan_For_Broker(uint requestId, address broker, uint amount);
    event Request_Loan_For_Opex(uint requestId, address opex_address, uint amount);
    event Approve_Loan(uint requestId, uint amount);
    event Reject_Loan(uint requestId);
    event Auto_Settlement_Transfer(address indexed to, uint indexed settlement_id, string indexed private_tx_hash, uint amount, bool auto_exchange);
    event Approve_Agent_Status(address agent, AgentStatus status);
    event Approve_Trader_Status(uint traderId, TraderStatus status);

    modifier onlyGatekeeper() {
        require(msg.sender == gate_keeper, "Only Gatekeeper");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator");
        _;
    }

    modifier checkZeroAddress(address account) {
        require(account != address(0), "Zero address");
        _;
    }

    modifier checkMobileHash(bytes32 mobile_hash) {
        require(!is_used_mobile_hash[mobile_hash], "Only unique mobile hash");
        _;
    }

    function init(address _rupeeCash) public initializer
    {
        __Ownable_init();
        RupeeCash = IRupeeCash(_rupeeCash);
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        JAXRE = IERC20(0x86ECE7D9cdA927B3Ec4044Df67B082FA55A1c198);
    }

    function get_all_traders(uint start, uint count) external view returns(Trader[] memory) {
        uint ret_count = (start + count) <= traderCount ? count : traderCount - start;
        Trader[] memory traders_ = new Trader[](ret_count);
        uint i;
        for(i = 0; i < count; i ++)  {
            traders_[i] = traders[start+i];
        }
        return traders_;
    }

    function get_traders(address owner) external view returns(Trader[] memory, uint[] memory){
        uint i;
        uint agent_trader_count;
        for(i = 0; i < traderCount; i ++) {
            if(traders[i].agent_address == owner)
                agent_trader_count ++;
        }
        Trader[] memory agent_traders = new Trader[](agent_trader_count);
        uint[] memory ids = new uint[](agent_trader_count);
        uint j;
        for(i = 0; i < traderCount; i ++) {
            if(traders[i].agent_address == owner) {
                ids[j] = i;
                agent_traders[j++] = traders[i];
            }
        }
        return (agent_traders, ids);
    }

    function set_gate_keeper(address _gate_keeper) external onlyOwner {
        gate_keeper = _gate_keeper;
        emit Set_Gate_Keeper(_gate_keeper);
    }
    
    function isWhitelisted(address account) external view returns(bool) {
        return  agents[account].status == AgentStatus.Active ||
                brokers[account].status == BrokerStatus.Active ||
                other_whitelist[account];
    }

    function set_other_whitelisted(address account, bool flag) external onlyOwner {
        other_whitelist[account] = flag;
        emit Set_Other_Whitelisted(account, flag);
    }

    function set_exchanger(address _exchanger) external onlyOwner {
        exchanger = _exchanger;
        emit Set_Exchanger(_exchanger);
    }

    function add_broker(bytes32 email_hash, bytes32 mobile_hash, address broker_address, address nominee_address, uint credit_rating) external
        checkZeroAddress(broker_address) onlyOwner checkMobileHash(mobile_hash)
    {
        Broker storage broker = brokers[broker_address];
        require(!is_used_address[broker_address], "Invalid account");
        is_used_address[broker_address] = true;
        is_used_mobile_hash[mobile_hash] = true;
        broker.id = brokerCount ++;
        broker.credit_rating = credit_rating;
        broker.email_hash = email_hash;
        broker.mobile_hash = mobile_hash;
        broker.nominee_address = nominee_address;
        broker.status = BrokerStatus.Active;
        broker_addresses[broker.id] = broker_address;
        emit Add_Broker(broker_address, broker);
    }

    function add_agent(bytes32 email_hash, bytes32 mobile_hash, address agent_address, uint credit_rating, bool is_settle_debt) external  checkZeroAddress(agent_address) 
        checkMobileHash(mobile_hash) 
    {
        Broker storage broker = brokers[msg.sender];
        require(broker.status == BrokerStatus.Active, "Only broker");
        Agent storage agent = agents[agent_address];
        require(!is_used_address[agent_address], "Invalid account");
        is_used_address[agent_address] = true;
        is_used_mobile_hash[mobile_hash] = true;
        agent.id = agentCount ++;
        agent.credit_rating = credit_rating;
        agent.is_settle_debt = is_settle_debt;
        agent.broker_address = msg.sender;
        agent.email_hash = email_hash;
        agent.mobile_hash = mobile_hash;
        agent.status = AgentStatus.Active;
        agent_addresses[agent.id] = agent_address;
        emit Add_Agent(agent_address, agent);
    }

    function set_agent_status(bytes32 email_hash, bytes32 mobile_hash, address agent_address, AgentStatus status) external {
        Agent storage agent = agents[agent_address];
        require(agent.broker_address == msg.sender, "Not a valid broker");
        require(agent.email_hash == email_hash && agent.mobile_hash == mobile_hash, "Invalid hash");
        require(status != AgentStatus.Init, "Invalid status");
        if(status != AgentStatus.Active)
            requested_agent_status[agent_address] = status;
        else
            agent.status = status;
        emit Set_Agent_Status(agent_address, status);
    }

    function approve_agent_status(address agent) external onlyOwner {
        require(requested_agent_status[agent] != AgentStatus.Init, "Invalid status");
        agents[agent].status = requested_agent_status[agent];
        emit Approve_Agent_Status(agent, requested_agent_status[agent]);
        requested_agent_status[agent] = AgentStatus.Init;
    }

    function set_agent(address agent_address, uint credit_rating, bool is_settle_debt) external {
        Agent storage agent = agents[agent_address];
        require(agent.broker_address == msg.sender && agent.status != AgentStatus.Init, "Invalid agent");
        agent.credit_rating = credit_rating;
        agent.is_settle_debt = is_settle_debt;
        emit Set_Agent(agent_address, agent);
    }

    function add_trader_request(bytes32 email_hash, bytes32 mobile_hash, uint trader_debt_to_agent, uint trader_credit_rating, uint account_type) external
        checkMobileHash(mobile_hash) 
    { 
        require(agents[msg.sender].status == AgentStatus.Active, "Only agent");
        uint trader_id = traderCount;
        Trader storage trader = traders[trader_id];
        trader.agent_address = msg.sender;
        if(trader_debt_to_agent > max_trader_debt_to_agent)
            trader_debt_to_agent = max_trader_debt_to_agent;
        trader.debt_to_agent = trader_debt_to_agent;
        trader.credit_rating = trader_credit_rating;
        trader.email_hash = email_hash;
        trader.mobile_hash = mobile_hash;
        trader.account_type = account_type;
        trader.status = TraderStatus.Pending;
        is_used_mobile_hash[mobile_hash] = true;
        emit Add_Trader_Request(traderCount++, trader);
    }
    
    function set_trader_status(uint traderId, TraderStatus status) external {
        require(traders[traderId].agent_address == msg.sender, "Invalid agent");
        require(traders[traderId].status != TraderStatus.Init && status != TraderStatus.Init, "Invalid status");
        if(status != TraderStatus.Active)
            requested_trader_status[traderId] = status;
        else
            traders[traderId].status = status;
        emit Set_Trader_Status(traderId, status);
    }

    function approve_trader_status(uint traderId) external onlyOperator {
        require(requested_trader_status[traderId] != TraderStatus.Init, "Invalid status");
        traders[traderId].status = requested_trader_status[traderId];
        emit Approve_Trader_Status(traderId, requested_trader_status[traderId]);
        requested_trader_status[traderId] = TraderStatus.Init;
    }

    function approve_trader(uint traderId) external onlyOperator {
        Trader storage trader = traders[traderId];
        require(trader.status == TraderStatus.Pending, "Invalid status");
        trader.status = TraderStatus.Active;
        emit Approve_Trader(traderId, trader);
    }

    function edit_trader(uint traderId, bytes32 email_hash, bytes32 mobile_hash, uint trader_credit_rating, uint account_type) 
        external onlyOwner { 
        Trader storage trader = traders[traderId];
        trader.credit_rating = trader_credit_rating;
        trader.email_hash = email_hash;
        trader.mobile_hash = mobile_hash;
        trader.account_type = account_type;
        emit Edit_Trader(traderId, trader);
    }

    function set_operator(address _operator) external onlyOwner {
        require(_operator != address(0), "Zero address");
        operator = _operator;
        emit Set_Operator(_operator);
    }

    function set_oracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Zero address");
        oracle = _oracle;
        emit Set_Oracle(_oracle);
    }

    function set_opex_wallet(address _opex_wallet) external onlyOwner {
        opex_wallet = _opex_wallet;
        emit Set_Opex_Wallet(_opex_wallet);
    }

    function set_max_trader_debt_to_agent(uint _debt) external onlyOwner {
        max_trader_debt_to_agent = _debt;
        emit Set_Max_Trader_Debt_To_Agent(_debt);
    }

    function set_broker_status(address broker_address, BrokerStatus status) external onlyOwner {
        Broker storage broker = brokers[broker_address];
        require(broker.status != BrokerStatus.Init && status != BrokerStatus.Init, "Invalid status");
        broker.status = status;
        emit Set_Broker_Status(status);
    }

    function set_min_auto_settlement_amount(uint amount) external onlyOwner {
        min_auto_settlement_amount = amount;
        emit Set_Min_Auto_Settlement_Amount(amount);
    }

    function loan_to_agent(address broker_address, address agent_address, uint debt) external {
        require(msg.sender == address(RupeeCash), "Only RupeeCash contract");
        Agent storage agent = agents[agent_address];
        require(brokers[agent.broker_address].status == BrokerStatus.Active, "Broker not active");
        require(agent.broker_address == broker_address && agent.status == AgentStatus.Active, "Invalid agent");
        agent.broker_debt += debt;
        emit Loan_To_Agent(broker_address, agent_address, debt);
    }

    function auto_settlement_transfer(address to, uint amount, uint settlement_id, bool force_auto_exchange, string memory private_tx_hash) external onlyGatekeeper {
        require(amount >= min_auto_settlement_amount && amount >= autosettlement_amounts[to], "Smaller than auto settlement amount");
        require(!is_used_tx_hash[private_tx_hash], "Tx hash not unique");
        require(settlements[settlement_id] == 0, "Settlement id not unique");
        is_used_tx_hash[private_tx_hash] = true;
        settlements[settlement_id] = amount;
        total_settlement_amounts[to] += amount;
        uint debt_settlement_amount = 0;
        if(agents[to].is_settle_debt) {
            debt_settlement_amount = _min(agents[to].broker_debt, amount * debt_settlement_ratio / 100);
            if(debt_settlement_amount > 0) {
                RupeeCash.transferFrom(gate_keeper, agents[to].broker_address, debt_settlement_amount);
                agents[to].broker_debt -= debt_settlement_amount;
            }
        }
        if(auto_exchange[to] || force_auto_exchange) {
            RupeeCash.transferFrom(gate_keeper, address(this), amount - debt_settlement_amount);
            RupeeCash.create_rupeeCash_busd_swap_request(amount, to);
        }
        else 
            RupeeCash.transferFrom(gate_keeper, to, amount - debt_settlement_amount);
        emit Auto_Settlement_Transfer(to, settlement_id, private_tx_hash, amount, auto_exchange[to] || force_auto_exchange);
    }

    function set_debt_settlement_ratio(uint ratio) external onlyOwner {
        require(ratio <= 50, "Over 50%");
        debt_settlement_ratio = ratio;
        emit Set_Debt_Settlement_Ratio(ratio);
    }

    function set_my_autosettlement_amount(uint amount) external {
        autosettlement_amounts[msg.sender] = amount;
        emit Set_My_Autosettlement_Amount(msg.sender, amount);
    }

    function repay_broker_debt(address agent_address, uint amount) external returns(address){
        require(msg.sender == address(RupeeCash), "Only RupeeCash contract");
        Agent storage agent = agents[agent_address];
        require(agent.status == AgentStatus.Active, "Only agent");
        require(amount <= agent.broker_debt, "Over broker debt");
        agent.broker_debt -= amount;
        emit Repay_Broker_Debt(agent_address, agent.broker_address, amount);
        return agent.broker_address;
    }

    function request_loan(address brokerOrOpex, uint amount) external onlyOperator {
        LoanRequest memory loanRequest;
        loanRequest.to = brokerOrOpex;
        loanRequest.amount = amount;
        loanRequests.push(loanRequest);
        if(brokerOrOpex == opex_wallet) {
            emit Request_Loan_For_Opex(loanRequestCount++, msg.sender, amount);
        }
        else {
            require(brokers[brokerOrOpex].status == BrokerStatus.Active, "Invalid broker");
            emit Request_Loan_For_Broker(loanRequestCount++, brokerOrOpex, amount);
        }
        
    }

    function approve_loan(uint requestId) external onlyOwner {
        require(loanRequests[requestId].status == LoanRequestStatus.Init, "Invalid status");
        loanRequests[requestId].status = LoanRequestStatus.Approved;
        emit Approve_Loan(requestId, loanRequests[requestId].amount);
    }

    function reject_loan(uint requestId) external onlyOwner {
        require(loanRequests[requestId].status == LoanRequestStatus.Init, "Invalid status");
        loanRequests[requestId].status = LoanRequestStatus.Rejected;
        emit Reject_Loan(requestId);
    }

    function set_auto_exchange(bool flag) external {
        auto_exchange[msg.sender] = flag;
    }

    function set_auto_settlement(bool flag) external {
        auto_settlement[msg.sender] = flag;
    }

    function set_auto_flags(bool _auto_exchange, bool _auto_settlement) external {
        auto_exchange[msg.sender] = _auto_exchange;
        auto_settlement[msg.sender] = _auto_settlement;
    }

    function set_community_fee(address wallet, uint fee) external onlyOwner {
        require(wallet != address(0), "Zero address");
        require(fee <= 1e3, "Fee: Higher than 10%");
        community_fee_wallet = wallet;
        community_fee = fee;
    }

}


function _min(uint a, uint b) pure returns(uint) {
    return a < b ? a : b;
}
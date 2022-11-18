// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./lib/BEP20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RupeeCashAdmin.sol";

contract RupeeCash is BEP20Upgradeable {

    RupeeCashAdmin public admin;

    // RupeeCash Swap
    IERC20 public BUSD; // = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public JAXRE; // = IERC20(0x86ECE7D9cdA927B3Ec4044Df67B082FA55A1c198);

    uint public max_jaxre_rupeeCash_ratio; // 1e8
    uint public max_exchange_ratio;

    enum RequestStatus { Init, Requested, Processed }
    
    struct Request {
        uint amountIn;
        uint amountJaxre;
        uint amountOut;
        uint request_timestamp;
        uint process_timestamp;
        address account;
        RequestStatus status;
    }

    uint public requestCount;

    bool public use_jaxre_route;
    
    mapping(uint => Request) public swap_requests;

    event Create_RupeeCash_Busd_Swap_Request(uint indexed requestId, Request request);
    event Set_Max_Jaxre_RupeeCash_Ratio(uint ratio);
    event Complete_Request(uint requestId);
    event Loan_To_Agent(address agent, uint amount);
    event Repay_Broker_Debt(address broker, uint amount);
    event Swap_Jaxre_RupeeCash(uint amountIn, address to);
    event Swap_RupeeCash_Jaxre(uint amountIn, address to);
    event Set_Use_Jaxre_Route(bool flag);

    modifier onlyGatekeeper() {
        require(msg.sender == admin.gate_keeper(), "Only Gatekeeper");
        _;
    }

    modifier onlyExchanger() {
        require(msg.sender == admin.exchanger(), "Only Exchanger");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == admin.oracle(), "Only Oracle");
        _;
    }

    function init() public initializer
    {
        _setup("RupeeCash", "RC", 18);
        max_jaxre_rupeeCash_ratio = 1e8;
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        JAXRE = IERC20(0x86ECE7D9cdA927B3Ec4044Df67B082FA55A1c198);
    }
    
    function set_admin(RupeeCashAdmin _admin) external onlyOwner {
        admin = _admin;
    }

    /**
     * @dev minter or admin.gate_keeper() mints gamerupee to merchant
     *      minter is assigned to one merchant and has minting_limits
     */
    function _mint(address account, uint256 amount) internal override {
        require((msg.sender == admin.gate_keeper() && account == admin.gate_keeper()), "Only admin.gate_keeper()");
        super._mint(account, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender == admin.gate_keeper() && admin.isWhitelisted(recipient), "Invalid transfer");
        super._transfer(sender, recipient, amount);
    }

    function loan_to_agent(address agent_address, uint amount) external {
        admin.loan_to_agent(msg.sender, agent_address, amount);
        super._transfer(msg.sender, agent_address, amount);
        emit Loan_To_Agent(agent_address, amount);
    }

    function repay_broker_debt(uint amount) external {
        address broker_address = admin.repay_broker_debt(msg.sender, amount);
        super._transfer(msg.sender, broker_address, amount);
        emit Repay_Broker_Debt(broker_address, amount);
    }

    function withdrawByAdmin(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function swap_jaxre_rupeeCash(uint amountIn) external onlyGatekeeper {
        JAXRE.transferFrom(msg.sender, address(this), amountIn);
        uint amountOut = amountIn * get_jaxre_rupeeCash_ratio() / 1e8;
        super._mint(msg.sender, amountOut);
        emit Swap_Jaxre_RupeeCash(amountIn, msg.sender);
    }

    function _swap_rupeeCash_jaxre(uint amountIn, address to) internal returns (uint amountOut){
        amountOut = amountIn * 1e8 / get_jaxre_rupeeCash_ratio();
        if(use_jaxre_route) {
            super._burn(msg.sender, amountIn);
            require(amountOut <= JAXRE.balanceOf(address(this)), "Insufficient JAXRE pool");
            JAXRE.transfer(to, amountOut);
        } else {
            super._transfer(msg.sender, to, amountIn);
        }
        emit Swap_RupeeCash_Jaxre(amountIn, to);
    }

    function create_rupeeCash_busd_swap_request(uint amountIn, address destination_address) external returns (uint requestId){
        require(msg.sender == address(admin) || admin.isWhitelisted(msg.sender), "Not whitelisted");
        uint jaxreAmount = _swap_rupeeCash_jaxre(amountIn, admin.exchanger());
        Request storage request = swap_requests[requestCount];
        request.amountIn = amountIn;
        request.amountJaxre = jaxreAmount;
        request.account = destination_address;
        request.request_timestamp = block.timestamp;
        request.status = RequestStatus.Requested;
        requestId = requestCount ++;
        emit Create_RupeeCash_Busd_Swap_Request(requestId, request);
    }

    function process_request(uint requestId, uint amountIn, uint amountOut) external onlyExchanger {
        Request storage request = swap_requests[requestId];
        require(request.status == RequestStatus.Requested, "Invalid status");
        require(request.amountIn == amountIn, "Invalid amountIn");
        require(amountIn * 1e4 / amountOut <= max_exchange_ratio, "Over max exchange ratio");
        uint community_fee = admin.community_fee() * amountOut / 1e4;
        if(community_fee > 0)
            BUSD.transferFrom(msg.sender, admin.community_fee_wallet(), community_fee);
        BUSD.transferFrom(msg.sender, request.account, amountOut - community_fee);
        request.amountOut = amountOut;
        request.process_timestamp = block.timestamp;
        request.status = RequestStatus.Processed;
        emit Complete_Request(requestId);
    }


    function set_max_jaxre_rupeeCash_ratio(uint _ratio) public onlyOracle {
        max_jaxre_rupeeCash_ratio = _ratio;
        emit Set_Max_Jaxre_RupeeCash_Ratio(_ratio);
    }

    function get_jaxre_rupeeCash_ratio() public view returns (uint) {
        if(JAXRE.balanceOf(address(this)) == 0 || totalSupply == 0) 
            return max_jaxre_rupeeCash_ratio;
        uint jaxre_rupeeCash_ratio = 1e8 * totalSupply / JAXRE.balanceOf(address(this));
        if(jaxre_rupeeCash_ratio > max_jaxre_rupeeCash_ratio)
            jaxre_rupeeCash_ratio = max_jaxre_rupeeCash_ratio;
        return jaxre_rupeeCash_ratio;
    }

    function set_max_exchange_ratio(uint exchange_ratio) external onlyOracle {
        max_exchange_ratio = exchange_ratio;
    }

    function get_swap_requests(address account) external view returns(Request[] memory){
        uint i;
        uint j;
        uint count;
        for(i = 0; i < requestCount; i++)
            if(swap_requests[i].account == account)
                count ++;
        Request[] memory my_requests = new Request[](count);
        for(i = 0; i < requestCount; i++)
            if(swap_requests[i].account == account)
                my_requests[j++] = swap_requests[i];
        return my_requests;
    }

    function set_use_jaxre_route(bool flag) external onlyOwner {
        use_jaxre_route = flag;
        emit Set_Use_Jaxre_Route(flag);
    }

}
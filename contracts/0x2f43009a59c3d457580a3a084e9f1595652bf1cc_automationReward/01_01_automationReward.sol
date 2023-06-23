contract automationReward{
    constructor(){
        name = "gegul_farm";
        symbol = "FARM";
        _transferOwnership(msg.sender);
    }

    receive() external payable{}
    fallback() external payable{}
    bytes32[40] private gap;
    struct payloadType{
        bytes checkPayload;
        bytes execPayload;
    }   
    mapping(address => payloadType) private payloads;

    address public owner;
    string public name;
    string public symbol;

    modifier onlyOwner(){
        require(owner == msg.sender, "access denied. owner ONLY.");
        _;
    }

    function anyCall(address _target, bytes memory payload) external payable onlyOwner{
        (bool success, bytes memory data) = _target.call{value: msg.value}(payload);
        require(success, "failed to call");
    }

    function addFarm(address _target, bytes memory _checkPayload, bytes memory _execPayload) external onlyOwner{
        payloads[_target] = payloadType(_checkPayload, _execPayload);
    }

    function transferOwnership(address to) external onlyOwner{
        _transferOwnership(to);
    }

    function getReward(address farm) external{
        payloadType memory payload = payloads[farm];
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "it's not initalized.");
        (bool success, bytes memory data) = farm.call(payload.execPayload);
        require(success, "failed to call function");
    }

    function checkReward(address farm) external view returns(bool _canExec, bytes memory _execPayload){
        payloadType memory payload = payloads[farm];
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "it's not initalized.");

        (bool success, bytes memory data) = farm.staticcall(payload.checkPayload);
        require(success, "failed to call function");
        _canExec = abi.decode(data, (bool));
        _execPayload = abi.encode(address(farm));
    }

    function _transferOwnership(address to) internal{
        owner = to;
    }

}
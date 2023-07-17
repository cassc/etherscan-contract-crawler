contract automationReward{
    constructor(){}

    receive() external payable{}
    fallback() external payable{}
    bytes32[40] private gap;
    struct payloadType{
        bytes checkPayload;
        bytes execPayload;
        bool enabled;
    }   
    mapping(address => payloadType) private payloads;

    address public owner;
    string public name;
    string public symbol;

    modifier onlyOwner(){
        require(owner == msg.sender, "access denied. owner ONLY.");
        _;
    }

    function initialize(string memory _name, string memory _symbol) external{
        if(owner == address(0)) _transferOwnership(msg.sender);
        require(owner == msg.sender, "owner ONLY.");
        name = _name;
        symbol = _symbol;
    }

    function anyCall(address _target, bytes memory _payload, uint256 _value) external payable onlyOwner{
        (bool success, bytes memory data) = _target.call{value: _value}(_payload);
        require(success, "failed to call");
    }

    function addFarm(address _target, bytes memory _checkPayload, bytes memory _execPayload) external onlyOwner{
        payloads[_target] = payloadType(_checkPayload, _execPayload, true);
    }

    function disableFarm(address _target) external onlyOwner{
        payloadType memory payload = payloads[_target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");
        payload.enabled = false;
        payloads[_target] = payload;
    }

    function transferOwnership(address to) external onlyOwner{
        _transferOwnership(to);
    }

    function performUpkeep(bytes calldata _performData) external{
        (address target) = abi.decode(_performData, (address));
        payloadType memory payload = payloads[target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");

        (bool success, bytes memory data) = target.call(payload.execPayload);
        require(success, "failed to call function");
    }

    function checkUpkeep(bytes calldata _checkData) external view returns(bool upkeepNeeded, bytes memory performData){
        (address target) = abi.decode(_checkData, (address));
        payloadType memory payload = payloads[target];
        require(payload.enabled == true, "disabled.");
        require(payload.checkPayload.length > 0 && payload.execPayload.length > 0, "target does not exist.");

        (bool success, bytes memory data) = target.staticcall(payload.checkPayload);
        require(success, "failed to call function");
        (upkeepNeeded) = abi.decode(data, (bool));
        performData = abi.encode(address(target));
    }

    function _transferOwnership(address to) internal{
        owner = to;
    }

}
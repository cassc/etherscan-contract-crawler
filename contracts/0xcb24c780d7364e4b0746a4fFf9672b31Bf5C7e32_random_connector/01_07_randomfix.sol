pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface Irecipient {

    function process(uint256 _random, bytes32 _requestId) external ;

}

interface Irandom_v3 {
    function requestRandomNumberWithCallback( ) external returns (uint256) ;
    function setAuth(address user, bool auth) external;
}

contract random_connector is AccessControl {



    bytes32 public constant CHAINLINK = keccak256("CHAINLINK");
    bytes32 public constant REQUESTOR = keccak256("REQUESTOR");

    bytes32        constant connectionSwap = 0x1a5309426a58e684803b56c89d36462b24e8242016b7219f5c90ec277c86e9b3;
    uint256                 public connectionRequest;
    address               constant connectionAddress = 0x2a3Bc72ed71DB2a27Cfe2Ba50aEcC692Fb04FcfF;

 

    Irandom_v3  immutable r3;

    event RandomReqested(address sender,uint256 requestId);
    event RandomDelivered(address requestor,uint256 random,bytes32 value);

    constructor() {
        r3 =  Irandom_v3 (0x78bC3996b384C3e8d35Adc0d16F0c5F4DF5de00E);
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REQUESTOR,msg.sender);
        _setupRole(CHAINLINK,address(r3));
        
    }

    function insertRequest() onlyRole(REQUESTOR) external {
        connectionRequest = r3.requestRandomNumberWithCallback( );
    }

 

    function process(uint256 _random, uint256 _requestId) external onlyRole(CHAINLINK) {
       
        if (_requestId == connectionRequest) {
            Irecipient(connectionAddress).process(_random,connectionSwap);
            emit RandomDelivered(connectionAddress,_random,connectionSwap);
        }
        
    }

}
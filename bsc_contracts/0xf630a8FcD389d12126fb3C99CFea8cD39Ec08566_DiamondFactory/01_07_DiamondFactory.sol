//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;
import "./Diamond.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IDiamondCut.sol";


interface iApp {
    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName) external payable;
    function updateFacets(IDiamondCut.FacetCut[] memory iFC) external;
}

interface prBeacon {
    struct sExchangeInfo {
        address chefContract;
        address routerContract;
        address rewardToken;
        address intermediateToken;
        address baseToken;
        string pendingCall;
        string contractType_solo;
        string contractType_pooled;
        bool psV2;
    }
    function getExchangeInfo(string memory _name) external view returns (sExchangeInfo memory);
    function getExchange(string memory _exchange) external returns(address);
    function getAddress(string memory _user) external returns(address);
}

contract DiamondFactory {
    address public beaconContract;
    mapping (address=>bool) adminUsers;
    mapping (address=>bool) godUsers;

    mapping (address => address[]) public proxyContracts;
    address[] public proxyContractsUsers;

    event NewProxy(address proxy, address user);
    bytes32 public constant DEPLOYER = keccak256("DEPLOYER");
    
    bool public paused;


    modifier adminUser {
        require(adminUsers[msg.sender] == true,"Locked function");
        _;
    }

    modifier godUser {
        require(godUsers[msg.sender] == true, "Locked function");
        _;
    }

    ///@notice Initialize the proxy factory contract
    ///@param _beacon the address of the beacon contract
    constructor (address _beacon, address _godUser, address _adminUser) {
        require(_beacon != address(0), "Beacon Contract required");
        beaconContract = _beacon;
        adminUsers[_adminUser] = true;
        adminUsers[_godUser] = true;

        godUsers[_godUser] = true;
    }

    ///@notice Sets the address of the beacon contract
    ///@param _sourceAddr the address of the source diamond contract
    function setSourceAddress(address _sourceAddr) public godUser {
        beaconContract = _sourceAddr;
    }

    ///@notice Sets the address of the beacon contract
    ///@dev call when beacon contract gets updated
    ///@param _beaconContract the address of the beacon contract
    function setBeacon(address _beaconContract) public godUser {
        beaconContract = _beaconContract;
    }



    ///@notice Allows admin to add an existing proxy contract to the list of proxy contracts for a user
    ///@param _proxyContract the address of the proxy contract
    ///@param _user the address of the user
    function addProxy(address _proxyContract, address _user) public adminUser {
        require(_proxyContract != address(0), "Proxy Contract required");
        require(_user != address(0), "User required");
        if (proxyContracts[msg.sender].length == 0) proxyContractsUsers.push(msg.sender);
        proxyContracts[_user].push(_proxyContract);
    }

    ///@notice Allows admin to add multiple  proxy contracts to the list of proxy contracts for a user
    ///@param _proxyContract the array of address for proxy contracts
    ///@param _user the address of the user
    function addProxyArray(address[] calldata _proxyContract, address _user) public adminUser {
        require(_proxyContract.length >0, "Proxy Contract required");
        require(_user != address(0), "User required");
        if (proxyContracts[msg.sender].length == 0) proxyContractsUsers.push(msg.sender);
        for (uint i = 0; i < _proxyContract.length; i++) {
            proxyContracts[_user].push(_proxyContract[i]);
        }
    }

    ///@notice Returns the last proxy contract created (or added) for a specific user
    ///@param _user the address of the user
    ///@return the address of the proxy contract
    function getLastProxy(address _user) public view returns (address) {
        require(_user != address(0), "User required");
        return proxyContracts[_user][proxyContracts[_user].length - 1];
    }

    ///@notice Gets bytecode of proxyContract
    ///@return the bytecode of the proxy contract
    function getBytecode() private pure returns (bytes memory) {
        bytes memory result = abi.encodePacked(type(Diamond).creationCode);
        return result;
    }

    
    ///@notice Creates a new proxy contract for a specific exchange and pool. 
    ///@dev Proxy contract is owned by calling user
    ///@dev for Solo contracts, only one proxy contract is needed unless custom logic contract is needed
    ///@param _pid the pool id
    ///@param _exchange the name of the exchange
    ///@return the address of the proxy contract
    function initialize(uint64  _pid, string memory _exchange, uint poolType, uint _salt) public payable adminUser returns (address) {   
        require(paused == false, "Proxy Factory is paused");     
        require(beaconContract != address(0), "Beacon Contract required");
        require(bytes(_exchange).length > 0,"Exchange Name cannot be empty");
        require(_salt > 0, "Salt must be provided");


        prBeacon.sExchangeInfo memory exchangeInfo = prBeacon(beaconContract).getExchangeInfo(_exchange);
        require(exchangeInfo.chefContract != address(0), "Chef Contract required");

        address sourceAddr = prBeacon(beaconContract).getExchange(exchangeInfo.contractType_pooled);

        address proxy = _clone(sourceAddr,_salt);

        if (proxyContracts[msg.sender].length == 0) proxyContractsUsers.push(msg.sender);
        proxyContracts[msg.sender].push(address(proxy));

        IDiamondLoupe.Facet[] memory fc = IDiamondLoupe(address(sourceAddr)).facets();
        require(fc.length > 0, "No facets found");


        IDiamondCut.FacetCut[] memory iFC = new IDiamondCut.FacetCut[](fc.length);

        for (uint i=0; i < fc.length; i++) {
            iFC[i].facetAddress = fc[i].facetAddress;
            iFC[i].action = IDiamondCut.FacetCutAction.Add;
            iFC[i].functionSelectors = fc[i].functionSelectors;
        }

        Diamond.DiamondArgs memory _args;
        _args.owner = address(this);
        Diamond(payable(proxy)).initialize(iFC, _args);
        
        emit NewProxy(address(proxy), msg.sender);

        iApp(address(proxy)).initialize{value:msg.value}(_pid, beaconContract, _exchange);    
        
        return address(proxy);
    }


    function updateFacets(IDiamondCut.FacetCut[] memory iFC) external godUser {    
        address sourceAddr = prBeacon(beaconContract).getExchange("MULTIEXCHANGEPOOLED");

        for (uint i = 0;i<proxyContractsUsers.length;i++) {
            if (proxyContracts[proxyContractsUsers[i]].length > 0) {
                iApp(sourceAddr).updateFacets(iFC);
                for (uint t = 0; t < proxyContracts[proxyContractsUsers[i]].length;t++) {
                    address _c =  proxyContracts[proxyContractsUsers[i]][t];
                    iApp(_c).updateFacets(iFC);
                }
            }

        }
    }

    ///@notice generates an address of a new proxy contract
    ///@dev used in front end
    ///@param _salt the salt value for the address
    ///@return the address of the proxy contract
    function getAddress(uint _salt) public view returns (address)
    {
        require(_salt > 0, "Salt must be provided");
        bytes32 newsalt = keccak256(abi.encodePacked(_salt,msg.sender));

        bytes memory bytecode = getBytecode();
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), newsalt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }    

    ///@notice adds new user to administrator role
    ///@param _user the address of the user

    function addAdmin(address _user) public godUser {
        adminUsers[_user] = true;
    }

    ///@notice removes user from administrator role
    ///@param _user the address of the user
    function removeAdmin(address _user) public godUser {
        adminUsers[_user] = false;
    }

    function updateGodUser(address _user, bool _state) public godUser {
        require(_user != msg.sender, "Can't modify self");
        godUsers[_user] = _state;
    }

    ///@notice Clones a proxy contract
    ///@param a the address of the source contract
    ///@param salt salt value for the address
    ///@return addr the address of the proxy contract

    function _clone(address a, uint256 salt) internal returns (address) {
        address retval;
        assembly {
        mstore(0x0, or(0x5880730000000000000000000000000000000000000000803b80938091923cF3, mul(a, 0x1000000000000000000)))
        retval := create2(0, 0, 0x20, salt)
        if iszero(extcodesize(retval)) {
            revert(0, 0)
        }
        }
        return retval;
    }

    ///@notice returns list of contracts for a specific user
    ///@param _addr the address of the user
    ///@return the list of contracts
    function returnContracts(address _addr) public view returns (address[] memory){
        return proxyContracts[_addr];
    }

    ///@notice Allow admin to pause deposits
    ///@dev Just flips the status, no direct allowance of setting
    function pause() public godUser {
        paused = !paused;
    }


}
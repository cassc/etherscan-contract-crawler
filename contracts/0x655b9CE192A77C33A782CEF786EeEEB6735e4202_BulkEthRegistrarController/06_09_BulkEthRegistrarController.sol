// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IETHRegistrarController.sol";
import "./BulkQuery.sol";
import "./BulkResult.sol";

contract BulkEthRegistrarController is Ownable {
    using SafeMath for uint;

    event NameRegistered(string name, address indexed owner, uint256 cost, uint fee,  uint256 duration);
    event NameRenewed(string name, address indexed owner, uint256 cost, uint fee, uint256 duration);

    uint private _feeRatio = 10; 
      
    function getFeeRatio() public view returns(uint) {
        return _feeRatio;
    } 
    
    function setFeeRatio(uint feeRatio) external onlyOwner  {
        _feeRatio = feeRatio;
    } 

    function withdraw(address payee) external onlyOwner payable {
        payable(payee).transfer(address(this).balance);
    }
 
    function withdrawOf(address payee, address token) external onlyOwner payable {
        IERC20(token).transfer(payable(payee), IERC20(token).balanceOf(address(this)));
    } 

    function balance() external view returns(uint256) {
        return address(this).balance;
    }
 
    function balanceOf(address token) external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function available(address controller, string memory name) public view returns(bool) {
        return IETHRegistrarController(controller).available(name);
    }

    function rentPrice(address controller, string memory name, uint duration) public view returns(uint) {
        return IETHRegistrarController(controller).rentPrice(name, duration);
    }
    
    function makeCommitment(address controller, string memory name, address owner, bytes32 secret) public pure returns(bytes32) {
        return makeCommitmentWithConfig(controller, name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(address controller, string memory name, address owner, bytes32 secret, address resolver, address addr) public pure returns(bytes32) {
        return IETHRegistrarController(controller).makeCommitmentWithConfig(name, owner, secret, resolver, addr);
    }

    function commit(address controller, bytes32 commitment) public {
        IETHRegistrarController(controller).commit(commitment);
    }
  
    function register(address controller, string calldata name, address owner, uint duration, bytes32 secret) external payable {
        registerWithConfig(controller, name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(address controller, string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable {
        uint cost = rentPrice(controller, name, duration);
        uint fee = cost.div(100).mul(_feeRatio);
        uint costWithFee = cost.add(fee); 
        
        require(msg.value >= costWithFee, "BulkEthRegistrarController: Not enough ether sent.");
        require(available(controller, name), "BulkEthRegistrarController: Name has already been registered");

        IETHRegistrarController(controller).registerWithConfig{ value: cost }(name, owner, duration, secret, resolver, addr);

        emit NameRegistered(name, owner, cost, fee, duration);
    } 

    function renew(address controller, string calldata name, uint duration) external payable {
        uint cost = rentPrice(controller, name, duration);
        uint fee = cost.div(100).mul(_feeRatio);
        uint costWithFee = cost.add(fee); 

        require( msg.value >= costWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");

        IETHRegistrarController(controller).renew{ value: cost }(name, duration);

        emit NameRenewed(name, msg.sender, cost, fee, duration);
    }

    function getBytes(string calldata secret) public pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(secret)));
    }

    function bulkAvailable(address controller, string[] memory names) public view returns (bool[] memory) {
        bool[] memory _availables = new bool[](names.length);
        for (uint i = 0; i < names.length; i++) {
            _availables[i] = available(controller, names[i]);
        }
        return _availables;
    }

    function bulkRentPrice(address controller, BulkQuery[] memory query) public view returns(BulkResult[] memory result, uint totalPrice, uint totalPriceWithFee) {
        result = new BulkResult[](query.length);
        for (uint i = 0; i < query.length; i++) {
            BulkQuery memory q = query[i];
            bool _available = available(controller, q.name);
            uint _price = rentPrice(controller, q.name, q.duration);
            uint _fee = _price.div(100).mul(_feeRatio);
            totalPrice += _price;
            totalPriceWithFee += _price.div(100).mul(_feeRatio).add(_price);
            result[i] = BulkResult(q.name, _available, q.duration, _price, _fee);
        }
    } 
 
    function bulkCommit(address controller, BulkQuery[] calldata query, string calldata secret) public { 
        bytes32 _secret = getBytes(secret);
        for(uint i = 0; i < query.length; i++) { 
            BulkQuery memory q = query[i]; 
            bytes32 commitment = makeCommitmentWithConfig(controller, q.name, q.owner, _secret, q.resolver, q.addr);
            commit(controller, commitment);
        } 
    } 

    function bulkRegister(address controller, BulkQuery[] calldata query, string calldata secret) public payable {
        uint256 totalCost;
        uint256 totalCostWithFee;
        BulkResult[] memory result;
        (result, totalCost, totalCostWithFee) = bulkRentPrice(controller, query);

        require(msg.value >= totalCostWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");
 
        bytes32 _secret = getBytes(secret);
        
        for( uint i = 0; i < query.length; ++i ) {
            BulkQuery memory q = query[i];
            BulkResult memory r = result[i];
    
            IETHRegistrarController(controller).registerWithConfig{ value: r.price }(q.name, q.owner, q.duration, _secret, q.resolver, q.addr);

            emit NameRegistered(q.name, q.owner, r.price, r.fee, q.duration);
        }
    } 

    function bulkRenew(address controller, BulkQuery[] calldata query) external payable {
        uint256 totalCost;
        uint256 totalCostWithFee;
        BulkResult[] memory result;
        (result, totalCost, totalCostWithFee) = bulkRentPrice(controller, query); 
 
        require( msg.value >= totalCostWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");

        for( uint i = 0; i < query.length; ++i ) {
            BulkQuery memory q = query[i];
            BulkResult memory r = result[i];
             
            IETHRegistrarController(controller).renew{ value: r.price }(q.name, q.duration);

            emit NameRenewed(q.name, msg.sender, r.price, r.fee, q.duration);
        }  
    }
}
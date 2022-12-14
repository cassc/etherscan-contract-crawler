// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./IRequest.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Request is Initializable, OwnableUpgradeable, IRequest {

    mapping(uint256 => bool) private requestStorage;

    address[] callers;
	
    modifier validCaller() {
	
		bool found;
		for(uint256 i=0; i < callers.length; i++) {
			if (msg.sender == callers[i]) {
				found = true;
				break;
			}
		}
        require(found, "invalid caller");
        _;
    }
	
	function setCaller(address caller) public onlyOwner {
        callers.push(caller);
    }
	
	function setCallers(address[] memory _callers) public onlyOwner {
        callers = _callers;
    }

    function initialize() public initializer {
        __Ownable_init();
    }
	
    function add(uint256 id, bytes memory request, bytes memory response) external validCaller {
		require(id > 0,"invalid request");
	    require(!requestStorage[id],"request duplicated");
	    requestStorage[id] = true;
		
		emit RequestEvent(id, tx.origin, request, response);
    }
	
	function get(uint256 id) external view returns (bool) {
		return requestStorage[id];
	}
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}
// 21e3c3d589dbb1fac0313bdcf91e3cbc4f227795
pragma solidity ^0.8.0;

import "ACLBase.sol";

contract EulerACL is ACLBase{
	string public constant override NAME = "EulerACL";
	uint public constant override VERSION = 1;

	struct EulerBatchItem {
        bool allowError;
        address proxyAddr;
        bytes data;
    }

    bytes4 internal constant depositSelector = 0xe2bbb158;
    bytes4 internal constant withdrawSelector = 0x441a3e70;
    bytes4 internal constant enterMarketSelector = 0x73f0b437;
    bytes4 internal constant exitMarketSelector = 0xc8a5fba3;
    mapping(bytes4 => bool) internal allowedSelector;

    function checkSelector(bytes4 _selector) public view returns(bool){
    	if (_selector == depositSelector || _selector == withdrawSelector || _selector == enterMarketSelector || _selector == exitMarketSelector){
    		return true;
    	}else{
    		return allowedSelector[_selector];
    	}
    }

    function setAllowedSelector(bytes4 _selector, bool _status) external onlySafe {
    	if(_selector == depositSelector || _selector == withdrawSelector || _selector == enterMarketSelector || _selector == exitMarketSelector){
    		return;
    	}
    	allowedSelector[_selector] = _status;
    }


	function batchDispatch(EulerBatchItem[] calldata _items, address[] calldata) external onlySelf{
        for(uint256 i=0; i < _items.length; i++){
            bytes4 _selector = bytes4(_items[i].data[:4]);
            require(checkSelector(_selector), "Operation not allowed");
        }
		
	}
}
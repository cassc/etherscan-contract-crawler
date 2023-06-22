pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *
 * @dev 결제용 ERC20 Token List 
 *
 */

contract ERC20TokenList is Ownable {
    using Address for address;

    address[] private _addresses;
    mapping (address => uint256) private _indexes;   // 1-based  1,2,3.....
    
    event AddToken(address indexed addr);
    event RemoveToken(address indexed addr);

    /**
     * @dev contains : 기존 등록 여부 조회
    */
    function contains(address addr) public view returns (bool) {
        return _indexes[addr] != 0;
    }

    /**
     * @dev addToken : ERC20 Token 추가 
     * 
     * Requirements:
     *
     *   address Not 0 address 
     *   중복여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */
    
    function addToken(address addr) public onlyOwner {

        //console.log("address = %s",addr);
        //console.log("contains = %s",contains(addr));

        require(addr != address(0),"TokenList/address_is_0");
        require(!contains(addr),"TokenList/address_already_exist");
        require(addr.isContract(),"TokenList/address_is_not_contract");

        _addresses.push(addr);
        _indexes[addr] = _addresses.length;

        emit AddToken(addr);
    }
    

    /**
     * @dev removeToken : ERC20 Token 삭제 
     * 
     * Requirements:
     *
     *   기존 존재여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */

    function removeToken(address addr) public  onlyOwner {
        require(contains(addr),"TokenList/address_is_not_exist");
        uint256 idx = _indexes[addr];
        uint256 toDeleteIndex = idx - 1;
        uint256 lastIndex = _addresses.length - 1;
        
        address lastAddress = _addresses[lastIndex];
        
        _addresses[toDeleteIndex] = lastAddress;
        _indexes[lastAddress] = toDeleteIndex + 1;
        
        _addresses.pop();
        delete _indexes[addr];

        emit RemoveToken(addr);
    }
    
    /**
     * @dev getAddressList : ERC20 Token List return 
     * 
	 */    
    function getAddressList() public view returns (address[] memory) {
        return _addresses;
    }
    
}
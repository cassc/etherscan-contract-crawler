// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vote is Ownable {
    struct Person {
        string name;
        address addr;
        uint256 secore;
    }
    uint256 public index = 0;
    mapping(address => Person) public campaigners;
    mapping(address => address) public personVoteRecord;
    address[] public list;

    function find(address[] memory arr, address target)
        public
        pure
        returns (bool)
    {
        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            address _a = arr[i];
            if (address(_a) == address(target)) {
                return true;
            }
        }
        return false;
    }

    function addCampaigner(string memory _name, address _addr)
        public
        onlyOwner
        returns (bool)
    {
        bool flag = find(list, _addr);
        require(flag == false, "You had added already!!");
        Person memory p = Person(_name, _addr, 0);
        index++;
        list.push(_addr);
        campaigners[_addr] = p;
        return true;
    }

    function vote(address _addr) public {
        require(
            personVoteRecord[msg.sender] == address(0),
            "You had voted already!!"
        );
        personVoteRecord[msg.sender] = _addr;
        uint256 len = list.length;
        for (uint256 i = 0; i < len; i++) {
            address _campaigner = list[i];
            Person storage item = campaigners[_campaigner];
            address itemAddr = item.addr;
            if (itemAddr == _addr) {
                item.secore++;
                break;
            }
        }
    }
}
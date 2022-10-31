// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

import "./Include.sol";
import {StringUtils} from "./bnsregistrar/StringUtils.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Auction is Configurable {
    //using Address for address;
    using StringUtils for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct UserPrice{
        address user;
        uint price;
        bool locked;
    }
    mapping (uint => bytes32) public roots; //round =>roots
    mapping (string => mapping (address => uint)) public bidSelfPrice; //name =>user=>price
    mapping (string => UserPrice) public nameHighPrice; //name =>user=>price
    mapping (address => uint )  public userBidNum; //user => bidNum

    uint public begin;
    uint public end;



	
    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }


    function __Auction_init(address governor_) public initializer {
        __Governable_init_unchained(governor_);
    }

    function setMerkleRoot(uint round,bytes32 _root) external governance {
	    roots[round] = _root;
    }

    function setTime(uint _begin,uint _end) external governance {
	    begin = _begin;
        end = _end;
    }

	
    function getBasePrice(string memory name) public view returns (uint,bool){
        uint prePrice = nameHighPrice[name].price;
        uint retPrice;
        bool isFirst = false;
        uint len = name.strlen();
        require(len>2,"name len must >2");
        if (prePrice ==0){
            isFirst = true;
            if (len ==3)
                retPrice = 1 ether;
            else if (len ==4)
                retPrice = 0.2 ether;
            else 
                retPrice =0.01 ether;
        }
        else {
            if (len<5)
                retPrice = ((prePrice*(1.05 ether)/(1 ether))/1e15+5)/10*1e16;//((prePrice*(1.05 ether)/(1 ether))/1e15+5)/10*1e16;
            else 
                retPrice =prePrice +1e16;
        }
        return (retPrice,isFirst);
    }

    function getLockBasePrice(string memory name) public view returns (uint,bool){
        uint prePrice = nameHighPrice[name].price;
        uint retPrice;
        uint len = name.strlen();
        require(len>2,"name len must >2");
        require(prePrice==0,"can not lock");
        if (len ==3)
            retPrice = 0.65 ether;
        else if (len ==4)
            retPrice = 0.15 ether;
        else 
            retPrice =0.01 ether;
        return (retPrice,true);//isFirst
    }


    function available(string memory name) public view returns(bool) {
        return valid(name) && (!isLock(name));
    }

    function isLock(string memory name) public view returns (bool) {
        return nameHighPrice[name].locked;
    }

          
    function valid(string memory name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (
                    bytes1(nb[i + 2]) == 0x8b ||
                    bytes1(nb[i + 2]) == 0x8c ||
                    bytes1(nb[i + 2]) == 0x8d
                ) {
                    return false;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf)
                    return false;
            }
        }
        return true;
    }



	function bid(string memory name,uint wlNum,bytes32[] calldata _merkleProof) payable public nonReentrant {
        require(block.timestamp>=begin,"not begin");
        require(block.timestamp<=end,"end");
        require(valid(name),"name unavailable");
        require(!isLock(name),"name locked");
        (uint basePrice,bool isFirst) = getBasePrice(name);
        require(msg.value>=basePrice,"price too low");
        if (bidSelfPrice[name][msg.sender]>0)
            require(userBidNum[msg.sender] <= wlNum,"reach max domain");
        else
            require(userBidNum[msg.sender]<wlNum,"reach max domain");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,wlNum));
        require(MerkleProofUpgradeable.verify(_merkleProof, roots[1], leaf),"Invalid Proof." );
        UserPrice memory userPrice = nameHighPrice[name];
        if (!isFirst){
            (bool success,) = payable(userPrice.user).call{value:userPrice.price}("");
            require(success,"send bnb faild");
            emit refund(name,userPrice.user,userPrice.price);
        }
        if (bidSelfPrice[name][msg.sender]==0){
            userBidNum[msg.sender] ++;
        }
        bidSelfPrice[name][msg.sender] = msg.value;     
        nameHighPrice[name] = UserPrice(msg.sender,msg.value,false);
        emit Bid(name,msg.sender,msg.value,wlNum,userBidNum[msg.sender],false);

	}

   	function lockBid(string memory name,uint wlNum,bytes32[] calldata _merkleProof) payable public nonReentrant {
        require(block.timestamp>=begin,"not begin");
        require(block.timestamp<=end,"end");
        require(valid(name),"name unavailable");
        require(!isLock(name),"name locked");
        (uint basePrice,bool isFirst) = getLockBasePrice(name);
        require(isFirst,"name can't lock");
        require(msg.value>=basePrice,"price too low");
        require(userBidNum[msg.sender]<wlNum,"reach max domain");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,wlNum));
        require(MerkleProofUpgradeable.verify(_merkleProof, roots[2], leaf),"Invalid Proof." );
        userBidNum[msg.sender] ++;
        bidSelfPrice[name][msg.sender] = msg.value;     
        nameHighPrice[name] = UserPrice(msg.sender,msg.value,true);
        emit Bid(name,msg.sender,msg.value,wlNum,userBidNum[msg.sender],true);
	}


    event refund(string name,address indexed user,uint price);
	event Bid(string name,address indexed user,uint price,uint wlNum,uint bidNum,bool locked);
	
    function withdraw() public governance {
        payable(msg.sender).transfer(address(this).balance);        
    }
}
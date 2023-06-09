// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;



import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract Buffer is ReentrancyGuard {

   
    address public owner = 0xB15DFb31A96b94ec150A237Bfc3d464Affe774f7;
    uint256 public immutable royaltyFeePercent = 1000;
    uint256 private immutable montageShare = 1000;
    address public immutable marketWallet = 0xB15DFb31A96b94ec150A237Bfc3d464Affe774f7; 
    address private validPayee;
    bytes32 private validDest;
    address private dest;
    
    error UnauthorizedPayee(address valid, address invalid);
    error UnauthorizedDest(address dest, uint256 share, bytes32 validdest);


    event WithdrawnCheck(address validPayee, address destAddy, uint256 share);
    event PayeeAdded(address payee, bytes32 vdest, address dest);
    event FeeReceived(address to, uint256 amount);
    event PayeeReset(address resetPayee, address resetDestAddy, bytes32 resetValidDest);

   
    modifier onlyGoodAddy() {

        require (msg.sender != address(0));
        _;

    }

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

   

    function _checkOwner() internal view {
        require(msg.sender == owner, "Only owner can call this function");
       
    }

    function hashHelper(uint256 _a, address _b, bytes32 _c) private pure returns(bool) {
        
        bool result;
       
        bytes32 destHash = keccak256(abi.encodePacked(_a,_b));
        if (destHash == _c)
        result = true;
        return result;
    }



    //============ Function to Receive ETH ============
    receive() external payable {
       
        uint256 montageFee = msg.value * montageShare / 10000;
       
        _transfer(marketWallet, montageFee);
       
        emit FeeReceived(address(this), msg.value);
    }

    //============ Function to Add Valid Payee ============
    function addValidPayee(address _newPayee, bytes32 _validDest, address _dest) external onlyOwner  {
         validPayee = _newPayee;

         validDest = _validDest;

         dest = _dest;
 
         emit PayeeAdded(validPayee, validDest, dest);
    }

      
       
    //============ Function to Withdraw ETH ============
    function withdraw(uint256 _shareAmount) external nonReentrant onlyGoodAddy {
        if (msg.sender != validPayee)
            revert UnauthorizedPayee(validPayee,msg.sender);


        if (hashHelper(_shareAmount,dest,validDest) != true)
            revert UnauthorizedDest(dest,_shareAmount,validDest);
        
      
        
        _transfer(dest, _shareAmount); 
        validPayee = address(0);
        dest = address(0);
        validDest = "";


        emit WithdrawnCheck(validPayee, dest, _shareAmount);
        emit PayeeReset(validPayee, dest, validDest);
    }

    


    
    
    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    //============ Function to Transfer ETH to Address ============
    function _transfer(address to, uint256 amount) internal  {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }

    
}
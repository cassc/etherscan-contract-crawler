// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../util/Strings.sol";
import "./Itoken.sol";
import "./IFailSafeOrchestrator.sol";

/**
 * @dev implements funds protection (FailSafeOrchestrator moves
 * funds under threat to this contract where the wallet owner
 * can withdraw the funds to another wallet at a later point.
 * 
 */
contract FailSafeWallet is Initializable, IERC721Receiver {
    using SafeERC20 for IERC20;
    address public owner;
    address public protectedAddr;
    bytes32 public opsRoot;
    uint public withdrawCounter;
    uint public lastWithdraw;

    // puting re-entrency code directly here, not to effect state on proxy
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

     modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function initialize(address _owner, address _protectedAddr) external initializer {
        require(_owner != address(0), "invalid owner addr");
        require(_protectedAddr != address(0), "invalid protected addr");

        owner = _owner;
        protectedAddr = _protectedAddr;
       _status = _NOT_ENTERED;
    }

    function payGasBill( uint gasBill) external nonReentrant {
         require(msg.sender == owner, "must be owner to request gasBill pay");
         IFailSafeOrchestrator fsf = IFailSafeOrchestrator(owner); 
         address gasToken = fsf.gasToken();

         require(gasToken != address(0), "invalid gasToken!");  

         IERC20 tok = IERC20(gasToken);
         uint256 bal = tok.balanceOf(address(this));

         require (bal >= gasBill, "insufficient balance to pay gas bill!"); 
         
         tok.safeTransferFrom(address(this), msg.sender, gasBill);       
    }

    function defend(address erc20Addr, uint gasCover) public {
      require(msg.sender == owner, "must be owner to intercept");
      require(erc20Addr != address(0), "invalid ec20 addr");  
      IERC20 underlying = IERC20(erc20Addr);

      uint256 allowance = underlying.allowance(protectedAddr, address(this));
      require (allowance > 0, "insufficient allowance");

      uint256 protectedAddrBal = underlying.balanceOf(protectedAddr);
      require (protectedAddrBal > 0, "no funds to protect"); 

      uint bal;
      if (allowance < protectedAddrBal) {
        bal = allowance;
      } else {
        bal = protectedAddrBal;
      }

      require (bal > gasCover,  "balanace insufficient to cover gas costs.");
      bal -= gasCover;

      // Only Orchistrator (owner allowed to call this method)
      //slither-disable-next-line arbitrary-send-erc20 before the issue
      underlying.safeTransferFrom(protectedAddr, address(this), bal);   
    }

    function defend721(address erc721Addr, uint tokenId) public {
      require(msg.sender == owner, "must be owner to intercept");
      require(erc721Addr != address(0), "invalid ec721 addr");  
      IERC721 underlying = IERC721(erc721Addr);
      
      require(address(this) == underlying.getApproved(tokenId) || 
        underlying.isApprovedForAll(protectedAddr, address(this)), "fs wallet no perms for token id!");
      require(protectedAddr == underlying.ownerOf(tokenId), "protected addr not owner of token id"); 
      underlying.safeTransferFrom(protectedAddr, address(this), tokenId);
    }

    function setRoot(bytes32 root) external {
        require(msg.sender == owner, "must be owner to set root");
        opsRoot = root;
    }

    //slither-disable-next-line arbitrary-send-erc20 before the issue
    function wrappedWithdraw (address erc20Addr,                   
                              uint amount,
                              uint expiryBlockNum,
                              uint count,
                              bytes memory fleetKeySignature,
                              bytes32[] memory fleetKeyProof // merkle proof caller authorized 
        ) external nonReentrant {

        IFailSafeOrchestrator fsf = IFailSafeOrchestrator(owner); 

        require(erc20Addr != address(0), "erc20 token not specified");
        require(amount > 0, "Invalid withdraw amount");
        //expiry blockNumber is integrity protected via fleetKeySignature
        require( expiryBlockNum  > block.number, "expired request");

        // enforce that expiration date is not too far into future
        require( expiryBlockNum  - block.number  <=  fsf.blockSkewDelta(), "block skew out of range");

        // integrity protected with sig
        require (count == withdrawCounter, "out of sequence withdraw request");


        address signer = fsf.recomputeAndRecoverSigner(erc20Addr,
       												   msg.sender, // emergency wallet
        											   amount,
        											   expiryBlockNum,  
       												   count,  
        											   fleetKeySignature);

        // signer needs to be aauthorized member of key fleet
        require(fsf.authzCheck(opsRoot, signer, fleetKeyProof), "not authorized to call wrappedWithdraw");
          
        IERC20 underlying = IERC20(erc20Addr);

        uint contractBalance = underlying.balanceOf(address(this));
        require(contractBalance >= amount, "the contract has insufficient funds");
        underlying.safeTransfer(msg.sender, amount);
        
        lastWithdraw = block.number;
        withdrawCounter ++;

    }
    
    function wrappedWithdraw721 (address erc721Addr,                   
                              uint tokenId,
                              uint expiryBlockNum,
                              uint count,
                              bytes memory fleetKeySignature,
                              bytes32[] memory fleetKeyProof // merkle proof caller authorized 
        ) external nonReentrant {

        IFailSafeOrchestrator fsf = IFailSafeOrchestrator(owner); 

        require(erc721Addr != address(0), "erc721 token not specified"); 
        //expiry blockNumber is integrity protected via fleetKeySignature
        require( expiryBlockNum  > block.number, "expired request");
        // enforce that expiration date is not too far into future
        require( expiryBlockNum  - block.number  <=  fsf.blockSkewDelta(), "block skew out of range");
        // integrity protected with sig
        require (count == withdrawCounter, "out of sequence withdraw request");

        address signer = fsf.recomputeAndRecoverSigner(erc721Addr,
                                 msg.sender, // emergency wallet
                                 tokenId,
                                 expiryBlockNum,  
                                 count,  
                                 fleetKeySignature);

        // signer needs to be aauthorized member of key fleet
        require(fsf.authzCheck(opsRoot, signer, fleetKeyProof), "not authorized to call wrappedWithdraw");
      
        IERC721 underlying = IERC721(erc721Addr);

        require(address(this) == underlying.ownerOf(tokenId), "addr not owner of token id");        
        underlying.safeTransferFrom(address(this), msg.sender, tokenId);
        
        lastWithdraw = block.number;
        withdrawCounter ++;
    }

    // implements IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
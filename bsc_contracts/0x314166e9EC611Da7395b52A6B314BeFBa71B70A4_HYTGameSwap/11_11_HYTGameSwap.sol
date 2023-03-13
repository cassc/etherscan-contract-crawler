// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol" ;
import "@openzeppelin/contracts/security/Pausable.sol" ;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol" ;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol" ;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol" ;
contract HYTGameSwap is AccessControl, Pausable, EIP712 {
    // record request id
    mapping(uint256 => bool) public orderNumExists ;

    // token erc20
    IERC20 public token ;

    // sign Addr
    address public signAddr ;

    /////////////////////////////////////////////////
    //                  events
    /////////////////////////////////////////////////
    event HYTClaimEvent(address account, uint256 orderNum, uint256 amount) ;

    constructor(address sign, address tokenAddr) EIP712("HYTGameSwap", "v1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = IERC20(tokenAddr) ;
        signAddr = sign ;
    }

    function setSignAccount(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signAddr = sign ;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause() ;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause() ;
    }

    // user claim batch
    function hytClaimBatch(uint256 [] memory orderNum, uint256 [] memory amount, bytes memory signature) external whenNotPaused {
        require(amount.length == orderNum.length && orderNum.length > 0, "Parameter error") ;
        checkClaimSign(orderNum, amount, signature) ;

        for(uint256 i = 0; i < orderNum.length; i++) {
            require(orderNumExists[ orderNum [i] ] == false, "repeat request") ;
            orderNumExists[ orderNum [i] ] = true ;
            bool isOk = token.transfer(_msgSender(), amount[i]) ;
            require(isOk, "HYT Token Transfer fail") ;
            emit HYTClaimEvent(_msgSender(), orderNum[i], amount[i]) ;
        }
    }

    // check claim signature
    function checkClaimSign(uint256 [] memory orderNum, uint256[] memory amount, bytes memory signature) private view {
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("hytClaimBatch(uint256[] orderNum,uint256[] amount,address owner)")),
            keccak256(abi.encodePacked(orderNum)),
            keccak256(abi.encodePacked(amount)),
            _msgSender()
        ) ;
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hashTypedDataV4(keccak256(encodeData)), signature);
        require(error == ECDSA.RecoverError.NoError && recovered == signAddr, "Incorrect request signature") ;
    }

    // batchTransfer only test
    function batchTransfer(address [] memory to, uint256 [] memory amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to.length == amount.length, "Parameter error") ;
        for(uint256 i = 0; i < to.length; i++) {
            bool isOk = token.transfer(to[i], amount[i]) ;
            require(isOk, "HYT Transfer Fail") ;
        }
    }

    // widthdraw
    function widthdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = token.balanceOf(address (this)) ;
        if(amount > 0) {
            token.transfer(_msgSender(), amount) ;
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./IPancakeRouter01.sol";

contract EzBet is Initializable, PausableUpgradeable, OwnableUpgradeable  {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}    
    mapping(uint256 => bool) usedNonces;
    mapping (address => bool) public whitelistedSigner;
    address public pancakeRouter;

    // 0 - topup, 1 - withdraw
    event Exchange (
        address userAddress,
        uint256 creditAmount,
        uint256 tokenAmount,
        address[] paymentPath,
        uint256 exchangeType, 
        uint256 nonce,
        bytes sig
    );
    mapping(uint256 => bool) applicationOperators;
    address public usdAddress;
    address public lpAddress;
    event NewOperator (
        address userAddress,
        uint256 creditAmount,
        uint256 usdAmount,
        uint256 lpAmount,
        uint256 nonce,
        bytes sig
    );
    function initialize(address _pancakeRouter) public initializer {
        __Pausable_init();
        __Ownable_init();

        pancakeRouter = _pancakeRouter;
    }    

    function isAlreadyExchanged(uint256 n) external view returns (bool){
        return usedNonces[n];
    }
    function isAlreadyTopUp(uint256 n) external view returns (bool){
        return usedNonces[n];
    }
    function isAlreadyOperator(uint256 n) external view returns (bool){
        return applicationOperators[n];
    }
   
 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function exchange(uint256 creditAmount, uint256 exchangeType, address[] calldata paymentPath, uint256 nonce, bytes memory sig ) external whenNotPaused {
        require(exchangeType==0 || exchangeType==1,"invalid exchange type");
        require(!usedNonces[nonce],"Used nonce");
        usedNonces[nonce] = true;

        validateData(creditAmount, exchangeType, paymentPath, nonce, sig);

        address userAddress = _msgSender();
        address contractAddress = address(this);
        uint256 tokenAmount;
        address paymentTokenAddress = paymentPath[paymentPath.length.sub(1)];

        if(paymentPath.length == 1){
            tokenAmount = creditAmount;
        } else {
            uint[] memory amounts = IPancakeRouter01(pancakeRouter).getAmountsOut(
                creditAmount, 
                paymentPath
            ); 
            tokenAmount = amounts[paymentPath.length.sub(1)];
        }
        // token to credit
        if (exchangeType == 0 ) {
            require(IERC20Upgradeable(paymentTokenAddress).allowance(userAddress , contractAddress)>=tokenAmount,"Token amount allowance is not enough to deposit");
    
            IERC20Upgradeable(paymentTokenAddress).safeTransferFrom(userAddress, contractAddress, tokenAmount);

        // credit to token
        } else if(exchangeType == 1) {
            uint256 contractBalance = IERC20Upgradeable(paymentTokenAddress).balanceOf(contractAddress);

            require(contractBalance>=tokenAmount,"Contract balance is not enough");

            IERC20Upgradeable(paymentTokenAddress).safeTransfer(userAddress, tokenAmount);
        }  

        emit Exchange (
            userAddress,
            creditAmount,
            tokenAmount,
            paymentPath,
            exchangeType, // 0 - topup , 1 - withdraw
            nonce,
            sig
        );        
    }

 
    function validateData(uint256 creditAmount, uint256 exchangeType, address[] calldata paymentPath, uint256 nonce, bytes memory sig ) private view {
        address _walletAddress = _msgSender();
        bytes32 signedMessage = keccak256(abi.encodePacked(_walletAddress, creditAmount, exchangeType, paymentPath[paymentPath.length-1], nonce));
        address signer = ECDSAUpgradeable.recover(signedMessage, sig);
        require(whitelistedSigner[signer]==true, "Not signed by the authority");
    }

    function setSigner(address _signer, bool _whitelisted) external onlyOwner {
        require(whitelistedSigner[_signer] != _whitelisted,"Invalid value for signer");
        whitelistedSigner[_signer] = _whitelisted;
    }

    function isSigner(address _signer) external view returns (bool) {
        return whitelistedSigner[_signer];
    }

    function applyAsOperator(uint256 creditAmount, uint256 usdAmount, uint256 lpAmount, uint256 nonce, bytes memory sig) external whenNotPaused {
      
        require(!applicationOperators[nonce],"Used nonce");
        applicationOperators[nonce] = true;
        validateApplication(creditAmount,usdAmount,lpAmount,nonce, sig);


        address contractAddress = address(this);
        address userAddress = _msgSender();
        // transfer the usd to the contract
        IERC20Upgradeable(usdAddress).safeTransferFrom(userAddress, contractAddress, usdAmount);

        // transfer the usd to LP
        IERC20Upgradeable(usdAddress).safeTransferFrom(userAddress, lpAddress, lpAmount);

        emit NewOperator (
            userAddress,
            creditAmount,
            usdAmount,
            lpAmount,
            nonce,
            sig
        );
    }

    function validateApplication(uint256 creditAmount, uint256 usdAmount, uint256 lpAmount, uint256 nonce, bytes memory sig ) private view {
        address _walletAddress = _msgSender();
        bytes32 signedMessage = keccak256(abi.encodePacked(_walletAddress, creditAmount, usdAmount , lpAmount, nonce));
        address signer = ECDSAUpgradeable.recover(signedMessage, sig);
        require(whitelistedSigner[signer]==true, "Not signed by the authority");
    }

    function setAddresses(address _usdAddress, address _lpAddress) external onlyOwner {
        usdAddress = _usdAddress;
        lpAddress = _lpAddress;
    }

}
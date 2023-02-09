// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimaCrowdsale is Context, Ownable, Pausable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	// The token being sold
	IERC20 private _token;
	
    // The token used to pay for the wMinima (USDT)
    IERC20 private _purchaseToken;

	// Address where funds are collected
	address private _wallet;

	// How many token units a buyer gets per wei.
	// The rate is the conversion between wei and the smallest and indivisible token unit.
	// So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
	// 1 wei will give you 1 unit, or 0.001 TOK.
	uint256[4] private _rates;
	uint256 private _currentRate;

	//size of each wMinima price tranche 
	uint256[4] private _tranches; 

	// Amount of usdt raised
	uint256 private _usdtRaised;

	// Amount of minima sold
	uint256 private _minimaSold;

	//hardcap of the crowdsale
	uint256 private _usdtCap;

    // The address who will create ECDSA signatures for users to participate in the crowdsale
    address private _signer;

    // A mapping of addresses and a boolean of if their signatures have been used, to track
    // who has already purchased from the crowdsale 
    mapping(address => bool) public purchased;

    /// @notice the EIP712 domain separator for purchasing wMinima
    bytes32 public immutable EIP712_DOMAIN;

    /// @notice EIP-712 typehash for purchasing wMINIMA
    bytes32 public constant SUPPORT_TYPEHASH = keccak256("Purchase(address purchaser,uint256 amount)");

	event TokensPurchased(
		address indexed beneficiary,
		uint256 value,
		uint256 amount
	);

	event FundsWithdrawn(address indexed withdrawer, uint256 amount);

	constructor(
		uint256[] memory rates,
		uint256[] memory tranches,
		uint256 usdtCap,
		address wallet,
		IERC20 token,
        IERC20 purchaseToken,
        address signer
	) public {
		require(rates[0] > 0, "Crowdsale: rate[0] is 0");
		require(rates[1] > 0, "Crowdsale: rate[1] is 0");
		require(rates[2] > 0, "Crowdsale: rate[2] is 0");
		require(rates[3] > 0, "Crowdsale: rate[3] is 0");
		require(wallet != address(0), "Crowdsale: wallet is the zero address");
		require(
			address(token) != address(0),
			"Crowdsale: token is the zero address"
		);
		require(
			address(purchaseToken) != address(0),
			"Crowdsale: purchaseToken is the zero address"
		);
		_currentRate = rates[0];
		_rates[0] = rates[0];
		_rates[1] = rates[1];
		_rates[2] = rates[2];
		_rates[3] = rates[3];
		_tranches[0] = tranches[0];
		_tranches[1] = tranches[1];
		_tranches[2] = tranches[2];
		_tranches[3] = tranches[3];						
		_usdtCap = usdtCap;
		_wallet = wallet;
		_token = token;
		_purchaseToken = purchaseToken;
        _signer = signer;

		EIP712_DOMAIN = keccak256(abi.encode(
			keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
			keccak256(bytes("MinimaCrowdSale")),
			keccak256(bytes("v1")),
			block.chainid,
			address(this)
		));
	}

	function token() public view returns (IERC20) {
		return _token;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function wallet() public view returns (address) {
		return _wallet;
	}

	function currentRate() public view returns (uint256) {
		return _currentRate;
	}

	function usdtRaised() public view returns (uint256) {
		return _usdtRaised;
	}

	function minimaSold() public view returns (uint256) {
		return _minimaSold;
	}

	function usdtCap() public view returns (uint256) {
		return _usdtCap;
	}	

	function purchaseToken() public view returns (IERC20) {
		return _purchaseToken;
	}

	function signer() public view returns (address) {
		return _signer;
	}

	function getCurrentTranche() internal returns (uint256) {

		if(_minimaSold > _tranches[2]){ 
			_currentRate = _rates[3]; 
		}else if(_minimaSold > _tranches[1]){ 
			_currentRate = _rates[2];
		}else if(_minimaSold > _tranches[0]){
			 _currentRate = _rates[1];
		}else { 
			_currentRate = _rates[0];
		}
		return _currentRate;
	}

	function purchaseTokens(bytes calldata signature, address beneficiary, uint256 usdtAmount) public payable whenNotPaused nonReentrant {
		_preValidatePurchase(beneficiary, usdtAmount);
        
		bytes32 digest = toTypedDataHash(beneficiary, usdtAmount);
        address signatureSigner = ECDSA.recover(digest, signature);
        
		require(signatureSigner == _signer, "purchaseTokens: This signature was not signed by the wMinima Crowdsale signer");
        require(signatureSigner != address(0), "purchaseTokens: invalid input signature");
	   
	    purchased[beneficiary] = true;
		// calculate token amount to be created
		uint256 tokens = _getTokenAmount(usdtAmount);

		// update state
		_usdtRaised = _usdtRaised + usdtAmount;
		_minimaSold = _minimaSold + tokens;

		IERC20(_purchaseToken).transferFrom(msg.sender, address(this), usdtAmount);
		
		emit TokensPurchased(beneficiary, usdtAmount, tokens);

	}

	function _preValidatePurchase(address beneficiary, uint256 usdtAmount)
		internal
		view
		virtual
	{
		require(_usdtRaised + usdtAmount <= _usdtCap, "purchaseTokens: This purchase will exceed the maximum crowsdale hardcap");
        require(!purchased[beneficiary], "Purchase: User has already purchased before");
		require(
			beneficiary != address(0),
			"Crowdsale: beneficiary is the zero address"
		);
		require(usdtAmount != 0, "Crowdsale: usdtAmount is 0");
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
	}

	function _getTokenAmount(uint256 usdtAmount)
		internal
		returns (uint256)
	{
		uint256 rate = getCurrentTranche();
		return usdtAmount * rate;
	}

    function toTypedDataHash(address _purchaser, uint256 _amount) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(SUPPORT_TYPEHASH, _purchaser, _amount));
        return ECDSA.toTypedDataHash(EIP712_DOMAIN, structHash);
    }

	function withdrawTokens(address _tokenContract, uint256 _amount) external onlyOwner {
		IERC20 tokenContract = IERC20(_tokenContract);
		tokenContract.safeTransfer(_wallet, _amount);
		emit FundsWithdrawn(_wallet, _amount);
	}
}
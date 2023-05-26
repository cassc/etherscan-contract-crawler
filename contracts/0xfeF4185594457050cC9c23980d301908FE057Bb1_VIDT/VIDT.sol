/**
 *Submitted for verification at Etherscan.io on 2020-10-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.8;

interface ERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);

	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address account, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function decreaseApproval(address spender, uint256 amount) external returns (bool success);
	function increaseApproval(address spender, uint256 amount) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	constructor () internal { }

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a && c >= b, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		uint256 c = a - b;
		require(b <= a && c <= a, errorMessage);
		return c;
	}
}

contract Ownable is Context {
	address private _owner;
	address private mainWallet;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender() || mainWallet == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyOwner whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyOwner whenPaused {
		paused = false;
		emit Unpause();
	}
}

library SafeERC20 {
	function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
}

contract VIDT is ERC20, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private frozenAccounts;
	mapping (address => bool) private verifiedPublishers;
	mapping (address => bool) private verifiedWallets;
	mapping (uint256 => string) private verifiedNFTs;
	bool private publicNFT = false;

	struct fStruct { uint256 index; uint256 nft; }
	mapping(string => fStruct) private fileHashes;
	string[] private fileIndex;

	string private _name;
	string private _symbol;
	uint8 private _decimals;
	uint256 private _totalSupply;

	uint256 public unused = 0;
	uint256 public token_number = 1;
	uint256 private _validationPrice = 1;
	uint256 private _validationFee = 1;
	address private _validationWallet = address(0);

	address private mainWallet = address(0x57E6B79FC6b5A02Cb7bA9f1Bb24e4379Bdb9CAc5);
	address private oldContract = address(0x445f51299Ef3307dBD75036dd896565F5B4BF7A5);
	address private _nftContract = address(0);
	address private _nftdContract = address(0);

	uint256 public constant initialSupply = 100000000;

	constructor() public {
		_name = 'VIDT Datalink';
		_symbol = 'VIDT';
		_decimals = 18;
		_totalSupply = 57386799 * 10**18;

		_validationWallet = msg.sender;
		verifiedWallets[msg.sender] = true;
		verifiedPublishers[msg.sender] = true;

		_balances[msg.sender] = _totalSupply;
	}

	function getOwner() external view virtual override returns (address) {
		return owner();
	}

	function decimals() external view virtual override returns (uint8) {
		return _decimals;
	}

	function symbol() external view virtual override returns (string memory) {
		return _symbol;
	}

	function name() external view virtual override returns (string memory) {
		return _name;
	}

	function nameChange(string memory newName) public onlyOwner {
		_name = newName;
	}

	function totalSupply() external view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external whenNotPaused override returns (bool) {
		require(!frozenAccounts[msg.sender] || recipient == owner(),"T1 - The wallet of sender is frozen");
		require(!frozenAccounts[recipient],"T2 - The wallet of recipient is frozen");

		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferToken(address tokenAddress, uint256 tokens) external onlyOwner {
		ERC20(tokenAddress).transfer(owner(),tokens);
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external whenNotPaused override returns (bool) {
		require((amount == 0) || (_allowances[msg.sender][spender] == 0),"A1- Reset allowance to 0 first");

		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external whenNotPaused override returns (bool) {
		require(!frozenAccounts[sender],"TF1 - The wallet of sender is frozen");
		require(!frozenAccounts[recipient] || recipient == owner(),"TF2 - The wallet of recipient is frozen");

		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TF1 - Transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function increaseApproval(address spender, uint256 addedValue) public whenNotPaused override returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "DA1 - Decreased allowance below zero"));
		return true;
	}

	function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused override returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "DA1 - Decreased allowance below zero"));
		return true;
	}

	function burn(uint256 amount) public {
		_burn(_msgSender(), amount);
	}

	function freeze(address _address, bool _state) public onlyOwner returns (bool) {
		frozenAccounts[_address] = _state;
		emit Freeze(_address, _state);
		return true;
	}

	function burnFrom(address account, uint256 amount) public {
		uint256 decreasedAllowance = _allowances[account][_msgSender()].sub(amount, "BF1 - Burn amount exceeds allowance");
		_approve(account, _msgSender(), decreasedAllowance);
		_burn(account, amount);
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "T1 - Transfer from the zero address");
		require(recipient != address(0) || frozenAccounts[sender], "T3 - Transfer to the zero address");

		_balances[sender] = _balances[sender].sub(amount, "T4 - Transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);

		emit Transfer(sender, recipient, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "B1 - Burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "B2 - Burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);

		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "A1 - Approve from the zero address");
		require(spender != address(0), "A2 - Approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function transferByOwner(address _to, uint256 _value) public onlyOwner returns (bool success) {
		_balances[msg.sender] = _balances[msg.sender].sub(_value);
		_balances[_to] = _balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function batchTransferByOwner(address[] memory _addresses, uint256[] memory _amounts) public onlyOwner returns (bool success) {
        require(_addresses.length == _amounts.length, "BT1 - Addresses length must be equal to amounts length");

		uint256 i = 0;
		for (i = 0; i < _addresses.length; i++) {
			_balances[msg.sender] = _balances[msg.sender].sub(_amounts[i]);
			_balances[_addresses[i]] = _balances[_addresses[i]].add(_amounts[i]);
			emit Transfer(msg.sender, _addresses[i], _amounts[i]);
		}
		return true;
	}

	function validatePublisher(address Address, bool State, string memory Publisher) public onlyOwner returns (bool) {
		verifiedPublishers[Address] = State;
		emit ValidatePublisher(Address,State,Publisher);
		return true;
	}

	function validateWallet(address Address, bool State, string memory Wallet) public onlyOwner returns (bool) {
		verifiedWallets[Address] = State;
		emit ValidateWallet(Address,State,Wallet);
		return true;
	}

	function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
		bytes32 out;
		for (uint i = 0; i < 32; i++) {
			out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function validateFile(address To, uint256 Payment, bytes calldata Data, bool cStore, bool eLog, bool NFT) external payable returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(verifiedPublishers[msg.sender],"V2 - Unverified publisher address");
		require(Data.length == 64,"V3 - Invalid hash provided");

		if (!verifiedWallets[To]) {
			To = _validationWallet;
		}

		uint256 index = 0;
		string memory fileHash = string(Data);

		if (cStore) {
			if (fileIndex.length > 0) {
				require(fileHashes[fileHash].index == 0,"V4 - This hash was previously validated");
			}

			fileIndex.push(fileHash);
			fileHashes[fileHash].index = fileIndex.length-1;
			index = fileHashes[fileHash].index;
		}

		bool nft_created = false;
		uint256 nftID = 0;

		if (NFT) {
			bytes memory nft_data = "";
			require(fileHashes[fileHash].nft == 0,"V5 - NFT exists already");
			(nft_created, nft_data) = _nftContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
			require(nft_created,"V6 - NFT contract call failed");

			nftID = uint256(bytesToBytes32(nft_data,0));

			verifiedNFTs[nftID] = fileHash;
			fileHashes[fileHash].nft = nftID;
		}

		if (_allowances[To][msg.sender] >= Payment) {
			_allowances[To][msg.sender] = _allowances[To][msg.sender].sub(Payment);
		} else {
			_balances[msg.sender] = _balances[msg.sender].sub(Payment);
			_balances[To] = _balances[To].add(Payment);
		}

		if (eLog) {
			emit ValidateFile(index,fileHash,nftID);
		}

		emit Transfer(msg.sender, To, Payment);
		return true;
	}

	function memoryValidateFile(uint256 Payment, bytes calldata Data) external payable whenNotPaused returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(verifiedPublishers[msg.sender],"V2 - Unverified publisher address");
		require(Data.length == 64,"V3 - Invalid hash provided");

		uint256 index = 0;
		string memory fileHash = string(Data);

		if (fileIndex.length > 0) {
			require(fileHashes[fileHash].index == 0,"V4 - This hash was previously validated");
		}

		fileIndex.push(fileHash);
		fileHashes[fileHash].index = fileIndex.length-1;
		index = fileHashes[fileHash].index;

		_balances[msg.sender] = _balances[msg.sender].sub(Payment);
		_balances[_validationWallet] = _balances[_validationWallet].add(Payment);

		emit Transfer(msg.sender, _validationWallet, Payment);
		return true;
	}

	function validateNFT(uint256 Payment, bytes calldata Data, bool divisable) external payable whenNotPaused returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(publicNFT || verifiedPublishers[msg.sender],"V2 - Unverified publisher address");
		require(Data.length == 64,"V3 - Invalid hash provided");

		uint256 index = 0;
		string memory fileHash = string(Data);
		bool nft_created = false;
		uint256 nftID = 0;
		bytes memory nft_data = "";

		require(fileHashes[fileHash].nft == 0,"V5 - NFT exists already");

		if (divisable) {
			(nft_created, nft_data) = _nftdContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
		} else {
			(nft_created, nft_data) = _nftContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
		}
		require(nft_created,"V6 - NFT contract call failed");

		nftID = uint256(bytesToBytes32(nft_data,0));

		verifiedNFTs[nftID] = fileHash;
		fileHashes[fileHash].nft = nftID;

		_balances[msg.sender] = _balances[msg.sender].sub(Payment);
		_balances[_validationWallet] = _balances[_validationWallet].add(Payment);

		emit Transfer(msg.sender, _validationWallet, Payment);
		emit ValidateFile(index,fileHash,nftID);
		return true;
	}

	function simpleValidateFile(uint256 Payment) external payable whenNotPaused returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(verifiedPublishers[msg.sender],"V2 - Unverified publisher address");

		_balances[msg.sender] = _balances[msg.sender].sub(Payment);
		_balances[_validationWallet] = _balances[_validationWallet].add(Payment);

		emit Transfer(msg.sender, _validationWallet, Payment);
		return true;
	}

	function covertValidateFile(uint256 Payment) external payable whenNotPaused returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(verifiedPublishers[msg.sender],"V2 - Unverified publisher address");

		_balances[msg.sender] = _balances[msg.sender].sub(Payment);
		_balances[_validationWallet] = _balances[_validationWallet].add(Payment);
		return true;
	}

	function verifyFile(string memory fileHash) public view returns (bool verified) {
		verified = true;
		if (fileIndex.length == 0) {
			verified = false;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			verified = false;
		}
		if (verified) {
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				verified = false;
			}
		} }
		if (!verified) {
			bool heritage_call = false;
			bytes memory heritage_data = "";
			(heritage_call, heritage_data) = oldContract.staticcall(abi.encodeWithSignature("verifyFile(string)", fileHash));
			require(heritage_call,"V0 - Old contract call failed");
			assembly {verified := mload(add(heritage_data, 32))}
		}
	}

	function verifyPublisher(address _publisher) public view returns (bool verified) {
		verified = verifiedPublishers[_publisher];
	}

	function verifyWallet(address _wallet) public view returns (bool verified) {
		verified = verifiedWallets[_wallet];
	}

	function frozenAccount(address _account) public view returns (bool frozen) {
		frozen = frozenAccounts[_account];
	}

	function verify(string memory fileHash) public view returns (bool) {
		if (fileIndex.length == 0) {
			return false;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			return false;
		}
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return false;
			}
		}
		return true;
	}

	function verifyFileNFT(string memory fileHash) public view returns (uint256) {
		if (fileIndex.length == 0) {
			return 0;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			return 0;
		}
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return 0;
			}
		}
		return fileHashes[fileHash].nft;
	}

	function verifyNFT(uint256 nftID) public view returns (string memory hash) {
		hash = verifiedNFTs[nftID];
	}

	function setPrice(uint256 newPrice) public onlyOwner {
		_validationPrice = newPrice;
	}

	function setFee(uint256 newFee) public onlyOwner {
		_validationFee = newFee;
	}

	function setWallet(address newWallet) public onlyOwner {
		_validationWallet = newWallet;
	}

	function setContracts(address nftContract, address nftdContract) public onlyOwner {
		_nftContract = nftContract;
		_nftdContract = nftdContract;
	}

	function setPublic(bool _public) public onlyOwner {
		publicNFT = _public;
	}

	function listFiles(uint256 startAt, uint256 stopAt) onlyOwner public returns (bool) {
		if (fileIndex.length == 0) {
			return false;
		}
		require(startAt <= fileIndex.length-1,"L1 - Please select a valid start");
		if (stopAt > 0) {
			require(stopAt > startAt && stopAt <= fileIndex.length-1,"L2 - Please select a valid stop");
		} else {
			stopAt = fileIndex.length-1;
		}
		for (uint256 i = startAt; i <= stopAt; i++) {
			emit ListFile(i,fileIndex[i],fileHashes[fileIndex[i]].nft);
		}
		return true;
	}

	function withdraw(address payable _ownerAddress) onlyOwner external {
		_ownerAddress.transfer(address(this).balance);
	}

	function validationPrice() public view returns (uint256) {
		return _validationPrice;
	}

	function validationFee() public view returns (uint256) {
		return _validationFee;
	}
	
	function validationWallet() public view returns (address) {
		return _validationWallet;
	}

	function nftContract() public view returns (address) {
		return _nftContract;
	}

	function nftdContract() public view returns (address) {
		return _nftdContract;
	}
	
	event Freeze(address indexed target, bool indexed frozen);
	event ValidateFile(uint256 indexed index, string indexed data, uint256 indexed nftID);
	event ValidatePublisher(address indexed publisherAddress, bool indexed state, string indexed publisherName);
	event ValidateWallet(address indexed walletAddress, bool indexed state, string indexed walletName);
	event ListFile(uint256 indexed index, string indexed data, uint256 indexed nft) anonymous;
}
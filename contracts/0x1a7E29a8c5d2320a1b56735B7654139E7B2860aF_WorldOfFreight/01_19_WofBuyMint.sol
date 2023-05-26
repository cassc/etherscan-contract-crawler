pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "hardhat/console.sol";


interface IWorldOfFreight {

	function balanceOG(address _user) external view returns(uint256);
}

contract WOFToken is ERC20("WoFToken", "WOF") {
    using SafeMath for uint256;
    uint256 constant public BASE_RATE = 25 ether;
    uint256 constant public INITIAL_ISSUANCE = 1 ether;
    mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate; 
    uint256 constant public END = 1947166276; //TMP

    IWorldOfFreight public wofContract;
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _wof) {
		wofContract = IWorldOfFreight(_wof);
	}   
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
    // called on transfers - transfer half of tokens, burn the rest
	function transferTokens(address _from, address _to) external {
		require(msg.sender == address(wofContract));
			uint256 time = min(block.timestamp, END); 
        	uint256 timerFrom = lastUpdate[_from]; 
		
        	if (timerFrom > 0)
				rewards[_from] += wofContract.balanceOG(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
                //rewards[_from] += BASE_RATE.mul(time.sub(timerFrom)).div(86400);
			if (timerFrom != END)
				lastUpdate[_from] = time;

			if (_to != address(0)) {
				uint256 timerTo = lastUpdate[_to];
				if (timerTo > 0)
					rewards[_to] += wofContract.balanceOG(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
				if (timerTo != END)
					lastUpdate[_to] = time;
			}
		
	}

   function rewardOnMint(address _user, uint256 _amount) external {
		require(msg.sender == address(wofContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
		if (timerUser > 0)
			rewards[_user] = rewards[_user].add(wofContract.balanceOG(_user).mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400)
				.add(_amount.mul(INITIAL_ISSUANCE)));
		else 
			rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
		lastUpdate[_user] = time;
	}


    function getReward(address _to) external {
		require(msg.sender == address(wofContract));
		uint256 reward = rewards[_to];
		if (reward > 0) {
			rewards[_to] = 0;
			_mint(_to, reward);
			emit RewardPaid(_to, reward);
		}
	}

    function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(wofContract));
		_burn(_from, _amount);
	}
    function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 pending = wofContract.balanceOG(_user).mul(BASE_RATE.mul((time.sub(lastUpdate[_user])))).div(86400);
		return rewards[_user] + pending;
	}

}

contract ERC721Namable is ERC721 {
    uint256 public nameChangePrice = 300 ether;
 
    // Mapping from token ID to name
	mapping (uint256 => string) private _tokenName;

	// Mapping if certain name string has already been reserved
	mapping (string => bool) private _nameReserved;

	event NameChange (uint256 indexed tokenId, string newName);

    constructor(string memory _name, string memory _symbol, string[] memory _names, uint256[] memory _ids) ERC721(_name, _symbol) {
		for (uint256 i = 0; i < _ids.length; i++)
		{
			toggleReserveName(_names[i], true);
			_tokenName[_ids[i]] = _names[i];
			emit NameChange(_ids[i], _names[i]);
		}
	}

    function changeName(uint256 tokenId, string memory newName) public virtual {
		address owner = ownerOf(tokenId);

		require(_msgSender() == owner, "ERC721: caller is not the owner");
		require(validateName(newName) == true, "Not a valid new name");
		require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
		require(isNameReserved(newName) == false, "Name already reserved");

		// If already named, dereserve old name
		if (bytes(_tokenName[tokenId]).length > 0) {
			toggleReserveName(_tokenName[tokenId], false);
		}
		toggleReserveName(newName, true);
		_tokenName[tokenId] = newName;
		emit NameChange(tokenId, newName);
	}

  

    function toggleReserveName(string memory str, bool isReserve) internal {
		_nameReserved[toLower(str)] = isReserve;
	}


	function tokenNameByIndex(uint256 index) public view returns (string memory) {
		return _tokenName[index];
	}


	function isNameReserved(string memory nameString) public view returns (bool) {
		return _nameReserved[toLower(nameString)];
	}

	function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 25) return false; // Cannot be longer than 25 characters
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;

			lastChar = char;
		}

		return true;
	}

	 /**
	 * @dev Converts the string to lowercase
	 */
	function toLower(string memory str) public pure returns (string memory){
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
}

contract WorldOfFreight is ERC721Namable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private contOwner;
    uint256 private constant _maxTokens = 10000;
    uint256 private constant _maxMint = 10;
    address public saleContract;
    uint256 public constant _price = 80000000000000000;//WEI // 0.08 ETH
    string public PROVENANCE = "";
    string public _prefixURI;

    bool private _saleActive = true;
    bool private _openSale = false;

    address public constant burn = address(0x000000000000000000000000000000000000dEaD);
    
    mapping(address => uint256) public balanceOG;

    WOFToken public wofToken;

    constructor(string memory _name, string memory _symbol, string[] memory _names, uint256[] memory _ids) ERC721Namable(_name, _symbol, _names, _ids) {
        contOwner = msg.sender;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }
       function toggleOpenSale() public onlyOwner {
        _openSale = !_openSale;
    }
    function myBalance (address _user) public view returns (uint256) {
        uint256 bal = balanceOf(_user);
        return bal;
    }

    function setSaleContract(address _saleContract) public onlyOwner {
        saleContract = _saleContract;
    }

    function mintItems(address to, uint256 amount) public  {
        require(msg.sender == saleContract, "Nice try :)");
        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);
        for (uint256 i = 0; i < amount; i++) {
            _mintItem(to);
        }
    }

    function openMint(uint256 amount) public payable {
        require(_openSale, 'Sale not open');
        require(amount <= _maxMint, 'Can not mint this much');
        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens, 'Not enough tokens remaining');
        require(msg.value >= amount * _price, 'Price too low');
        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }


    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();
        wofToken.rewardOnMint(to, 1);
        uint256 id = _tokenIds.current();
        require(id <= _maxTokens);
        balanceOG[to] = balanceOG[to].add(1);
        _safeMint(to, id);
        return id;
    }

    //WOF TOKEN
    function setWofToken(address _yield) external onlyOwner {
		wofToken = WOFToken(_yield);
	}
     function changeNamePrice(uint256 _newPrice) external onlyOwner {
		nameChangePrice = _newPrice;
	}


    function changeName(uint256 tokenId, string memory newName) public override {
		wofToken.burn(msg.sender, nameChangePrice);
		super.changeName(tokenId, newName);
	}
    function getReward() external {
		wofToken.transferTokens(msg.sender, address(0));
		wofToken.getReward(msg.sender);
	}


    function transferFrom(address from, address to, uint256 tokenId) public override {
		wofToken.transferTokens(from, to);
		balanceOG[from] = balanceOG[from].sub(1);
		balanceOG[to]++;
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		wofToken.transferTokens(from, to);
		balanceOG[from] = balanceOG[from].sub(1);
		balanceOG[to]++;
		super.safeTransferFrom(from, to, tokenId, _data);
	}
    function tokensLeft() external view returns (uint256) {
        uint256 totalMinted =  _tokenIds.current();
        uint256 tokens = _maxTokens.sub(totalMinted);
        return tokens;
    }
    function mintedcount() public view returns (uint256){
        uint256 totalMinted =  _tokenIds.current();
        return totalMinted;
    }

    //RESERVE
    function reserve(uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintItem(msg.sender);
        }
    }
    //SEND TO WINNERS
    function giveAway(address to, uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintItem(to);
        }
    }

    function withdrawAmount(address payable to, uint256 amount) public onlyOwner{
        require(msg.sender == contOwner);
        to.transfer(amount); 
     }

}
contract WofBuyMint is Ownable  {

    using SafeMath for uint256;
    uint256 private _maxTokens = 9833;
    uint256 private _maxPresale = 9833;
    address private contOwner;
    bool private _saleActive = true;
    bool private _preSaleActive = true;
    uint256 public _preSalestartTime = 1632679200; 
    uint256 public _salestartTime = 1632765600; 
    uint256 public _buyTime = 259200;
    uint256 public constant _price = 80000000000000000;//WEI // 0.08 ETH

    mapping(address => uint256) public preSaleUserReserved;
    mapping(address => uint256) public userReserved;
    mapping(address => uint256) public buyTime;

    WorldOfFreight public _wofContract;
    constructor () {
        contOwner = msg.sender;
    }

    function toggleSale() public onlyOwner  {
        _saleActive = !_saleActive;
    }
    function togglePreSale() public onlyOwner  {
        _preSaleActive = !_preSaleActive;
    }
    function setPreSaleStartTime(uint256 time) public onlyOwner  {
        _preSalestartTime = time;
    }
     function setSaleStartTime(uint256 time) public onlyOwner  {
        _salestartTime = time;
    }
    function setBuyTime(uint256 time) public onlyOwner  {
        _buyTime = time;
    }
    function setMaxTokens(uint256 amount) public onlyOwner  {
        _maxTokens = amount;
    }
    function setWofContract(address _wof) public onlyOwner {
		_wofContract = WorldOfFreight(_wof);
	}

    function myAmount(address _user) public view returns (uint256) {
        uint256 userTotalAmount = preSaleUserReserved[_user].add(userReserved[_user]);
        return userTotalAmount;
    }

    function buyDeadline(address _user) public view returns (uint256) {
        uint256 timestamp = buyTime[_user];
        return timestamp;
    }

    function presaleBuy(address _user, uint256 amount) public payable returns (uint256) {
        uint256 time = block.timestamp;
        require(msg.value >= amount * _price);
        require(amount <= _maxPresale, 'Sorry, sold out');
        require(time > _preSalestartTime, "Sale has not started yet");

        if(time >= _preSalestartTime && time < _preSalestartTime.add(600) ) { 
            require(preSaleUserReserved[_user] <= 4,'Max amount bought');
            require(amount <= 4, 'Can not mint this much');
            preSaleUserReserved[_user] = preSaleUserReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _preSalestartTime.add(600) && time < _preSalestartTime.add(1200)) {
            require(preSaleUserReserved[_user] <= 20,'Max amount bought');
            require(amount <= 16, 'Can not mint this much');
            preSaleUserReserved[_user] = preSaleUserReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _preSalestartTime.add(1200)) {
            require(preSaleUserReserved[_user] <= 84,'Max amount bought');
            require(amount <= 64, 'Can not mint this much');
            preSaleUserReserved[_user] = preSaleUserReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _preSalestartTime.add(1800) && time < _salestartTime.add(1800)) {
            require(preSaleUserReserved[_user] <= 196,'Max amount bought');
            require(amount <= 112, 'Can not mint this much');
            preSaleUserReserved[_user] = preSaleUserReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        _maxTokens = _maxTokens.sub(preSaleUserReserved[_user]);
        _maxPresale = _maxPresale.sub(preSaleUserReserved[_user]);
        return preSaleUserReserved[_user];
    }

    function buy(address _user, uint256 amount) public payable returns (uint256) {
        uint256 time = block.timestamp;
        require(msg.value >= amount * _price);
        require(amount <= _maxTokens, 'Sorry, sold out');
        require(time > _salestartTime, "Sale has not started yet");
        
        if(time >= _salestartTime && time < _salestartTime.add(600) ) { 
            require(userReserved[_user] <= 4,'Max amount bought');
            require(amount <= 4, 'Can not mint this much');
            userReserved[_user] = userReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _salestartTime.add(600) && time < _salestartTime.add(1200)) {
            require(userReserved[_user] <= 20,'Max amount bought');
            require(amount <= 16, 'Can not mint this much');
            userReserved[_user] = userReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _salestartTime.add(1200) && time < _salestartTime.add(1800)) {
            require(userReserved[_user] <= 84,'Max amount bought');
            require(amount <= 64, 'Can not mint this much');
            userReserved[_user] = userReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        else if(time >= _salestartTime.add(1800)) {
            require(userReserved[_user] <= 192,'Max amount bought');
            require(amount <= 112, 'Can not mint this much');
            userReserved[_user] = userReserved[_user].add(amount);
            buyTime[_user] = time;
        }
        _maxTokens = _maxTokens.sub(userReserved[_user]);
        return userReserved[_user];
    }

    function mint(address _user) public {
        uint256 time = block.timestamp;
        uint256 userTotalAmount = preSaleUserReserved[_user].add(userReserved[_user]);
        uint256 timeLeft = time.sub(buyTime[_user]);
        require(userTotalAmount > 0, 'You have no tickets left');
        require(timeLeft <= _buyTime, 'Sorry, you ran out of time to mint');

        preSaleUserReserved[_user] = 0;
        userReserved[_user] = 0;
        _wofContract.mintItems(_user, userTotalAmount);
    }

     function withdrawAmount(address payable to, uint256 amount) public onlyOwner {
         require(msg.sender == contOwner);
         to.transfer(amount); 
     }
}
/*

██╗    ██╗ █████╗ ███╗   ██╗███╗   ██╗ █████╗ ██████╗ ███████╗███████╗
██║    ██║██╔══██╗████╗  ██║████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔════╝
██║ █╗ ██║███████║██╔██╗ ██║██╔██╗ ██║███████║██████╔╝█████╗  ███████╗
██║███╗██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══██║██╔══██╗██╔══╝  ╚════██║
╚███╔███╔╝██║  ██║██║ ╚████║██║ ╚████║██║  ██║██████╔╝███████╗███████║
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
                                                                                                                                                                        
███╗   ███╗██╗   ██╗███████╗██╗ ██████╗     ██████╗██╗     ██╗   ██╗██████╗ 
████╗ ████║██║   ██║██╔════╝██║██╔════╝    ██╔════╝██║     ██║   ██║██╔══██╗
██╔████╔██║██║   ██║███████╗██║██║         ██║     ██║     ██║   ██║██████╔╝
██║╚██╔╝██║██║   ██║╚════██║██║██║         ██║     ██║     ██║   ██║██╔══██╗
██║ ╚═╝ ██║╚██████╔╝███████║██║╚██████╗    ╚██████╗███████╗╚██████╔╝██████╔╝
╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝     ╚═════╝╚══════╝ ╚═════╝ ╚═════╝ 

We're all Wannabes!

*/  

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IVIBE20.sol";

contract WBMC is ERC721, Ownable {  

    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIds;
    string internal baseURI;
    uint internal maxPurchase = 10;
    uint internal wbPrice = 70000000000000000; //0,07 eth
    uint internal _totalSupply = 0;

    bool public publicSale = false;

    string public PROVENANCE = "";
    uint256 public MAX_WANNABES = 10027;

    uint256 public constant NAME_CHANGE_PRICE = 1830 * (10 ** 18);
    uint256 constant public RATE = 10 * (10 ** 18); 
	uint256 constant public INITIAL_ISSUANCE = 1830 * (10 ** 18);

    mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

    mapping(uint256 => string) private _tokenNames;
    mapping(string => bool) private _namesUsed;

    IVIBE20 public vibeToken;

    event ERC20RewardPaid(address indexed user, uint256 reward);
    event Named(uint256 indexed index, string name);

    constructor(string memory myBase, address _vibe20address) ERC721("WannabesMusicClub", "WBMC") {
        setBaseURI(myBase);
        vibeToken = IVIBE20(_vibe20address);        
    }

    function switchSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function order(uint256 _wbQty) updateRewardOnMint(msg.sender, _wbQty)
	public 
	payable 
    {
        require(publicSale, "Sale not started");
        require(_wbQty <= maxPurchase, ">MaxPurch");
        require(totalSupply() + _wbQty <= MAX_WANNABES, ">MaxSupply");
        uint salePrice = _wbQty*wbPrice;
        require(msg.value >= salePrice, "not enough eth");
        
        for (uint256 i = 0; i < _wbQty; i++) {
            _tokenIds.increment(); 
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _totalSupply++;
        }                        
    }

    function adminOrder(uint256 _wbQty, address _to) updateRewardOnMint(_to, _wbQty) onlyOwner
	public 
    {
        require(totalSupply() + _wbQty <= MAX_WANNABES, ">MaxSupply");
        for (uint256 i = 0; i < _wbQty; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(_to, newItemId);
            _totalSupply++;
        }                        
    }
    
    // Get current price
    function getPrice() public view returns (uint) {
        return wbPrice;
    }

    // Get total Supply
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }   

    // Set price
    // Just in case ETH does crazy things
    function setPrice(uint _newPrice) public onlyOwner {
        wbPrice = _newPrice;
    }

    // Get Max Purch
    function getMax() public view returns (uint) {
        return maxPurchase;
    }

    // Set Max Purch
    function setMax(uint _newMax) public onlyOwner {
        maxPurchase = _newMax;
    }

    //withdraw
    function withdraw(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }

    /*
    * =====================================
    * Metadata
    * =====================================
    */

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "!token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /*
    * =====================================
    * VIBE20 Rewards 
    * Everything is about vibe here!
    * =====================================
    */

    // set vibe token address
    function setVIBE(address _newVibeAddress) public onlyOwner {
        vibeToken = IVIBE20(_newVibeAddress);
    }

    // called on transfers or at getRewards
	modifier updateReward(address _from, address _to) {
		if (lastUpdate[_from] > 0)
            rewards[_from] += balanceOf(_from) * RATE*(block.timestamp - lastUpdate[_from]) / 86400;
		lastUpdate[_from] = block.timestamp;
		if (_to != address(0)) {
			if (lastUpdate[_to] > 0)
				rewards[_to] += balanceOf(_to) * RATE*(block.timestamp - lastUpdate[_to]) / 86400;
			lastUpdate[_to] = block.timestamp;
		}
		_;
	}

	// called when minting many NFTs
	modifier updateRewardOnMint(address _user, uint256 _amount) {
		if (lastUpdate[_user] > 0)
			rewards[_user] += balanceOf(_user) * (RATE * (block.timestamp - lastUpdate[_user])) / 86400
				+ (_amount * INITIAL_ISSUANCE);
		else 
			rewards[_user] += _amount * (INITIAL_ISSUANCE);
		lastUpdate[_user] = block.timestamp;
		_;
	}

	function getReward() external updateReward(msg.sender, address(0)) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			vibeToken.mint(msg.sender, reward);
			emit ERC20RewardPaid(msg.sender, reward);
		}
	}

    function getRewardBalance(address holder) external view returns (uint) {
        uint256 holderReward; 
        if (lastUpdate[holder] > 0)
            holderReward = rewards[holder] + balanceOf(holder) * RATE*(block.timestamp - lastUpdate[holder]) / 86400;
        else
            holderReward = 0;
        return holderReward;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override updateReward(from, to){
		ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override updateReward(from, to) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) 
    public 
    override 
    updateReward(from, to) {
		ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    /*
    * ==========================================================================
    * NAMING
    * Be careful with it. They say, your fate depends on your name!
    * ==========================================================================
    */

    function setName(uint256 tokenId, string memory name) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "!token.owner");
        require(validateName(name) == true, "!name.valid");
        require(isNameUsed(name) == false, "name.used");

        vibeToken.burnBurner(msg.sender, NAME_CHANGE_PRICE);

        if (bytes(_tokenNames[tokenId]).length > 0) {
            _namesUsed[toLower(_tokenNames[tokenId])] = false;
        }
        _namesUsed[toLower(name)] = true;
        _tokenNames[tokenId] = name;
        emit Named(tokenId, name);
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return _tokenNames[index];
    }

    function isNameUsed(string memory nameString) public view returns (bool) {
        return _namesUsed[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3) return false;
        if (b.length > 32) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;
        bytes1 lastChar = b[0];
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (char == 0x20 && lastChar == 0x20) return false;
            if (
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x20)
            ) return false;
            lastChar = char;
        }
        return true;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

}

/*
Thanks for reading! May the force be with you!
*/
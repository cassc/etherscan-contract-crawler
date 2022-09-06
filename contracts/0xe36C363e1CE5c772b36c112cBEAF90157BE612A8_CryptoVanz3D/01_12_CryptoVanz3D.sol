// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
 
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

// Interface for original CryptoVanz contract.
interface ICryptoVanz {
    function ownerOf(uint256) external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

// TLDR:
// 3D vanz = 1 to collectionSize 
// mintUpgrade() from collectionSize + 1 onwards (baseURI/upgrade_kit.json)
// upgrade() turns upgrade_kit into upgrade[token] w/new upgradeURIextended

contract CryptoVanz3D is ERC721A, Ownable, PaymentSplitter {
    address private vanzContractAddr = 0x3b7ee460DceC30482aC48acAA0AbB2C3Aa4155a3;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;

    uint256 public saleState = 0;
    // none = 0 
    // presale = 1 
    // public = 2 

    string private _baseURIextended = "ipfs://QmaKJzwKMH2xs5L73Wwig1NkfUcCLVfUM3KvevKLMiEj9v"; 
    string private _upgradeURIextended = ""; 

    uint16 public constant maxMint = 10;
    uint16 public constant collectionSize = 500;

    uint256 public constant presalePrice = 0.03 * 10**18; // 0.03eth   
    uint256 public price = 0.069 * 10**18; // 0.069eth

    uint256 public launchDate;   

    mapping(address => bool) public claimed;
    mapping(uint256 => uint256) public upgrades;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721A ("CryptoVanz3D", "CV3D") PaymentSplitter (_payees, _shares) payable  {        
        launchDate = block.timestamp;
    }

    function setBaseURI(string memory URI_) 
        external 
        onlyOwner 
    {
        _baseURIextended = URI_;
    }

    function setUpgradeURI(string memory URI_) 
        external 
        onlyOwner 
    {
        _upgradeURIextended = URI_; 
    }

    function setVanzContractAddr(address _newAddress) 
        external 
        onlyOwner 
    {
        vanzContractAddr = _newAddress;
    }

    function setSaleState(uint16 _state) 
        external 
        onlyOwner 
    {
        require(_state >= 0, "invalid state");
        require(_state < 3 , "invalid state");
        saleState = _state;
    }

    function currentPrice() 
        public 
        view 
        returns (uint256) 
    {
        if (saleState == 1) {
            return presalePrice;
        } else {
            return price;
        }
    }

    function setPrice(uint256 _price) 
        external 
        onlyOwner 
    {
        price = _price; 
    }

    function holdermint()
        external
        payable
    {
        require(saleState == 1, "not presale");
        require(msg.value >= currentPrice(), "insufficient eth to mint");
        require((totalSupply() + 1) <= collectionSize, "not enough left");
        require(!claimed[msg.sender], "already claimed");

        require(ICryptoVanz(vanzContractAddr).balanceOf(msg.sender) > 0,  "not Vanz holder");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 quantity) 
        external 
        payable 
    {
        require(saleState == 2, "not public sale");
        require(quantity > 0, "Cannot mint 0");
        require(quantity <= maxMint, "Too many");
        require((totalSupply() + quantity) <= collectionSize, "not enough left");
        require(msg.value >= currentPrice() * quantity, "insufficient eth to mint");

        _safeMint(msg.sender, quantity);
    }

    function driverMint(address to, uint256 quantity) 
        external 
        onlyOwner 
    {
        // Owner can mint for giveaways and airdrops
        require((totalSupply() + quantity) <= collectionSize, "not enough left");
        _safeMint(to, quantity);
    }

    function mintUpgrade(address to, uint256 quantity) 
        external 
        onlyOwner 
    {
        require (totalSupply() >= collectionSize, "No upgrades before sellout");
        for(uint16 i = 1; i <= quantity; i++) {        
            upgrades[totalSupply() + i] = 0;
        }
        _safeMint(to, quantity); 
    }

    function upgrade(uint256 kitId, uint256 tokenId, string memory newURI) 
        external 
        onlyOwner 
    {
        require(kitId > collectionSize, "Not upgrade");
        require(tokenId <= totalSupply(), "Invalid van id");
        require(_exists(kitId), "Upgrade doesn't exist");
        require(upgrades[kitId] == 0, "Upgrade already used");

        upgrades[kitId] = tokenId;
        _upgradeURIextended = newURI;
    }

    function changeUpgradeToken(uint256 kitId, uint256 tokenId) 
        external 
        onlyOwner 
    {
        require(_exists(kitId), "Upgrade doesn't exist");
        require(upgrades[kitId] != 0, "Upgrade not set yet");

        upgrades[kitId] = tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Nonexistent token"
        );

        if (tokenId <= collectionSize) {
            return string(abi.encodePacked(_baseURIextended, "/", toString(tokenId), ".json"));
        } if (upgrades[tokenId] == 0) {
            return string(abi.encodePacked(_baseURIextended, "/", "upgrade_kit.json"));
        } else {
            return string(abi.encodePacked(_upgradeURIextended, "/", toString(tokenId), ".json"));
        }
    }

    function upgraded(uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        // returns 0 unless it's an upgraded token
        if (tokenId <= collectionSize) {
            return 0; // not an upgrade
        } else if (tokenId > totalSupply()) {
            return 0; // does not exist
        } else {
            return upgrades[tokenId];
        }
    }    

    function exists(uint256 tokenId) 
        public 
        view 
        returns (bool) 
    {
        return _exists(tokenId);
    }    

    function _startTokenId() 
        internal 
        pure 
        override 
        returns (uint256) 
    {
        return 1;
    }

    function presaleClaimed(address addy) 
        public 
        view 
        returns (bool) 
    {
        return claimed[addy];
    }

    function isHolder() 
        public 
        view 
        returns (bool) 
    {
        if (ICryptoVanz(vanzContractAddr).balanceOf(msg.sender) > 0) {
            return true;
        }
        return false;
    }

    function canPresale() 
        public 
        view 
        returns (bool) 
    {
        if (!isHolder()) { return false; }
        if (presaleClaimed(msg.sender)) { return false; }
        return true;
    }

    function upgradeURI() 
        public 
        view 
        returns (string memory) 
    {
        return _upgradeURIextended;
    }    


    function toString(uint256 value) 
        internal 
        pure 
        returns (string memory) 
    {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
//@naftponk
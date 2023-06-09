pragma solidity 0.7.4;
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract NFFTContract is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Proof of all blocks position and rarity
    string public constant NFFT_SEQUENCE_PROOF = "788a8a7b124969d872f9d89d6438526a73585019cc804cd711756b03399d38e1";

    // Max suply of NFFT blocks
    uint256 public constant MAX_NFFT_SUPPLY = 9112;

    // Admin wallets
    address payable[] private wallets;

    //Contract URI
    string private _contractURI;

    constructor(string memory _name, string memory _symbol, string memory _baseURI, string memory contractURI, address payable[] memory _wallets) ERC721(_name, _symbol) {
        _setBaseURI(_baseURI);
        _contractURI = contractURI;
        wallets = _wallets;
    }

    /**
    * @dev OpenSea contract meta-data
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev Get max amount a wallet can mint per transaction on current tier.
    */
    function getNfftMaxAmount(uint8 tier) public pure returns (uint256) {
        //Tier 7
        if (tier == 6) {
            return 5;
        } else if (tier == 5) {
            return 10;
        } else if (tier == 4) {
            return 20;
        } else if (tier == 3) {
            return 30;
        } else if (tier == 2) {
            return 40;
        } else {
            return 50;
        }
    }

    /**
    * @dev Get block price based on tier.
    */
    function getPrice(uint8 tier) public pure returns (uint256) {
        //Tier 6
        if (tier == 6) {
            return 600000000 gwei; //0.6
        } else if (tier == 5) {
            return 500000000 gwei; //0.5
        } else if (tier == 4) {
            return 400000000 gwei; //0.4
        } else if (tier == 3) {
            return 300000000 gwei; //0.3
        } else if (tier == 2) {
            return 200000000 gwei; //0.2
        } else {
            return 150000000 gwei; //0.15 ETH 
        }
    }

    /**
    * @dev Get current tier (doesn't require exact check on totalSupply)
    */
    function getTier() public view returns(uint8) {
        uint256 currentSupply = totalSupply();
        uint8 tier;
        //Tier 7
        if(currentSupply > 8699) {
            tier = 6;
        } else if(currentSupply > 7979) {
            tier = 5;
        } else if(currentSupply > 7179) {
            tier =  4;
        } else if(currentSupply > 5999) {
            tier = 3;
        } else if(currentSupply > 3499) {
            tier = 2;
        } else {
            tier = 1;
        }
        return tier;
    }

    /**
    * @dev Mint some blocks!
    */
    function mintBlock(uint8 numberOfBlocks) external payable {
        uint8 tier = getTier();
        require(numberOfBlocks > 0, "You cannot mint 0 blocks");
        require(numberOfBlocks <= getNfftMaxAmount(tier), "Exceeds max blocks per tx");
        require(SafeMath.add(totalSupply(), numberOfBlocks) <= MAX_NFFT_SUPPLY, "Exceeds total blocks supply");
        require(SafeMath.mul(getPrice(tier), numberOfBlocks) == msg.value, "Incorrect ETH amount");

        for (uint8 i = 0; i < numberOfBlocks; i++) {
            uint256 tokenID = totalSupply();
            _safeMint(msg.sender, tokenID);
        }

    }

    /**
    * @dev Some blocks might be preminted (Callable only by owner)
    */
    function mint(uint8 numberOfBlocks, address _to) onlyOwner external {
        require(SafeMath.add(totalSupply(), numberOfBlocks) <= MAX_NFFT_SUPPLY, "Exceeds total blocks supply");

        for (uint8 i = 0; i < numberOfBlocks; i++) {
            uint256 tokenID = totalSupply();
            _safeMint(_to, tokenID);
        }
    }

    /**
     * @dev Withdraw ether from this contract (Callable only by owner)
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 v2 = SafeMath.div(SafeMath.mul(balance, 25), 1000);
        uint256 v = SafeMath.sub(balance, v2);
        uint256 v1 = SafeMath.div(SafeMath.mul(v, 20), 100);
        uint256 v3 = SafeMath.div(SafeMath.sub(v, v1), 2);
        Address.sendValue(wallets[0], v3);
        Address.sendValue(wallets[1], v3);
        Address.sendValue(wallets[3], v2);
        Address.sendValue(wallets[2], v1);
    }

    /**
    * @dev Withdraw ether from this contract - in case of crazy numbers (Callable by owner only)
    */
    function withdrawAll() external onlyOwner {
         uint256 balance = address(this).balance;
         msg.sender.transfer(balance);
    }

    /**
    * @dev Change wallets if needed (Callable only by owner)
    */
    function changeWallets(address payable[] memory _wallets) external onlyOwner {
        wallets = _wallets;
    }

    /**
    * @dev Changes the base URI of token metadata (Callable only by owner)
    */
    function changeBaseURI(string memory baseURI) onlyOwner external {
       _setBaseURI(baseURI);
    }

    /**
    * @dev Changes the contract URI (Callable only by owner)
    */
    function changeContractURI(string memory contractURI) onlyOwner external {
       _contractURI = contractURI;
    }
}
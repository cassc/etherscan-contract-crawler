// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

/*

    ███████████                           █████              ███████████                                    █████  ███                  
    ░░███░░░░░███                         ░░███              ░░███░░░░░███                                  ░░███  ░░░                   
    ░███    ░███  ██████   ████████    ███████   ██████      ░███    ░███  ██████   ████████   ██████    ███████  ████   █████   ██████ 
    ░██████████  ░░░░░███ ░░███░░███  ███░░███  ░░░░░███     ░██████████  ░░░░░███ ░░███░░███ ░░░░░███  ███░░███ ░░███  ███░░   ███░░███
    ░███░░░░░░    ███████  ░███ ░███ ░███ ░███   ███████     ░███░░░░░░    ███████  ░███ ░░░   ███████ ░███ ░███  ░███ ░░█████ ░███████ 
    ░███         ███░░███  ░███ ░███ ░███ ░███  ███░░███     ░███         ███░░███  ░███      ███░░███ ░███ ░███  ░███  ░░░░███░███░░░  
    █████       ░░████████ ████ █████░░████████░░████████    █████       ░░████████ █████    ░░████████░░████████ █████ ██████ ░░██████ 
    ░░░░░         ░░░░░░░░ ░░░░ ░░░░░  ░░░░░░░░  ░░░░░░░░    ░░░░░         ░░░░░░░░ ░░░░░      ░░░░░░░░  ░░░░░░░░ ░░░░░ ░░░░░░   ░░░░░░  
                                                                                                                                     
   

                ██████████████████████████████████████████████████████████████████████
                ██████████████████████████████████████████████████████████████████████
                ██████████████████████████████████████████████████████████████████████
                ██████████████████████████████████████████████████████████████████████
                ██████████████████████████████████████████████████████████████████████
                ██████████████████████████████████████████████████████████████████████
                ███████████████████████████████████▓▓▓▓▓▓█▓▓▒▓▓▓▓▒▓▓▓█████████████████
                ███████████████████████████████▓▓▒▓▒▒▒▒▓▒▒▒▓▓▓▓▓▓▓▓▓▒▒▓███████████████
                ███████████▓▓▓▓▓▓▓▓▒▓▓██▓▓▓▓▒▓▓▒▒▒░░░░▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓█████████████
                █████████▓▒▒▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▒███▓▓▓▓▓▓▓▒▓████████████
                ████████▒▒▓▓▓▓▓▓▓▓▓▓▓▓█▒░░░░░░░░░░░░░░░░░░░░░▒▓▓▓██▓▓▓▓▓▓▒████████████
                ███████▒▒▓▓▓███████▓▓▓▒░░░░░░░░░░░░░░░░░░░░░▒▒░░░▒▓▓▓▓▓▓▓▒████████████
                ███████▒▓▓▓██████▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▒▒████████████
                ███████▒▓▓▓▓██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒▓█████████████
                ███████▒▒▓▓▓▓▓▒░░░░░░░░░░░░░▒▓▓▓▓▓▒▒▓▓▒░░░░░░▓▒▓▓▓▓▒░░▒▒▒█████████████
                ████████▒▒▓▓▓▓░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓░░░░░▓▓▓▓▓▓▓▓▒░░▒▒▒████████████
                █████████▓▒▒▓░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▒▒▓▓▓░░░░░▓▓▓▓▒▒▓▓▓▒░░▓▒████████████
                ██████████▒█░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▒▒▓▓▓░░░░░▓▓▓▓▒▒▓▓▓▒░░▓▒████████████
                █████████▒▒▒░░░░░░░░░░░░▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▒░░░░▒▓▓▒▓▓▓▓▓▓▒░▒▒▒███████████
                █████████▒▓░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░▒▒▓▓▓▓▓▓▒░░▓▒▒██████████
                █████████▒▓░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓░░░░▒▓▓▓▓▓▓░░░░░░░░░░░█▒██████████
                █████████▒▓░░░░░░░░░░░░░░░▒▓▓▓▓▓▓░░░░░░░░▒▓▓▓▓▒░░░░░░░░░░░▒▒▒█████████
                █████████▒▓░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒█████████
                █████████▓░█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒█████████
                ██████████▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▒░░░░░░░░░░▒▒▒█████████
                ███████████▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▒▒░░░░░░░░░░░█▒██████████
                ██████████▓▒▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒██████████
                █████████▓▒▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░▓███████████
                ████████▓░█▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▓▓▓▓▓▓▒▒██████████
                ███████▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒█████████
                ███████░▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒████████
                ██████▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓███████
                █████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓░███████
                ████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒▓▓█████
                ████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█▓▓▓▓▓▓▓▒▓█████


    ███████████   ███                       ████     ███████████                           █████                  
    ░░███░░░░░███ ░░░                       ░░███    ░░███░░░░░███                         ░░███                   
    ░███    ░███ ████  █████ █████  ██████  ░███     ░███    ░███  ██████   ████████    ███████   ██████    █████ 
    ░██████████ ░░███ ░░███ ░░███  ███░░███ ░███     ░██████████  ░░░░░███ ░░███░░███  ███░░███  ░░░░░███  ███░░  
    ░███░░░░░░   ░███  ░░░█████░  ░███████  ░███     ░███░░░░░░    ███████  ░███ ░███ ░███ ░███   ███████ ░░█████ 
    ░███         ░███   ███░░░███ ░███░░░   ░███     ░███         ███░░███  ░███ ░███ ░███ ░███  ███░░███  ░░░░███
    █████        █████ █████ █████░░██████  █████    █████       ░░████████ ████ █████░░████████░░████████ ██████ 
    ░░░░░        ░░░░░ ░░░░░ ░░░░░  ░░░░░░  ░░░░░    ░░░░░         ░░░░░░░░ ░░░░ ░░░░░  ░░░░░░░░  ░░░░░░░░ ░░░░░░  
                                                                                                                                                                                                                
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRNG {
	function rng(
		uint256 from,
		uint256 to,
		uint256 r
	) external view returns (uint256);
}

contract PixelPandas is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    constructor() ERC721A("Pixel Pandas", "PXLP") PaymentSplitter(addressList, splitList) {

    }
    uint256 constant MAX_SUPPLY = 8888;                    // Track max and current supply for collection
    uint256 constant TEAM_RESERVES = 100;                  // Team mint reserves
    uint256 private MAX_MINT_PER_WALLET_WL = 2;            // Panda Paradise holders are allocated 2 free mint per whitelisted wallet
    uint256 private MAX_MINT_PER_WALLET_PUBLIC = 8;        // Maximum of 8 mints per wallet during public sale
    bool private reservesMinted = false;                   // Tracks if team reserves are minted
    string public _contractBaseURI;
    IRNG private random;


    bool public saleEnabled = false;
    bool public wlSaleEnabled = false;
    uint256 constant MINT_PRICE = 0.01 ether;
    mapping (address => uint256) private walletAmountsWL;
    mapping (address => bool) private usedWL;
    mapping (address => uint256) private walletAmountsPublic;

    uint256 public MAX_WL_SUPPLY = 3500;
    uint256 public CURRENT_WL_SUPPLY = 1;

    // Payment splitter
	address[] private addressList = [
		0x93129d64192Bbbe08502817b587D58158De7583D
	];

	uint256[] private splitList = [100];

    // Merkle root used for WL
	bytes32 public root = 0xd422c93cd6ecebe32121d368d066ebaead2e44bf2a994121029c1bb6d272395b;

    event mintedPublic(address indexed user, uint256 indexed amtFree, uint256 totalMinted, uint256 amtPaidEth);

    // Setter functions
    function flipPublicSaleState() external onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function flipWLMintState() external onlyOwner {
        wlSaleEnabled = !wlSaleEnabled;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

    function setRandom(address _random) external onlyOwner {
        random = IRNG(_random);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

    function setMaxPerWalletPublic(uint256 _max) external onlyOwner {
        MAX_MINT_PER_WALLET_PUBLIC = _max;
    }

    function setMaxPerWalletWL(uint256 _max) external onlyOwner {
        MAX_MINT_PER_WALLET_WL = _max;
    }

    // Mint functions
    function rareAuctionMint(uint256 quantity) external onlyOwner {
        require(quantity + _totalMinted() <= MAX_SUPPLY, "No more items are left to mint");
        _mint(msg.sender, quantity, '', true);
    }

    function reservesMint() external onlyOwner {
        require(reservesMinted == false, "Team reserves have already been minted");
        require(TEAM_RESERVES + _totalMinted() <= MAX_SUPPLY, "No more items are left to mint");
        _mint(msg.sender, TEAM_RESERVES, '', true);
        reservesMinted = true;
    }

    function wlMint(uint256 quantity, bytes32[] calldata proof) external {
        require(tx.origin == msg.sender, "No");
        require(wlSaleEnabled, "WL sale has not started");
        require(quantity > 0, "You must mint at least 1 Pixel Panda");
        require(quantity + _totalMinted() <= MAX_SUPPLY, "No more items are left to mint");
        require(walletAmountsWL[msg.sender] < MAX_MINT_PER_WALLET_WL, "You are not allowed to mint any more Pixel Pandas");
        require(CURRENT_WL_SUPPLY + quantity <= MAX_WL_SUPPLY, "WL is sold out");
        require(quantity <= MAX_MINT_PER_WALLET_WL, "You are only allowed to mint 2 Pixel Panda per whitelisted wallet");
        require(isTokenValid(msg.sender, quantity, proof), "WL proof invalid");
        require(usedWL[msg.sender] == false, "You have already used your WL free mint");
        walletAmountsWL[msg.sender] += quantity;
        CURRENT_WL_SUPPLY += quantity;
        usedWL[msg.sender] = true;
        _mint(msg.sender, quantity, '', true);
    }

    function publicMint(uint256 quantity) external payable nonReentrant {
        require(tx.origin == msg.sender, "No");
        require(saleEnabled, "Sale has not started");
        require(quantity > 0, "You must mint at least 1 Pixel Panda");
        require(quantity + _totalMinted() <= MAX_SUPPLY, "No more items are left to mint");
        require(walletAmountsPublic[msg.sender] + quantity <= MAX_MINT_PER_WALLET_PUBLIC, "You are not allowed to mint more than 8 Pixel Pandas per wallet");
        require(msg.value == quantity * MINT_PRICE, "Incorrect amount of ether sent");
        walletAmountsPublic[msg.sender] += quantity;
        _mint(msg.sender, quantity, '', true);

        uint256 returnAmt = (random.rng(1000, 2**69 - 28, block.timestamp) % ((((quantity * 6 * 2) / 2) / 3) / 2));
        require(returnAmt * MINT_PRICE <= msg.value);
        payable(msg.sender).transfer(returnAmt * MINT_PRICE); // Returns funds for amount of Pixel Pandas that were free

        emit mintedPublic(msg.sender, returnAmt, quantity, msg.value - (returnAmt * MINT_PRICE));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }
    
    // Merkle tree WL
    function isTokenValid(
		address _to,
		uint256 _quantity,
		bytes32[] memory _proof
	) public view returns (bool) {
		// Construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _quantity));
		// Verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

}
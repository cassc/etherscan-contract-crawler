// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TextApes is ERC721A, Ownable {

    constructor() ERC721A("TextApe", "TEXTAPE") {}

    string private _uri;

    bytes32 public root;

    uint constant public maxSupply = 10000;
    uint public price = 0.009 ether;
    uint public maxFreePerWallet = 1;
    uint public maxFreeMintCount = 6500;
    uint public freeMintCount = 0;
    uint public maxFeeMintPerWallet = 5;

    bool public paused = false;
    bool public presaleM = false;
    bool public publicM = false;
    
 
    // ---------------------------------------------------------------------------------------------
    // MAPPINGS
    // ---------------------------------------------------------------------------------------------

    mapping(address => uint) public freeMinted; 
    mapping(address => uint) public feeMinted; 

    // ---------------------------------------------------------------------------------------------
    // OWNER SETTERS
    // ---------------------------------------------------------------------------------------------

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxFeeMintCount(uint _count) external onlyOwner {
        maxFeeMintPerWallet = _count;
    }

    function setMaxFreePerWallet(uint amount) external onlyOwner {
        maxFreePerWallet = amount;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
        if (publicM) {
            publicM = !publicM;
        }
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
        if (presaleM) {
            presaleM = !presaleM;
        }
    }

    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }
    
    function setBaseURI(string calldata uri_) external onlyOwner {
        _uri = uri_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setMerkleRoot(bytes32 merkleroot) external onlyOwner {
        root = merkleroot;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function devMint(uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addrs, uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount * addrs.length) <= maxSupply, "NOT_ENOUGH_TOKENS");

        for (uint i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], amount);
        }
    }

    function presaleMint(address account, uint256 amount, bytes32[] calldata _proof) external payable isValidMerkleProof(_proof) {
        require(msg.sender == account, "ACCOUNT_NOT_ALLOWED");
        require(amount > 0, "AMOUNT_ERROR!");
        require(!paused, "SALE_NOT_ACTIVE!");
        require(presaleM, "SALE_NOT_ACTIVE!");
        require(tx.origin == msg.sender, "NOT_ALLOW_CONTRACT_CALL!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        if (freeMinted[msg.sender] + amount <= maxFreePerWallet && freeMintCount + amount <= maxFreeMintCount) {
            // free mint
            freeMintCount += amount;
            _safeMint(msg.sender, amount);
            freeMinted[msg.sender] += amount;
        } else {
            require(feeMinted[msg.sender] + amount <= maxFeeMintPerWallet, "OUT_OF_MAX_PER_WALLET");
            require(amount * price <= msg.value, "NOT_ENOUGH_MONEY!");
            _safeMint(msg.sender, amount);
            feeMinted[msg.sender] += amount;
        }
    }

    function mint(uint256 amount) external payable {
        require(amount > 0, "AMOUNT_ERROR!");
        require(!paused, "SALE_NOT_ACTIVE!");
        require(publicM, "SALE_NOT_ACTIVE!");
        require(tx.origin == msg.sender, "NOT_ALLOW_CONTRACT_CALL!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        if (freeMinted[msg.sender] + amount <= maxFreePerWallet && freeMintCount + amount <= maxFreeMintCount) {
            // free mint
            freeMintCount += amount;
            _safeMint(msg.sender, amount);
            freeMinted[msg.sender] += amount;
        } else {
            require(feeMinted[msg.sender] + amount <= maxFeeMintPerWallet, "OUT_OF_MAX_PER_WALLET");
            require(amount * price <= msg.value, "NOT_ENOUGH_MONEY!");
            _safeMint(msg.sender, amount);
            feeMinted[msg.sender] += amount;
        }
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }
}
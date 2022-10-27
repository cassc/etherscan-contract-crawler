// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ELEMENTS is Ownable, ERC721A, ReentrancyGuard {
    // Total Supply is 5555
    uint256 public maxSupply = 5155;
    uint256 public freeSupply = 400;

    bool public paused = true;
    bool public presalePaused = true;
    bool public freesalePaused = true;
    string public baseURI;

    address private teamWallet = 0xc00fCD5e5c7D931b1d42b84bf9292b2D28B9Aec5;
    uint256 private maxTeamMint = 200;
    uint256 private teamSupply = 0;

    // Merkle roots for verifying WL and holder status
    bytes32 public merkleRootFree = 0x20fd7415716a377deebe741ae8196a030846fb7b928a064d1d1b33d8f070e7db;
    bytes32 public merkleRootWL = 0x6be4fe536121f862391d7774a3492e605916b5b34b1627e1704a64e862620d6f;

    // For checking minted per wallet
    mapping(address => uint) public mintedWL;
    mapping(address => uint) public mintedFree;

    uint[] public pricesWL = [0.029 ether, 0.026 ether, 0.023 ether, 0.021 ether, 0.019 ether, 0.017 ether, 0.015 ether, 0.013 ether, 0.011 ether, 0.010 ether, 0];
    uint[] public pricesPublic = [0.039 ether, 0.035 ether, 0.032 ether, 0.029 ether, 0.026 ether, 0.023 ether, 0.021 ether, 0.019 ether, 0.017 ether, 0.015 ether, 0];

    constructor() ERC721A('THE ELEMENTS', 'ELBAE') { }

    /** MINTING FUNCTIONS */

    /**
     * @dev Allows you to mint 11 tokens per transaction in public sale
     */
    function mint(uint _mintAmount) public nonReentrant payable {
        // Checks if wallet has minted
        require(tx.origin == _msgSender(), "Only EOA");
        require(_mintAmount <= 11, "No more than 11 per tx.");

        require(!paused, "Public sale is paused.");
        require(totalSupply() + _mintAmount <= maxSupply, "Not enough mints left.");

        require(msg.value >= getPricePublic(_mintAmount), "Not enough ether");
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * @dev Presale mint function, you can mint 11 per whitelisted wallet
     */
    function mintPresale(bytes32[] calldata _merkleProof, uint _mintAmount) public nonReentrant payable {
        // Checks if wallet has minted
        require(tx.origin == _msgSender(), "Only EOA");
        require(_mintAmount <= 11, "No more than 11 per tx.");  
        require(mintedWL[msg.sender] + _mintAmount <= 11, "Max number of WL mints reached!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // Check MerkleProofs to verify if on WL
        if(MerkleProof.verify(_merkleProof, merkleRootWL, leaf)) {
            require(!presalePaused, "Presale is paused");
            require(totalSupply() + _mintAmount <= maxSupply, "Not enough mints left.");

            require(msg.value >= getPriceWL(_mintAmount), "Not enough ether");
            
            mintedWL[msg.sender] += _mintAmount;
            _safeMint(msg.sender, _mintAmount);
        } else {
            revert();
        }
    }

    /**
     * @dev Free mint function, you can mint 1 per wallet on list
     */
    function mintFree(bytes32[] calldata _merkleProof) public nonReentrant payable {
        // Checks if wallet has minted
        require(tx.origin == _msgSender(), "Only EOA");
        require(mintedFree[msg.sender] + 1 <= 1, "Max number of free mints reached!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // Check MerkleProofs to verify if on WL
        if(MerkleProof.verify(_merkleProof, merkleRootFree, leaf)) {
            require(!freesalePaused, "Free sale is paused");
            require(totalSupply() + 1 <= maxSupply + freeSupply, "Not enough mints left.");
            
            mintedFree[msg.sender] += 1;
            _safeMint(msg.sender, 1);
        } else {
            revert();
        }
    }

    function getPriceWL(uint _amount) public view returns (uint) {
        uint price = 0;
        for(uint i = 0; i < _amount; i++) {
            price += pricesWL[i];
        }
        return price;
    }

    function getPricePublic(uint _amount) public view returns (uint) {
        uint price = 0;
        for(uint i = 0; i < _amount; i++) {
            price += pricesPublic[i];
        }
        return price;
    }

    /**
     * @dev Allows team to mint 50 at a time straight to team wallet
     */
    function teamMint() public onlyOwner {
        require(totalSupply() + 50 <= maxSupply, "No enough mints left.");
        require(teamSupply + 50 <= maxTeamMint, "No enough team mints left.");

        _safeMint(teamWallet, 50);
        teamSupply = teamSupply + 50;
    }

    /**
     * @dev Allows team to mint remaining free tokens (or remaining public tokens)
     */
    function mintRemaining() public onlyOwner {
        uint leftoverFree = maxSupply + freeSupply - totalSupply();
        _safeMint(teamWallet, leftoverFree);
    }

    /**
     * Functions to set MerkleRoots, paused states and uri strings
     */
    function setMerkleRootFree(bytes32 merkleRoot_) public onlyOwner {
        merkleRootFree = merkleRoot_;
    }

    function setMerkleRootWL(bytes32 merkleRoot_) public onlyOwner {
        merkleRootWL = merkleRoot_;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPresalePause(bool _state) public onlyOwner {
        presalePaused = _state;
    }

    function setFreesalePause(bool _state) public onlyOwner {
        freesalePaused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
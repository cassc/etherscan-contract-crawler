// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IMinter {
    function whitelistOnly() external view returns (bool);
    function mintStarted() external view returns (bool);
}

contract GenesisCollection is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    bytes32 public merkleRoot;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant TOTAL_SUPPLY = 9_724;
    uint256 public constant MAX_MINT_PER_WALLET = 5;

    // Authorized contract to mint tokens
    IMinter MinterContract;

    string private baseTokenURI;
    string private placeholderTokenURI;
    uint256 public mintPrice = 0.08 ether;
    bool _preminted;
    bool public revealed;
    mapping (address => uint256) _mintsPerWallet;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _placeholderTokenURI
    ) ERC721(_name, _symbol) {
        placeholderTokenURI = _placeholderTokenURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setCost(uint256 newCost) public onlyRole(MINTER_ROLE) {
        require(newCost > 0, "Cost must be greater than 0 eth");
        mintPrice = newCost;
    }

    function setMerkleRoot(bytes32 root) public onlyRole(MINTER_ROLE) {
        merkleRoot = root;
    }

    function setMinterContract(address contractAddress) public onlyRole(MINTER_ROLE) {
        MinterContract = IMinter(contractAddress);
    }

    function setPlaceholderUri(string memory _newUri) public onlyRole(MINTER_ROLE) {
        placeholderTokenURI = _newUri;
    }

    function setBaseTokenUri(string memory _newUri) public onlyRole(MINTER_ROLE) {
        baseTokenURI = _newUri;
    }

    function toggleReveal() public onlyRole(MINTER_ROLE) {
        revealed = !revealed;
    }

    function mintEnded() public view returns (bool) {
        return _tokenIdCounter.current() == TOTAL_SUPPLY;
    }

    function checkToken(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function premint(uint256 premintCount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_preminted, "Already preminted");
        for (uint256 i = 1; i <= premintCount; i++) {
            _safeMint(msg.sender, i);
        }
        _preminted = true;
        _tokenIdCounter._value = premintCount;
    }

    function whitelistMint(uint256 mintCount, bytes32[] calldata proof) public payable {
        require(MinterContract.mintStarted(), "Mint not started yet");
        require(MinterContract.whitelistOnly(), "Method can only be used during early mint");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "User is not whitelisted");

        require(mintCount > 0, "Invalid mint count");
        require(_tokenIdCounter.current() + mintCount <= TOTAL_SUPPLY, "Requested mint count exceeds supply");
        require(msg.value >= mintCount * mintPrice, "Transaction value did not meet mint price");
        uint256 currentMints = _mintsPerWallet[msg.sender];
        require(currentMints < MAX_MINT_PER_WALLET, "Already minted the max allowed");
        require(currentMints + mintCount <= MAX_MINT_PER_WALLET, "Requested mint count exceeds max allowed");

        for (uint256 i = 0; i < mintCount; i++) {    
            _tokenIdCounter.increment();
            _mintsPerWallet[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function mint(uint256 mintCount) public payable {
        require(MinterContract.mintStarted(), "Mint not started yet");

        require(mintCount > 0, "Invalid mint count");
        require(_tokenIdCounter.current() + mintCount <= TOTAL_SUPPLY, "Requested mint count exceeds supply");
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            require(!MinterContract.whitelistOnly(), "Whitelist mint only");
            require(msg.value >= mintCount * mintPrice, "Transaction value did not meet mint price");
            uint256 currentMints = _mintsPerWallet[msg.sender];
            require(currentMints < MAX_MINT_PER_WALLET, "Already minted the max allowed");
            require(currentMints + mintCount <= MAX_MINT_PER_WALLET, "Requested mint count exceeds max allowed");
        }

        for (uint256 i = 0; i < mintCount; i++) {    
            _tokenIdCounter.increment();
            _mintsPerWallet[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(baseTokenURI).length > 0 && revealed
            ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"))
            : string(abi.encodePacked(placeholderTokenURI, tokenId.toString(), ".json"));
    }
}
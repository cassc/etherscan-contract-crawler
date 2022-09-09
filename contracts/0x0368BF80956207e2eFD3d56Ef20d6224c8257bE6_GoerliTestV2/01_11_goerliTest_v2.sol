// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721ACustom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GoerliTestV2 is ERC721A, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    bytes32 public whitelistMerkleRoot;

    string public baseURI;
    address private treasury;
    address private airdrop1;
    address private airdrop2;
    address private airdrop3;

    mapping(address => bool) public adminAddresses;
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicClaimed;

    modifier onlyAdminOrOwner() {
        bool isAdmin = false;
        if (adminAddresses[msg.sender] == true) {
            isAdmin = true;
        }
        if (msg.sender == owner()) {
            isAdmin = true;
        }
        require(isAdmin == true, "Not an admin");
        _;
    }

    struct SaleConfig {
        bool presaleActive;
        bool publicSaleActive;
        uint256 whitelistPrice;
        uint256 price;
        uint256 maxSupply;
        uint256 maxPublicMint;
        uint256 maxWhitelistMint;
    }
    SaleConfig public saleConfig;

    constructor(
        uint256 _maxSupply,
        uint256 _maxPublicMint,
        uint256 _maxWhitelistMint,
        bool _presaleActive,
        bool _publicSaleActive,
        bytes32 _wlMerkleRoot,
        address _treasury,
        address _airdrop1,
        address _airdrop2,
        address _airdrop3
    ) payable ERC721A("goerliTestV2", "goerliTestV2") {
        saleConfig.maxSupply = _maxSupply;
        saleConfig.price = 0.04 ether;
        saleConfig.whitelistPrice = 0.036 ether;
        saleConfig.presaleActive = _presaleActive;
        saleConfig.publicSaleActive = _publicSaleActive;
        saleConfig.maxPublicMint = _maxPublicMint;
        saleConfig.maxWhitelistMint = _maxWhitelistMint;
        whitelistMerkleRoot = _wlMerkleRoot;
        treasury = _treasury;
        airdrop1 = _airdrop1;
        airdrop2 = _airdrop2;
        airdrop3 = _airdrop3;
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(saleConfig.presaleActive == true, "Presale inactive");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Not whitelisted"
        );
        require(
            whitelistClaimed[msg.sender] + _amount <=
                saleConfig.maxWhitelistMint,
            "Whitelist mint exceeded"
        );

        require(
            msg.value >= _amount * saleConfig.whitelistPrice,
            "Insufficient funds"
        );
        require(
            totalSupply() + _amount <= saleConfig.maxSupply,
            "Cannot mint more than max supply"
        );

        payable(treasury).transfer(msg.value);
        unchecked {
            whitelistClaimed[msg.sender] += _amount;
        }
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(saleConfig.publicSaleActive == true, "Public sale inactive");
        require(
            totalSupply() + _amount <= saleConfig.maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            msg.value >= (saleConfig.price * _amount),
            "Insufficient funds"
        );
        require(
            publicClaimed[msg.sender] + _amount <= saleConfig.maxPublicMint,
            "Mint exceeds max mint per address"
        );

        payable(treasury).transfer(msg.value);
        unchecked {
            publicClaimed[msg.sender] += _amount;
        }
        _safeMint(msg.sender, _amount);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
            "ERC721Metadata: URI query for nonexistant token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    // ---------------------------------Admin functions-------------------------------------

    function setAdminAddresses(address[] calldata _wallets)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = true;
        }
    }

    function removeAdminAddresses(address[] calldata _wallets)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = false;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdminOrOwner {
        baseURI = _newBaseURI;
    }

    ///@notice input new price in gwei
    function setPrice(uint256 _newPrice) external onlyAdminOrOwner {
        saleConfig.price = _newPrice;
    }

    ///@notice input new price in gwei
    function setPreSalePrice(uint256 _newPrice) external onlyAdminOrOwner {
        saleConfig.whitelistPrice = _newPrice;
    }

    function burnToken(uint256 _tokenId) external onlyAdminOrOwner {
        address owner = ERC721A.ownerOf(_tokenId);
        require(owner == msg.sender, "Not the owner of this token");
        super._burn(_tokenId);
    }

    function mintTreasury(uint256 _treasuryAmount, uint256 _airdrop1Amount, uint256 _airdrop2Amount, uint256 _airdrop3Amount) public onlyAdminOrOwner {
        _safeMint(treasury, _treasuryAmount);
        _safeMint(airdrop1, _airdrop1Amount);
        _safeMint(airdrop2, _airdrop2Amount);
        _safeMint(airdrop3, _airdrop3Amount);
    }

    function pauseContract() public onlyAdminOrOwner {
        _pause();
    }

    function unpauseContract() public onlyAdminOrOwner {
        _unpause();
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyAdminOrOwner {
        saleConfig.maxSupply = _newMaxSupply;
    }

    function setPublicSale(bool _status) external onlyAdminOrOwner {
        saleConfig.publicSaleActive = _status;
    }

    function activatePreSale(uint256 _treasuryAmount, uint256 _airdrop1Amount, uint256 _airdrop2Amount, uint256 _airdrop3Amount) external onlyAdminOrOwner {
        setPreSale(true);
        mintTreasury(_treasuryAmount, _airdrop1Amount, _airdrop2Amount, _airdrop3Amount);
    }

    function setPreSale(bool _status) public onlyAdminOrOwner {
        saleConfig.presaleActive = _status;
    }

    function switchToPublicPhase() external onlyAdminOrOwner {
        saleConfig.presaleActive = false;
        saleConfig.publicSaleActive = true;
    }

    function setWhitelistMerkleRoot(bytes32 _newWhitelistMerkleRoot)
        external
        onlyAdminOrOwner
    {
        whitelistMerkleRoot = _newWhitelistMerkleRoot;
    }

    function setTreasuryAddress(address _treasury) external onlyAdminOrOwner {
        treasury = _treasury;
    }
    function setAirdrop1Address(address _airdrop1) external onlyAdminOrOwner {
        airdrop1 = _airdrop1;
    }
    function setAirdrop2Address(address _airdrop2) external onlyAdminOrOwner {
        airdrop2 = _airdrop2;
    }
    function setAirdrop3Address(address _airdrop3) external onlyAdminOrOwner {
        airdrop3 = _airdrop3;
    }
}
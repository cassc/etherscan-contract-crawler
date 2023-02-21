// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FortuneBunny is ERC721A, Ownable {
    uint256 public MAXSUPPLY = 1888;
    uint256 public MAXTOKENPERMINT = 2;
    uint256 public price = 0.02 ether;

    bytes32 public merkleRoot;
    uint256 public whitelistMaxAmount = 1;
    bool public whitelistStatus = false;
    bool public publicStatus = false;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    event Withdraw(address indexed account, uint256 amount);
    event WhitelistMinted(address indexed account, uint256 amount);
    event PublicMinted(
        address indexed minter,
        address indexed receiver,
        uint256 amount
    );
    event AdminMinted(address indexed account, uint256 amount);

    constructor(string memory _baseuri, bytes32 _root)
        ERC721A("FortuneBunny", "FB")
    {
        merkleRoot = _root;
        uriPrefix = _baseuri;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _price) {
        require(msg.value >= _price * _mintAmount, "Insufficient funds");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= MAXTOKENPERMINT,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= MAXSUPPLY,
            "Max supply exceeded"
        );
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "The caller is contract");
        _;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice whitelist mint function
     * @param _merkleProof merkle proof for msg.sender
     * @param _mintAmount number of token to mint
     */
    function whitelistMint(uint64 _mintAmount, bytes32[] calldata _merkleProof)
        external
        onlyEOA
    {
        require(_mintAmount==1, "Invalid mint amount");
        require(whitelistStatus, "The whitelist sale is not enabled");
        uint64 whitelistMinted = _getAux(_msgSender()) + _mintAmount;
        require(
            whitelistMinted <= whitelistMaxAmount,
            "Address already claimed all whitelist mint"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        _setAux(_msgSender(), whitelistMinted);
        _safeMint(_msgSender(), _mintAmount);
        
        emit WhitelistMinted(_msgSender(), _mintAmount);
    }

    /**
     * @notice public sale mint function
     * @param quantity number of tokens to mint
     */
    function publicMint(uint64 quantity)
        external
        payable
        mintPriceCompliance(quantity, price)
        mintCompliance(quantity)
        onlyEOA
    {
        require(publicStatus, "The public sale is not enabled");
        uint64 publicMinted = _getAux(_msgSender()) + quantity;
        require(
            publicMinted <= MAXTOKENPERMINT,
            "Address already claimed all public mint"
        );
        _setAux(_msgSender(), publicMinted);
        _safeMint(_msgSender() , quantity);
        emit PublicMinted(_msgSender(), _msgSender(), quantity);
    }

    /**
     * @notice admin mint to specific address
     * @param to address to receive nft
     * @param quantity number of tokens to mint
     */
    function adminMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAXSUPPLY, "Max supply exceeded");
        _safeMint(to, quantity);
        emit AdminMinted(to, quantity);
    }

    /***********************************|
    |             Setter                |
    |__________________________________*/

    /**
     * @notice set the base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        uriPrefix = _baseURI;
    }

    /**
     * @notice set the merkle proof root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice set the whitelist status
     */
    function setWhitelistMintEnabled(bool _state) external onlyOwner {
        whitelistStatus = _state;
    }

    /**
     * @notice set the public status
     */
    function setPublicMintEnabled(bool _state) external onlyOwner {
        publicStatus = _state;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(abi.encodePacked(uriPrefix, _toString(_tokenId), uriSuffix));
    }

    /**
     * @notice withdraw the fund, only owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_msgSender()).call{value: balance}("");
        require(success, "Withdraw failed");
        emit Withdraw(_msgSender(), balance);
    }
}
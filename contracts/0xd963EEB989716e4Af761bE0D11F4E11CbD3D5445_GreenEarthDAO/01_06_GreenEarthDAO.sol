// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GreenEarthDAO is ERC721A, Ownable {
    uint256 public MintSupply = 1440;
    uint256 public MAXTOKENPERMINT = 5;
    uint256 public wlPrice = 0.08 ether;
    uint256 public price = 0.18 ether;

    bytes32 public merkleRoot= 0x1dc3e53aa8701fd1c6fc0eee763482fcff0feba6440e0d39107f22df1118ef6b;
    uint256 public whitelistMaxAmount = 5;
    bool public whitelistStatus = false;
    bool public publicStatus = false;

    string public uriPrefix = "ar://tdjPL-xTz3_h-Y66PtdVUiDKL0ggrWnzMLTyb0RR5zM/json/";
    string public uriSuffix = ".json";


    event Withdraw(address indexed account, uint256 amount);
    event WhitelistStatusChange(bool _old, bool _new);
    event WhitelistMinted(address indexed account, uint256 amount);
    event PublicMinted(
        address indexed minter,
        address indexed receiver,
        uint256 amount
    );
    event AdminMinted(address indexed account, uint256 amount);
    event MerkleRootChange(bytes32 _old, bytes32 _new);
    event SetBaseURI(string _old, string _new);
    event Received(address caller,uint amount,string message);

    constructor() ERC721A("GreenEarthDAO", "EARTHDAO"){}

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
            totalSupply() + _mintAmount <= MintSupply,
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
        payable
        onlyEOA
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount, wlPrice)
    {
        require(whitelistStatus, "The whitelist sale is not enabled");
        uint64 whitelistMinted = _getAux(_msgSender()) + _mintAmount;
        require(
            whitelistMinted <= whitelistMaxAmount,
            "Address already claimed"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        _safeMint(_msgSender(), _mintAmount);
        _setAux(_msgSender(), whitelistMinted);
        emit WhitelistMinted(_msgSender(), _mintAmount);
    }

    /**
     * @notice public sale mint function
     * @param to address to receive nft
     * @param quantity number of tokens to mint
     */
    function publicMint(address to, uint256 quantity)
        external
        payable
        mintPriceCompliance(quantity, price)
        mintCompliance(quantity)
        onlyEOA
    {
        require(publicStatus, "The public sale is not enabled");
        _safeMint(to, quantity);
        emit PublicMinted(_msgSender(), to, quantity);
    }

    /**
     * @notice admin mint to specific address
     * @param to address to receive nft
     * @param quantity number of tokens to mint
     */
    function adminMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MintSupply, "Max supply exceeded");
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
        string memory _old = uriPrefix;
        uriPrefix = _baseURI;
        emit SetBaseURI(_old, _baseURI);
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        wlPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMintSupply(uint256 _supply) external onlyOwner {
        MintSupply = _supply;
    }


    /**
     * @notice set the merkle proof root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        bytes32 _old = merkleRoot;
        merkleRoot = _merkleRoot;
        emit MerkleRootChange(_old, _merkleRoot);
    }

    /**
     * @notice set the whitelist status
     */
    function setWhitelistMintEnabled(bool _state) external onlyOwner {
        bool _old = whitelistStatus;
        whitelistStatus = _state;
        emit WhitelistStatusChange(_old, _state);
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
        (bool success, ) = payable(0x37eAB6100016E6527629B13488e85eFD8773F620).call{value: balance}("");
        require(success, "Withdraw failed");
        emit Withdraw(_msgSender(), balance);
    }

    function transferToken(address token, address to, uint256 amount) external onlyOwner {
        ITOKEN(token).transfer(to, amount);
    }

    fallback() external payable{
        emit Received(msg.sender, msg.value,"fallback was called");
    }

    receive() external payable{
        emit Received(msg.sender, msg.value,"receive was called");
    }


}

interface ITOKEN{
    function transfer(address to, uint256 amount) external;
}
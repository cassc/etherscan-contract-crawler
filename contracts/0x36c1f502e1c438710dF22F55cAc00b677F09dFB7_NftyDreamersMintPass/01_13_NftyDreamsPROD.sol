// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NftyDreamersMintPass is ERC1155, Ownable {
    string private _name;
    string private _symbol;
    string private _merkleTreeInputURI;
    bytes32 private _merkleRoot;

    uint256 public _price;
    uint256 public _currentSupply;
    uint256 public _reservesMinted;
    uint256 public _reserveSupply = 500;
    uint256 public _maxSupplyLimit = 9500;
    uint256 public _totalSupply = 10000;
    uint256 public _maxPerWallet = 5;
    uint256 public _maxTermLimit = 5;
    bool public _isAllowListSaleActive = false;
    bool public _isPublicSaleActive = false;

    mapping(uint256 => string) public tokenURI;
    mapping(address => uint256) public minted;
    
    event AllowListSaleMinted(address indexed to, uint256 indexed term, uint256 amount);
    event PublicSaleMinted(address indexed to, uint256 indexed term, uint256 amount);
    event ReservesMinted(address indexed to, uint256 indexed term, uint256 amount);

    constructor() ERC1155("ipfs://ipfs/") {
        _name = "NftyDreams DAO Dreamers";
        _symbol = "NDDD";
        _price = 0.015 ether;
    }

    modifier mintCheck(
        uint256 term,
        uint256 amount,
        uint256 value
    ) {
        require(
            term <= _maxTermLimit,
            "Exceeding max term limit [max 5 terms]"
        );
        require(
            minted[msg.sender] + amount <= _maxPerWallet,
            "Exceeding max mint limit [max 5 per wallet]"
        );
        require(
            _currentSupply + amount <= _maxSupplyLimit + _reservesMinted,
            "Exceeding max supply limit [total - 9,500 + 500 (reserve)]"
        );
        require(
            value == (amount * term) * _price,
            "Ether value sent is incorrect"
        );
        _;
    }

    function mintPublic(uint256 term, uint256 amount)
        external
        payable
        mintCheck(term, amount, msg.value)
    {
        require(_isPublicSaleActive == true, "Public Sale not active");
        minted[msg.sender] += amount;
        _currentSupply += amount;
        _mint(msg.sender, term, amount, "");
        emit PublicSaleMinted(msg.sender, term, amount);
    }

    function mintAllowList(
        uint256 term,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable mintCheck(term, amount, msg.value) {
        require(_isAllowListSaleActive == true, "AllowList Sale not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            _checkEligibility(_merkleRoot, merkleProof, leaf) == true,
            "Address not eligible / Invalid merkle proof"
        );

        minted[msg.sender] += amount;
        _currentSupply += amount;
        _mint(msg.sender, term, amount, "");
        emit AllowListSaleMinted(msg.sender, term, amount);
    }

    function mintReserves(address to, uint256 term, uint256 amount)
        external
        onlyOwner
    {
        require(
            _reservesMinted + amount <= _reserveSupply,
            "Exceeding max reserve supply (max 500 tokens)"
        );
        minted[msg.sender] += amount;
        _reservesMinted += amount;
        _currentSupply += amount;
        _mint(to, term, amount, "");
        emit ReservesMinted(msg.sender, term, amount);
    }

    function checkAllowlistEligibility(
        address walletAddress,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(walletAddress));
        bool eligibility = _checkEligibility(_merkleRoot, merkleProof, leaf);
        return eligibility;
    }

    function _checkEligibility(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        bytes32 leaf
    ) internal pure returns (bool) {
        return (MerkleProof.verify(merkleProof, merkleRoot, leaf));
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 id, string memory newURI) external onlyOwner {
        tokenURI[id] = newURI;
        emit URI(newURI, id);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokenURI[id];
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function setMerkleTreeInput(string memory merkleTreeInput) external onlyOwner {
        _merkleTreeInputURI = merkleTreeInput;
    }

    function getMerkleTreeInput() external view returns (string memory) {
        return _merkleTreeInputURI;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setWalletLimit(uint256 limit) external onlyOwner {
        _maxPerWallet = limit;
    }

    function setSaleStatus(bool publicSale, bool allowListSale)
        external
        onlyOwner
    {
        _isPublicSaleActive = publicSale;
        _isAllowListSaleActive = allowListSale;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function withdrawFunds() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(IERC20 tokenContract, address to) external onlyOwner {
        tokenContract.transfer(to, tokenContract.balanceOf(address(this)));
    }
}
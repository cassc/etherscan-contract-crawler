// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A_royalty.sol";

contract SpectrumPepes is Ownable, ERC721A {
    using Strings for uint256;

    bool public SaleActive = false;
    bool public WhitelistSaleActive = false;
    bool public SpecialWhitelistSaleActive = false;

    string public baseURI;
    string public unrevealedURI =
        "ipfs://QmRUpjXHJH738kCvKMjXTyqCtG39YPCysQkw4Xert6MuqP/unrevealed.json";
    bool public revealed = false;

    uint256 public MAX_SUPPLY = 6900;
    uint256 public MAX_TOTAL_PUBLIC = 6900;
    uint256 public MAX_TOTAL_SPECIAL_WL = 6900;
    uint256 public MAX_TOTAL_WL = 6900;

    uint256 public MAX_PER_WALLET_PUBLIC = 25;
    uint256 public MAX_PER_WALLET_SPECIAL_WL = 1;
    uint256 public MAX_PER_WALLET_WL = 5;

    uint256 public wlSalePrice = 0 ether;
    uint256 public specialwlSalePrice = 0 ether;
    uint256 public publicSalePrice = 0.04 ether;

    bytes32 public merkleRootWL;
    bytes32 public merkleRootSpecialWL;

    mapping(address => uint256) public amountNFTsperWalletPUBLIC;
    mapping(address => uint256) public amountNFTsperWalletWL;
    mapping(address => uint256) public amountNFTsperWalletSpecialWL;

    address public withdrawalWallet;

    uint96 royaltyFeesInBips;
    address royaltyReceiver;

    constructor(
        uint96 _royaltyFeesInBips,
        bytes32 _merkleRootWL,
        bytes32 _merkleRootSpecialWL,
        address _withdrawalWallet,
        string memory _baseURI
    ) ERC721A("SpectrumPepes", "SPECTRUM") {
        merkleRootWL = _merkleRootWL;
        merkleRootSpecialWL = _merkleRootSpecialWL;
        baseURI = _baseURI;
        royaltyFeesInBips = _royaltyFeesInBips;
        royaltyReceiver = msg.sender;
        withdrawalWallet = _withdrawalWallet;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function specialwhitelistMint(
        address _account,
        uint256 _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        uint256 price = specialwlSalePrice;
        require(
            SpecialWhitelistSaleActive == true,
            "Whitelist sale is not activated"
        );
        require(msg.sender == _account, "Mint with your own wallet.");
        require(isSpecialWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNFTsperWalletSpecialWL[msg.sender] + _quantity <=
                MAX_PER_WALLET_SPECIAL_WL,
            "Max per wallet limit reached"
        );
        require(
            totalSupply() + _quantity <= MAX_TOTAL_SPECIAL_WL,
            "Max supply exceeded"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletSpecialWL[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function whitelistMint(
        address _account,
        uint256 _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        uint256 price = wlSalePrice;
        require(WhitelistSaleActive == true, "Whitelist sale is not activated");
        require(msg.sender == _account, "Mint with your own wallet.");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNFTsperWalletWL[msg.sender] + _quantity <= MAX_PER_WALLET_WL,
            "Max per wallet limit reached"
        );
        require(
            totalSupply() + _quantity <= MAX_TOTAL_WL,
            "Max supply exceeded"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWL[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(msg.sender == _account, "Mint with your own wallet.");
        require(SaleActive == true, "Public sale is not activated");
        require(
            totalSupply() + _quantity <= MAX_TOTAL_PUBLIC,
            "Max supply exceeded"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(
            amountNFTsperWalletPUBLIC[msg.sender] + _quantity <=
                MAX_PER_WALLET_PUBLIC,
            "Max per wallet limit reached"
        );
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPUBLIC[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function lowerSupply(uint256 _MAX_SUPPLY) external onlyOwner {
        require(_MAX_SUPPLY < MAX_SUPPLY, "Cannot increase supply!");
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMaxTotalPUBLIC(uint256 _MAX_TOTAL_PUBLIC) external onlyOwner {
        MAX_TOTAL_PUBLIC = _MAX_TOTAL_PUBLIC;
    }

    function setMaxTotalWL(uint256 _MAX_TOTAL_WL) external onlyOwner {
        MAX_TOTAL_WL = _MAX_TOTAL_WL;
    }

    function setMaxTotalSpecialWL(uint256 _MAX_TOTAL_SPECIAL_WL) external onlyOwner {
        MAX_TOTAL_SPECIAL_WL = _MAX_TOTAL_SPECIAL_WL;
    }

    function setMaxPerWalletWL(uint256 _MAX_PER_WALLET_WL) external onlyOwner {
        MAX_PER_WALLET_WL = _MAX_PER_WALLET_WL;
    }

    function setMaxPerWalletSpecialWL(uint256 _MAX_PER_WALLET_SPECIAL_WL)
        external
        onlyOwner
    {
        MAX_PER_WALLET_SPECIAL_WL = _MAX_PER_WALLET_SPECIAL_WL;
    }

    function setMaxPerWalletPUBLIC(uint256 _MAX_PER_WALLET_PUBLIC)
        external
        onlyOwner
    {
        MAX_PER_WALLET_PUBLIC = _MAX_PER_WALLET_PUBLIC;
    }

    function setWLSalePrice(uint256 _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    function setSpecialWLSalePrice(uint256 _specialwlSalePrice)
        external
        onlyOwner
    {
        specialwlSalePrice = _specialwlSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function toggleSaleActive(bool _SaleActive) external onlyOwner {
        SaleActive = _SaleActive;
    }

    function toggleWhitelistSaleActive(bool _WhitelistSaleActive)
        external
        onlyOwner
    {
        WhitelistSaleActive = _WhitelistSaleActive;
    }

    function toggleSpecialWhitelistSaleActive(bool _SpecialWhitelistSaleActive)
        external
        onlyOwner
    {
        SpecialWhitelistSaleActive = _SpecialWhitelistSaleActive;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (revealed == false) {
            return (unrevealedURI);
        } else
            return
                string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    //Whitelist
    function setMerkleRootWL(bytes32 _merkleRootWL) external onlyOwner {
        merkleRootWL = _merkleRootWL;
    }
    function setMerkleRootSpecialWL(bytes32 _merkleRootSpecialWL) external onlyOwner {
        merkleRootSpecialWL = _merkleRootSpecialWL;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verifyWL(leaf(_account), _proof);
    }
     function isSpecialWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verifySpecialWL(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verifyWL(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRootWL, _leaf);
    }
    function _verifySpecialWL(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRootSpecialWL, _leaf);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyReceiver = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    // WITHDRAW
    function changeWithdrawalWallet(address _withdrawalWallet)
        external
        onlyOwner
    {
        withdrawalWallet = _withdrawalWallet;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(withdrawalWallet).transfer(balance);
    }

    receive() external payable {
        revert("Only if you mint");
    }
}
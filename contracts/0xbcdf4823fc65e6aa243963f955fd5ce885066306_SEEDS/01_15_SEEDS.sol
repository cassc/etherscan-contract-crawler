// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract SEEDS is ERC721, ERC721Burnable, Pausable, Ownable {
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public unitPrice = 100000000000000000; //0.1 ether
    string public _defaultBaseURI;
    bytes32 private _presaleRoot;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public royaltyFee;
    address public royaltyWallet;

    mapping(address => uint) public accountToMintPreSale;

    // Switches
    bool private publicSaleActive;
    bool private preSaleActive;


    constructor(string memory _newBaseURI, bytes32 _pre) ERC721("SEEDS", "SEEDS") {
        setBaseURI(_newBaseURI);
        _presaleRoot = _pre;
    }

    function _baseURI() internal view override returns (string memory) {
        return _defaultBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _defaultBaseURI = _newBaseURI;
    }

    function setPresaleMintHash(bytes32 _root) external onlyOwner {
        _presaleRoot = _root;
    }

    function startPreSale(uint256 _unitPrice) external onlyOwner
    {
        require(!preSaleActive, "Private Sale Started already");
        unitPrice = _unitPrice;
        preSaleActive = true;
    }

    function pausePreSale() external onlyOwner {
        require(preSaleActive, "Private Sale not active");
        preSaleActive = false;
    }

    function startSale(uint256 _unitPrice) external onlyOwner
    {
        require(!publicSaleActive, "Started already");
        unitPrice = _unitPrice;
        publicSaleActive = true;
    }

    function pauseSale() external onlyOwner {
        require(publicSaleActive, "Sale not active");
        publicSaleActive = false;
    }

    function safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32 root, bytes32[] memory proof)
    internal pure returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function presaleMint(uint256 numTokens, bytes32[] calldata proof) external payable
    {
        require(preSaleActive, "Presale not active");
        require((totalSupply() + numTokens) <= MAX_TOKENS, "Exceed Max Supply");
        require(unitPrice * numTokens <= msg.value, "Not Enough Ether");
        require(_verify(_leaf(msg.sender), _presaleRoot, proof), "Invalid address for presale mint");

        for (uint256 i = 0; i < numTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function mintInternal(address to, uint256 numTokens) external onlyOwner {
        require((totalSupply() + numTokens) <= MAX_TOKENS, "Exceed Max Supply");
        for (uint256 i = 0; i < numTokens; i++) {
            safeMint(to);
        }
    }

    function mint(uint256 numTokens) external payable {
        require(publicSaleActive, "Sale not active");
        require(numTokens > 0 && numTokens <= 20, "Invalid Number of Tokens");
        require(unitPrice * numTokens <= msg.value, "Not Enough Ether");
        require((totalSupply() + numTokens) <= MAX_TOKENS, "Exceed Max Supply");

        for (uint256 i = 0; i < numTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }


    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256)
    {
        return (royaltyWallet, (value * royaltyFee) / 10000);
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(value <= 10000, "INVALID Royalties");
        require(recipient != address(0), "BLACKHOLE WALLET");
        royaltyWallet = recipient;
        royaltyFee = value;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
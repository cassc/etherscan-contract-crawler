// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BGCCSupporter is ERC1155, DefaultOperatorFilterer, EIP712, Ownable {
    using SafeMath for uint256;

    using Counters for Counters.Counter;

    string private constant SIGNING_DOMAIN = "BGCCSUPPORTER";
    string private constant SIGNATURE_VERSION = "1";

    mapping(uint256 => string) private _uris;
    mapping (string => bool) public redeemed;
    mapping(bytes32 => bool) private signaturesUsed;
    uint256 public totalTokens; 
    uint256 public maxPerToken = 100; 
    uint256 public maxPerMint = 5; 
    address public signatureSigner = 0x0eD61e354A47FEB7016Af01d2C39FDB93cef7f4B;
    uint256 public mintPrice;
    mapping(uint256 => uint256) public tokenMinted;
    Counters.Counter private _countTracker;
    string public name;
    string public symbol;
    address public multiSigOwner;

 
    constructor(
        string memory _name, 
        string memory _symbol, 
        address _multiSigOwner
    ) ERC1155("") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        name = _name;
        symbol = _symbol;
        setMultiSig(_multiSigOwner);
    }


    function totalMinted() public view returns (uint256) {
        return _countTracker.current();
    }


    function setMultiSig(address _multiSig) public onlyOwner {
        multiSigOwner = _multiSig;
    }

    function setPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function getTokenSupply(uint256 tokenId) public view returns (uint256) {
        return maxPerToken - tokenMinted[tokenId];
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }

    function setTokenURI(uint256 tokenId, string memory tokenUri) public onlyOwner {
        _uris[tokenId] = tokenUri;
    }

    function generateToken(
        string memory tokenUri
    ) public onlyOwner {
        uint256 newID = totalTokens;
        setTokenURI(newID, tokenUri);
        totalTokens += 1;
        tokenMinted[newID] = 0;
        ownerMint(multiSigOwner, newID, 1);

    }

    function ownerMint(address _to, uint256 tokenId, uint256 _count) public onlyOwner {
        require(_count > 0, "Mint count should be greater than zero");
        uint256 availableTokens = maxPerToken - tokenMinted[tokenId];
        require(availableTokens >= _count, "Not Enough Tokens Supply");
        for (uint256 i = 0; i < _count; i++) {
            _mintOneItem(_to, tokenId);
        }
    }

    
    //the first 100 - Ownermint, 101 - 250 Allowlist, and then 251 - 400 is set Price 
    function mintAllowList(uint256 tokenId, string memory claimId, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public payable {
        uint256 availableTokens = maxPerToken - tokenMinted[tokenId];
        require(_countTracker.current() < 250, "Allow List Mint Closed");
        require(availableTokens >= 1, "Not Enough Tokens Supply");
        require(ecr(hash, v, r, s) == signatureSigner, "Signature invalid");
        require(!redeemed[claimId], "Already redeemed");
        require(!signaturesUsed[hash], "Hash Already Used");
        redeemed[claimId] = true;
        signaturesUsed[hash] = true;
        _mintOneItem(msg.sender, tokenId);
        
    }

   
    function mint(uint256 tokenId, uint256 _count) external payable {
        require(msg.value >= mintPrice * _count, "Insufficient funds");
        require(_count > 0, "Mint count should be greater than zero");
        require(maxPerMint >= _count, "Max Per Mint is 5");
        uint256 availableTokens = maxPerToken - tokenMinted[tokenId];
        require(availableTokens >= _count, "Not Enough Tokens Supply");

        for (uint256 i = 0; i < _count; i++) {
            _mintOneItem(msg.sender, tokenId);
        }

    }

   
    function _mintOneItem(address _to,  uint256 tokenId) private {
        _countTracker.increment();
        tokenMinted[tokenId]++;
        _mint(_to, tokenId, 1, "");
    }


    function ecr(bytes32 msgh, uint8 v, bytes32 r, bytes32 s) public pure
        returns (address sender) {
            return ecrecover(msgh, v, r, s);
        }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(multiSigOwner, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Transfer failed.");
    }


    //opensea functions
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
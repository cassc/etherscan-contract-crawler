// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Tooney
 * Tooney - a contract for my non-fungible Tooney.
 */
contract Tooney is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    event SetDiscountPercent(uint256 _percent);

    uint256 private maxSupply = 17312;
    
    uint public constant INIT_TOONEY_RESERVE = 112;
    uint public constant MAX_TOONEY_PURCHASE = 11;

    Counters.Counter private currentTokenId;

    bool public saleIsActive = false;
    uint256 public price = 0.07 ether;
    uint256 public discount = 10;
    uint256 internal constant HUNDRED_PERCENT = 100;

    string private baseTokenURI;
    address payable public payments;

    address factoryAddress;

    mapping(bytes => bool) public signatureUsed;

    constructor(string memory _baseTokenURI, address _payments)
        ERC721("Tooney", "TOONC")
    {
        payments = payable(_payments);
        setBaseURI(_baseTokenURI);
        reserveTooneys(INIT_TOONEY_RESERVE);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice; //convert new price into ether
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setMaxSupply(uint256 newSupplyLimit) public onlyOwner {
        maxSupply = newSupplyLimit;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    /**
     * @notice Set discount added
     * @param _percent Discount percent. 0 - 100
     * @dev Could only be invoked by the contract owner.
     */
    function setDiscount(uint256 _percent) external onlyOwner {
        require(
            _percent <= HUNDRED_PERCENT,
            "Discount cannot be more than 100%"
        );

        discount = _percent;
        emit SetDiscountPercent(_percent);
    }

    function getDiscount() public view returns (uint256) {
        return discount;
    }

    function preSale(
        address _purchaser,
        uint256 _count,
        bytes32 hash,
        bytes memory signature
    ) public payable nonReentrant {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not allowlisted"
        );
       
        uint256 totalMinted = totalSupply();
        require(
            totalMinted + _count <= getMaxSupply(),
            "Purchase would exceed max tokens !"
        );
        require(_count <= MAX_TOONEY_PURCHASE, "Can only mint 11 tokens at a time !");

        // apply discount for each purchase
        uint256 _price = price - ((price * discount) / HUNDRED_PERCENT);

        require(
            msg.value >= _price * _count,
            "Purchase value is not the minimum mint price !"
        );

        for (uint256 i = 0; i < _count; i++) {
            mintTo(_purchaser);
        }
        
        signatureUsed[signature] = true;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function purchase(address _purchaser, uint256 _count) public payable nonReentrant {
        uint256 totalMinted = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(
            totalMinted + _count <= getMaxSupply(),
            "Purchase would exceed max tokens"
        );
        require(_count <= MAX_TOONEY_PURCHASE, "Can only mint 11 tokens at a time");

        // apply discount for each purchase
        uint256 _price = price - ((price * discount) / HUNDRED_PERCENT);

        require(
            msg.value >= _price * _count,
            "Purchase value is not the minimum mint price"
        );

        for (uint256 i = 0; i < _count; i++) {
            mintTo(_purchaser);
        }
    }

    function mintTo(address _recipient) internal {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(_recipient, newItemId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "";
    }

    function getTooneysByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = payable(payments).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function reserveTooneys(uint256 _count) public onlyOwner {
        uint256 totalMinted = totalSupply();
        require(
            totalMinted + _count <= getMaxSupply(),
            "Purchase would exceed max tokens"
        );

        for (uint256 i = 0; i < _count; i++) {
            mintTo(msg.sender);
        }
    } 

    function setFactory(address _factoryAddress) public onlyOwner {
        factoryAddress = _factoryAddress;
    }

    function mintFromPack(address _recipient, uint _count) external payable {
        require(msg.sender == factoryAddress, "Only factory can mint");
        require(saleIsActive, "Sale must be active to mint tokens");

        for (uint256 i = 0; i < _count; i++) {
            mintTo(_recipient);
        }
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }
}
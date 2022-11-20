// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {DefaultOperatorFilterer} from "./src/DefaultOperatorFilterer.sol";



/**
 * @title VoidersGenesis
 * is ERC721A-compatible contract.
 */
contract VoidersGenesis is  DefaultOperatorFilterer, ERC721A, ERC2981, Ownable {
    using ECDSA for bytes32;

    address public immutable whitelistChecker;
    uint256 public constant maxTotalSupply = 888;
    uint256 public constant presalePrice = 0.25 ether;
    uint128 public presaleStartTime;
    uint128 public presaleEndTime;
    string private _baseTokenURI;
    string private _unrevealedURI;
    string private _contractURI;
    bool public revealed = false;

    mapping(address => bool) public mintedFromWhitelist;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newTokenURI,
        string memory _newContractURI,
        string memory _newUnrevealedURI,
        uint128 _presaleStartTime,
        address _management,
        address _whitelistChecker,
        uint96 _royaltyFeesInBips
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = _newTokenURI;
        _contractURI = _newContractURI;
        _unrevealedURI = _newUnrevealedURI;
        
        require(
            _whitelistChecker != address(0),
            "Whitelist checker cannot be 0"
        );
        whitelistChecker = _whitelistChecker;
        require(_management != address(0), "Invalid treasury address");
        // _mintERC2309(_management, 52);
        _mintTo(_management, 53);

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleStartTime + 24 hours;

        setRoyaltyInfo(owner(), _royaltyFeesInBips);
    }


    /**
     * @dev Mints a token to an approved address with discount.
     * @param signature of whitelisted address from whitelist checker
     */
    function presaleMint(bytes memory signature) external payable {
        require(
            keccak256(abi.encodePacked(msg.sender))
                .toEthSignedMessageHash()
                .recover(signature) == whitelistChecker,
            "You are not whitelisted"
        );
        require(
            block.timestamp >= presaleStartTime &&
                block.timestamp < presaleEndTime,
            "Presale is not active"
        );
        require(
            !mintedFromWhitelist[msg.sender],
            "You are already minted from whitelist"
        );
        require(msg.value == presalePrice, "Wrong amount of ETH");
        mintedFromWhitelist[msg.sender] = true;
        _mintTo(msg.sender, 1);
    }

    /**
     * @dev Changes presale start time in case of emergency.
     */
    function changePresaleTime(uint128 _newStartTime, uint128 _newEndTime) external onlyOwner {
        require(
            _newStartTime > block.timestamp,
            "New start time should be greater than current time"
        );
        presaleStartTime = _newStartTime;
        presaleEndTime = _newEndTime;
    }

    function reveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function approve(address operator, uint256 tokenId) public  override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

      function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    /**
     * @dev Royalty.
     */

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

      function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId || // ERC2981 interface
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }


    /**
     * @dev Mints the rest of the tokens to owner for selling.
     */
    function ownerMintForSell() external onlyOwner {
        require(
            block.timestamp > presaleEndTime,
            "Can sell only after presale"
        );
        uint256 numToMint = maxTotalSupply - totalSupply();
        _mintTo(msg.sender, numToMint);
    }

    /**
     * @dev Withdraws presell rewards.
     */
    function ownerWithdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Changes baseTokenURI.
     * @param _newBaseTokenURI new URI for all tokens
     */
    function changeBaseTokenURI(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseTokenURI = _newBaseTokenURI;
    }

    /**
     * @dev Changes baseContractURI.
     * @param _newContractURI new URI for all tokens
     */
    function changeContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

        /**
     * @dev Changes unrevealedURI.
     */
    function changeUnrevealedURI(string memory _newUnrevealedURI) public onlyOwner {
        _unrevealedURI = _newUnrevealedURI;
    }


    /**
     * @dev Returns contractURI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

        /**
     * @dev Returns unrevealedURI.
     */

    function unrevealedURI() public view returns (string memory) {
        return _unrevealedURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns URI for exact token.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return unrevealedURI();
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(_tokenId), ".json")
                )
                : "";
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to new URI for all tokens
     */
    function _mintTo(address _to, uint256 _quantity) internal {
        require(totalSupply() < maxTotalSupply, "Exceeds max supply of tokens");

        _mint(_to, _quantity);
    }
}
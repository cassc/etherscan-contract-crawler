// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheAGFIVault is ERC721, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint public supplyLimit = 100;
    uint256 public currentSupply = 0;
    uint private mintCap = 10;
    uint256 public mintingFee = 400000000;
    address public feeDestination;
    string private baseURI;
    mapping(address => uint256) public minted;
    address public erc20Token;
    bytes32 public constant URI_UDPATER_ROLE = keccak256("URI_UDPATER_ROLE");

    constructor(
        address _erc20Token,
        string memory _uri
    ) ERC721("The AGFI Vault", "AVAULT") {
        feeDestination = msg.sender;
        baseURI = _uri;
        erc20Token = _erc20Token;
        _grantRole(URI_UDPATER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(address recipient) external {
        require(currentSupply < supplyLimit, "Maximum supply reached");
        require(
            minted[recipient] < mintCap,
            "Recipient cannot mint more than 10 NFTs"
        );

        IERC20(erc20Token).transferFrom(msg.sender, feeDestination, mintingFee);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        minted[recipient]++;
        _safeMint(recipient, tokenId);
        currentSupply++;
    }

    function bulkMintNFT(address recipient, uint256 quantity) external {
        require(currentSupply < supplyLimit, "Maximum supply reached");
        require(
            currentSupply + quantity <= supplyLimit,
            "Maximum supply reached"
        );
        require(
            (minted[recipient] + quantity) <= mintCap,
            "Recipient cannot mint more than 10 NFTs"
        );

        IERC20(erc20Token).transferFrom(
            msg.sender,
            feeDestination,
            mintingFee * quantity
        );
        minted[recipient] += quantity;
        for (uint i = 1; i <= quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(recipient, tokenId);
            currentSupply++;
        }
    }

    function increaseSupplyBy(
        uint256 increaseBy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supplyLimit = supplyLimit + increaseBy;
    }

    function updateFeeToken(
        address newToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newToken != address(0), "Invalid token address");
        erc20Token = newToken;
    }

    function updateMintingFee(
        uint256 newFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingFee = newFee;
    }

    function updateFeeDestination(
        address newDestination
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDestination != address(0), "Invalid fee destination");
        feeDestination = newDestination;
    }

    function setBaseURI(
        string memory newBaseURI
    ) external onlyRole(URI_UDPATER_ROLE) {
        baseURI = newBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
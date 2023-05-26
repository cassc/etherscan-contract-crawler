// SPDX-License-Identifier: Unlicense

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.4;

contract PartyHorses is ERC721A, Ownable {
    using ECDSA for bytes32;

    IERC721 public pregameContract;
    address public signingAddress;

    mapping(uint256 => bool) public pregameUsed;
    mapping(address => uint256) public makersMintedByAddress;

    string public baseUri;

    bool public publicSaleActive = false;
    bool public privateSaleActive = false;

    uint256 public constant MAX_MINT_PER_TXN = 5;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant TEAM_SUPPLY = 100;
    uint256 public constant TREASURY_SUPPLY = 100;
    uint256 public constant MARKETING_SUPPLY = 100;

    uint256 public constant MAX_PUBLIC_SUPPLY =
        MAX_SUPPLY - TEAM_SUPPLY - TREASURY_SUPPLY - MARKETING_SUPPLY;

    uint256 public constant PRIVATE_MINT_PRICE = 0.148 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.2 ether;

    constructor() ERC721A("Party Horses", "PARTYHORSES") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function togglePrivateSaleActive() external onlyOwner {
        privateSaleActive = !privateSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function setPregameContract(address contractAddress) external onlyOwner {
        pregameContract = IERC721(contractAddress);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function makersMint(uint256 count, bytes calldata _allowlistSignature)
        external
        payable
    {
        require(privateSaleActive, "Private sale not currently active");
        require(totalSupply() + count <= MAX_PUBLIC_SUPPLY, "No supply left.");
        require(msg.value >= PRIVATE_MINT_PRICE * count, "Not enough eth.");
        require(
            count > 0 && count <= MAX_MINT_PER_TXN,
            "Must mint between 1 and 5"
        );
        require(
            verifySignature(
                keccak256(abi.encode(msg.sender)),
                _allowlistSignature
            ),
            "Not on the allowlist."
        );
        require(
            makersMintedByAddress[msg.sender] + count <= MAX_MINT_PER_TXN,
            "Max 5 for Maker's mint."
        );

        makersMintedByAddress[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function privateMint(uint256 pregameId, uint256 count) external payable {
        require(privateSaleActive, "Private sale not currently active");
        require(pregameId >= 1 && pregameId <= 2000, "Invalid Pregame ID");
        require(totalSupply() + count <= MAX_PUBLIC_SUPPLY, "No supply left.");
        require(msg.value >= PRIVATE_MINT_PRICE * count, "Not enough eth.");
        require(
            count > 0 && count <= MAX_MINT_PER_TXN,
            "Must mint between 1 and 5"
        );
        require(
            pregameContract.ownerOf(pregameId) == msg.sender,
            "You do not own this Pregame NFT"
        );
        require(
            !pregameUsed[pregameId],
            "Pregame already used for private mint"
        );

        pregameUsed[pregameId] = true;
        _safeMint(msg.sender, count);
    }

    function mint(uint256 count) external payable {
        require(publicSaleActive, "Public sale not currently active");
        require(msg.value >= PUBLIC_MINT_PRICE * count, "Not enough eth.");
        require(
            count > 0 && count <= MAX_MINT_PER_TXN,
            "Must mint between 1 and 5"
        );
        require(totalSupply() + count <= MAX_PUBLIC_SUPPLY, "No supply left.");

        _safeMint(msg.sender, count);
    }

    function adminMint(uint256 count) external onlyOwner {
        require(totalSupply() + count <= MAX_SUPPLY);
        _safeMint(msg.sender, count);
    }

    function setSigningAddress(address _addr) public onlyOwner {
        signingAddress = _addr;
    }

    function verifySignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            hash.toEthSignedMessageHash().recover(signature) == signingAddress;
    }
}
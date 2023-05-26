//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//    _____           _                  _____             _
//   / ____|         | |     /\         |  __ \           | |
//  | (___   __ _  __| |    /  \   ___  | |  | |_   _  ___| | __
//   \___ \ / _` |/ _` |   / /\ \ / __| | |  | | | | |/ __| |/ /
//   ____) | (_| | (_| |  / ____ \\__ \ | |__| | |_| | (__|   <
//  |_____/ \__,_|\__,_| /_/    \_\___/ |_____/ \__,_|\___|_|\_\

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SadAsDuck is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant TEAM_MINT = 333;

    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_PRESALE_MINT = 3;

    uint256 public constant PUBLIC_PRICE = .05 ether;
    uint256 public constant PRESALE_PRICE = .03 ether;

    string private baseTokenUri;
    string public placeholderTokenUri;

    address public crossmintAddress =
        0xdAb1a1854214684acE522439684a145E62505233;

    /* Error Messages */
    string public constant NOT_LIVE = "Minting is not live.";
    string public constant OVER_SUPPLY = "Over max supply.";
    string public constant BELOW_PRICE = "Below sale price.";
    string public constant BEYOND_MAX = "Cannot mint beyond max.";
    string public constant MINT_PAUSED = "Minting is paused.";
    string public constant CROSSMINT_ONLY =
        "This function is for Crossmint only.";

    bool public isRevealed;
    bool public publicSale;
    bool public preSale;
    bool public paused;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalPresaleMint;

    constructor() ERC721A("Sad as Duck", "SAD") {}

    function crossmintPresale(
        address _to,
        uint256 _quantity,
        bytes32[] memory _merkleProof
    ) public payable {
        require(preSale, NOT_LIVE);
        require(!paused, MINT_PAUSED);
        require(msg.sender == crossmintAddress, CROSSMINT_ONLY);
        require(msg.value >= (PRESALE_PRICE * _quantity), BELOW_PRICE);
        require((totalSupply() + _quantity) <= MAX_SUPPLY, OVER_SUPPLY);
        require(
            (totalPresaleMint[_to] + _quantity) <= MAX_PRESALE_MINT,
            BEYOND_MAX
        );
        bytes32 sender = keccak256(abi.encodePacked(_to));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "Address is not on access list."
        );

        totalPresaleMint[_to] += _quantity;
        _safeMint(_to, _quantity);
    }

    function crossmint(address _to, uint256 _quantity) public payable {
        require(publicSale, NOT_LIVE);
        require(!paused, MINT_PAUSED);
        require(msg.sender == crossmintAddress, CROSSMINT_ONLY);
        require((totalSupply() + _quantity) <= MAX_SUPPLY, OVER_SUPPLY);
        require(msg.value >= (PUBLIC_PRICE * _quantity), BELOW_PRICE);
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            BEYOND_MAX
        );

        totalPublicMint[_to] += _quantity;
        _safeMint(_to, _quantity);
    }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Team already minted.");
        teamMinted = true;
        _safeMint(msg.sender, TEAM_MINT);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceholderUri(string memory _placeholderTokenUri)
        external
        onlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function togglePreSale() external onlyOwner {
        preSale = !preSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract MuxxoCat is Ownable, ERC721AQueryable, ERC2981 {
    using Strings for uint256;

    uint16 public ROYALTY_BASIS_POINT = 690;
    uint16 public MAX_SUPPLY = 6969;
    uint16 public constant MAX_SPECIAL_SUPPLY = 2401;
    uint16 public constant MAX_NORMAL_SUPPLY = 4499;

    uint8 public constant TEAM_MINT_AMOUNT = 69;

    uint256 public constant SPECIAL_MINT_PRICE = .02 ether;

    uint8 public constant MAX_MINT_PRESALE_NORMAL = 1;
    uint8 public constant MAX_MINT_PRESALE_SPECIAL = 1;

    uint16 public constant MAX_MINT_PUBLIC_NORMAL = 20;
    uint16 public constant MAX_MINT_PUBLIC_SPECIAL = 20;

    string private baseTokenUri = "https://api.traitsniper.com/api/muxxo_cat/metadata/";

    uint16 public TOTAL_PRESALE_NORMAL_MINTED;
    uint16 public TOTAL_PRESALE_SPECIAL_MINTED;

    uint16 public TOTAL_PUBLIC_NORMAL_MINTED;
    uint16 public TOTAL_PUBLIC_SPECIAL_MINTED;

    uint16 public TOTAL_MINTED;

    uint16 public TOTAL_SPECIAL_MINTED;
    uint16 public TOTAL_NORMAL_MINTED;
    //deploy smart contract, toggle WL, toggle WL when done, toggle isPublicSale
    //2 days later toggle reveal
    bool public isPublicSale;
    bool public isPresale;

    bytes32 private merkleRoot = 0x64da8b3749ca925d2fb154058b1d28087c71942b8e13ef3a51b52c8d31e3ed7a;

    mapping(address => uint16) public publicSaleMinted;
    mapping(address => uint16) public publicSpecialMinted;
    mapping(address => uint16) public presaleMinted;
    mapping(address => uint16) public presaleSpecialMinted;

    constructor(address payable royaltyReceiver) ERC721A('Muxxo Cat', 'MuxxoCat') {
        _setDefaultRoyalty(royaltyReceiver, ROYALTY_BASIS_POINT);
        _teamMint();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'Muxxo Cat :: Cannot be called by a contract');
        _;
    }

    function mintPublic(uint16 _quantity) external callerIsUser {
        require(isPublicSale, 'Muxxo Cat :: Public Sale Not Yet Active.');
        require((totalSupply() + _quantity) <= MAX_SUPPLY, 'Muxxo Cat :: Cannot mint beyond max supply');
        require((TOTAL_NORMAL_MINTED + _quantity) <= MAX_NORMAL_SUPPLY, 'Muxxo Cat :: Beyond Max Supply for Minting');
        require(
            (publicSaleMinted[msg.sender] + _quantity) <= MAX_MINT_PUBLIC_NORMAL,
            'Muxxo Cat :: Already minted max allowed amount!'
        );
        TOTAL_MINTED += _quantity;
        TOTAL_NORMAL_MINTED += _quantity;
        TOTAL_PUBLIC_NORMAL_MINTED += _quantity;
        publicSaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mintPublicSpecial(uint16 _quantity) external payable callerIsUser {
        require(isPublicSale, 'Muxxo Cat :: Public Sale Not Yet Active.');
        require((totalSupply() + _quantity) <= MAX_SUPPLY, 'Muxxo Cat :: Cannot mint beyond max supply');
        require(
            (TOTAL_SPECIAL_MINTED + _quantity) <= MAX_SPECIAL_SUPPLY,
            'Muxxo Cat :: Beyond Max Supply for Minting Special'
        );
        require(
            (publicSpecialMinted[msg.sender] + _quantity) <= MAX_MINT_PUBLIC_SPECIAL,
            'Muxxo Cat :: Already minted max allowed amount!'
        );
        require(msg.value >= (SPECIAL_MINT_PRICE * _quantity), 'Muxxo Cat :: Payment is below the price');
        TOTAL_MINTED += _quantity;
        TOTAL_PUBLIC_SPECIAL_MINTED += _quantity;
        TOTAL_SPECIAL_MINTED += _quantity;
        publicSpecialMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(SPECIAL_MINT_PRICE * _quantity);
    }

    function mintPrivate(bytes32[] memory _merkleProof, uint16 _quantity) external callerIsUser {
        require(isPresale, 'Muxxo Cat :: Presale Not Yet Active');
        require((totalSupply() + _quantity) <= MAX_SUPPLY, 'Muxxo Cat :: Cannot mint beyond max supply');
        require(_quantity >= 1, 'Muxxo Cat :: Invalid quantity');
        require(
            (presaleMinted[msg.sender] + _quantity) <= MAX_MINT_PRESALE_NORMAL,
            'Muxxo Cat :: Already minted max allowed amount!'
        );
        require((TOTAL_NORMAL_MINTED + _quantity) <= MAX_NORMAL_SUPPLY, 'Muxxo Cat :: Beyond Max Supply for Minting');
        bytes32 sender = keccak256(abi.encode(0, msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), 'Muxxo Cat :: You are not in whitelist');

        TOTAL_MINTED += _quantity;
        TOTAL_NORMAL_MINTED += _quantity;
        TOTAL_PRESALE_NORMAL_MINTED += _quantity;
        presaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mintPrivateSpecial(bytes32[] memory _merkleProof, uint16 _quantity) external payable callerIsUser {
        require(isPresale, 'Muxxo Cat :: Presale Not Yet Active');
        require((totalSupply() + _quantity) <= MAX_SUPPLY, 'Muxxo Cat :: Cannot mint beyond max supply');
        require(_quantity >= 1, 'Muxxo Cat :: Invalid quantity');
        require(
            (presaleSpecialMinted[msg.sender] + _quantity) <= MAX_MINT_PRESALE_SPECIAL,
            'Muxxo Cat :: Already minted max allowed amount!'
        );
        require(
            (TOTAL_SPECIAL_MINTED + _quantity) <= MAX_SPECIAL_SUPPLY,
            'Muxxo Cat :: Beyond Max Supply for Minting Special'
        );
        require(msg.value >= (SPECIAL_MINT_PRICE * _quantity), 'Muxxo Cat :: Payment is below the price');

        bytes32 sender = keccak256(abi.encode(0, msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), 'Muxxo Cat :: You are not in whitelist');

        TOTAL_MINTED += _quantity;
        TOTAL_SPECIAL_MINTED += _quantity;
        TOTAL_PRESALE_SPECIAL_MINTED += _quantity;
        presaleSpecialMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(SPECIAL_MINT_PRICE * _quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, 'Need to send more ETH.');
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _teamMint() internal onlyOwner {
        TOTAL_MINTED += TEAM_MINT_AMOUNT;
        TOTAL_NORMAL_MINTED += TEAM_MINT_AMOUNT;
        _safeMint(msg.sender, TEAM_MINT_AMOUNT);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return
            bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), '.json')) : '';
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleIsPresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function toggleIsPublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function updateSupply(uint16 supply) external onlyOwner {
        MAX_SUPPLY = supply;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
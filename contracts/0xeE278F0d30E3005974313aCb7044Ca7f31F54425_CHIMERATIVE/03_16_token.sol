//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract TOKEN is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 public maxSupply = 1000;
    uint256 public prePrice = 0.02 ether;
    uint256 public pubPrice = 0.04 ether;

    bool public preSaleStart;
    bool public pubSaleStart;
    bool public revealed;

    uint256 public mintLimit = 3;

    string public notRevealedURI =
        "https://utgddupxklcytipfc7pdc4dteiypkzrvnrxgser4lc5tmtqzafvq.arweave.net/pMwx0fdSxYmh5RfeMXBzIjD1ZjVsbmkSPFi7Nk4ZAWs";
    bytes32 public merkleRoot;

    address public royaltyAddress = 0xd2Cf1aa09dC1494E43a74cDa7Dc75c8d54E3099B;
    uint96 public royaltyFee = 1000;

    mapping(address => uint256) public claimed;
    mapping(uint256 => uint8) private _mintType;

    constructor() ERC721A("Chimerative monsters", "CHIMERA") {
        _setDefaultRoyalty(msg.sender, royaltyFee);

        _mintERC2309(0xd2Cf1aa09dC1494E43a74cDa7Dc75c8d54E3099B, 70);
        _mintERC2309(0x00E21fa5FDE28DE9217a112D35b51452FdC726e9, 30);
        _mintERC2309(0x253058B7F0fF2C6218dB7569cE1d399F7183E355, 20);
        _mintERC2309(0xed14275FeB016186482dD03cd7BE4E9E47EE6c07, 20);
        _mintERC2309(0x9290FF032035aAD6e84B7A63c2cf9BEE31dd1742, 1);
        _mintERC2309(0x3168ad7BEED95C5F58356Ca3c9aA961E57b1b48C, 1);
        _mintERC2309(0xd08162a6DF30f29DB70c2a393cDB42a0314A170a, 1);
        _mintERC2309(0x7eBEd76432dB76A8Dfe7221fA29f5D4f8Eb0a1E5, 1);
        _mintERC2309(0x292E4d6aB815F410819b4472100F08423BE378B8, 1);
        _mintERC2309(0x233C05a9De5C2c9975bD494CA725f415DD6956D2, 1);
        _mintERC2309(0xBAa98fe972144EF1DE53b801045CEc5A291cB30E, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = pubPrice * _quantity;
        require(pubSaleStart, "Presale is active");
        _mintCheck(_quantity, supply, cost);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        for (uint256 i = 0; i < _quantity; ) {
            uint256 tokenId = supply + i;
            _mintType[tokenId] = 1;
            unchecked {
                i++;
            }
        }
    }

    function preMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = prePrice * _quantity;
        require(preSaleStart, "Presale is not active");
        _mintCheck(_quantity, supply, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheck(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_quantity > 0, "Mint quantity cannot be zero");
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(_quantity > 0, "Mint quantity cannot be zero");
        require(supply + _quantity <= maxSupply, "Max supply over");
        _safeMint(_address, _quantity);

        for (uint256 i = 0; i < _quantity; ) {
            uint256 tokenId = supply + i;
            _mintType[tokenId] = 0;
            unchecked {
                i++;
            }
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed) {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return notRevealedURI;
        }
    }

    function checkMintType(uint256 _tokenId) external view returns (uint8) {
        require(_exists(_tokenId), "nonexistent token");
        return _mintType[_tokenId];
    }

    // only owner
    function setNotRevealedURI(string memory _uri) public onlyOwner {
        notRevealedURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setPrePrice(uint256 _price) public onlyOwner {
        prePrice = _price;
    }

    function setPubPrice(uint256 _price) public onlyOwner {
        pubPrice = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setMintLimit(uint256 _quantity) public onlyOwner {
        mintLimit = _quantity;
    }

    function setMintType(uint256 _tokenId, uint8 _type) public onlyOwner {
        _mintType[_tokenId] = _type;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;

        address cre = payable(0x00E21fa5FDE28DE9217a112D35b51452FdC726e9);
        address dev = payable(0x253058B7F0fF2C6218dB7569cE1d399F7183E355);
        address mer = payable(0xed14275FeB016186482dD03cd7BE4E9E47EE6c07);

        bool success;

        (success, ) = cre.call{value: ((sendAmount * 6000) / 10000)}("");
        require(success, "Failed to withdraw Ether");

        (success, ) = dev.call{value: ((sendAmount * 2000) / 10000)}("");
        require(success, "Failed to withdraw Ether");

        (success, ) = mer.call{value: ((sendAmount * 2000) / 10000)}("");
        require(success, "Failed to withdraw Ether");
    }

    // Royality
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TOKEN is
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public constant NL_PRICE = 0.015 ether;
    uint256 public constant PRICE = 0.02 ether;
    uint256 public totalSupply = 0;

    uint256 public constant MINT_LIMIT_NL = 6;
    uint256 public constant MINT_LIMIT_AL = 3;

    mapping(uint256 => bool) public isSaleStart;

    bytes32 public merkleRootNL;
    bytes32 public merkleRootAL;

    string private _baseTokenURI;

    mapping(uint256 => uint256) public charCounts;

    mapping(address => uint256) public claimed;

    // walletAddress => (mintType => claimCount)
    mapping(address => mapping(uint256 => uint256)) public claimTypeOfCount;

    constructor() ERC721("NAMAIKI GIRLS MUSIC", "NGM") {
        _setDefaultRoyalty(0xaC58E445594eC187eC8D82400d3457D9A67119cf, 1000);
        merkleRootNL = 0x9fe1f0d40e434a1591135970b6a6bab00af569e07584d9cb4144f4763cbd6350;
        merkleRootAL = 0xd9fde55118c63daeef26099ac1daba137600c211fa00b18c254e1592f61b33db;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(ERC721.tokenURI(_tokenId), ".json"));
    }

    // 1.Namy, Size: 232, startIndex: 1
    // 2.Maruru, Size: 310, startIndex: 233
    // 3.Riff, Size: 254, startIndex: 543
    // 4.Elena, Size: 238, startIndex: 797
    // 5.Ako, Size: 238, startIndex: 1035
    // 6.Sekai, Size: 228, startIndex: 1273
    modifier checkCharStock(uint256 _charNum, uint256 _quantity) {
        if (_charNum == 1) {
            require(charCounts[_charNum] + _quantity < 233, 'Not enough Namy left.');
        }
        if (_charNum == 2) {
            require(charCounts[_charNum] + _quantity < 311, 'Not enough Maruru left.');
        }
        if (_charNum == 3) {
            require(charCounts[_charNum] + _quantity < 255, 'Not enough Riff left.');
        }
        if (_charNum == 4) {
            require(charCounts[_charNum] + _quantity < 239, 'Not enough Elena left.');
        }
        if (_charNum == 5) {
            require(charCounts[_charNum] + _quantity < 239, 'Not enough Ako left.');
        }
        if (_charNum == 6) {
            require(charCounts[_charNum] + _quantity < 229, 'Not enough Sekai left.');
        }
        _;
    }

    function checkMerkleProof(uint256 _mintType, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool result;
        if (_mintType == 0) {
            result = MerkleProof.verifyCalldata(_merkleProof, merkleRootNL, leaf);
        }
        if (_mintType == 1) {
            result = MerkleProof.verifyCalldata(_merkleProof, merkleRootAL, leaf);
        }
        return result;
    }

    function _mintCharacters(address _to, uint256 _charNum, uint256 _quantity) internal {
        for (uint256 i = 0; i < _quantity;) {
            uint256 tokenId;
            if (_charNum == 1) {
                tokenId = charCounts[_charNum] + 1;
            } else if (_charNum == 2) {
                tokenId = charCounts[_charNum] + 233;
            } else if (_charNum == 3) {
                tokenId = charCounts[_charNum] + 543;
            } else if (_charNum == 4) {
                tokenId = charCounts[_charNum] + 797;
            } else if (_charNum == 5) {
                tokenId = charCounts[_charNum] + 1035;
            } else if (_charNum == 6) {
                tokenId = charCounts[_charNum] + 1273;
            }
            _safeMint(_to, tokenId);
            unchecked {
                ++totalSupply;
                ++charCounts[_charNum];
                ++i;
            }
        }
    }

    // _mintType 0: NL, 1: AL
    function preMint(uint256 _mintType, uint256 _charNum, uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
        checkCharStock(_charNum, _quantity)
    {
        require(checkMerkleProof(_mintType, _merkleProof), "Invalid Merkle Proof");

        if (_mintType == 0) {
            require(isSaleStart[0], 'Before sale begin.');
            require(MINT_LIMIT_NL >= _quantity + claimed[msg.sender], 'Mint quantity over');
            require(msg.value >= NL_PRICE * _quantity, "Not enough funds");
        }
        if (_mintType == 1) {
            require(isSaleStart[1], 'Before sale begin.');
            require(MINT_LIMIT_AL >= _quantity + claimed[msg.sender], 'Mint quantity over');
            require(msg.value >= PRICE * _quantity, "Not enough funds");
        }

        require(totalSupply + _quantity <= MAX_SUPPLY, "Max supply over");

        claimed[msg.sender] += _quantity;
        claimTypeOfCount[msg.sender][_mintType] += _quantity;

        _mintCharacters(msg.sender, _charNum, _quantity);
    }

    function pubMint(uint256 _charNum, uint256 _quantity)
        public
        payable
        nonReentrant
        checkCharStock(_charNum, _quantity)
    {
        require(msg.value >= PRICE * _quantity, "Not enough funds");
        require(isSaleStart[2], "Before sale begin.");
        require(totalSupply + _quantity <= MAX_SUPPLY, "Max supply over");

        claimed[msg.sender] += _quantity;
        claimTypeOfCount[msg.sender][2] += _quantity;

        _mintCharacters(msg.sender, _charNum, _quantity);
    }

    function allCharMint(uint256 _mintType, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        require(charCounts[1] + 1 < 233, 'Not enough Namy left.');
        require(charCounts[2] + 1 < 311, 'Not enough Maruru left.');
        require(charCounts[3] + 1 < 255, 'Not enough Riff left.');
        require(charCounts[4] + 1 < 239, 'Not enough Elena left.');
        require(charCounts[5] + 1 < 239, 'Not enough Ako left.');
        require(charCounts[6] + 1 < 229, 'Not enough Sekai left.');

        uint256 totalCost;
        if (_mintType == 2) {
            require(isSaleStart[2], "Before sale begin.");
            require(totalSupply + 6 <= MAX_SUPPLY, "Max supply over");
            totalCost = PRICE * 6;
        } else {
            require(_mintType == 0, 'AL Only.');
            require(isSaleStart[0], 'Before sale begin.');
            require(MINT_LIMIT_NL >= 6 + claimed[msg.sender], 'Mint quantity over');
            totalCost = NL_PRICE * 6;

            require(checkMerkleProof(_mintType, _merkleProof), "Invalid Merkle Proof");
        }
        require(msg.value >= totalCost, "Not enough funds");

        require(totalSupply + 6 <= MAX_SUPPLY, "Max supply over");

        claimed[msg.sender] += 6;
        claimTypeOfCount[msg.sender][_mintType] += 6;

        for (uint256 i = 1; i <= 6;) {
            _mintCharacters(msg.sender, i, 1);
            unchecked {
                ++i;
            }
        }
    }

    function ownerMint(uint256 _charNum, uint256 _quantity, address _address)
        public
        nonReentrant
        checkCharStock(_charNum, _quantity)
        onlyOwner
    {
        require(totalSupply + _quantity <= MAX_SUPPLY, "Max supply over");

        _mintCharacters(_address, _charNum, _quantity);
    }

    // only owner
    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    // _mintType 0: NL, 1: AL
    function setMerkleRoot(uint256 _mintType, bytes32 _merkleRoot) public onlyOwner {
        if (_mintType == 0) {
            merkleRootNL = _merkleRoot;
        }
        if (_mintType == 1) {
            merkleRootAL = _merkleRoot;
        }
    }

    // _saleType 0: NL, 1: AL, 2: public
    function saleStart(uint256 _saleType, bool _state) public onlyOwner {
        isSaleStart[_saleType] = _state;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(0xaC58E445594eC187eC8D82400d3457D9A67119cf), ((balance * 3600) / 10000)); // Founder
        Address.sendValue(payable(0x6cde76Ece170333e0b43C74325F178118af372f8), ((balance * 2800) / 10000)); // Musician
        Address.sendValue(payable(0x48A23fb6f56F9c14D29FA47A4f45b3a03167dDAe), ((balance * 2000) / 10000)); // Developer
        Address.sendValue(payable(0xf04a829373e3F3e4F755488e0deE511d1DD9bB98), ((balance * 1600) / 10000)); // Marketer
    }

    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}
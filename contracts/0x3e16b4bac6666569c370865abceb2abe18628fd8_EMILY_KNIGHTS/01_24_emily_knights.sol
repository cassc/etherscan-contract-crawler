//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721psi/contracts/ERC721Psi.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract EMILY_KNIGHTS is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1500;

    uint256 public constant PRICE_AL1 = 0;
    uint256 public constant PRICE_AL2 = 0.005 ether;
    uint256 public constant PRICE_AL3 = 0.007 ether;
    uint256 public constant PRICE_PUB = 0.009 ether;

    mapping (uint256 => bool) public saleStart; // 1: AL1, 2: AL2, 3: AL3, 4: Public
    mapping (uint256 => bytes32) public merkleRoot; // 1: AL1, 2: AL2, 3: AL3

    bool private _revealed;
    string private _baseTokenURI;
    string private _unrevealedURI = "https://emily-nft-assets.s3.ap-northeast-1.amazonaws.com/unrevealed/metadata.json";

    mapping(address => uint256) public claimed; // totalClaimed
    mapping(uint256 => mapping(address => uint256)) public claimedForSale; // saleType => (address => claimed)
    mapping(uint256 => string) public charName; // tokenId => name

    event Mint(address indexed _address, uint256 _quantity, uint256 _mintType);

    constructor() ERC721Psi("EmilyKnights", "EK") {
        _setDefaultRoyalty(address(0x5444F2D8a68bE0daFe38dEf6cDaa172C2D015A05), 1000);

        // 事前配布
        _safeMint(0x5444F2D8a68bE0daFe38dEf6cDaa172C2D015A05, 10);
        _safeMint(0x253058B7F0fF2C6218dB7569cE1d399F7183E355, 10);
        _safeMint(0xBAa98fe972144EF1DE53b801045CEc5A291cB30E, 13);
        _safeMint(0xA3fD3586726C6B71B5925613909B40564aFf9F86, 13);
        _safeMint(0x3C2EBB7c2c4ee839c12708c123D6a54F5fbb1562, 5);
        _safeMint(0xd77989A5b8Ded89B74215845f245E35D932CD740, 5);
        _safeMint(0xfff66e751ec31Bc8757819d969b35071c32CE46e, 3);
        _safeMint(0x998DFdC33E7d529de31F9A213265f42E0b28E2f8, 3);
        _safeMint(0xb7653171De23982acaDc2aa3c40E662C929663dB, 2);
        _safeMint(0x35594B527422aAb97d0e3b5813D72BD6e9aE1717, 3);
        _safeMint(0x0383C0bDD89e915C1E2b4Ac3445a3158211056E9, 3);
        _safeMint(0x28B89726e06B5881bd5d4aAB35D6E3F84606Bb99, 3);
        _safeMint(0x00E21fa5FDE28DE9217a112D35b51452FdC726e9, 3);
        _safeMint(0x292E4d6aB815F410819b4472100F08423BE378B8, 3);
        _safeMint(0xdf1c6F94fe16337EA61e726Fa6F268de7268f787, 3);
        _safeMint(0x254c98BC580dAb615b84e144d377bC8AB168Bbe2, 1);
        _safeMint(0x60C1a53bD2c7D3a399C1dCE05c60A8CDa353640B, 1);
        _safeMint(0x65Aad16650AFf6B1c11e779EE3C9b361808C5F61, 1);
        _safeMint(0x5D0218806AD8045Ec085005ca6F119B6bcc21758, 1);
        _safeMint(0xC4cf182696E3810f654632bfF8770EC9AB826Db5, 1);
        _safeMint(0xeB93B1A498b858CA5Edc0f30eAE390463C754C93, 1);
        _safeMint(0xBE6e5a76D58F91A44620a0f7eedc80E22136860D, 1);
        _safeMint(0xebF8713E7565719A1bE6F2158d6Fb205e442Cac6, 1);
        _safeMint(0x0303D829D9B81D0939a974cB0C88ea27AB7129c9, 1);
        _safeMint(0x42A662B820e0C3a860faD43f34D92cDb4769CF8B, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721Psi)
        returns (string memory)
    {
        if (_revealed) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return _unrevealedURI;
        }
    }

    function pubMint(uint256 _quantity, address _receiver) public payable nonReentrant {
        uint256 cost = PRICE_PUB * _quantity;
        require(saleStart[4], "Before sale begin.");
        require(_quantity > 0, 'Please set quantity.');
        _mintCheck(4, _quantity, cost, 0);

        claimed[_receiver] += _quantity;
        claimedForSale[4][_receiver] += _quantity;
        _safeMint(_receiver, _quantity);

        emit Mint(_receiver, _quantity, 4);
    }

    function verifyAddressAndAmount(
        address _address,
        uint256 _amount,
        uint256 _mintType,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address, _amount));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_mintType], leaf);
    }

    function preMint(uint256 _mintType, uint256 _quantity, bytes32[] calldata _merkleProof, uint256 _mintLimit)
        public
        payable
        nonReentrant
    {
        uint256 cost = 0;
        if (_mintType == 1) {
            cost = PRICE_AL1 * _quantity;
        } else if (_mintType == 2) {
            cost = PRICE_AL2 * _quantity;
        } else if (_mintType == 3) {
            cost = PRICE_AL3 * _quantity;
        }
        require(_quantity > 0, 'Please set quantity.');
        require(saleStart[_mintType], "Before sale begin.");
        require(verifyAddressAndAmount(msg.sender, _mintLimit, _mintType, _merkleProof), "Invalid Merkle Proof");
        _mintCheck(_mintType, _quantity, cost, _mintLimit);

        claimed[msg.sender] += _quantity;
        claimedForSale[_mintType][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

        emit Mint(msg.sender, _quantity, _mintType);
    }

    function _mintCheck(
        uint256 _mintType,
        uint256 _quantity,
        uint256 _cost,
        uint256 _mintLimit
    ) private view {
        uint256 supply = totalSupply();
        require(supply + _quantity <= MAX_SUPPLY, "Max supply over");
        require(msg.value == _cost, "Not enough funds");
        if (_mintType != 4) {
            // Check mintLimit except Public
            require(
                claimedForSale[_mintType][msg.sender] + _quantity <= _mintLimit,
                "Mint quantity over"
            );
        }
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= MAX_SUPPLY, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // only owner
    function setUnrevealedURI(string calldata _uri) public onlyOwner {
        _unrevealedURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(uint256 _mintType, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot[_mintType] = _merkleRoot;
    }

    function setSaleStart(uint256 _mintType, bool _state) public onlyOwner {
        saleStart[_mintType] = _state;
    }

    function setName(uint256 _tokenId, string calldata _name) public {
        require(ownerOf(_tokenId) == msg.sender, "ERC721: caller is not the owner");
        charName[_tokenId] = _name;
    }

    function setNameForce(uint256 _tokenId, string calldata _name) public onlyOwner {
        charName[_tokenId] = _name;
    }

    function reveal(bool _state) public onlyOwner {
        _revealed = _state;
    }


    // 報酬配分
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        // 10000 = 1%
        Address.sendValue(payable(0x5444F2D8a68bE0daFe38dEf6cDaa172C2D015A05), ((balance * 500000) / 1000000));
        Address.sendValue(payable(0x7Abb65089055fB2bf5b247c89E3C11F7dB861213), ((balance * 300000) / 1000000));
        Address.sendValue(payable(0xA3fD3586726C6B71B5925613909B40564aFf9F86), ((balance * 50000) / 1000000));
        Address.sendValue(payable(0xBAa98fe972144EF1DE53b801045CEc5A291cB30E), ((balance * 50000) / 1000000));
        Address.sendValue(payable(0x3C2EBB7c2c4ee839c12708c123D6a54F5fbb1562), ((balance * 50000) / 1000000));
        Address.sendValue(payable(0xd77989A5b8Ded89B74215845f245E35D932CD740), ((balance * 50000) / 1000000));
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
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}
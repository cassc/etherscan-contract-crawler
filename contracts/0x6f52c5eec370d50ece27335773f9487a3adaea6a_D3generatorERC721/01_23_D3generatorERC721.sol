// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract D3generatorERC721 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIdCounter;
    string private baseURI;
    uint256 public mintCost;
    uint256 public maxSupply;
    mapping(address => uint256) public mintCountPerAddress;
    uint256 public maxMintCountPerAddress;
    uint256 public royaltyBasePoints;
    address private signerAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI_,
        address _owner,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _maxMintCountPerAddress,
        uint256 _royaltyBasePoints,
        address _signerAddress
    ) public initializer {
        __ERC721_init(_name, _symbol);
        baseURI = _baseURI_;
        mintCost = _mintCost;
        __Ownable_init();
        __Pausable_init();
        _transferOwnership(_owner);
        maxSupply = _maxSupply;
        maxMintCountPerAddress = _maxMintCountPerAddress;
        royaltyBasePoints = _royaltyBasePoints;
        signerAddress = _signerAddress;
    }

    function setMintCost(uint256 _mintCost) public onlyOwner {
        mintCost = _mintCost;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"',
                                    name(),
                                    '","seller_fee_basis_points":',
                                    Strings.toString(royaltyBasePoints),
                                    ',"fee_recipient":"',
                                    "0x",
                                    toAsciiString(address(this)),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }


    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    //royalty everything else
    function royaltyInfo(uint _tokenId, uint _salePrice)
        external
        view
        returns (address receiver, uint royaltyAmount)
    {
        return (address(this), uint((_salePrice * royaltyBasePoints) / 10000));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airDrop(address[] calldata _receipients, uint256 amount)
        public
        onlyOwner
    {
        for (uint i = 0; i < _receipients.length; i++) {
            _safeMint(_receipients[i], amount);
        }
    }

    function setRoyaltyBasePoints(uint256 _royaltyBasePoints) public onlyOwner{
        royaltyBasePoints=_royaltyBasePoints;
    }

    function mintWhitelist(
        uint256 _mintAmount,
        uint256 _mintCost,
        bytes calldata signature
    ) public payable {
        require(msg.value >= _mintCost * _mintAmount);

        address signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(msg.sender, _mintAmount, _mintCost))
            ),
            signature
        );

        require(signer == signerAddress);
        _mintLoop(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable whenNotPaused {
        require(msg.value >= mintCost * _mintAmount);

        _mintLoop(msg.sender, _mintAmount);
    }

    function withdraw() public onlyOwner {
/*        address taxWallet = 0x09e8c457AEDB06C2830c4Be9805d1B20675EdeD8;

        (bool hs, ) = payable(taxWallet).call{
            value: (address(this).balance * 1) / 100
        }("");
        require(hs);
*/

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) private {
        require(tokenIdCounter.current() + _mintAmount <= maxSupply);
        require(
            maxMintCountPerAddress == 0 ||
                mintCountPerAddress[_receiver] + _mintAmount <=
                maxMintCountPerAddress
        );

        mintCountPerAddress[_receiver] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenIdCounter.increment();
            _safeMint(_receiver, tokenIdCounter.current());
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RFG is ERC721, ERC721Enumerable, Ownable, AccessControl {
    using Strings  for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // Constants
    uint256 public constant MAX_SUPPLY       = 10000;
    uint256 public constant MAX_MINT         = 20;
    uint8   public constant MAX_PRESALE_MINT = 4;

    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");

    uint256 public price = 0.05 ether;

    string public PROVENANCE;
    string public baseURI;

    bool public presaleIsActive = false;
    bool public saleIsActive    = false;

    mapping(string => bool)  private usedNonces;
    mapping(address => bool) private usedAddresses;

    address private signerAddress = 0x38ED80ae81Ca5Ac262b909432FDE26Cd167ecAdE;

    // Wallets
    address private communityP  = 0x770D0F963Eb76e7f481240389F0fab2FA4B2682D;
    address private communityCF = 0xC02670Fac3Af5dE06Ee3C696CdbbDc8a5FCB59A5;
    address private roadmapTSC  = 0xF6E3FB417577C2Da97d674DF5122af50A5A04AC0;
    address private operations  = 0x36092180b481f0ec9d54f7e2CB916c8c78F91892;
    address private kfish       = 0xe652421ad1DC7bD8F95cea611B11C9AfbD500AC3;
    address private ab          = 0x5Df9322fdB55F62D1CF846a63010145716e0Ccba;
    address private travis      = 0xF6C09fCA3a5729E59Eb17e6e8db28cb9CD1C2055;
    address private cloroxo     = 0x2B031166645D849D5b06fEA65977cb487B4dD993;
    address private heem        = 0xd3869641f5858399BbC5A1E8420557c5E9E43E70;
    address private ginko       = 0x2486C9FC111b30Db51390dE9568E9001caC45169;
    address private largo       = 0x6698F320B0C04C285A4c57Bf7298147C58e28Fd8;
    address private mighty      = 0x9fB0ceA887cb61f4E47d97aE08a0104CA3c5e72a;

    // Modifiers
    modifier originGuard() {
        require(msg.sender == tx.origin, "Sender and Origin are not the same.");
        _;
    }

    constructor(address[] memory _coreAddresses, string memory _cBaseURI) ERC721("Reptilians for Good", "RFG") {
        baseURI = _cBaseURI;
        for (uint256 i = 0; i < _coreAddresses.length; i++) {
            _setupRole(CORE_ROLE, _coreAddresses[i]);
        }
    }

    // Set Functions
    function setProvenance(string memory _provenance) public onlyOwner {
        PROVENANCE = _provenance;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPresaleIsActive(bool _presaleIsActive) external onlyOwner {
        presaleIsActive = _presaleIsActive;
    }

    function setSaleIsActive(bool _saleIsActive) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function hashTransaction(address _sender, uint256 _qty, string memory _nonce) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_sender, _qty, _nonce)))
          );

          return hash;
    }

    function matchAddresSigner(bytes32 hash, bytes memory _signature) private view returns(bool) {
        return signerAddress == hash.recover(_signature);
    }

    function presaleMint(bytes32 hash, bytes memory _signature, string memory _nonce, uint256 _mintAmount) external payable originGuard {
        uint256 totalSupply = totalSupply();

        require(presaleIsActive, "Presale is not active");
        require(!usedAddresses[msg.sender], "ALREADY_MINTED");
        require(!usedNonces[_nonce], "HASH_USED");
        require(matchAddresSigner(hash, _signature), "DIRECT_MINT_DISALLOWED");
        require(
            _mintAmount <= MAX_PRESALE_MINT,
            "Amount exceeds presale mint limit"
        );
        require(
            totalSupply + _mintAmount <= MAX_SUPPLY,
            "Mint amount would exceed MAX_SUPPLY"
        );
        require(price * _mintAmount <= msg.value, "Incorrect Eth value");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }
        usedAddresses[msg.sender] = true;
        usedNonces[_nonce] = true;
    }

    // Public
    function mint(uint256 _mintAmount) public payable originGuard {
        uint256 totalSupply = totalSupply();

        require(saleIsActive, "Sale is not active");
        require(_mintAmount <= MAX_MINT, "Amount exceeds sale mint limit");
        require(
            totalSupply + _mintAmount <= MAX_SUPPLY,
            "Mint amount would exceed MAX_SUPPLY"
        );
        require(price * _mintAmount <= msg.value, "Incorrect Eth value");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : ".json";
    }

    // Internal
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Team Functions
    function devMint(uint256 _mintAmount) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + _mintAmount <= MAX_SUPPLY,
            "Mint amount would exceed MAX_SUPPLY"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }
    }

    function withdraw() public onlyRole(CORE_ROLE) {
        // RFG
        uint256 communityPAmount  = (address(this).balance * 27) / 1000;
        uint256 communityCFAmount = (address(this).balance * 27) / 1000;
        uint256 roadmapTSCAmount  = (address(this).balance * 7) / 100;
        uint256 operationsAmount  = (address(this).balance * 6) / 100;

        // Calculated from the rest of the balance
        uint256 teamAmount = address(this).balance -
            communityPAmount -
            communityCFAmount -
            roadmapTSCAmount -
            operationsAmount;

        // X% distributed to the team
        uint256 kfishAmount  = teamAmount.mul(75).div(1000);
        uint256 abAmount     = teamAmount.mul(5).div(100);
        uint256 travisAmount = teamAmount.mul(785).div(1000);
        uint256 cloroxoAmount  = teamAmount.mul(3).div(100);
        uint256 heemAmount   = teamAmount.mul(3).div(100);
        uint256 ginkoAmount  = teamAmount.mul(2).div(100);
        uint256 largoAmount  = teamAmount.mul(5).div(1000);
        uint256 mightyAmount = teamAmount.mul(5).div(1000);

        payable(communityP).transfer(communityPAmount);
        payable(communityCF).transfer(communityCFAmount);
        payable(roadmapTSC).transfer(roadmapTSCAmount);
        payable(operations).transfer(operationsAmount);
        payable(kfish).transfer(kfishAmount);
        payable(ab).transfer(abAmount);
        payable(travis).transfer(travisAmount);
        payable(cloroxo).transfer(cloroxoAmount);
        payable(heem).transfer(heemAmount);
        payable(ginko).transfer(ginkoAmount);
        payable(largo).transfer(largoAmount);
        payable(mighty).transfer(mightyAmount);
    }
}
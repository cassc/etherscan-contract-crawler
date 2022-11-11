//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract BeyondLand is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    string public PROVENANCE_HASH;

    uint256 public totalLandsClaimed;
    mapping(address => uint256) public claimMinted;
    bool public claimableActive = false;
    uint256 public MAX_CLAIMABLE_LANDS = 2060;

    uint256 public mintStartTime = 1668121200;
    uint256 public mintEndTime = 1668207600;
    uint256 public mintPrice = 0.1 ether;
    uint256 public MAX_PUBLIC_LANDS = 1440;

    string private baseURI;
    string private hiddenMetadataURI;
    bool public revealed;

    address private signer;
    uint256 public MAX_LANDS = 3500;
    uint256 public maxMintPerAddress = 4;

    constructor() ERC721A("Worlds Beyond Official - Genesis Land Collection", "BEYONDLG") {}

    function claimLands(uint256 numLands, uint256 maxLands, bytes calldata signature) external {
        require(
            _verify(keccak256(abi.encodePacked(msg.sender, maxLands)), signature),
            "Invalid signature"
        );
        require(claimableActive, "Mint not started");
        require(numLands + claimMinted[msg.sender] <= maxLands, "Max claimable lands per address exceeded");
        require(totalLandsClaimed + numLands <= MAX_CLAIMABLE_LANDS, "Max claimable lands exceeded");

        claimMinted[msg.sender] += numLands;
        totalLandsClaimed += numLands;
        _mintLands(msg.sender, numLands);
    }

    function mintLands(uint256 numLands) external payable {
        require(mintStartTime <= block.timestamp && block.timestamp <= mintEndTime, "Mint not started");
        require(msg.value == mintPrice * numLands, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        require(numLands + _numberMinted(msg.sender) <= maxMintPerAddress, "Max lands per address exceeded");
        require(totalLandsMinted() + numLands <= MAX_PUBLIC_LANDS, "Max public lands exceeded");

        _mintLands(msg.sender, numLands);
    }

    // Internal functions

    function _mintLands(address recipient, uint256 numLands) internal {
        require(
            totalSupply() + numLands <= MAX_LANDS,
            "Max lands supply exceeded"
        );

        _mint(recipient, numLands);
    }

    function _verify(bytes32 hash, bytes calldata signature) internal view returns (bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    // ERC721A

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // External functions

    function tokensOf(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function mintActive() external view returns (bool) {
        return mintStartTime <= block.timestamp;
    }

    function totalLandsMinted() public view returns (uint256) {
        return totalSupply() - totalLandsClaimed;
    }

    function mintedPerAddress(address owner) external view returns (uint256) {
        return _numberMinted(owner);
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

        if (!revealed) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    // Owner functions

    function setClaimableActive(bool _active) external onlyOwner {
        claimableActive = _active;
    }

    function setMintStartTime(uint256 _mintStartTime, uint256 _mintEndTime) external onlyOwner {
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
    }

    function setSupply(uint256 _maxClaimableLands, uint256 _maxPublicLands) external onlyOwner {
        MAX_CLAIMABLE_LANDS = _maxClaimableLands;
        MAX_PUBLIC_LANDS = _maxPublicLands;
        MAX_LANDS = _maxClaimableLands + _maxPublicLands;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function burnSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply > 0, "New supply must > 0");
        require(
            _newSupply < MAX_LANDS,
            "Can only reduce max supply"
        );
        require(
            _newSupply >= totalSupply(),
            "Cannot burn more than current supply"
        );
        MAX_LANDS = _newSupply;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenMetadataURI(string memory _hiddenURI) external onlyOwner {
        hiddenMetadataURI = _hiddenURI;
    }

    function setProvenanceHash(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(owner()), amount);
    }
}
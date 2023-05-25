// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface RaregotchiPetInterface {
    function mint(
        address destinationAddress,
        uint16 toyId,
        uint256[] calldata tokenIds
    ) external;
}

interface PetResolver {
    function getPetsForToy(uint256 _toyId) external returns (uint256[] memory);
    function open(uint256 _toyId, uint8 _type, uint8 _size) external;
}

interface MetadataInterface {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function packageURI(uint256 tokenId) external view returns (string memory);
    function unveil() external;
}

contract RaregotchiToy is ERC721 {
    event Unveiling();
    event ToyOpen(uint16 indexed toyId, string familyName, uint256[] petIds);

    RaregotchiPetInterface petContract;
    PetResolver petResolver;
    MetadataInterface metadataContract;

    bool private isFrozen = false;

    address public signerAddress;
    uint16 totalSupply = 0;
    uint16 maxSupply = 3000;

    mapping(uint16 => string) public toyFamilyName;
    mapping(uint256 => bool) public toyOpen;

    constructor() ERC721("RaregotchiToy", "RGT") {}

    modifier callerIsUser() {
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    /**
     * @dev Set the metadata contract address
     */
    function setMetadataContractAddress(address _address)
        external
        onlyOwner
        contractIsNotFrozen
    {
        metadataContract = MetadataInterface(_address);
    }

    /**
     * @dev Set the pet contract address
     */
    function setPetContractAddress(address _address)
        external
        onlyOwner
        contractIsNotFrozen
    {
        petContract = RaregotchiPetInterface(_address);
    }

    /**
     * @dev Set the pet contract address
     */
    function setPetResolverContractAddress(address _address)
        external
        onlyOwner
        contractIsNotFrozen
    {
        petResolver = PetResolver(_address);
    }

    function unveil() external onlyOwner {
        metadataContract.unveil();
        emit Unveiling();
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function isOpen(uint256 tokenId) external view returns (bool) {
        return toyOpen[tokenId];
    }

    function batchMint(
        address destinationAddress,
        uint256[] calldata tokenIds
    ) external onlyMinter {
        require(totalSupply < maxSupply, "The maximum number of toys is reached");
        totalSupply += uint16(tokenIds.length);
        _batchMint(destinationAddress, tokenIds);
    }

    function open(
        uint16 _tokenId,
        uint256 _fromTimestamp,
        uint8 _type,
        uint8 _size,
        string calldata _familyName,
        bytes calldata _signature
    ) external callerIsUser {
        bytes32 messageHash = generateOpenHash(
            msg.sender,
            _tokenId,
            _fromTimestamp,
            _type,
            _size,
            _familyName
        );
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(
            recoveredWallet == signerAddress,
            "Invalid signature for the caller"
        );
        require(block.timestamp >= _fromTimestamp, "Too early to open");
        require(ownerOf(_tokenId) == msg.sender, "Invalid Token ID");
        require(toyOpen[_tokenId] == false, "Token already open");

        toyOpen[_tokenId] = true;
        toyFamilyName[_tokenId] = _familyName;


        petResolver.open(_tokenId, _type, _size);
        uint256[] memory petIds = petResolver.getPetsForToy(_tokenId);

        petContract.mint(msg.sender, _tokenId, petIds);
        emit ToyOpen(_tokenId, _familyName, petIds);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
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

        return metadataContract.tokenURI(tokenId);
    }

    function packageURI(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return metadataContract.packageURI(tokenId);
    }

    // Private and Internal functions

    function generateOpenHash(
        address _address,
        uint16 _tokenId,
        uint256 _fromTimestamp,
        uint8 _type,
        uint8 _size,
        string memory _familyName
    ) internal pure returns (bytes32) {
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _address, // 20 bytes
                _tokenId, // 2 bytes (uint16)
                _fromTimestamp, // 32 bytes(uint256)
                _type,
                _size,
                _familyName
            )
        );

        bytes memory result = abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash);

        return keccak256(result);
    }
}
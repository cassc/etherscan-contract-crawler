// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Legends is ERC1155, AccessControl {
    // nft type
    enum nftType {
        Character,
        MetaverseLand,
        Food,
        Spell
    }

    // number of rarities types: COMMON=>1000, RARE=>500, EPIC=>250, LEGENDARY=>100
    uint256[] public nftCharacterRarities = [1000, 500, 250, 100];

    // A struct to store NFT Piece information
    struct nftInfo {
        address creator; // creator address of this piece type
        nftType nfttype;
        uint256 supplyAmount;
    }

    //  nonce for nft collection type
    uint256 private nonce;

    // Events
    event NftCreated(
        uint256 indexed pieceId,
        address creator,
        uint8 _type,
        uint256 _supplyNumber
    );
    event MintNFT(
        uint256 indexed pieceId,
        address minter,
        uint256 _amount,
        address _receiver
    );
    // Info about each type of Nft
    mapping(uint256 => nftInfo) private NftInfo;

    string public baseURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
        Create a new NFT
        @param _nftType NFT Type of created piece: 0:Character, 1: Metaverse, 2: Food, 3: Spell
        @param _rarity If NFT type is Character, set the rarity => 0: COMMON, 1: RARE, 2: EPIC 3:LEGENDARY
        @param _supply initial supply number of the nft except Character 
     */
    function createNft(
        nftType _nftType,
        uint8 _rarity,
        uint256 _supply
    ) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Legends: Only minters can create new NFT"
        );
        uint256 supplyNumber;
        if (_nftType == nftType.Character) {
            require(
                _rarity < 4,
                "CreateNFT: Character rarities should be less than 4."
            );
            supplyNumber = nftCharacterRarities[_rarity];
        }
        if (_nftType != nftType.Character) {
            require(
                _supply > 0,
                "CreateNFT: supply number can not be less than zero."
            );
            supplyNumber = _supply;
        }

        NftInfo[nonce++] = nftInfo(msg.sender, _nftType, supplyNumber);
        emit NftCreated(nonce - 1, msg.sender, uint8(_nftType), supplyNumber);

        // mint initial supply to the creator
        _mint(msg.sender, nonce - 1, supplyNumber, "");
    }

    /**
        Update NFT supply
        @param _nftId NFT token ID
        @param _mintAmount token new mint amount
        @param _receiver receiver address
    */
    function mintNFT(
        uint256 _nftId,
        uint256 _mintAmount,
        address _receiver
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Legends: Only minters can Mint NFT"
        );
        nftInfo storage nft = NftInfo[_nftId];
        require(
            nft.nfttype != nftType.Character,
            "MintNFT: Character type can not mint"
        );
        _mint(msg.sender, _nftId, _mintAmount, "");
        nft.supplyAmount = nft.supplyAmount + _mintAmount;
        emit MintNFT(_nftId, msg.sender, _mintAmount, _receiver);
    }

    /**
        Grant a new minter
        @param _candidate user address to be a new minter
     */
    function grantMinter(address _candidate) external {
        grantRole(MINTER_ROLE, _candidate);
    }

    /**
        Revoke a minter
        @param _minter minter address to be reverted
     */
    function revokeMinter(address _minter) external {
        revokeRole(MINTER_ROLE, _minter);
    }

    /**
        Get nonce: 
     */
    function getNonce() external view returns (uint256) {
        return nonce;
    }

    /**
        Get piece info
        @param _id piece id
     */
    function getNftInfo(uint256 _id)
        external
        view
        returns (
            address _creator,
            uint8 _type,
            uint256 _supplyAmount
        )
    {
        _type = uint8(NftInfo[_id].nfttype);
        _creator = NftInfo[_id].creator;
        _supplyAmount = NftInfo[_id].supplyAmount;
    }

    /**
        Get nft token URI
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId < nonce, "Legends: Token ID should be less than nonce");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
        Set the nft BaseURI
     */
    function setBaseURI(string calldata baseURI_) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Legends: Only minter can change the baseURI"
        );
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        returns (string memory ptr)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}
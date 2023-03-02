pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IBitQuackPassportDepature.sol";

contract BitQuackPassports is ERC721A, ERC2981, Ownable, Pausable {
    uint256 public constant MQ_BURN_PER = 10;
    uint256 public constant BITQUACK_SUPPLY = 350;

    address public mqAddress;
    address public bqtAddress;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    string public collectionInscription =
        "6152791661f84bc53c9011c0912b001d31e03893f647b91a300753e5d1273267i0";
    bool public departing;

    string public contractURIString;
    string public tokenImageString = "https://northupcrypto.mypinata.cloud/ipfs/QmP4B561dmad2SnmtqzNixAJUcaVNdJWAh1o2wFYuJt1Va";

    address[] public teleburnAddresses;

    constructor() ERC721A("BitQuack Passports", "BQP") {
        _pause();
    }

    //////// Public functions
    function mintPassport(uint256[] calldata mqIds) external whenNotPaused {
        require(mqIds.length == MQ_BURN_PER, "Burn correct number of quacks");

        // Burn the 10 quacks to get the passport
        for (uint256 i = 0; i < mqIds.length; i++) {
            IERC721(mqAddress).transferFrom(msg.sender, burnAddress, mqIds[i]);
        }

        _safeMint(msg.sender, 1);
    }

    function depart(uint256 id, string memory ordAddress) external {
        require(departing, "Not ready for depature");

        // Teleburn and transfer
        transferFrom(msg.sender, teleburnAddresses[id-1], id);
        bool success = IBitQuackPassportDepature(bqtAddress).transferOrdinal(
            id, ordAddress
        );
        require(success, "Transfer must succeed");
    }

    function supportsInterface(bytes4 interfaceId)
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
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // Cherry-picking from ERC71AQueryable
    function tokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds;
        assembly {
            tokenIds := mload(0x40)
            mstore(0x40, add(tokenIds, shl(5, add(tokenIdsLength, 1))))
            mstore(tokenIds, tokenIdsLength)
        }
        address currOwnershipAddr;
        uint256 tokenIdsIdx;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ) {
            TokenOwnership memory ownership = _ownershipAt(i);
            assembly {
                // if `ownership.burned == false`.
                if iszero(mload(add(ownership, 0x40))) {
                    if mload(ownership) {
                        currOwnershipAddr := mload(ownership)
                    }
                    if iszero(shl(96, xor(currOwnershipAddr, owner))) {
                        tokenIdsIdx := add(tokenIdsIdx, 1)
                        mstore(add(tokenIds, shl(5, tokenIdsIdx)), i)
                    }
                }
                i := add(i, 1)
            }
        }
        return tokenIds;
    }

    function contractURI() public view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "BitQuack Passport #',
                                Strings.toString(tokenId),
                                '", "description": "BitQuack Passports are a gateway token to obtaining a BitQuack ordinal through burning MoonQuacks", "image": "',
                                tokenImageString,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    //////// Admin functions

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setMQAddress(address _mqAddress) external onlyOwner {
        mqAddress = _mqAddress;
    }

    function setBQTAddress(address _bqtAddress) external onlyOwner {
        bqtAddress = _bqtAddress;
    }

    function setDeparting(bool _departing) external onlyOwner {
        departing = _departing;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ, ) = payable(msg.sender).call{value: balance}("");
        require(succ);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setTokenImageString(string memory _tokenImageString)
        external
        onlyOwner
    {
        tokenImageString = _tokenImageString;
    }

    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTeleburnAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        teleburnAddresses = _addresses;
    }

    //////// Internal functions

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}

//[email protected]_ved
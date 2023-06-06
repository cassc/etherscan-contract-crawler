//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game G1 Bud
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LL420G1Bud is Ownable, ERC721Burnable, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    uint256 public constant TOTAL_SUPPLY = 30_000;
    string public constant NAME = "LOOK LABS 420 Buds";
    string public constant SYMBOL = "BUDS";
    uint256 public constant MINT_AMOUNT = 1;

    Counters.Counter private _count;

    string private _baseTokenURI;
    address private _validator;

    /* ==================== EVENTS ==================== */

    event Initialized(string tokenURI);
    event Mint(address indexed user, address to, uint256 id);

    /* ==================== METHODS ==================== */

    /**
     * @dev Initialize the contract by setting baseUri.
     *
     * @param _tokenURI Base URI for metadata
     * @param _account Validator address
     */
    constructor(string memory _tokenURI, address _account) ERC721(NAME, SYMBOL) {
        _baseTokenURI = _tokenURI;
        _validator = _account;

        emit Initialized(_baseTokenURI);
    }

    /**
     * @dev This function allows to mint G1 Bud.
     *      The id should be generated and sent from off-chain backend.
     * @param _to Address to be sent the minted token
     * @param _id Token id to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _timestamp,
        bytes memory _signature
    ) external whenNotPaused {
        _mint(_to, _id, _timestamp, _signature);
    }

    /**
     * @dev This function allows to batch mint G1 Bud.
     *      The id should be generated and sent from off-chain backend.
     * @param _to Address to be sent the minted token
     * @param _ids Array of token ids
     * @param _timestamps Array of timestamp to verify the signature
     * @param _signatures Array of signature is generated from LL backend.
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _timestamps,
        bytes[] memory _signatures
    ) external whenNotPaused {
        require(_ids.length == _timestamps.length && _timestamps.length == _signatures.length, "Unmatched data");
        uint256 length = _ids.length;

        for (uint256 i; i < length; i++) {
            _mint(_to, _ids[i], _timestamps[i], _signatures[i]);
        }
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev Mint G1 Bud.
     * @param _to Address to be sent the minted token
     * @param _id Token id to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _timestamp,
        bytes memory _signature
    ) internal {
        require(totalMinted() < TOTAL_SUPPLY, "Reached max supply");
        require(_verify(_to, _id, _timestamp, _signature), "Not verified");

        _count.increment();
        _safeMint(_to, _id);

        emit Mint(_msgSender(), _to, _id);
    }

    /**
     * @dev Verify if the signature is right and available to mint
     *
     * @param _to Address to be sent the minted token
     * @param _id Token id to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function _verify(
        address _to,
        uint256 _id,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked(_to, keccak256("Gen1Bud"), _id, MINT_AMOUNT, _timestamp));
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != _validator) return false;

        return true;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* ==================== GETTER METHODS ==================== */

    /**
     * @dev returns total minted
     */
    function totalMinted() public view returns (uint256) {
        return uint256(_count.current());
    }

    /**
     * @dev The function checks if the token is minted or not
     * @param _id Token id to mint
     */
    function isMinted(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    /**
     * @dev The function checks if the token is minted or not
     * @param _ids Token id to mint
     */
    function isAllMinted(uint256[] memory _ids) external view returns (bool[] memory) {
        uint256 length = _ids.length;
        require(length > 0, "Zero length");

        bool[] memory result = new bool[](length);
        for (uint256 i; i < length; i++) {
            result[i] = _exists(_ids[i]);
        }

        return result;
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev Owner can set the validator address
     *
     * @param _account The validator address
     */
    function setValidator(address _account) external onlyOwner {
        _validator = _account;
    }

    /**
     * @dev Owner can set the base uri
     *
     * @param baseURI Base URI for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
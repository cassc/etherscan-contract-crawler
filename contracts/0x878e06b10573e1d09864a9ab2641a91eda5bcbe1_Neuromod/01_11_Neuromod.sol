//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./dependencies/ERC721.sol";

contract Neuromod is ERC721, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 4444;
    bool public lockedUrlChange;
    uint256 public totalSupply;
    string public provenanceHash;
    uint256 public maxId;

    mapping(address => bool) public minters;

    event LockedUrl();
    event MinterAdded(address _minter, bool _enabled);
    event UrlChanged(uint256 indexed _id, string _newUrl);
    event ProvenanceHashChanged(string _hash);

    error Unauthorized();
    error OutOfRange();
    error SupplyReached();
    error Locked();

    constructor() ERC721("Neuromod", "Neuromod") {}

    string private baseUri = "https://neuromod.io/tokens/";

    //****** EXTERNAL *******/

    /**
     * @notice minting possible only by the minters
     */
    function mintBatch(address _owner, uint16[] calldata _tokenIds) external {
        if (!minters[msg.sender]) revert Unauthorized();
        unchecked {
            uint256 length = _tokenIds.length;
            if (totalSupply + length > MAX_SUPPLY) revert SupplyReached();
            totalSupply += length;
            uint256 i;
            for (; i < length; i++) {
                if (maxId < _tokenIds[i]) maxId = _tokenIds[i];
                _mint(_owner, _tokenIds[i]);
            }
        }
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Changing base uri for reveals or in case something happens with the IPFS
     */
    function setBaseUri(string calldata _newBaseUri) external onlyOwner {
        if (lockedUrlChange) revert Locked();

        baseUri = _newBaseUri;
        emit UrlChanged(0, _newBaseUri);
    }

    /**
     * @notice Changing provenance hash once we lock everything
     */
    function setProvenanceHash(string calldata _newProvenance) external onlyOwner {
        if (keccak256(abi.encodePacked(provenanceHash)) != keccak256(abi.encodePacked(""))) revert Locked();

        provenanceHash = _newProvenance;
        emit ProvenanceHashChanged(_newProvenance);
    }

    /**
     * @notice add minter
     */
    function addMinter(address _minter, bool _enabled) external onlyOwner {
        minters[_minter] = _enabled;
        emit MinterAdded(_minter, _enabled);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @notice returns token ids owned by a owner, don t use this in another contract tho as it's gas intensive
     */
    function tokensOfOwner(address _owner) external view returns (uint16[] memory) {
        uint256 balance = balanceOf(_owner);
        uint16[] memory tokens = new uint16[](balance);
        uint256 index;
        unchecked {
            uint256 i = 1;
            for (; i <= maxId; i++) {
                if (ownerOf(i) == _owner) {
                    tokens[index] = uint16(i);
                    index++;
                }
            }
        }
        return tokens;
    }

    /**
     * @notice returns token ids batched owned by a owner
     */
    function tokensOfOwnerBatched(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (uint16[] memory) {
        if (_stop > maxId) _stop = maxId;
        uint256 balance = balanceOf(_owner);
        uint16[] memory tokens = new uint16[](balance);
        uint256 index;
        uint256 i = _start;
        unchecked {
            for (; i <= _stop; i++) {
                if (ownerOf(i) == _owner) {
                    tokens[index] = uint16(i);
                    index++;
                }
            }
        }

        return tokens;
    }

    /**
     * @notice returns owners of tokens, batched, don t use this in another contract tho as it's gas intensive
     */
    function ownersOfTokens() external view returns (address[] memory) {
        address[] memory owners = new address[](totalSupply);
        unchecked {
            uint256 i = 1;
            for (; i <= maxId; i++) {
                owners[i - 1] = ownerOf(i);
            }
        }
        return owners;
    }

    /**
     * @notice returns owners of tokens, batched
     */
    function ownersOfTokensBatched(uint256 _start, uint256 _stop) external view returns (address[] memory) {
        if (_stop > totalSupply) _stop = maxId;
        address[] memory owners = new address[](_stop - _start);
        unchecked {
            uint256 i = _start;
            for (; i <= _stop; i++) {
                owners[i - _start] = ownerOf(i);
            }
        }

        return owners;
    }

    /**
     * @notice lock changing url for ever.
     */
    function lockUrlChanging() external onlyOwner {
        lockedUrlChange = true;
        emit LockedUrl();
    }

    //****** PUBLIC *******/

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }
}
//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721.sol";

//    _____                 __                     _____        
//   /     \   ____   ____ |  | __  ______   _____/ ____\       
//  /  \ /  \ /  _ \ /    \|  |/ / /  ___/  /  _ \   __\        
// /    Y    (  <_> )   |  \    <  \___ \  (  <_> )  |          
// \____|__  /\____/|___|  /__|_ \/____  >  \____/|__|          
//         \/            \/     \/     \/                       
// _________                        __                          
// \_   ___ \_______ ___.__._______/  |_  ____   ___  _____  ___
// /    \  \/\_  __ <   |  |\____ \   __\/  _ \  \  \/ /\  \/  /
// \     \____|  | \/\___  ||  |_> >  | (  <_> )  \   /  >    < 
//  \______  /|__|   / ____||   __/|__|  \____/    \_/  /__/\_ \
//         \/        \/     |__|                              \/

contract CryptoMonksVX is DefaultOperatorFilterer, ERC721, AccessControl, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 3500;
    bool public _lockedUrlChange;
    uint256 public totalSupply;
    mapping(address => bool) public minters;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event LockedUrl();
    event MinterAdded(address _minter, bool _enabled);
    event UrlChanged(uint256 indexed _id, string _newUrl);

    error Unauthorized();
    error OutOfRange();
    error SupplyReached();
    error Locked();

    constructor() ERC721("Monks Of Crypto VX", "Monks Of Crypto VX") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    string private baseuri = "https://ipfs.io/ipfs/";

    //****** EXTERNAL *******/

    /**
     * @notice minting
     */
    function mintBatch(address _owner, uint16[] calldata _tokenIds) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");
        unchecked {
            uint256 length = _tokenIds.length;
            if (totalSupply + length > MAX_SUPPLY) revert SupplyReached();
            totalSupply += length;
            for (uint256 i; i < length; i++) _mint(_owner, _tokenIds[i]);
        }
    }

    function mint(address _owner, uint256 _tokenId) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");
        unchecked {
            if (totalSupply >= MAX_SUPPLY) revert SupplyReached();
            totalSupply++;
            _mint(_owner, _tokenId);
        }
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "Missing BURNER_ROLE");
        _burn(_tokenId);
    }

    /**
     * @notice Changing base uri for reveals or in case something happens with the IPFS
     */
    function setBaseUri(string calldata _newBaseUri) external onlyOwner {
        if (_lockedUrlChange) revert Locked();

        baseuri = _newBaseUri;
        emit UrlChanged(0, _newBaseUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseuri;
    }

    /**
     * @notice returns token ids owned by a owner, don't use this onchain
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            unchecked {
                uint256[] memory result = new uint256[](tokenCount);
                uint256 index;
                uint256 i = 1;
                for (i; i < MAX_SUPPLY; i++) {
                    if (ownerOf(i) == _owner) {
                        result[index] = i;
                        index++;
                    }
                }
                return result;
            }
        }
    }
    

    /**
     * @notice returns token ids batched owned by a owner, don't use this onchain
     */
    function tokensOfOwnerBatched(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (uint16[] memory) {
        if (_stop > MAX_SUPPLY) _stop = MAX_SUPPLY;
        uint256 balance = balanceOf(_owner);
        uint16[] memory tokens = new uint16[](balance);
        uint256 index;
        for (uint256 i = _start; i <= _stop; ) {
            unchecked {
                if (ownerOf(i) == _owner) {
                    tokens[index] = uint16(i);
                    index++;
                }
                i++;
            }
        }

        return tokens;
    }

    /**
     * @notice returns token ids owned by a owner, don't use this onchain
     */
    function ownersOfTokens() external view returns (address[] memory) {
        address[] memory owners = new address[](totalSupply);
        unchecked {
            for (uint256 i = 1; i <= totalSupply; i++) {
                owners[i - 1] = ownerOf(i);
            }
        }
        return owners;
    }

    /**
     * @notice returns token ids batched owned by a owner, don't use this onchain
     */
    function ownersOfTokensBatched(uint256 _start, uint256 _stop) external view returns (address[] memory) {
        if (_stop > totalSupply) _stop = totalSupply;
        address[] memory owners = new address[](totalSupply);
        for (uint256 i = _start; i <= _stop; ) {
            unchecked {
                owners[i - _start] = ownerOf(i);
                i++;
            }
        }

        return owners;
    }

    /**
     * @notice lock changing url for ever.
     */
    function lockUrlChanging() external onlyOwner {
        _lockedUrlChange = true;
        emit LockedUrl();
    }

    //****** PUBLIC *******/

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

        function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
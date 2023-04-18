// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../lib/Base64.sol";
import "../lib/Rescuable.sol";
import "../lib/image/GIF32.sol";
import "../lib/image/PixelSVG.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

interface ICustomAttributes {
    function getCustomAttributes () external view returns (bytes memory);
}

interface ITokenizedContract {
    function resolverClaim (address newOwner) external;
}

interface IReverseRegistrar {
    function claim (address owner) external returns (bytes32);
}

/*
 * @title Codex
 * @author Ponderware Ltd
 * @dev tokenizes contracts including itself
 */
contract Codex is ERC721, ERC2981, Pausable, Rescuable {

    event ENSError();

    bytes32 immutable internal salt;

    constructor () ERC721("codex", "c.l") {
        salt = keccak256("code.lawless");
        handleMint("codex",
                   "tokenizes primary code.lawless contracts - including itself" ,
                   hex"131a0000131a0703009c9b20208e64699e68aa8a4141441331cd743c454411b40424fd8460f02781e4762e8872c95c1e5b2ea1745ad041abd8acd6baed6691dbddf53bae06160d4699fb7520446a2d181b6800020a47796e6600140a0b7b6504010e870139645b853b8a8b8c415d7c5e7250410b990e69809d663c3b0b08a3a43b080e9f2e3b6e253b000fa98d0d6f7f803b81b13b7eb5b6780d56a0789dc39e012bc7c82321001a1920208e64699e68aaae6cebbe702ccf746ddf78aeef7ceff72100a8a720208e646906a8a98e015110d234ad64fb425014cfab4de09b4d2e96aab97e41a1301228048c372150d77cb28e106964239154a1c85c84437482211c4897d3997caf370e5bd269bf45be5cbd2bbb037c3a5d1204840566702f8485868656782e8c91918e7f9092929436978a8d508c8a0aa17e9a840e0d0a08080ca3900b0ba9b00dac860b280809b80eb305ba01b8a1ab949586b201a1a13d900ac6c83436cc0a342c45d22221007e7d20208e24109c653a4e4481aae524b52f0c10724407f61d4491ceae470874229ca1adc8412a61454964f35445a7d51413ebe22d031b6ecdfa8b40b2a522648d2611deef4297d892cbc7da46fcee85321c0b7578690a010881734b85087a89508b0a6d23049092230a0908918e36989b832a0a9f7d3d00a3a52527a40021",
                   0,
                   msg.sender,
                   address(this));
        IReverseRegistrar(ENSReverseRegistrar).claim(msg.sender);
    }

    address public ENSReverseRegistrar = 0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb;
    address public ENSReverseResolver = 0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;
    address public ENS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    function setENSAddresses (address ens, address reverseRegistrar, address reverseResolver) public onlyOwner {
        ENS = ens;
        ENSReverseRegistrar = reverseRegistrar;
        ENSReverseResolver = reverseResolver;
    }

    struct TokenDetails {
        address contractAddress;
        string name;
        string description;
        bytes image;
    }

    TokenDetails[] internal Details;

    function totalSupply () public view returns (uint256) {
        return Details.length;
    }

    function tokenAddress (uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return Details[tokenId].contractAddress;
    }

    function owner() public view returns (address) {
        return ownerOf(0);
    }

    modifier onlyOwner () {
        require(msg.sender == owner(), "Not Owner");
        _;
    }

    bool public frozen = false;

    modifier whenNotFrozen () {
        require(!frozen, "Frozen");
        _;
    }

    function freeze () public onlyOwner {
        frozen = true;
    }

    function pause () public onlyOwner {
        _pause();
    }

    function unpause () public onlyOwner {
        _unpause();
    }

    function updateDetails (uint tokenId, string memory name, string memory description, bytes memory image) public onlyOwner whenNotFrozen {
        _requireMinted(tokenId);
        TokenDetails storage details = Details[tokenId];
        details.name = name;
        details.description = description;
        details.image = image;
    }

    function resolverClaim (address newOwner) public {
        require (msg.sender == address(this), "not codex");
        try IReverseRegistrar(ENSReverseRegistrar).claim(newOwner) {
        } catch {
            emit ENSError();
        }
    }

    bool internal notMinting = true;

    mapping (address => bool) internal childContracts;

    function handleMint (string memory name, string memory description, bytes memory image, uint256 tokenId, address to, address contractAddress) internal {
        Details.push(TokenDetails(contractAddress, name, description, image));
        notMinting = false;
        _safeMint(to, tokenId, "");
        notMinting = true;
    }

    function mint (string memory name, string memory description, bytes memory image, bytes calldata bytecode) public onlyOwner whenNotFrozen whenNotPaused {
        uint256 tokenId = totalSupply();
        bytes memory bytecode = abi.encodePacked(bytecode, abi.encode(tokenId));
        address addr = Create2.computeAddress(salt, keccak256(bytecode));
        handleMint(name, description, image, tokenId, owner(), addr);
        Create2.deploy(0, salt, bytecode);
        ITokenizedContract(addr).resolverClaim(owner());
        childContracts[addr] = true;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        safeTransferFrom(owner(), newOwner, 0);
    }

    function safeTokenTransferOwnership (uint tokenId, address newOwner) public {
        _requireMinted(tokenId);
        require (tokenAddress(tokenId) == msg.sender, "not token contract");
        _safeTransfer(ownerOf(tokenId), newOwner, tokenId, "");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return assembleMetadata(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(!paused(), "ERC721Pausable: token transfer while paused");

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        if (notMinting) {
            ITokenizedContract(tokenAddress(tokenId)).resolverClaim(to);
        }
    }

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[_owner][index];
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /* Images */

    struct Model {
        uint8 width;
        uint8 height;
        uint8 aniX;
        uint8 aniY;
        uint8 aniWidth;
        uint8 aniHeight;
        uint8 offsetX;
        uint8 offsetY;
        bytes f1;
        bytes f2;
        bytes f3;
        bytes f4;
    }

    function slice(uint begin, uint len, bytes memory arr) internal pure returns (bytes memory) {
        bytes memory res = new bytes(len);
        for (uint i = 0; i < len; i++) {
            res[i] = arr[i+begin];
        }
        return res;
    }

    function slice2(uint loc, bytes memory arr) internal pure returns (uint) {
        uint res = uint(uint8(arr[loc])) << 8;
        return (res + uint8(arr[loc + 1]));
    }

    function unpackModel (bytes memory input) internal pure returns (Model memory) {

        uint pointer = 8;
        uint len = slice2(pointer, input);
        pointer += 2;
        bytes memory f1 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f2 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f3 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f4 = slice(pointer, len, input);

        return Model(uint8(bytes1(input[0])),
                     uint8(bytes1(input[1])),
                     uint8(bytes1(input[2])),
                     uint8(bytes1(input[3])),
                     uint8(bytes1(input[4])),
                     uint8(bytes1(input[5])),
                     uint8(bytes1(input[6])),
                     uint8(bytes1(input[7])),
                     f1,
                     f2,
                     f3,
                     f4);
    }


    uint8 constant MCS = 5;

    bytes constant Chroma = hex"554d3f0303033927203c322e0e0c0a161410211e17262525595959808080aaaaaae6e6e6b0b08bbdbd9cdfdfc4e6dfd89e8e70d4be95f8dfaffefed2332e244e443272654f92826500ffffffff00ff0000ff009cff3fd4ff5bf3ff9affffcaff";

    function animatedGIF (Model memory m, bytes memory chroma) internal pure returns (string memory) {
        bytes memory framedata = abi.encodePacked(abi.encodePacked(GIF32.gce(false, 100, 0),
                                                                   GIF32.frame(0, 0, m.width, m.height, MCS, m.f1)),

                                                  GIF32.gce(true, 1, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f2),

                                                  GIF32.gce(true, 100, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f3),

                                                  GIF32.gce(true, 100, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f4));
        bytes memory gif = GIF32.assembleAnimated(m.width, m.height, framedata, MCS, chroma);
        return string(abi.encodePacked("data:image/gif;base64,", Base64.encode(gif)));
    }

    function getRGB (bytes memory chroma, uint index) internal pure returns (bytes memory) {
        uint r = uint8(chroma[index * 3]);
        uint g = uint8(chroma[index * 3 + 1]);
        uint b = uint8(chroma[index * 3 + 2]);
        return abi.encodePacked("rgb(", Strings.toString(r),",", Strings.toString(g),",", Strings.toString(b),")");
    }

    uint constant private SCALE_FACTOR = 18;

    function position (Model memory m) internal pure returns (int x, int y, uint width, uint height) {
        width = m.width * SCALE_FACTOR;
        height = m.height * SCALE_FACTOR;
        x = int(uint(m.offsetX) * SCALE_FACTOR) + 12;
        y = int(uint(m.offsetY) * SCALE_FACTOR) + 12;
    }

    function assembleSVG (bytes memory image) internal pure returns (bytes memory) {
        Model memory m = unpackModel(image);
        (int x, int y, uint width, uint height) = position(m);
        bytes memory chroma = Chroma;
        string memory gif = animatedGIF(m, chroma);
        bytes memory img = PixelSVG.img(x, y, width, height, gif);
        return abi.encodePacked("data:image/svg+xml;base64,",
                                Base64.encode(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMidYMid meet' viewBox='0 0 600 600' width='600' height='600'>",
                                                               "<rect x='0' y='0' width='600' height='600' fill='",
                                                               getRGB(chroma, 0),
                                                               "' />",
                                                               img,
                                                               "</svg>")));
    }

    /* Metadata */

    function encodeStringAttribute (string memory key, string memory value) public pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":\"",value,"\"}");
    }

    function encodeNumericAttribute (string memory key, uint256 value) public pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",Strings.toString(value),",\"display_type\":\"number\"}");
    }

    function toB64JSON (string memory name,
                        string memory description,
                        bytes memory attributes,
                        bytes memory image)
        internal pure returns (string memory) {
        bytes memory json = abi.encodePacked("{\"attributes\":[",
                                             attributes,
                                             "], \"name\":\"",
                                             name,
                                             "\", \"description\":\"",
                                             description,
                                             "\",\"image\":\"",
                                             image,
                                             "\"}"
                                             );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    function contractDetails (address contractAddress) internal view returns (bytes memory) {
        if(!ERC165Checker.supportsERC165(contractAddress)) return bytes("");

        bytes memory result;

        if (ERC165Checker.supportsInterface(contractAddress, type(ICustomAttributes).interfaceId)) { // Custom Metadata
            result = abi.encodePacked(",", ICustomAttributes(contractAddress).getCustomAttributes());
        }

        if (ERC165Checker.supportsInterface(contractAddress, 0xd9b67a26)) { // ERC-1155
            result = abi.encodePacked(result, ",", encodeStringAttribute("token type", "ERC-1155"));
        } else if (ERC165Checker.supportsInterface(contractAddress, 0x780E9D63)) { // ERC-721 Enumerable
            result = abi.encodePacked(",", encodeStringAttribute("token type", "ERC-721"),
                                      ",", encodeNumericAttribute("total supply", IERC721Enumerable(contractAddress).totalSupply()));
        }

        return result;
    }

    function assembleMetadata (uint tokenId) internal view returns (string memory) {
        TokenDetails memory details = Details[tokenId];
        return toB64JSON(details.name,
                         details.description,
                         abi.encodePacked(encodeStringAttribute("address", Strings.toHexString(details.contractAddress)),
                                          contractDetails(details.contractAddress)),
                         assembleSVG(details.image));
    }

    function withdraw() public onlyOwner {
        _withdraw(owner());
    }

    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        _withdrawForeignERC20(owner(), tokenContract);
    }

    function withdrawForeignERC721(address tokenContract, uint256 _tokenId) public onlyOwner {
        _withdrawForeignERC721(owner(), tokenContract, _tokenId);
    }

    function executeAction (address target, bytes calldata payload)
        public
        payable
        onlyOwner
        returns(bytes memory)
    {
        require(!childContracts[target] && target != address(this), "child contract");
        (bool success, bytes memory data) = target.call{ value: msg.value }(payload);
        if (success) {
            return data;
        } else {
            if (data.length == 0) {
                revert("Action Failed");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                        }
            }
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoFiSkylines is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public max_supply = 3333;
    string private _contractURI;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    string animationCode;
    string animationURI;
    address payable admin;

    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bytes32) bHash;

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only Owner allowed");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address payable _admin,
        string memory _animationURI,
        address openseaProxyRegistry_
    ) ERC721(_name, _symbol) {
        admin = _admin;
        animationURI = _animationURI;
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(
            uint256(100000000000000000).mul(_amount) == msg.value,
            "Invalid value"
        );
        require(_amount <= 20, "Cannot mint more than 20 at a time");
        require(
            _tokenIds.current().add(_amount) <= max_supply,
            "Mint exceeds max supply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            _mint(msg.sender, newNftTokenId);
            bHash[newNftTokenId] = bytes32(
                keccak256(abi.encodePacked(address(msg.sender), newNftTokenId))
            );
        }
    }

    function setAnimationCode(string memory newAnimationCode) public onlyAdmin {
        animationCode = newAnimationCode;
    }

    function setAnimationURI(string memory newAnimationURI) public onlyAdmin {
        animationURI = newAnimationURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        string memory seed = bytes32ToString(bHash[_tokenId]);
        string memory baseColor = strSlice(59, 64, seed);
        string memory fg = baseColor;
        string memory bg = getBG(baseColor);
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    uint2str(_tokenId),
                    '","animation_url":"',
                    animationURL(_tokenId, seed),
                    '","image_data":"',
                    baseImg(fg, bg),
                    '"}'
                )
            );
    }

    function animationURL(uint256 _tokenId, string memory _seed)
        internal
        view
        returns (string memory)
    {
        return string(abi.encodePacked(animationURI, _seed));
    }

    function baseImg(string memory fg, string memory bg)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' width='512px' height='512px'>",
                    "<rect width='100%' height='100%' fill='",
                    bg,
                    "'/>",
                    "<text x='194' y='224' font-size='64' fill='#",
                    fg,
                    "'>LoFi</text>",
                    "<text x='134' y='288' font-size='64' fill='#",
                    fg,
                    "'>SkyLines</text>",
                    "<rect x='20' y='256' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='100' y='325' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='175' y='450' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='250' y='400' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='325' y='475' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='400' y='275' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "<rect x='475' y='375' width='50' height='512' fill-opacity='0' stroke='#",
                    fg,
                    "'/>",
                    "</svg>"
                )
            );
    }

    function getBG(string memory _seedColor)
        internal
        pure
        returns (string memory)
    {
        string memory s1 = strSlice(1, 2, _seedColor);
        string memory s2 = strSlice(3, 4, _seedColor);
        string memory s3 = strSlice(5, 6, _seedColor);
        uint256 ss1 = fromHex(s1);
        uint256 ss2 = fromHex(s2);
        uint256 ss3 = fromHex(s3);

        uint256 i1 = ss1 ^ uint256(255);
        uint256 i2 = ss2 ^ uint256(255);
        uint256 i3 = ss3 ^ uint256(255);

        return
            string(
                abi.encodePacked(
                    "#",
                    toHexString(i1),
                    toHexString(i2),
                    toHexString(i3)
                )
            );
    }

    function withdraw(uint256 amount) external payable onlyAdmin {
        require(amount <= address(this).balance);
        admin.transfer(amount);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    function strSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
    }

    function fromHex(string memory s) public pure returns (uint256) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0);
        bytes memory r = new bytes(ss.length / 2);
        uint256 total;
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            total += (fromHexChar(uint8(ss[2 * i])) *
                16 +
                fromHexChar(uint8(ss[2 * i + 1])));
        }
        return total;
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyAdmin
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
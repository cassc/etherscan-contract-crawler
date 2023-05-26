pragma solidity >0.6.1 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./LuckyProvable.sol";
import "./LuckyRaffle.sol";

interface ILuckyManekiNFT {
    function revealOffset() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);
}

contract LuckyManekiNFT is ERC721, Ownable, ReentrancyGuard {
    LuckyProvable ctxProvable;
    LuckyRaffle ctxRaffle;
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    string public constant PROVENANCE = "a174be7664367c61bd7dd5ae2c7b90c1a167bf8d6bf6ec2682273aabdab2c85b";
    uint256 public constant MAX_SUPPLY = 14159;
    uint256 public reserveRemain;
    uint256 public revealOffset;
    mapping(uint256 => string) private _tokenNames;
    mapping(string => bool) private _namesUsed;
    bool public isActive;
    uint256 public withdrawn = 0;
    uint256 public fundsReserved = 0;
    event Named(uint256 indexed index, string name);

    constructor() public ERC721("LuckyManekiNFT", "LMK") {
        isActive = false;
        reserveRemain = 350;
        _setBaseURI("https://luckymaneki.com/token/");
    }

    function setupRaffleProvable(address raffle, address provable)
        public
        onlyOwner
    {
        ctxRaffle = LuckyRaffle(payable(raffle));
        ctxProvable = LuckyProvable(payable(provable));
    }

    function mint(uint256 qty) public payable nonReentrant {
        require(isActive, "!active");
        require(qty <= 20, "qty>$(MAX_QTY)");
        require(
            (totalSupply() + qty + reserveRemain) <= (MAX_SUPPLY),
            "qty>supply"
        );
        require(msg.value == salePrice().mul(qty), "payment");

        fundsReserved = fundsReserved + msg.value.mul(10).div(100);
        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function ownerOfAux(uint256 index) public view returns (address owner) {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSelector(
                bytes4(keccak256("ownerOf(uint256)")),
                (index)
            )
        );
        if (success) {
            address _owner = abi.decode(returnData, (address));
            return _owner;
        } else {
            return address(0x0);
        }
    }

    function __execReveal(uint256 _index, uint256 rand) public {
        _index;
        require(msg.sender == address(ctxProvable), "sender!=provable");
        require(revealOffset == 0, "!!reveal");
        revealOffset = (rand % (MAX_SUPPLY));
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function salePrice() public pure returns (uint256) {
        return 0.075 ether;
    }

    /*
    -------------------------------------
    NAMING
    -------------------------------------
    */
    function setName(uint256 tokenId, string memory name) public {
        require(revealOffset > 0, "!reveal");
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "!token.owner");
        require(validateName(name) == true, "!name.valid");
        require(isNameUsed(name) == false, "name.used");
        if (bytes(_tokenNames[tokenId]).length > 0) {
            _namesUsed[toLower(_tokenNames[tokenId])] = false;
        }
        _namesUsed[toLower(name)] = true;
        _tokenNames[tokenId] = name;
        emit Named(tokenId, name);
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return _tokenNames[index];
    }

    function isNameUsed(string memory nameString) public view returns (bool) {
        return _namesUsed[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3) return false;
        if (b.length > 32) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;
        bytes1 lastChar = b[0];
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (char == 0x20 && lastChar == 0x20) return false;
            if (
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x20)
            ) return false;
            lastChar = char;
        }
        return true;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /*
    -------------------------------------
    ADMIN
    -------------------------------------
    */

    function setActive(bool val) external onlyOwner {
        isActive = val;
    }

    function reserve(uint256 qty) external onlyOwner {
        require(qty <= reserveRemain, "qty");
        require((totalSupply() + qty) <= MAX_SUPPLY, "qty>supply");
        reserveRemain = reserveRemain.sub(qty);
        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function withdrawSafe(address recipient, uint256 amt) external onlyOwner {
        require(
            (amt+withdrawn+fundsReserved) <= (address(this).balance),
            "insuff"
        );
        withdrawn = withdrawn + amt;
        (bool success, ) = payable(recipient).call{value: amt}("");
        require(success, "ERROR");
    }

    function withdrawUnsafe(address recipient, uint256 amt) external onlyOwner {
        (bool success, ) = payable(recipient).call{value: amt}("");
        require(success, "ERROR");
    }

    function sendRafflePrize(address recipient, uint256 amt)
        public
        returns (bool)
    {
        require(msg.sender == address(ctxRaffle), "sender!=raffle");
        require(recipient != address(0x0));
        fundsReserved = fundsReserved.sub(amt);

        (bool success, ) = payable(recipient).call{value: amt}("");

        require(success, "FAILED");
        return success;
    }

    receive() external payable {}
}
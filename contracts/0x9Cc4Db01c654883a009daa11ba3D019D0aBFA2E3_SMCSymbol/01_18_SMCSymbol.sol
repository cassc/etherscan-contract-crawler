// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ISMCSymbol.sol";
import "./IApprovalProxy.sol";

abstract contract SMCSymbolERC721 is
    ISMCManager,
    ERC721Enumerable,
    AccessControl,
    Pausable,
    Ownable
{
    using Address for address;
    using Strings for uint256;

    event UpdateApprovalProxy(address _newProxyContract);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    ISMCSymbolDescriptor public SMCSymbolDescriptorContract;
    ISMCSymbolData public SMCSymbolDataContract;
    IApprovalProxy public approvalProxy;

    string public Respect;
    uint256 public RespectColorCode;

    string[] private codesOfArts;

    uint256[] private limit = [0, 0, 4200, 700, 10, 1, 0, 0, 0, 0];
    uint256[] private rights = [0, 0, 1, 7, 100, 5000, 0, 0, 0, 0];

    uint256[] private katanaPattern5 = [11111111];
    uint256[] private katanaPattern4;
    uint256[] private katanaPattern3 = [
        11010100,
        11010010,
        11001010,
        10101010,
        10101001,
        10100101,
        10010101
    ];
    uint256[] private katanaPattern2 = [
        10000001,
        10000010,
        10000100,
        10001000,
        10010000,
        10100000,
        11000000
    ];

    constructor(
        string memory _name,
        string memory _synbol,
        string memory _respect,
        uint256 _respectColorCode,
        uint256 _katanaPattern4,
        string[] memory _codeOfArts
    ) ERC721(_name, _synbol) {
        Respect = _respect;
        RespectColorCode = _respectColorCode;
        katanaPattern4.push(_katanaPattern4);
        codesOfArts = _codeOfArts;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function setDescriptorContract(address descriptor) public onlyOwner {
        SMCSymbolDescriptorContract = ISMCSymbolDescriptor(descriptor);
    }

    function setDataContract(address dataContract) public onlyOwner {
        SMCSymbolDataContract = ISMCSymbolData(dataContract);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        require(isValidTokenId(tokenId), "SMCERC721: invalid tokenId");
        _mint(to, tokenId);
    }

    function mint(address[] memory tos, uint256[] memory tokenIds) public {
        require(
            tos.length == tokenIds.length,
            "SMCERC721: mint args must be equals"
        );
        for (uint256 i; i < tos.length; i++) {
            mint(tos[i], tokenIds[i]);
        }
    }

    function mintFor(
        address to,
        uint256 tokenId,
        bytes calldata mintingBlob
    ) public {
        mint(to, tokenId);
    }

    function setApprovalProxy(address _new) public onlyOwner {
        approvalProxy = IApprovalProxy(_new);
        emit UpdateApprovalProxy(_new);
    }

    function setApprovalForAll(address _spender, bool _approved)
        public
        virtual
        override(ERC721, IERC721)
    {
        if (
            address(approvalProxy) != address(0x0) &&
            Address.isContract(_spender)
        ) {
            approvalProxy.setApprovalForAll(msg.sender, _spender, _approved);
        }
        super.setApprovalForAll(_spender, _approved);
    }

    function isApprovedForAll(address _owner, address _spender)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        bool original = super.isApprovedForAll(_owner, _spender);
        if (address(approvalProxy) != address(0x0)) {
            return approvalProxy.isApprovedForAll(_owner, _spender, original);
        }
        return original;
    }

    function pause() external onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MINTER_ROLE) {
        _unpause();
    }

    function getTypeId(uint256 tokenId) public view returns (uint256) {
        require(isValidTokenId(tokenId), "SMCSymbol: invalid token id");
        return tokenId / 10000;
    }

    function getSerial(uint256 tokenId) public view returns (uint256) {
        require(isValidTokenId(tokenId), "SMCSymbol: invalid token id");
        return tokenId % 10000;
    }

    function getIndex(uint256 tokenId) public view returns (uint256) {
        require(isValidTokenId(tokenId), "SMCSymbol: invalid token id");
        uint256 rarityDigit = getRarityDigit(tokenId);
        uint256 offset = 0;
        for (uint256 i = limit.length - 1; i > rarityDigit; i--) {
            offset += limit[i];
        }
        return offset + getSerial(tokenId);
    }

    function getRespect() public view override returns (string memory) {
        return Respect;
    }

    function getRespectColorCode() public view override returns (uint256) {
        return RespectColorCode;
    }

    function getCodesOfArt(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, "COA", codesOfArts);
    }

    function getRarity(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return SMCSymbolDataContract.Rarities()[getRarityDigit(tokenId)];
    }

    function getSamurights(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return rights[getRarityDigit(tokenId)];
    }

    function getName(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory firstName = pluck(
            tokenId,
            "FIRSTNAME",
            SMCSymbolDataContract.FirstNames()
        );
        string memory initial = pluck(
            tokenId,
            "INITIAL",
            SMCSymbolDataContract.Initials()
        );

        return string(abi.encodePacked(firstName, " ", initial));
    }

    function getNativePlace(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            pluck(tokenId, "NATIVEPLACE", SMCSymbolDataContract.NativePlaces());
    }

    function getJapaneseZodiac(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            pluck(tokenId, "ZODIAC", SMCSymbolDataContract.JapaneseZodiacs());
    }

    function getColorLCode(uint256) public view override returns (uint256) {
        return RespectColorCode;
    }

    function getColorL(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return SMCSymbolDataContract.Colors()[getColorLCode(tokenId)];
    }

    function getColorRCode(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        string[] memory colors = SMCSymbolDataContract.Colors();
        string[] memory patterns = SMCSymbolDataContract.Patterns();
        uint256 rarityDigit = getRarityDigit(tokenId);
        if (rarityDigit != 2) {
            return RespectColorCode;
        }

        uint256 code = (((getSerial(tokenId) - 1) /
            getKatanaPattern(rarityDigit).length /
            (patterns.length - 1) /
            (patterns.length - 1)) % (colors.length - 2)) + 1;

        if (code == RespectColorCode) {
            return colors.length - 1;
        }
        return code;
    }

    function getColorR(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[] memory colors = SMCSymbolDataContract.Colors();
        return colors[getColorRCode(tokenId)];
    }

    function getPatternLCode(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        string[] memory patterns = SMCSymbolDataContract.Patterns();

        uint256 rarityDigit = getRarityDigit(tokenId);

        if (rarityDigit == 5) {
            return 10;
        }

        if (rarityDigit == 4) {
            return 10;
        }

        uint256 code = ((getSerial(tokenId) - 1) /
            getKatanaPattern(rarityDigit).length /
            (patterns.length - 1)) % (patterns.length - 1);
        return code;
    }

    function getPatternL(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[] memory patterns = SMCSymbolDataContract.Patterns();

        return patterns[getPatternLCode(tokenId)];
    }

    function getPatternRCode(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        string[] memory patterns = SMCSymbolDataContract.Patterns();

        uint256 rarityDigit = getRarityDigit(tokenId);

        if (rarityDigit == 5) {
            return 10;
        }

        uint256 code = ((getSerial(tokenId) - 1) /
            getKatanaPattern(rarityDigit).length) % (patterns.length - 1);
        return code;
    }

    function getPatternR(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[] memory patterns = SMCSymbolDataContract.Patterns();

        return patterns[getPatternRCode(tokenId)];
    }

    function getKatanaPattern(uint256 rarity)
        private
        view
        returns (uint256[] memory)
    {
        if (rarity == 5) {
            return katanaPattern5;
        }
        if (rarity == 4) {
            return katanaPattern4;
        }
        if (rarity == 3) {
            return katanaPattern3;
        }
        if (rarity == 2) {
            return katanaPattern2;
        }
        require(true, "invalid rarity katana");
        uint256[] memory dummy;
        return dummy;
    }

    function getActivatedKatana(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluckKatana(tokenId, getKatanaPattern(getRarityDigit(tokenId)));
    }

    function pluckKatana(uint256 tokenId, uint256[] memory sourceArray)
        internal
        view
        returns (string memory)
    {
        uint256 code = (getSerial(tokenId) - 1) % sourceArray.length;
        uint256 katana = sourceArray[code] * RespectColorCode;
        bytes memory strBytes = bytes(katana.toString());
        bytes memory result = new bytes(7);

        // triming first digit
        for (uint256 i = 1; i < 8; i++) {
            result[i - 1] = strBytes[i];
        }
        return string(result);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(isValidTokenId(tokenId), "SMCSymbol: invalid tokenId");
        return
            ISMCSymbolDescriptor(SMCSymbolDescriptorContract).tokenURI(
                this,
                tokenId
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function getRarityDigit(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        require(isValidTokenId(tokenId), "SMCSymbol: invalid tokenId");
        return tokenId / 10000000;
    }

    function isValidTokenId(uint256 tokenId) internal view returns (bool) {
        uint256 r = tokenId / 10000000;
        if (r > 9) {
            return false;
        }

        uint256 l = limit[r];
        uint256 serial = tokenId % 10000;

        if (serial == 0) {
            return false;
        }

        if (serial > l) {
            return false;
        }

        return true;
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(keyPrefix, tokenId);
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function random(string memory prefix, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return random(string(abi.encodePacked(prefix, tokenId.toString())));
    }

    function random(string memory input) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(RespectColorCode.toString(), input))
            );
    }
}

contract SMCSymbol is SMCSymbolERC721 {
    constructor(
        string memory _name,
        string memory _synbol,
        string memory _respect,
        uint256 _respectColorCode,
        uint256 _katanaPattern4,
        string[] memory _codeOfArts
    )
        SMCSymbolERC721(
            _name,
            _synbol,
            _respect,
            _respectColorCode,
            _katanaPattern4,
            _codeOfArts
        )
    {}
}
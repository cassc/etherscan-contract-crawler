//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/access/controllerPanel.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Generic721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma abicoder v2;

contract Base721 is Generic721, controllerPanel {
    using Strings for uint256;
    // This is a packed array of booleans.

    mapping(uint16 => uint8) internal tokenData;
    event whitelistMintEvent(uint64, address);
    event forgeAllEvent(uint64[]);
    string public baseURI = "https://client-metadata.ether.cards/api/ENS_NFT/";
    address public presigner;
    mapping(uint64 => mapping(address => bool)) public whitelist_claimed;

    constructor(
        string memory name,
        string memory symbol,
        address _presigner
    ) Generic721(name, symbol) {
        presigner = _presigner;
    }

    function changePresigner(address _presigner) external onlyOwner {
        presigner = _presigner;
    }

    function addCardClass(
        string memory _className,
        uint64 _start, // class starting serial
        uint64 _end, // class end serial
        uint128 _salesTime
    ) public override onlyOwner {
        Generic721.addCardClass(_className, _start, _end, _salesTime);
    }

    function ManOverrideCard(
        uint64 _cardID,
        string memory _className,
        uint64 _start,
        uint64 _end,
        uint64 _initial,
        uint64 _minted
    ) public override onlyOwner {
        Generic721.ManOverrideCard(
            _cardID,
            _className,
            _start,
            _end,
            _initial,
            _minted
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setDataFolder(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(string(_baseURI()), "contract.json"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // reformat to directory structure as below
        string memory folder = (tokenId % 100).toString();
        string memory file = tokenId.toString();
        string memory slash = "/";
        return
            string(
                abi.encodePacked(
                    string(_baseURI()),
                    folder,
                    slash,
                    file,
                    ".json"
                )
            );
    }

    receive() external payable {
        // React to receiving ether
    }

    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }

    function batchMint(
        address _receiver,
        uint64 _cardType,
        uint256 _howMany
    ) external onlyAllowed {
        for (uint64 i = 1; i <= _howMany; i++) {
            mint(_receiver, _cardType);
        }
    }

    function mintTest(address _receiver, uint64 _cardType)
        external
        onlyAllowed
    {
        mint(_receiver, _cardType);
    }

    function mint(address _receiver, uint64 _cardType)
        internal
        returns (uint256)
    {
        uint256 _newItemId = Generic721.getCardTypeNextID(_cardType);
        require(_newItemId != 0, "seriesEnded");
        Generic721._safeMint(_receiver, _newItemId);
        return _newItemId;
    }

    function whitelistMint(uint64 _cardType, bytes memory signature) public {
        // Validate.
        require(verify(_cardType, msg.sender, signature), "!sig");
        require(!whitelist_claimed[_cardType][msg.sender], "claimed");
        mint(msg.sender, _cardType);
        whitelist_claimed[_cardType][msg.sender] = true;
        emit whitelistMintEvent(_cardType, msg.sender);
    }

    function verify(
        uint64 _cardType,
        address _user,
        bytes memory _signature
    ) public view returns (bool) {
        require(_user != address(0), "NativeMetaTransaction: INVALID__user");
        bytes32 _hash =
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(_user, _cardType))
            );
        require(_signature.length == 65, "Invalid signature length");
        address recovered = ECDSA.recover(_hash, _signature);
        return (presigner == recovered);
    }

    function _setClaimed(uint16 _position) internal {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        tokenData[byteNum] = uint8(tokenData[byteNum] | (2**bitPos));
    }

    function isClaimed(uint16 _position) public view returns (bool result) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (tokenData[byteNum] == 0) return false;
        return tokenData[byteNum] & (0x01 * 2**bitPos) != 0;
    }

    function forgeAll(uint64[] memory tokenIds) public {
        require(tokenIds.length == 12, "!length");
        for (uint8 i = 0; i < 12; i++) {
            (uint64 localSeriesID, ) = getCardTypeFromID(tokenIds[i]);
            require(uint8(localSeriesID) == i + 1, "not in sequence");
            require(super.ownerOf(tokenIds[i]) == msg.sender, "!last");
            require(!isClaimed(uint16(tokenIds[i])), "Claimed.");
            _setClaimed(uint16(tokenIds[i]));
        }
        mint(msg.sender, 13);
        emit forgeAllEvent(tokenIds);
    }

    function indexArray(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 sum = this.balanceOf(_user);
        uint256[] memory indexes = new uint256[](sum);

        for (uint256 i = 0; i < sum; i++) {
            indexes[i] = this.tokenOfOwnerByIndex(_user, i);
        }
        return indexes;
    }

    function changeMintTime(
        uint64 _cardID,
        uint128 _mintTime,
        uint128 _mintEndTime
    ) external onlyOwner {
        require(_cardID != 0, "!0");
        CardType[_cardID].mintTime = _mintTime;
        CardType[_cardID].mintEndTime = _mintEndTime;
    }
}
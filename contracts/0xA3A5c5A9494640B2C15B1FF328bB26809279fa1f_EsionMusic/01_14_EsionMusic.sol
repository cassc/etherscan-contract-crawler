// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract EsionMusic is ERC1155, ERC2981, Ownable {
    uint256 private constant eachTokenAmount = 500;
    uint8 public constant INTRO = 0;
    uint8 public constant MOMMYSON = 1;
    uint8 public constant CHANJU = 2;
    uint8 public constant WONSTEINZIORPARK = 3;
    uint8 public constant SIONJUNG = 4;
    uint8 public constant OUTTRO = 5;
    uint8 public constant LAST_TOKEN_ID = OUTTRO;

    string private metadataUri = "";

    using Strings for uint256;

    constructor(
        string memory _metadataUri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC1155(_metadataUri) {
        _mint(msg.sender, INTRO, eachTokenAmount, "");
        _mint(msg.sender, MOMMYSON, eachTokenAmount, "");
        _mint(msg.sender, CHANJU, eachTokenAmount, "");
        _mint(msg.sender, WONSTEINZIORPARK, eachTokenAmount, "");
        _mint(msg.sender, SIONJUNG, eachTokenAmount, "");
        _mint(msg.sender, OUTTRO, eachTokenAmount, "");
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);

        metadataUri = _metadataUri;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(_isTokenExist(_id), "Not Exist Token");
        return string(abi.encodePacked(metadataUri, _id.toString()));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataUri, "contractURI"));
    }

    function _isTokenExist(uint256 _id) private pure returns (bool) {
        return _id <= LAST_TOKEN_ID;
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _burn(from, id, amount);
    }

    function mint(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(from, id, amount, "");
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
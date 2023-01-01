// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./rarible/LibPart.sol";
import "./rarible/LibRoyaltiesV2.sol";
import "./rarible/RoyaltiesV2.sol";
import "./lib/Base64.sol";

contract Omikuji is IERC165, ERC721, Ownable, ReentrancyGuard, RoyaltiesV2 {
    using Strings for uint256;

    string private constant svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><defs><style>.a{font-size:57px;}.b{font-size:415px;}</style></defs><text class="a" x="0" y="60">\u3042\u306A\u305F\u306E\u904B\u52E2\u306F</text><text class="b" x="500" y="600" text-anchor="middle">';
    string private constant svg2 = '</text><text class="a" x="650" y="940">\u306A\u3093\u3058\u3083\u306D\uFF1F</text></svg>';
    string[] private jsonArray = ['{"name": "', '","description": "', '","image": "', '"}'];
    string[] private kujiname = ["\u5927\u51F6", " \u51F6 ", "\u672B\u5409", "\u5C0F\u5409", "\u4E2D\u5409", " \u5409 ", "\u5927\u5409"];
    string private constant _dataStr = 'data:application/json;base64,';

    uint256 private constant COST = 0.01 ether;
    address private constant _RecvOwner = 0x2fa56A56aB5f3447752fF8D0FcbC88bf2e58B3B6;

    mapping(uint256 => string) public _URI;

    uint256 public totalSupply = 0;

    address payable private defaultRoyaltiesReceipientAddress;
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;
    uint96 private defaultPercentageBasisPoints = 1000;

    constructor()
    ERC721("Omikuji", "Omikuji")
    {
        defaultRoyaltiesReceipientAddress = payable(_RecvOwner);
    }

    function mint()
        external 
        payable
        nonReentrant
    {
        require(msg.value >= COST, "Did not send enough eth.");

        if (msg.value > COST) {
            (bool sent, ) = msg.sender.call{value: msg.value - COST}("");
            require(sent, "failed to send back fund");
        }

        unchecked { ++totalSupply; }

        string memory mintData = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(svg, kujiname[rnd(totalSupply)], svg2))));

        _safeMint(msg.sender, totalSupply);
        _URI[totalSupply] = mintData;
    }

    function rnd(uint256 tokenId) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenId.toString(), block.number.toString()))) % 7;
    }
 
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS);
    }

    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(IERC165, ERC721) 
        returns (bool) 
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_dataStr, Base64.encode(abi.encodePacked(jsonArray[0], 'Omikuji #', tokenId.toString(), jsonArray[1], 'Fully onchain Omikuji.', jsonArray[2], _URI[tokenId], jsonArray[3]))));
    }

    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }
    
    function renounceOwnership() public override onlyOwner {}  
    
    receive() external payable {}
}
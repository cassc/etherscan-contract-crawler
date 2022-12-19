// SPDX-License-Identifier: MIT
// Eric Corriel Studios - ericcorrielstudios.com

pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BruteForce is ERC721, Ownable, ERC721Royalty, DefaultOperatorFilterer{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string constant BASE_URI = "https://ericcorrielstudios.com";
    address royaltyRecipient;
    uint8 constant NUM_MINTS = 1;
    string[] hexChars;

    constructor() ERC721("Brute Force", "0xBF") {
        hexChars.push("0"); hexChars.push("1"); hexChars.push("2"); hexChars.push("3"); hexChars.push("4"); hexChars.push("5"); hexChars.push("6"); hexChars.push("7"); hexChars.push("8"); hexChars.push("9");
        hexChars.push("a"); hexChars.push("b"); hexChars.push("c"); hexChars.push("d"); hexChars.push("e"); hexChars.push("f");
        royaltyRecipient = msg.sender;
        _setDefaultRoyalty(royaltyRecipient, 750);

        //mint
        _safeMint(msg.sender, 1);
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function getRandomHex(uint256 _length, uint256 prime, bool appendOx) public view returns (string memory){
        string memory r = (appendOx)? "0x": "";
        for(uint8 i=0;i<_length;i++){
            r = string.concat(r,hexChars[(block.timestamp*(i+1))%prime%16]);
        }
        return r;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "',getRandomHex(40, 101, true),'",',
            '"description": "*Brute Force* creates a new public/private key pair every block raising the question: can an on-chain NFT attack the chain that it\'s on?",',
            '"external_url": "https://ericcorrielstudios.com",',
            '"image_data": "',getSvg(),'",',
            '"image": "',_baseURI(), '/assets/img/work/brute-force/brute-force.cover.jpg",',
            '"background_color": "000000"',
            '}'
        );
        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    function getSvg() public view returns(string memory){
        string memory beg =
        "<svg id='svg' viewBox='0 0 200 200' preserveAspectRatio='xMidYMid meet' xmlns='http://www.w3.org/2000/svg' style='display: inline-block;"
        "background-color:#000000;"
        "width:  100%;"
        "height: 100%;'>"
        "<text font-family='monospace' fill='white' dominant-baseline='middle' text-anchor='middle' font-weight='900' id='public' transform='scale(.5 .5)' x='100%' y='50%' dy='40%' dx='0'>";
        beg = string.concat(beg,getRandomHex(40, 101, true));
        string memory mid=
        "</text>"
        "<text font-family='monospace' fill='white' dominant-baseline='middle' text-anchor='middle' font-weight='900' id='private' transform='scale(.33 .33)' x='152%' y='50%' dy='100%' dx='0'>";
        mid = string.concat(mid,getRandomHex(64, 103, false));
        string memory end=
        "</text></svg>";
        beg = string.concat(beg,mid);

        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                string.concat(beg,end)
                            )
                        )
                    )
                )
            )
        );
    }
    function getLastMintedTokenId() external view returns (uint256){
        return _tokenIdCounter.current();
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked(
                '{',
                '"name": "Brute Force",',
                '"description": "Ethereum v Ethereum",',
                '"image": "',_baseURI(), '/assets/img/work/brute-force/brute-force.cover.jpg",',
                '"external_link": "https://ericcorrielstudios.com/",',
                '"seller_fee_basis_points": "750",',
                '"fee_recipient": "',Strings.toHexString(uint160(royaltyRecipient), 20),'"',
                '}'
            ))));
    }

    // OpenSea OperatorFilterRegistry
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Overrides
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        return (getTokenURI(tokenId));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Balance and payable
    function withdraw(address payable _to) public payable onlyOwner {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    receive() external payable {}

    fallback() external payable {}


}
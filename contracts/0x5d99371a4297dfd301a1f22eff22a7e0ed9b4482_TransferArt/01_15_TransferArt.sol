pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import 'base64-sol/base64.sol';
import './UintStrings.sol';
import "hardhat/console.sol";

contract TransferArt is ERC721Enumerable {
    uint128 private _startMintFeeWei = 1e17;
    uint256 private _nonce;
    uint256 public originals;
    uint256 public maxOriginals = 64;
    address public manager;
    mapping(uint256 => address[]) public transferHistory;
    mapping(uint256 => uint256)  public copyOf;

    constructor(address _manager) ERC721("Generative Transfer Art Project 1", "GTAP1") {
        manager = _manager;
    }

    function mintFeeWei() public view returns(uint256){
        return _startMintFeeWei + (originals * 1e16);
    }

    function addressRgba(address account) public pure returns (string memory, string memory, string memory, string memory){
        bytes32 h = keccak256(abi.encodePacked(account));
        string memory r = UintStrings.decimalString(uint8(h[0]), 0, false);
        string memory g = UintStrings.decimalString(uint8(h[1]), 0, false);
        string memory b = UintStrings.decimalString(uint8(h[2]), 0, false);
        string memory a = UintStrings.decimalString(uint8(h[3]), 2, false);

        return (r,g,b,a);
    }

    function mint(address mintTo) payable external {
        require(msg.value >= mintFeeWei(), "TransferArt: Mint fee too low");
        require(originals < maxOriginals, "TransferArt: All originals have been minted");
        _safeMint(mintTo, ++_nonce, "");
        originals++;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if(transferHistory[tokenId].length < 16) {
            transferHistory[tokenId].push(to);
            if(from != address(0)){
                _mint(from, ++_nonce);
                copyOf[_nonce] = tokenId;
            }
        }
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        if(copyOf[tokenId] != 0){
            tokenId = copyOf[tokenId];
        }
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"Generative Transfer Art Project 1 - Token',
                                    ' #',
                                    UintStrings.decimalString(tokenId, 0, false),
                                    '", "description":"',
                                    'The image of this NFT is created by its first 16 transfers, populating a 4x4 grid of squares. A new colored square is added on each transfer. The `to` address of the transfer determines the color. Each of the first 16 `transfered to` addresses get a copy of this NFT. The image is entirely Solidity generated.',
                                    '", "image": "',
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(bytes(generateSVG(transferHistory[tokenId]))),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function generateSVG(address[] memory transferHistory) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 200 200" width="200" height="200" xml:space="preserve">',
                '<style type="text/css">',
                    'rect{width:50px;height:50px;}',
                '</style>',
                generateRects(transferHistory),
                '</svg>'
            )
        );
    }

    function generateRects(address[] memory transferHistory) private pure returns (string memory result) {
            for (uint i; i < transferHistory.length; i++){
                result = string(abi.encodePacked(result, generateRect(transferHistory[i], i)));
            }
    }

    function generateRect(address account, uint256 index) private pure returns (string memory) {
        (string memory r, string memory g, string memory b, string memory a) = addressRgba(account);

        return string(
            abi.encodePacked(
            '<rect x="',
            UintStrings.decimalString((index % 4) * 50, 0, false),
            '" y="',
            UintStrings.decimalString((index / 4) * 50, 0, false),
            '" fill="rgba(',
            r,
            ',',
            g,
            ',',
            b,
            ',',
            a,
            ')"/>'
            )
        );
    }

    function updateManager(address _manager) external {
        require(msg.sender == manager, "TransferArt: forbidden");
        manager = _manager;
    }

    function payManager(uint256 amount) external {
        require(msg.sender == manager, "TransferArt: forbidden");
        require(amount <= address(this).balance, "TransferArt:  amount  too high");
        payable(manager).transfer(amount);
    }
}
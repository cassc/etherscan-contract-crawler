// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";
import "./base64.sol";

contract BitcoinPresents is DefaultOperatorFilterer, ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public maxFreeAmount = 1555;
    uint256 public maxFreePerWallet = 5;
    uint256 public price = 0.001 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerWallet = 100;
    uint256 public teamReserved = 100;
    bool public mintEnabled = true;
    string public baseURI;

    constructor() ERC721A("Bitcoin Presents", "Bitcoin") {
        _safeMint(msg.sender, 100);
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
        uint256 cost = price;
        uint256 _maxPerWallet = maxPerWallet;

        if (
            totalSupply() < maxFreeAmount &&
            _numberMinted(msg.sender) < maxFreePerWallet &&
            quantity <= maxFreePerWallet
        ) {
            cost = 0;
            _maxPerWallet = maxFreePerWallet;
        }

        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );

        uint256 needPayCount = quantity;
        if (_numberMinted(msg.sender) == 0) {
            needPayCount = quantity - 1;
        }
        require(
            msg.value >= needPayCount * cost,
            "Please send the exact amount."
        );
        _safeMint(msg.sender, quantity);
    }

    function teamMint() public onlyOwner {
        _safeMint(msg.sender, teamReserved);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string[26] memory colors = ["#F7931A","#46885f","#30322e","#c6ab6f","#763164","#1b387e","#336a75", "#7f766d","#eeeeee","#FCE74C","#fdcce5","#bd7ebe","#00bfa0","#fd7f6f","#dc0ab4","#f46a9b","#d0f400","#9b19f5","#ffa300","#e60049","#82b6b9","#b3d4ff","#00ffff","#0bb4ff","#35d435","#61ff75"];
        string memory color = colors[tokenId % 25];
        string memory rawSvg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" version="1.1" viewBox="0 0 4091.27 4091.73"><rect width="100%" height="100%" fill="',
                color,
                '"/><path fill="white" fill-rule="nonzero" d="M2947.77 1754.38c40.72,-272.26 -166.56,-418.61 -450,-516.24l91.95 -368.8 -224.5 -55.94 -89.51 359.09c-59.02,-14.72 -119.63,-28.59 -179.87,-42.34l90.16 -361.46 -224.36 -55.94 -92 368.68c-48.84,-11.12 -96.81,-22.11 -143.35,-33.69l0.26 -1.16 -309.59 -77.31 -59.72 239.78c0,0 166.56,38.18 163.05,40.53 90.91,22.69 107.35,82.87 104.62,130.57l-104.74 420.15c6.26,1.59 14.38,3.89 23.34,7.49 -7.49,-1.86 -15.46,-3.89 -23.73,-5.87l-146.81 588.57c-11.11,27.62 -39.31,69.07 -102.87,53.33 2.25,3.26 -163.17,-40.72 -163.17,-40.72l-111.46 256.98 292.15 72.83c54.35,13.63 107.61,27.89 160.06,41.3l-92.9 373.03 224.24 55.94 92 -369.07c61.26,16.63 120.71,31.97 178.91,46.43l-91.69 367.33 224.51 55.94 92.89 -372.33c382.82,72.45 670.67,43.24 791.83,-303.02 97.63,-278.78 -4.86,-439.58 -206.26,-544.44 146.69,-33.83 257.18,-130.31 286.64,-329.61l-0.07 -0.05zm-512.93 719.26c-69.38,278.78 -538.76,128.08 -690.94,90.29l123.28 -494.2c152.17,37.99 640.17,113.17 567.67,403.91zm69.43 -723.3c-63.29,253.58 -453.96,124.75 -580.69,93.16l111.77 -448.21c126.73,31.59 534.85,90.55 468.94,355.05l-0.02 0z" style="&#10;transform: rotate(347deg);&#10;    transform-origin: center;&#10;"/></svg>'
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name":"Bitcoin #',
                                tokenId.toString(),
                                '",',
                                '"image": "',
                                "data:image/svg+xml;base64,",
                                encodedSvg,
                                '",',
                                '"attributes": [{"trait_type": "Bitcoin", "value": "To The Moon!!"'
                            )
                        )
                    )
                )
            );
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    //=========================================================================
    // OPENSEA-PROVIDED OVERRIDES for OPERATOR FILTER REGISTRY
    //=========================================================================

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

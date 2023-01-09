// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/main/contracts/token/ERC721/extensions/ERC721FOnChain.sol";
import "@franknft.eth/erc721-f/contracts/utils/Payable.sol";

/**
 * @title CryptoNovo Token
 *
 * @dev an onChain Art contract to help recover the stolen CryptoPunk #3706 from CryptoNovo
 * NovoPixels is a community-driven token created to support and assist one of our own, 
 * CryptoNovo, who fell victim to a scam and lost many of his NFTs. 
 * The proceeds from the sale of NovoPixels will be used to help CryptoNovo get his beloved pixel art profile picture back.
 *
 */
contract NovoPixels is ERC721FOnChain, Payable {
    string constant svgHead =
        '<svg version="1.1"  xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 620 620"><rect x="0" y="0" width="620" height="620" fill="#';
    string constant svgFooter = '" /></svg>';

    uint8[576] pixels; // need to set the below data as it's too long to hardcode it.
    // [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 1, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 1, 3, 1, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 1, 3, 1, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 1, 3, 1, 3, 1, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 1, 3, 1, 3, 1, 3, 1, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 1, 3, 1, 3, 1, 3, 1, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 1, 3, 3, 3, 3, 3, 3, 3, 1, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 3, 4, 4, 4, 4, 4, 4, 3, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 2, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 7, 7, 7, 0, 4, 0, 7, 7, 7, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 5, 5, 5, 0, 4, 0, 5, 5, 5, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 0, 0, 0, 4, 8, 8, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 4, 4, 4, 4, 8, 8, 4, 4, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 4, 4, 4, 4, 4, 4, 4, 4, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 4, 4, 4, 0, 0, 0, 4, 4, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 3, 3, 4, 4, 4, 4, 4, 4, 3, 3, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 3, 0, 4, 0, 4, 4, 4, 0, 0, 3, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 4, 4, 0, 0, 0, 6, 6, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 4, 4, 4, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 4, 4, 4, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]
    uint24[9] colours =[0, 21632, 6818885, 2265088, 11438689, 11346272, 7111829, 9178458, 14024704];
    uint256 public constant MAX_TOKENS = 576;
    uint256 public tokenPrice = 0.04 ether;
    uint256 private startingIndex;
    bool public saleIsActive;
    bool public revealed;
    address public constant FUND_NOVO= 0xd7Da0AE98F7A1da7c3318c32E78a1013C00df935;

    constructor() payable ERC721FOnChain("NovoPixels", "NOVO", "NovoPixels is a community-driven token created to support and assist one of our own, CryptoNovo, who fell victim to a scam and lost many of his NFTs. The proceeds from the sale of NovoPixels will be used to help CryptoNovo get his beloved pixel art profile picture back.") {}

    /**
     * Changes the state of saleIsActive from true to false and false to true
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    /**     
    * Reveal the collection
    */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**     
    * Set the token data 
    */
    function setTokenData(uint8[] calldata data) external onlyOwner{
        uint length = data.length;
        for (uint i; i < length; ) {
            pixels[i]=data[i];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Mints `numberOfTokens` tokens for `sender`
     */
    function mint(uint256 numberOfTokens) payable external {
        require(msg.sender == tx.origin, "No Contracts allowed.");
        require(saleIsActive, "Sale NOT active yet");
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct"); 
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _mint(msg.sender, supply + i); // no need to use safeMint as we don't allow contracts.
                i++;
            }
        }
    }

    /**
     * @notice Overridden function which creates custom SVG image
     */
    function renderTokenById(
        uint256 id
    ) public view override returns (string memory) {
        require(_exists(id), "Non-Existing token");
        string[3] memory parts;
        parts[0] = svgHead;
        if(revealed){
            parts[1] = uint2hexstr(colours[pixels[getCorrectedId(id)]]);
        } else {
            parts[1] = "6C8495";
        }
        parts[2] = svgFooter;
        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2]
                )
            );
    }

    /**
     * @dev Creates the traits data
     */
    function getTraits(
        uint256 id
    ) public view override returns (string memory) {
        require(_exists(id), "Non-Existing token");
        if(!revealed){
            return "";
        }
        string[3] memory traits;
        traits[0] = string(
            abi.encodePacked(
                "{"
                "\n",
                '"trait_type": "x",',
                "\n",
                '"value": "',
                Strings.toString(getCorrectedId(id)%24),
                '"',
                "\n",
                "}"
                "\n"
            )
        );
        traits[1] = string(
            abi.encodePacked(
                ",{",
                "\n",
                '"trait_type": "y",',
                "\n",
                '"value": "',
                Strings.toString(getCorrectedId(id)/24),
                '"',
                "\n",
                "}"
                "\n"
            )
        );
        traits[2] = string(
            abi.encodePacked(
                ",{",
                "\n",
                '"trait_type": "Colour",',
                "\n",
                '"value": "',
                uint2hexstr(colours[pixels[getCorrectedId(id)]]),
                '"',
                "\n",
                "}"
                "\n"
            )
        );
        return string(abi.encodePacked("[", traits[0], traits[1], traits[2],"]"));
    }

    function getCorrectedId(uint256 id) private view returns (uint256) {
        return (id+startingIndex)%MAX_TOKENS;
    }

    /**
    * returns the mint offset once the collection is revealed.
    */
    function getOffset() public view returns (uint256) {
        if(revealed){
            return startingIndex;
        }
        return 0;
    }

    function uint2hexstr(uint i) private pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return leftPadWithZeros(string(bstr));
    }
    function leftPadWithZeros(string memory _input) private pure returns (string memory) {
        while (bytes(_input).length < 6) {
            _input = string(abi.encodePacked("0",_input));
        }
    return _input;
}
    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");
        startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKENS;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = 37;
        }
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(FUND_NOVO, balance);
    }
}
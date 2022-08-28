/* SPDX-License-Identifier: MIT 
 
      ********************************
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      * ░░░██████████████████████░░░ *
      * ░░░██░░░░░░██░░░░░░████░░░░░ *
      * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
      * ░░░██████████████████░░░░░░░ *
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      ************************♥tt*****

 »»————- V3 Phunks for Mental Health ————-««

    Created by the CryptoPhunks community

100% of mint fees and secondary royalties are 
       sent trustlessly to maps.org

    ERC721R contract by middlemarch.eth
»»————-——————————————————————————————————-««*/

pragma solidity 0.8.15;

import "./ERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract V3Phunks is ERC721r, Ownable {

    mapping(address => uint256) walletMinted;

    uint256 maxPerWallet = 10;
    uint256 fee = 0.005 ether;
    uint256 counter;
    bool public mintState = false;

    constructor() ERC721r("V3 Phunks", "V3PHUNKS", 10_000) {}

    function flipMintState() public onlyOwner {
        mintState = !mintState;
    }

    function publicMint(uint256 amount) external payable {
        require (mintState, "Mint is not active");
        require(walletMinted[msg.sender] + amount <= maxPerWallet, "Max 10 Phunks per wallet");
        require(msg.value >= (fee * amount), "Not enought eth");
        require(amount + counter < 10000);

        counter += amount;
        walletMinted[msg.sender] += amount;
        _mintRandom(msg.sender, amount);
    }

    //metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //charity info
    address public mapsEthAddress = 0xd0cF3a17f8Bc362540c354E9eEc761C5A7952b5D;

    //withdraw to charityAddress
    function withdraw() external {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
                
        Address.sendValue(payable(mapsEthAddress), balance);
    }

}
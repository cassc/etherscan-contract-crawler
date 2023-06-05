// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Gradis is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    uint256 public constant gradisPrice = 10000000000000000; //0.01 ETH
    uint256 public constant maxGradisPurchase = 5;
    uint256 public constant MAX_GRADIS = 8075;
    bool public saleIsActive = false;
    bool public whitelistSaleIsActive = false;
    string private gradisBaseUri;
    Counters.Counter private _totalGradisTokens;

    constructor() ERC721("Gradis", "GRDS") {}

    function totalSupply() public view returns (uint256 count) {
        return _totalGradisTokens.current();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() public onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        gradisBaseUri = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return gradisBaseUri;
    }

    function contractURI() public view returns (string memory) {
        return gradisBaseUri;
    }

    function reserveGradis(uint256[] memory gradisTokens) public onlyOwner {
        for (uint256 i = 0; i < 75; i++) {
            _safeMint(msg.sender, gradisTokens[i]);
            _totalGradisTokens.increment();
        }
    }

    function whitelistMint(uint256[] memory gradisTokens) public payable {
        require(whitelistSaleIsActive, "Sale is not active");
        require(gradisTokens.length > 0, "No Gradis to mint");
        require(
            gradisTokens.length <= maxGradisPurchase,
            "number of gradis incorrect"
        );
        require(
            msg.value >= gradisPrice * gradisTokens.length,
            "Ether amount incorrect"
        );
        require(
            _totalGradisTokens.current() + gradisTokens.length <= 1575,
            "Purchase exceeds what is allowed for the list"
        );

        for (uint256 i = 0; i < gradisTokens.length; i++) {
            _safeMint(msg.sender, gradisTokens[i]);
            _totalGradisTokens.increment();
        }
    }

    function mintGradis(uint256[] memory gradisTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(gradisTokens.length > 0, "No Gradis to mint");
        require(
            gradisTokens.length <= maxGradisPurchase,
            "number of gradis incorrect"
        );
        require(
            msg.value >= gradisPrice * gradisTokens.length,
            "Ether amount incorrect"
        );
        require(
            _totalGradisTokens.current() + gradisTokens.length <= MAX_GRADIS,
            "Purchase would exceed max supply"
        );

        for (uint256 i = 0; i < gradisTokens.length; i++) {
            _safeMint(msg.sender, gradisTokens[i]);
            _totalGradisTokens.increment();
        }
    }
}
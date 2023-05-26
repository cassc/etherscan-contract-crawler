// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract ShonenJunk is ERC721A, Ownable {
    string private baseURI;
    address addr_1 = 0xdb275FaC4239aa53e3c56b7e999Dfc2B2406b671;

    // reserved for giveaways
    uint256 public reserved = 800;

    // total NFTs that can be minted
    uint256 public maxSupply = 9001;

    // number of NFTs that can be minted at once
    uint256 public maxPerAddressDuringMint = 3;

    // floor prices
    uint256 public tier0Price = 0.00 ether;
    uint256 public tier1Price = 0.05 ether;
    uint256 public tier2Price = 0.08 ether;

    bool public paused = true;

    constructor(
      string memory name,
      string memory symbol,
      string memory initBaseURI
    ) ERC721A(name, symbol, maxPerAddressDuringMint) {
        setBaseURI(initBaseURI);
    }

    // Purchase requires a _signature from the author.
    // This is a 2-party authenticated purchase: the contract owner and minter.
    // Purchaser pays gas fees.
    function purchase(uint256 num, uint256 _timestamp, uint256 priceTier, bytes memory _signature) public payable {

        uint256 supply = totalSupply();
        require( !paused,                             "Sale paused" );
        require( num <= maxPerAddressDuringMint,      "Batch size exceeded" );
        require( supply + num < maxSupply - reserved, "Exceeds maximum NFTs supply" );

        address wallet = _msgSender();
        address signerOwner = signatureWallet(wallet, num, _timestamp, _signature);
        require(signerOwner == owner(),             "Not authorized to mint");
        require(block.timestamp >= _timestamp - 30, "Signature expired, out of time");

        if (priceTier == 0) {
            require( msg.value >= tier0Price * num, "Ether sent is not correct" );
        }
        else if (priceTier == 1) {
            require( msg.value >= tier1Price * num, "Ether sent is not correct" );
        }
        else if (priceTier == 2) {
            require( msg.value >= tier2Price * num, "Ether sent is not correct" );
        }
        else {
            revert("Invalid price tier");
        }

        _safeMint( msg.sender, num );

    }

    function signatureWallet(address wallet, uint256 _num, uint256 _timestamp, bytes memory _signature) internal pure returns (address){
        return ECDSA.recover(ethSignedMessage(keccak256(abi.encode(wallet, _num, _timestamp))), _signature);
    }

    function ethSignedMessage(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    // Contract owner pays gas fee
    function giveAway(address recipient, uint256 num) public onlyOwner {
        require( num <= reserved, "Exceeds reserved NFTs supply" );

        while (num > 0) {
            if (num <= maxPerAddressDuringMint) {
                _safeMint( recipient, num );
                num -= num;
            } else {
                _safeMint( recipient, maxPerAddressDuringMint );
                num -= maxPerAddressDuringMint;
            }
        }

        reserved -= num;
    }

    function setPrice(uint256 priceTier, uint256 newPrice) public onlyOwner {
        if (priceTier == 0) {
            tier0Price = newPrice;
        }
        else if (priceTier == 1) {
            tier1Price = newPrice;
        }
        else if (priceTier == 2) {
            tier2Price = newPrice;
        }
        else {
            revert("Invalid price tier");
        }
    }

    function setPause(bool val) public onlyOwner {
        paused = val;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Include trailing slash in uri
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 all = address(this).balance;
        require(payable(addr_1).send(all));
    }

}
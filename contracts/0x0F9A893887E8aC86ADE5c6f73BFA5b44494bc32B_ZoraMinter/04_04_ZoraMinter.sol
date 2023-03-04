// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
// import "hardhat/console.sol";

interface NFTDrop {

    // https://eips.ethereum.org/EIPS/eip-721
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);

    // https://etherscan.io/address/0x5eb5babcefea846b220c82f222f00df95934f5f0#code#F25#L433
    function purchase(uint256 quantity) external payable returns (uint256 firstMintedTokenId);

}

// http://mintmore.xyz/
contract ZoraMinter is Ownable {

    uint256 public totalMinted;
    address[] public allClones;
    mapping (address => uint256) public usedClones;

    function proxyInit() external {
        require(owner() == address(0x0), 'owner-is-not-0');
        _transferOwnership(msg.sender); // to creator
    }

    function mint1(address nft, address to, uint256 price) external payable onlyOwner {
        uint256 tokenId = NFTDrop(nft).purchase{value: price}(1);
        NFTDrop(nft).transferFrom(address(this), to, tokenId + 1);
    }

    function mintN(address nft, uint256 price, uint256 n) external payable {
        // we will charge a 1% minting fee
        require(msg.value >= price * n * 101 / 100, "value-not-enough");
        totalMinted += n;

        uint256 nAllClones = allClones.length;
        uint256 nUsedClones = usedClones[nft];

        // make sure we have enough clones
        if (nAllClones - nUsedClones < n) {
            for (uint256 i = 0; i < n; i++) {
                address clone = Clones.clone(address(this));
                ZoraMinter(clone).proxyInit();
                allClones.push(clone);
            }
        }

        // reuse available clones to save gas
        usedClones[nft] = nUsedClones + n;
        for (uint256 i = 0; i < n; i++) {
            address clone = allClones[nUsedClones + i];
            ZoraMinter(clone).mint1{value: price}(nft, msg.sender, price);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
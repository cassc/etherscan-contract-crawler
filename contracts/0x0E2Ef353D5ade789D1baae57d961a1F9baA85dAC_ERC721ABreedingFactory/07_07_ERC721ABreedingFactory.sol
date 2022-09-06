// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721ABreeding.sol";

abstract contract LaunchPass {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
}

contract ERC721ABreedingFactory is Ownable {

    mapping(uint256 => address) public deployments;
    address public launchpassAddress;
    ERC721ABreeding[] public nfts;

    constructor(address _launchpassAddress) {
        launchpassAddress = _launchpassAddress;
    }

    function updateConfig(address _launchpassAddress) public onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function getDeployedNFTs() public view returns (ERC721ABreeding[] memory) {
        return nfts;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        uint16 _maxSupply,
        address _momContract,
        address _dadContract
    ) public {
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.ownerOf(_launchpassId) == msg.sender,  "Not owner");
        ERC721ABreeding nft = new ERC721ABreeding(_name, _symbol, _uri, msg.sender, _maxSupply, _momContract, _dadContract);
        deployments[_launchpassId] = address(nft);
        nfts.push(nft);
    }
}
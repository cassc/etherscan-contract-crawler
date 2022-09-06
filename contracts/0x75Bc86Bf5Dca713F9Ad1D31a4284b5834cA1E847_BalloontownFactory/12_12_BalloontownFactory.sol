// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Balloontown.sol";

abstract contract LaunchPass {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
}

contract BalloontownFactory is Ownable {

    mapping(uint256 => address) public deployments;
    address public treasuryAddress;
    address public launchpassAddress;
    uint16 public treasuryShare;
    Balloontown[] public nfts;
    address[] payees;
    uint256[] shares;

    constructor(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare) {
        treasuryAddress = _treasuryAddress;
        launchpassAddress = _launchpassAddress;
        treasuryShare = _treasuryShare;
    }

    function updateConfig(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
    }

    function getDeployedNFTs() public view returns (Balloontown[] memory) {
        return nfts;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        address[] memory _payees,
        uint256[] memory _shares,
        Balloontown.Token memory token
    ) public {
        require(_payees.length == _shares.length,  "Invalid splitter");
        payees = _payees;
        shares = _shares;
        payees.push(treasuryAddress);
        shares.push(treasuryShare);
        uint16 totalShares = 0;
        for (uint16 i = 0; i < shares.length; i++) {
            totalShares = totalShares + uint16(shares[i]);
        }
        require(totalShares == 100,  "Invalid splitter");
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.ownerOf(_launchpassId) == msg.sender,  "Not owner");
        Balloontown nft = new Balloontown(_name, _symbol, _uri, payees, shares, msg.sender, token);
        deployments[_launchpassId] = address(nft);
        nfts.push(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }
}
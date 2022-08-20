// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721ACustom.sol";

abstract contract LaunchPass {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
}

contract ERC721ACustomFactory is Ownable {

    struct Referrer {
        address payee;
        uint16 share;
    }

    mapping(uint256 => address) public deployments;
    mapping(uint256 => Referrer) public referrers;
    address public treasuryAddress;
    address public launchpassAddress;
    uint16 public treasuryShare;
    ERC721ACustom[] public nfts;
    address[] payees;
    uint256[] shares;

    constructor(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare) {
        treasuryAddress = _treasuryAddress;
        launchpassAddress = _launchpassAddress;
        treasuryShare = _treasuryShare;
    }

    function addReferrer(uint256 _launchpassId, uint16 _share, address _address) public onlyOwner {
        require(referrers[_launchpassId].payee == address(0), "Invalid referrer");
        referrers[_launchpassId].payee = _address;
        referrers[_launchpassId].share = _share;
    }

    function removeReferrer(uint256 _launchpassId) public onlyOwner {
        require(referrers[_launchpassId].payee != address(0), "Invalid referrer");
        delete referrers[_launchpassId];
    }

    function updateConfig(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
    }

    function getDeployedNFTs() public view returns (ERC721ACustom[] memory) {
        return nfts;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        address[] memory _payees,
        uint256[] memory _shares,
        ERC721ACustom.Token memory token
    ) public {
        require(_payees.length == _shares.length,  "Invalid splitter");
        payees = _payees;
        shares = _shares;
        if (referrers[_launchpassId].payee != address(0)) {
            payees.push(referrers[_launchpassId].payee);
            shares.push(referrers[_launchpassId].share);
            payees.push(treasuryAddress);
            shares.push(treasuryShare - referrers[_launchpassId].share);
        } else {
            payees.push(treasuryAddress);
            shares.push(treasuryShare);
        }
        uint16 totalShares = 0;
        for (uint16 i = 0; i < shares.length; i++) {
            totalShares = totalShares + uint16(shares[i]);
        }
        require(totalShares == 100,  "Invalid splitter");
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.ownerOf(_launchpassId) == msg.sender,  "Not owner");
        ERC721ACustom nft = new ERC721ACustom(_name, _symbol, _uri, payees, shares, msg.sender, token);
        deployments[_launchpassId] = address(nft);
        nfts.push(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }
}
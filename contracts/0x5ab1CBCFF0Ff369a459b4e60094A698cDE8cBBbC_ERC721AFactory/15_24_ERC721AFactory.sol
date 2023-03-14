// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721AContract.sol";

contract ERC721AFactory is Ownable {

    struct Referrer {
        address payee;
        uint16 share;
    }

    mapping(uint256 => address) public deployments;
    mapping(uint256 => Referrer) public referrers;
    address public treasuryAddress;
    address public launchpassAddress;
    uint16 public treasuryShare;
    address public fiatMinter;
    address public r2eAddress;
    address public dcAddress;
    ERC721AContract[] private nfts;
    address[] payees;
    uint256[] shares;

    constructor(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare, address _fiatMinter, address _r2eAddress, address _dcAddress) {
        treasuryAddress = _treasuryAddress;
        launchpassAddress = _launchpassAddress;
        treasuryShare = _treasuryShare;
        fiatMinter = _fiatMinter;
        r2eAddress = _r2eAddress;
        dcAddress = _dcAddress;
    }

    function setFiatMinter(address _address) external onlyOwner {
        fiatMinter = _address;
    }

    function setReferrer(uint256 _launchpassId, uint16 _share, address _address) public onlyOwner {
        require(referrers[_launchpassId].payee == address(0), "Bad referrer");
        if (_share == 0) delete referrers[_launchpassId];
        referrers[_launchpassId].payee = _address;
        referrers[_launchpassId].share = _share;
    }

    function updateConfig(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare, address _r2eAddress, address _dcAddress) external onlyOwner {
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
        r2eAddress = _r2eAddress;
        dcAddress = _dcAddress;
    }

    function getDeployedNFTs() external view returns (ERC721AContract[] memory) {
        return nfts;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        string memory _provenance,
        address[] memory _payees,
        uint256[] memory _shares,
        ERC721AContract.Token memory _token,
        ERC721AContract.RoyaltyInfo memory _royalties
    ) external {
        require(_payees.length == _shares.length,  "Bad splitter");
        payees = _payees;
        shares = _shares;
        if (referrers[_launchpassId].payee != address(0)) {
            payees.push(referrers[_launchpassId].payee);
            shares.push(referrers[_launchpassId].share);
            payees.push(treasuryAddress);
            shares.push(treasuryShare - referrers[_launchpassId].share);
        } else if (treasuryShare > 0) {
            payees.push(treasuryAddress);
            shares.push(treasuryShare);
        }
        uint16 totalShares = 0;
        for (uint16 i = 0; i < shares.length; i++) {
            totalShares = totalShares + uint16(shares[i]);
        }
        require(totalShares == 100,  "Bad splitter");
        IERC721 launchpass = IERC721(launchpassAddress);
        require(launchpass.ownerOf(_launchpassId) == msg.sender,  "Not owner");
        address[] memory _interfaces = new address[](3);
        _interfaces[0] = r2eAddress;
        _interfaces[1] = dcAddress;
        _interfaces[2] = fiatMinter;
        ERC721AContract nft = new ERC721AContract(_name, _symbol, _uri, payees, shares, msg.sender, _interfaces, _provenance, _token, _royalties);
        deployments[_launchpassId] = address(nft);
        nfts.push(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }
}
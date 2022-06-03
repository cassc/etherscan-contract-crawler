// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AContract.sol";

abstract contract LaunchPass {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
}

contract ERC721AFactory is Ownable {

    struct Referrer {
        address payee;
        uint256 share;
    }

    mapping(uint256 => address) public deployments;
    mapping(uint256 => Referrer) public referrers;
    address public treasuryAddress;
    uint256 public treasuryShare;
    address public launchpassAddress;
    ERC721AContract[] public nfts;
    address[] payees;
    uint256[] shares;

    constructor(address _treasuryAddress, address _launchpassAddress, uint256 _treasuryShare) {
        treasuryAddress = _treasuryAddress;
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
    }

    function addReferrer(uint256 _launchpassId, uint256 _share, address _address) public onlyOwner {
        require(referrers[_launchpassId].payee == address(0), "Referrer already exists.");
        referrers[_launchpassId].payee = _address;
        referrers[_launchpassId].share = _share;
    }

    function updateReferrer(uint256 _launchpassId, uint256 _share, address _address) public onlyOwner {
        require(referrers[_launchpassId].payee != address(0), "Referrer does not exist.");
        referrers[_launchpassId].payee = _address;
        referrers[_launchpassId].share = _share;
    }

    function removeReferrer(uint256 _launchpassId) public onlyOwner {
        require(referrers[_launchpassId].payee != address(0), "Referrer does not exist.");
        delete referrers[_launchpassId];
    }

    function setTreasuryShare(uint256 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
    }

    function setTreasuryAddress(address payable _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setLaunchPassAddress(address _launchpassAddress) public onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function getDeployedNFTs() public view returns (ERC721AContract[] memory) {
        return nfts;
    }

    function deploy(
        address[] memory _payees,
        uint256[] memory _shares,
        ERC721AContract.InitialParameters memory initialParameters
    ) public {
        require(_payees.length == _shares.length,  "Shares and payees must have the same length.");
        payees = _payees;
        shares = _shares;
        if (referrers[initialParameters.launchpassId].payee != address(0)) {
            payees.push(referrers[initialParameters.launchpassId].payee);
            shares.push(referrers[initialParameters.launchpassId].share);
            payees.push(treasuryAddress);
            shares.push(treasuryShare - referrers[initialParameters.launchpassId].share);
        } else {
            payees.push(treasuryAddress);
            shares.push(treasuryShare);
        }
        uint256 totalShares = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            totalShares = totalShares + shares[i];
        }
        require(totalShares == 100,  "Sum of shares must equal 100.");
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.balanceOf(msg.sender) > 0,  "You do not have a LaunchPass.");
        require(launchpass.ownerOf(initialParameters.launchpassId) == msg.sender,  "You do not own this LaunchPass.");
        ERC721AContract nft = new ERC721AContract(payees, shares, msg.sender, initialParameters);
        deployments[initialParameters.launchpassId] = address(nft);
        nfts.push(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }

}
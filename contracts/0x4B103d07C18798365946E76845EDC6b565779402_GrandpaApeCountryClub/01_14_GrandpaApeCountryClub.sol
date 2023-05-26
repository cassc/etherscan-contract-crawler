// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./OGacc.sol";

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
contract GrandpaApeCountryClub is ERC721A, Ownable, OpenSeaProxyRegistry {

    /*
        ░██████╗░░█████╗░░█████╗░░█████╗░
        ██╔════╝░██╔══██╗██╔══██╗██╔══██╗
        ██║░░██╗░███████║██║░░╚═╝██║░░╚═╝
        ██║░░╚██╗██╔══██║██║░░██╗██║░░██╗
        ╚██████╔╝██║░░██║╚█████╔╝╚█████╔╝
        ░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚════╝░
    */

    using SafeMath for uint256;

    address payable private _PaymentAddress;
    address public immutable proxyRegistryAddress;
    address private immutable oldGaccWalletAddress;
    mapping(address => bool) proxyToApproved;
    address private creator;
    OGacc private immutable ogacc;

    uint256 public GACC_MAX = 5000;
    string private baseURI;
    bool public claimIsActive = false;

    constructor(
        string memory name,
        string memory symbol,
        address oldGaccAddress,
        address _oldGaccWalletAddress,
        address _proxyRegistryAddress
    ) ERC721A(name, symbol) {
        _PaymentAddress = payable(msg.sender);
        ogacc = OGacc(oldGaccAddress);
        creator = msg.sender;
        proxyRegistryAddress = _proxyRegistryAddress;
        oldGaccWalletAddress = _oldGaccWalletAddress;
    }

    function setPaymentAddress(address paymentAddress) external onlyOwner {
        _PaymentAddress = payable(paymentAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    // Check if address is proxied
    function getProxyState(address proxyAddress) public view returns (bool) {
        return proxyToApproved[proxyAddress];
    }

    //Allow gasless OpenSea listing
    //Allow gas(less) future collection approval for cross-collection interaction
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        if (proxyToApproved[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mintApes(uint numberOfTokens) public onlyOwner payable {
        require(totalSupply().add(numberOfTokens) < GACC_MAX + 1, "Purchase would exceed max supply of Apes");
        _safeMint(msg.sender, numberOfTokens);
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function claimApes(uint[] memory apeIds) external {
        require(claimIsActive, "Claims must be active to claim Ape");
        
        // Loop through each ape to make sure each is owned and not yet claimed
        for(uint i = 0; i < apeIds.length; i++) {
            uint apeId = apeIds[i];
            require(
                    ogacc.ownerOf(apeId) == msg.sender,
                    "Must own the original apes you're attempting to claim"
            );
            require(
                    ownerOf(apeId) == creator,
                    "At least one Grandpa was already claimed"
            );
        }

        for(uint i = 0; i < apeIds.length; i++) {
            uint apeId = apeIds[i];
            // Transfer old grandpa to contract owner so we can delete collection
            ogacc.safeTransferFrom(
                msg.sender,
                oldGaccWalletAddress,
                apeId
            );
            // Transfer the new grandpa
            safeTransferFrom(
                creator,
                msg.sender,
                apeId
            );
        }
    }

}
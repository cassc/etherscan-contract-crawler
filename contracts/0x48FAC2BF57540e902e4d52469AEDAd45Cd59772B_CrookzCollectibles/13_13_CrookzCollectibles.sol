// SPDX-License-Identifier: MIT

//       _____              __             _____  __
//     _/ ____\_ __   ____ |  | __   _____/ ____\/  |_  ______
//     \   __\  |  \_/ ___\|  |/ /  /    \   __\\   __\/  ___/
//      |  | |  |  /\  \___|    <  |   |  \  |   |  |  \___ \
//      |__| |____/  \___  >__|_ \ |___|  /__|   |__| /____  >
//                       \/     \/      \/                 \/

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';


contract CrookzCollectibles is ERC1155, Ownable {
    using ECDSA for bytes32;

    // public vars
    string private _contractUri = "";
    string public name = "Crookz Collectibles";
    string public symbol = "CRKZCL";

    bool public claimEnabled = true;
    mapping (address => mapping(uint256 => bool)) public fugitives;

    mapping (uint256 => uint256) public census; // block numbers the censuses were taken at per token, if any

    // private vars
    address private _signer;

    constructor(
        string memory _initBaseURI,
        address signer
    )
    ERC1155(_initBaseURI){
        _signer = signer;
    }

    function setBaseUri(string calldata newUri) public onlyOwner {
        _setURI(newUri);
    }

    function setContractUri(string calldata newUri) public onlyOwner {
        _contractUri = newUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function updateSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function publishCensus(uint256 blockNumber, uint256 id) external onlyOwner {
        census[id] = blockNumber;
    }

    function _hash(address _address, uint256 id) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, id));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == _signer);
    }

    function setClaimState(bool _claimEnabled) public onlyOwner {
        claimEnabled = _claimEnabled;
    }

    function claim(uint8 v, bytes32 r, bytes32 s, uint256 id) public {
        require(claimEnabled, "Claiming has not been enabled.");
        require(!fugitives[msg.sender][id], "Token has already been stolen.");
        require(_verify(_hash(msg.sender, id), v, r, s), "Invalid signature");
        _mint(msg.sender, id, 1, ""); // mints only one per address, irrespective of number of Crookz held
        fugitives[msg.sender][id] = true;
    }

    function moneyPrinter(address to, uint256 amount, uint256 id) public onlyOwner {
        // ability for Rion Labs to mint tokens
        _mint(to, id, amount, "");
    }

}
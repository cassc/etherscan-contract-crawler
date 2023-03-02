// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./DelegateCash.sol";

contract ToneGarden is ERC721, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _totalSupply;

    uint public constant MAX_SUPPLY = 5555;
    uint public constant MAX_TEAM_MINT = 100;
    uint256 public PRICE = .03 ether;
    uint256 public ALLOW_LIST_PRICE = .02 ether;
    uint public constant MAX_MINT = 20;
    uint public constant MAX_ALLOW_LIST_MINT = 5;

    bool public phase1 = false;
    bool public phase2 = false;

    bool private devTeamMinted = false;

    address[] claimableAddrs;

    uint _supply;
    bytes32 private allowList;

    string _baseURL = "";

    IDelegationRegistry dc;

    constructor(bytes32 _allowList, address _dc) ERC721("Tone Garden Founders Pass", "TONE") {
        allowList = _allowList;
        dc = IDelegationRegistry(_dc);
    }

    function mint(address _to) internal {
        _totalSupply.increment();
        _safeMint(_to, _totalSupply.current());
    }

    function allowListMint(address _vault, uint256 amount, bytes32[] calldata proof) public payable {
        require(phase1, "phase 1 not enabled");
        require(amount * ALLOW_LIST_PRICE == msg.value, "Insufficient funds.");

        address requester = msg.sender;
        if (_vault != address(0)) { 
            bool isDelegateValid = dc.checkDelegateForContract(msg.sender, _vault, address(this));
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }

        string memory payload = string(abi.encodePacked(requester));
        require(_verify(_leaf(payload), proof, allowList), "invalid proof");
        require(_totalSupply.current() + amount <= MAX_SUPPLY, "exceeds max supply");

        for(uint i; i < amount; i++) {
            mint(requester);
        }
    }

    function partnerMint(address _vault, uint256 amount, address collection) public payable {
        require(phase1, "phase 1 not enabled");
        require(amount * ALLOW_LIST_PRICE == msg.value, "Insufficient funds.");
        require(_totalSupply.current() + amount <= MAX_SUPPLY, "exceeds max supply");

        address requester = msg.sender;
        if (_vault != address(0)) { 
            bool isDelegateValid = dc.checkDelegateForContract(msg.sender, _vault, address(this));
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }

        IERC721 erc721 = IERC721(collection);
        require(erc721.balanceOf(requester) > 0, "");
        for(uint i; i < amount; i++) {
            mint(requester);
        }
    }

    function publicMint(address _vault, uint256 quantity) public payable {
        require(phase2, "public mint not enabled");
        require(_totalSupply.current() + quantity <= MAX_SUPPLY, "exceeds max supply");
        require(quantity <= MAX_MINT, "max minted for wallet");
        require(quantity * PRICE == msg.value, "Insufficient funds.");

        address requester = msg.sender;
        if (_vault != address(0)) {
            requester = _vault;
        }

        for(uint i; i < quantity; i++) {
            mint(requester);
        }
    }

    function teamMint(uint amount) public onlyOwner {
        require(_totalSupply.current() + amount <= MAX_TEAM_MINT, "exceeds max team mint");

        for(uint i; i < amount; i++) {
            mint(msg.sender);
        }

        devTeamMinted = true;
    }

    function flipPhase1() public onlyOwner {
        phase1 = !phase1;
    }

    function flipPhase2() public onlyOwner {
        phase2 = !phase2;
    }

    function _leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function withdraw() public {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send to owner.");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        _baseURL = _uri;
    }

    function getClaimableAddresses() public view returns (address[] memory){
        return claimableAddrs;
    }

    function clearClaimableAddresses() external onlyOwner {
        while(claimableAddrs.length > 0) {
            claimableAddrs.pop();
        }
    }

    function addClaimableAddress(address _addr) external onlyOwner {
        claimableAddrs.push(_addr);
    }

    function addedClaimableAddresses(address[] memory _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            claimableAddrs.push(_addresses[i]);
        }
    }

    function hasCollectionPartnerNFT(address addr) public view returns (address) {
        for (uint i = 0; i < claimableAddrs.length; i++) {
            IERC721 erc721 = IERC721(claimableAddrs[i]);
            if (erc721.balanceOf(addr) > 0) {
                return claimableAddrs[i];
            }
        }

        return address(0);
    }

    function getAllowList() public view returns (bytes32) {
        return allowList;
    }

    function setAllowList(bytes32 _allowList) external onlyOwner {
        allowList = _allowList;
    }
}
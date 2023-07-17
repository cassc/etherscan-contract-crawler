// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "ERC1155.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Pausable.sol";
import "ERC1155Burnable.sol";
import "ERC1155Supply.sol";
import "MerkleProof.sol";

contract BillionaireBabiesIncubator is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {

    string public name = "mintincubator";
    string public symbol = "bbi";


    uint256 public constant INCUBATOR = 1;
    uint256 public constant MAX_MINT_PER_ADDRESS = 5;
    uint256 public preSaleMintPrice = 0.1 ether;
    uint256 public publicSaleMintPrice = 0.15 ether;
    uint256 public tokenCount;

    bytes32 internal merkleRoot;

    bool public preSaleOpen = false;
    bool public publicSaleOpen = false;
    bool public teamAwardClaimed = false;
    address payable internal teamAddress;
    mapping(address => uint256) internal preSaleUserMints;
    mapping(address => uint256) internal publicSaleUserMints;

    /// Function Not open yet
    error NotOpenYet();
    /// Amount exceeds address allowance
    error AmountExceedsAllowance();
    /// msg.value too low
    error MintPayableTooLow();
    /// You are not on the whitelist
    error NotOnWhitelist();
    /// Team award already claimed
    error TeamAwardClaimed();

    constructor(address _teamAddress) ERC1155("") {
        teamAddress = payable(_teamAddress);
    }

    modifier isBelowUserAllowance(uint256 amount, mapping(address => uint256) storage userMints) {
        if (SafeMath.add(amount, userMints[msg.sender]) > MAX_MINT_PER_ADDRESS)
            revert AmountExceedsAllowance(); // dev: amount would exceed address allowance
        _;
    }

    modifier isNotBelowMintPrice(uint256 _amount, uint256 _mintPrice) {
        if (msg.value < SafeMath.mul(_amount, _mintPrice))
            revert MintPayableTooLow(); // dev: msg.value too low
        _;
    }

    function preSaleMint(uint256 _amount, bytes32[] calldata _merkleProof) external
        isNotBelowMintPrice(_amount, preSaleMintPrice)
        isBelowUserAllowance(_amount, preSaleUserMints)
        payable {
        if (preSaleOpen == false) revert NotOpenYet(); // dev: premint not open

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf) == false)
            revert NotOnWhitelist(); // dev: not on the whitelist
        safeMint(_amount, preSaleUserMints);
    }

    function publicMint(uint256 _amount) external
        isNotBelowMintPrice(_amount, publicSaleMintPrice)
        isBelowUserAllowance(_amount, publicSaleUserMints)
        payable {
        if (publicSaleOpen == false) revert NotOpenYet(); // dev: public mint not open
        safeMint(_amount, publicSaleUserMints);
    }

    function safeMint(uint256 _amount, mapping(address => uint256) storage _userMints) internal
        {
        tokenCount = SafeMath.add(tokenCount, _amount);
        _userMints[msg.sender] = SafeMath.add(_userMints[msg.sender], _amount);
        _mint(msg.sender, INCUBATOR, _amount, "");
    }

    function teamAward() external onlyOwner {
        if (teamAwardClaimed) revert TeamAwardClaimed(); // dev: team award claimed

        teamAwardClaimed = true;
        tokenCount = SafeMath.add(tokenCount, 50);
        _mint(teamAddress, INCUBATOR, 50, "");
    }

    function withdrawFunds() external virtual onlyOwner {
        teamAddress.transfer(address(this).balance);
    }

    /**
    * views
    */

    function getPreSaleAddressRemainingMints(address _address) external view returns (uint256) {
        return MAX_MINT_PER_ADDRESS - preSaleUserMints[_address];
    }

    function getPublicSaleAddressRemainingMints(address _address) external view returns (uint256) {
        return MAX_MINT_PER_ADDRESS - publicSaleUserMints[_address];
    }

    /**
    * Settings
    */

    function togglePreSaleOpen() external virtual onlyOwner {
        preSaleOpen = !preSaleOpen;
    }

    function togglePublicSaleOpen() external virtual onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setPreSaleMintPrice(uint256 _mintPrice) public onlyOwner {
        preSaleMintPrice = _mintPrice;
    }

    function setPublicSaleMintPrice(uint256 _mintPrice) public onlyOwner {
        publicSaleMintPrice = _mintPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Pysanka humanitarian NFT
/// @notice The Pysanka project was born from the desire to help the Ukrainian people after they were attacked by Russia, while showing gratitude to anyone that donates to the cause.
/// @custom:security-contact [email protected]
contract PysankaV2 is ERC721, Ownable {
    using Counters for Counters.Counter;

    bool private reentrancyGuard;
    /// @notice Maximum amount of tokens that can be minted.
    uint public immutable supplyCap = 10_000;
    /// @notice Price of a single NFT mint.
    uint public immutable tokenPrice = 0.0380 ether;
    /// @notice Total number of beneficiaries of minting.
    uint public numberOfBeneficiaries;
    uint private teamSize;

    /// @notice Array of the beneficiaries of minting.
    mapping(uint => Beneficiary) public beneficiaries;
    mapping(uint => address payable) private team;

    struct Beneficiary{
        address payable beneficiary;
        string title;
    }

    Counters.Counter private _tokenIdCounter;

    event NewBeneficiary(
        address indexed beneficiary,
        string title,
        uint currentNumberOfBeneficiaries
    );

    constructor(address[] memory initialHodlers, address[] memory _team) ERC721("Pysanka", "PYS") {
        for(uint i = 0; i < initialHodlers.length; i++){
            require(safeMint(initialHodlers[i]), "Pysanka: initailMint failed");
        }
        for(uint j = 0; j < _team.length; j++){
            team[j] = payable(_team[j]);
        }
        teamSize = _team.length;
    }

    modifier reentrancyProtection(){
        require(!reentrancyGuard, "Pysanka: reentrancyGuard");
        reentrancyGuard = true;
        _;
        reentrancyGuard = false;
    }

    /// @notice Returns the current supploy of minted tokens.
    /// @return uint Number of tokens
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    /// @notice Adds beneficiary of the minting.
    /// @param _beneficiary Address of the beneficiary
    /// @param _title Title of the beneficiary
    function addBeneficiary(address payable _beneficiary, string memory _title) public onlyOwner {
        require(_beneficiary != address(0x0), "Pysanka: _beneficiary is 0x0 address");
        require(
            keccak256(abi.encodePacked(_title)) != keccak256(abi.encodePacked("")),
            "Pysanka: _title is empty string"
        );
        beneficiaries[numberOfBeneficiaries].beneficiary = _beneficiary;
        beneficiaries[numberOfBeneficiaries].title = _title;
        numberOfBeneficiaries += 1;
        emit NewBeneficiary(_beneficiary, _title, numberOfBeneficiaries);
    }

    /// @notice Mints the tokens. The amount of tokens is determined by the amount of Ether acompanying the transaction divided by the token price.
    /// @return bool Status of execution
    function saleMint() public payable returns(bool){
        require(_tokenIdCounter.current() < supplyCap, "Pysanka: supplyCap reached");
        require(tokenPrice <= msg.value, "Pysanka: not enough Ether to buy token");
        require(msg.value/tokenPrice <= 100, "Pysanka: can only mint 100 tokens in one transaction");
        require(
            _tokenIdCounter.current() + msg.value/tokenPrice <= supplyCap,
            "Pysanka: minting this amount would surpass supply cap"
        );
        for(uint i = 0; i < msg.value/tokenPrice; i++){
            require(safeMint(msg.sender), "Pysanka: saleMint failed");
        }
        return true;
    }

    /// @notice Used to forward the funds accumulated by the minting process
    /// @return bool Status of execution
    function allocateFunds() public reentrancyProtection returns(bool) {
        uint humanitarianFunds = address(this).balance / 10 * 9;
        uint maintenanceFunds = address(this).balance - humanitarianFunds;

        for(uint i = 0; i < numberOfBeneficiaries; i++){
            (bool success, ) = beneficiaries[i].beneficiary.call{value: humanitarianFunds/numberOfBeneficiaries}("");
            require(success, "Pysanka: allocating beneficiaty funds failed");
        }

        team[0].transfer(maintenanceFunds - (maintenanceFunds / 100 * 5 * (teamSize - 1)));
        for(uint j = 1; j < teamSize; j++){
            (bool success, ) = team[j].call{value: maintenanceFunds / 100 * 5}("");
            require(success, "Pysanka: allocating team funds failed");
        }
        return true;
    }

    function safeMint(address to) internal returns(bool) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://pysanka.xyz/tokens/metadata/";
    }

    fallback() external payable {
        require(saleMint(), "Pysanka: saleMintfailed");
    }

    receive() external payable {
        require(saleMint(), "Pysanka: saleMintfailed");
    }
}
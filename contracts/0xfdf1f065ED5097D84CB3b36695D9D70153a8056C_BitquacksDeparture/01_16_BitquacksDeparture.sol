// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IBitQuackPassportDepature.sol";
import "./Soulbound.sol";

contract BitquacksDeparture is IBitQuackPassportDepature, Ownable, Soulbound {

    string public contractURIString;
    string public tokenImageString = "https://northupcrypto.mypinata.cloud/ipfs/QmP4B561dmad2SnmtqzNixAJUcaVNdJWAh1o2wFYuJt1Va";


    address passportAddress = 0xd9607B6061936Cc49cc0384f324A49756EeFAfF4;

    struct Depature{
        uint256 timestamp;
        string ordAddress;
    }

    mapping(uint256=>Depature) public departures;

    constructor() ERC721("BitQuack Used Passports", "BQUP") {}

    //////// Public functions

    event TransferToBTC(uint256 indexed id, string ordAddress);
    function transferOrdinal(uint256 id, string memory ordAddress) public override returns (bool){
        // Must come from BQP contract
        require(msg.sender == passportAddress);
        
        // Give SBT for on-eth tracking
        _mint(tx.origin , id);

        // Transfer
        emit TransferToBTC(id, ordAddress);
        departures[id] = Depature(block.timestamp, ordAddress);
        return true;
    }

    function getTokenOrdAddress(uint256 id) external view returns(string memory){
        return departures[id].ordAddress;
    }

    function getTokenTimestamp(uint256 id) external view returns(uint256){
        return departures[id].timestamp;
    }

    function contractURI() public view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "BitQuack Used Passport #',
                                Strings.toString(tokenId),
                                '", "description": "BitQuack Passports are a gateway token to obtaining a BitQuack ordinal through burning MoonQuacks", "image": "',
                                tokenImageString,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    //////// Owner functions    
    function setPassportAddress(address _passportAddress) external onlyOwner {
        passportAddress = _passportAddress;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setTokenImageString(string memory _tokenImageString)
        external
        onlyOwner
    {
        tokenImageString = _tokenImageString;
    }

}
// [email protected]_ved
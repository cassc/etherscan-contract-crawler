pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/**
 * NFT Contract, 2022.
 * Scotland, UK.
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract EligibleCollection {
    function ownerOf(uint256 _tokenId) external view virtual returns (address);

    function totalSupply() public view virtual returns (uint256);
}

contract NFTContractERC721A is ERC721A, Ownable {
    uint256 public tokenPrice;
    uint256 public maxMintsPerToken;
    uint256 public maxTokens;
    bool public saleIsActive;
    string private baseURI;

    address[] public eligibleContractAddresses;
    mapping(address => EligibleCollection) public eligibleContracts;
    /*
     * Creates a map of key: address, value: a map of key: tokenID, value: # mints
     */
    mapping(address => mapping(uint256 => uint256)) public usedEligibleMints;

    constructor(
        string memory collectionName,
        string memory tokenName,
        uint256 _tokenPrice,
        uint256 _maxMintsPerToken,
        address[] memory _eligibleContractAddresses
    ) ERC721A(collectionName, tokenName) {
        baseURI = "PUT YOUR URL HERE";
        saleIsActive = false;
        tokenPrice = _tokenPrice;
        maxMintsPerToken = _maxMintsPerToken;
        eligibleContractAddresses = _eligibleContractAddresses;
        for (uint8 i = 0; i < eligibleContractAddresses.length; i++) {
            eligibleContracts[
                eligibleContractAddresses[i]
            ] = EligibleCollection(eligibleContractAddresses[i]);
            maxTokens += eligibleContracts[eligibleContractAddresses[i]]
                .totalSupply();
        }
    }

    function getEligibleContractAddresses()
        public
        view
        returns (address[] memory)
    {
        return eligibleContractAddresses;
    }

    function doesSenderOwnToken(address contractAddress, uint256 tokenID)
        public
        view
        returns (bool)
    {
        require(
            isContractAddressValid(contractAddress),
            "Contract address is invalid"
        );
        return
            eligibleContracts[contractAddress].ownerOf(tokenID) == msg.sender;
    }

    function isContractAddressValid(address contractAddress)
        public
        view
        returns (bool)
    {
        for (uint8 i = 0; i < eligibleContractAddresses.length; i++) {
            if (eligibleContractAddresses[i] == contractAddress) {
                return true;
            }
        }
        return false;
    }

    /*
     * Sets the baseURI for all tokens metadata
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /*
     * Getter for the baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * Start the general sale
     */
    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale already started");
        saleIsActive = true;
    }

    /*
     * Pause the general sale
     */
    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale already paused");
        saleIsActive = false;
    }

    function getNumberOfTokenAddressCombo(
        address _address,
        uint256 tokenID,
        address[] calldata addresses,
        uint256[] calldata tokenIDs
    ) public pure returns (uint8) {
        uint8 numberOfTokenIDsDuplicates;
        for (uint8 i = 0; i < addresses.length; i++) {
            if (_address == addresses[i] && tokenID == tokenIDs[i]) {
                numberOfTokenIDsDuplicates += 1;
            }
        }
        return numberOfTokenIDsDuplicates;
    }

    /**
     * Checks if a token is eligible for minting
     */

    function tokenChecker(
        address[] calldata addresses,
        uint256[] calldata tokenIDs
    ) external view returns (bool) {
        for (uint8 i = 0; i < addresses.length; i++) {
            if (
                usedEligibleMints[addresses[i]][tokenIDs[i]] +
                    getNumberOfTokenAddressCombo(
                        addresses[i],
                        tokenIDs[i],
                        addresses,
                        tokenIDs
                    ) <=
                maxMintsPerToken
            ) {
                return true;
            }
        }
        return false;
    }

    /*
     * Mints a given number of tokens
     */
    function mint(address[] calldata addresses, uint256[] calldata tokenIDs)
        external
        payable
    {
        require(saleIsActive, "Sale is not active");
        require(
            addresses.length == tokenIDs.length,
            "Addresses and tokenIDs should be same length"
        );
        require(
            totalSupply() + addresses.length <= maxTokens,
            "Not enough tokens left"
        );
        require(
            tokenPrice * addresses.length <= msg.value,
            "Ether value sent is not correct"
        );
        for (uint8 i = 0; i < tokenIDs.length; i++) {
            require(
                doesSenderOwnToken(addresses[i], tokenIDs[i]) == true,
                "Token not owned by msg sender"
            );
            require(
                usedEligibleMints[addresses[i]][tokenIDs[i]] +
                    getNumberOfTokenAddressCombo(
                        addresses[i],
                        tokenIDs[i],
                        addresses,
                        tokenIDs
                    ) <=
                    maxMintsPerToken,
                "Token used to mint already"
            );
        }
        for (uint8 i = 1; i <= addresses.length; i++) {
            usedEligibleMints[addresses[i - 1]][tokenIDs[i - 1]] += 1;
        }
        _mint(msg.sender, addresses.length);
    }

    /*
     * Withdraw the money from the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
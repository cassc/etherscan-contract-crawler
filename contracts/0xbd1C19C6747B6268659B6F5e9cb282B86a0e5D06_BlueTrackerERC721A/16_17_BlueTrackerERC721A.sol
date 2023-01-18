// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

/*

______ _          _____              _             
| ___ \ |        |_   _|            | |            
| |_/ / |_   _  ___| |_ __ __ _  ___| | _____ _ __ 
| ___ \ | | | |/ _ \ | '__/ _` |/ __| |/ / _ \ '__|
| |_/ / | |_| |  __/ | | | (_| | (__|   <  __/ |   
\____/|_|\__,_|\___\_/_|  \__,_|\___|_|\_\___|_|   

                                                                
*/
/// @title Bluetracker NFT contract.
contract BlueTrackerERC721A is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        PublicSale,
        SoldOut
    }

    // Private
    string private _baseTokenUri;
    uint private teamLength;
    uint private maxPublic =  220;
    uint private maxGift = 113;
    uint private currentGift = 0;

    // Public
    uint public maxSupply = maxPublic + maxGift;
    Step public sellingStep;
    uint public publicSalePrice = 0.06 ether;
    uint public constant MAX_PER_WALLET_PUBLIC = 1;
    mapping(address => uint) public publicAddresses;

    //Constructor of the collection
    constructor(string memory baseTokenUri, address[] memory _team, uint[] memory _teamShares) 
    ERC721A("Bluetracker - Token", "BtT")
    PaymentSplitter(_team, _teamShares) {
        _baseTokenUri = baseTokenUri;
        teamLength = _team.length;
    }

    /**
    * @notice Ensure that the transaction comes from a user and not a contract
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Publicly mint a _quantity of NFT to the _account
    **/
    function publicSaleMint() external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale not activated or soldout");
        require(msg.value == publicSalePrice, "Funds given do not match requested price");
        require(publicAddresses[msg.sender] + 1 <= MAX_PER_WALLET_PUBLIC, "Max amount already reached for public");
        require(totalSupply() + 1 - currentGift <= maxPublic, "Reached max supply");
        publicAddresses[msg.sender] += 1;
        _safeMint(msg.sender, 1);
        if(totalSupply() - currentGift >= maxPublic) {
            sellingStep = Step.SoldOut;
        }
    }

    /**
    * @notice Gift a _quantity of NFT to the _account
    **/
    function gift(address[] calldata _to, uint[] calldata _quantity, uint totalQuantity) external onlyOwner {
        require(sellingStep > Step.Before, "Gift can happen only during public or soldout space");
        require(currentGift + totalQuantity <= maxGift, "Max supply for gift exceed");
        uint receiverLength = _to.length;
        require(receiverLength == _quantity.length, "Different amount of parameters send between receiver and quantity");
        for(uint i = 0; i < receiverLength; i++)
        {
            _safeMint(_to[i], _quantity[i]);
        }
        currentGift += totalQuantity;
    }

    /**
    * @notice Define the base revealed for the NFT
    */
    function setbaseTokenUri(string memory baseTokenUri) external onlyOwner {
        _baseTokenUri = baseTokenUri;
    }

    /** 
    * @notice Change the supply for the public
    *
    * @param newPublicSupply The new public supply
    */
    function setMaxPublicSupply(uint newPublicSupply) external onlyOwner {
        maxPublic = newPublicSupply;
        maxSupply = maxPublic + maxGift;
    }

    /** 
    * @notice Change the supply for the gifts
    *
    * @param newGiftSupply The new gift supply
    */
    function setMaxGiftSupply(uint newGiftSupply) external onlyOwner {
        maxGift = newGiftSupply;
        maxSupply = maxPublic + maxGift;
    }

    /**
    * @notice Change the public price
    *
    * @param newPriceValue The new public price
    */
    function setPublicPrice(uint newPriceValue) external onlyOwner {
        publicSalePrice = newPriceValue;
    }

    /**
    * @notice Change the current step to the new _step
    *
    * @param newStep The new step for the contract
    */
    function setStep(uint newStep) external onlyOwner {
        sellingStep = Step(newStep);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view virtual override returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        return string(abi.encodePacked(_baseTokenUri, _nftId.toString(), ".json"));
    }

    /**
    * @notice Pay everyone in the team
    */
    function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }
}